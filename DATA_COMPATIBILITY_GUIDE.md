# Guía Técnica de Compatibilidad de Datos (Firestore -> Local)

Este documento sirve como contrato técnico para el mapeo y la sanitización de los datos almacenados en nuestra base de datos remota (Firestore) hacia la nueva arquitectura de la aplicación orientada al offline-first (Quick Finance).

## 1. El Problema de las Inconsistencias
La base de datos original fue alimentada usando diferentes versiones de los modelos de la app, lo que generó desviaciones en el tipado de los datos (e.g., valores almacenados como `String` que lógicamente son numéricos) y diferencias de nomenclatura (diccionarios no alineados). 

Para evitar crasheos silenciosos o excepciones de parseo (`TypeError`), nuestro sistema implementa una **Capa de Sanitización / Mapper Tolerante**.

## 2. Reglas de Traducción (Mapper Tolerante)

### 2.1. Tipos de Transacción (`type` / `tipo`)
El campo antiguo `tipo` acepta strings variados por falta de un Enum cerrado en el backend. 
- **Entrada detectada:** `'gasto'`, `'egreso'`, `'expense'`, `'ingreso'`, `'income'`.
- **Salida estandarizada:** Enumerador `TransactionType`.
- **Regla de mapeo:** Todo lo que empiece por `'gast'`, `'egres'`, o `'expens'` (case-insensitive) se mapea forzosamente a `TransactionType.expense`. Todo lo que empiece por `'ingre'` o `'incom'` va a `TransactionType.income`.

### 2.2. Montos (`amount` / `monto`)
- **Entrada detectada:** Valores `String` como `"250.50"` para mitigar la pérdida de precisión de coma flotante en JSON/Firestore antiguo. Ocasionalmente pueden venir como enteros o dobles nativos.
- **Salida estandarizada:** Tipo `double` para manipulación local.
- **Regla de mapeo:** Si el valor es de tipo numérico, se realiza `.toDouble()`. Si es un string, se utiliza `double.tryParse` removiendo comas para soportar strings mal formateados. El Default fallback será `0.0`.

### 2.3. Identificador de Perfil (`profileId` / `profile_id`)
- **Entrada detectada:** Algunos documentos en Firestore fueron creados usando el tipo `int` nativo, mientras que en entidades como `Budget` se escribieron como `String`.
- **Salida estandarizada:** Tipo `String` estricto, dado que es el estándar moderno en la mayoría de implementaciones Firebase Auth.
- **Regla de mapeo:** Al parsear `profile_id`, todo valor será forzado usando `.toString()`. 

### 2.4. Fechas (`createdAt`, `date`, `fecha`, `fecha_inicio`)
- **Entrada detectada:** Strings ISO-8601 acortadas (`'YYYY-MM-DD'`), o tipos `Timestamp` si fueron introducidos directo por funciones Firebase.
- **Salida estandarizada:** `DateTime` de Dart local.
- **Regla de mapeo:** Se verifica si la data entrante es un objeto `Timestamp` de la SDK de Firebase. Si lo es, se invoca `.toDate()`. De lo contrario, si es un `String`, se invoca `DateTime.tryParse()`. El fallback si falla será `DateTime.now()`.

### 2.5. Deudas (Debts)
- **Estado Actual:** No existe un payload local en el codebase de `develop` diseñado para deudas. 
- **Decisión Arquitectónica:** Se omiten las deudas del flujo `TransactionEntity` central para mantener un modelo transaccional puro. Las deudas deben gestionarse en su propio subdominio y en su momento implementarán un mapper similar regido por este mismo estándar (Fechas tryParse, montos como String parseables, etc).

## 3. Implementación
El cumplimiento de este contrato lo garantiza la clase `LegacyTransactionMapper` (ubicada en la carpeta global `lib/core/mappers/legacy_transaction_mapper.dart` dada su responsabilidad transversal).

Para facilitar el uso directo con Firebase, el mapper soporta formalmente dos entradas de inyección:
- **Opción Ideal:** `LegacyTransactionMapper.fromFirestore(DocumentSnapshot doc)` -> Consume directamente la metadata real del documento y ejecuta la extracción segura.
- **Opción Alternativa:** `LegacyTransactionMapper.fromMap(Map<String, dynamic> json, {String? documentId})` -> Uso estándar en texto crudo.

## 4. Tabla de Prioridad de Nombres Legacy
Para mantener consistencia, el mapper resolverá los nombres de llaves de los diccionarios legacy según el siguiente orden de prioridad estricto. Si la primera llave existe y no es nula, se utiliza; si no, se busca la siguiente.

| Campo Destino | Prioridad de Búsqueda (Legacy Keys) | Valor por Defecto / Fallback |
| --- | --- | --- |
| **ID** | `id`, *documentId (Firestore)* | `Uuid().v4()` o Timestamp Generator |
| **Tipo** | `type`, `tipo` | `TransactionType.expense` |
| **Monto** | `amount`, `monto` | `0.0` |
| **Nota** | `note`, `description`, `descripcion`, `title`, `nombre` | `''` (String vacío) |
| **Categoría** | `categoryId`, `category_id`, `categoria_id` | `null` |
| **Fecha de Creación** | `createdAt`, `fecha_creacion`, `date`, `fecha` | `DateTime.now()` |
| **Fecha de Actualización** | `updatedAt`, `fecha_actualizacion` | Fallback a `createdAt` |
| **Eliminación lógica** | `deletedAt`, `fecha_eliminacion` | `null` |
| **Versión** | `version` | `1` |

## 5. Contrato Final del Modelo (`TransactionEntity`)
El modelo destino final en nuestra capa de dominio queda estructurado de la siguiente forma una vez ha sido depurado por el mapper:

```dart
class TransactionEntity {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String note;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final int version;
  final String? deviceId;
}
```

**Esclarecimientos Finales:**
- `id`: Viene del doc ID de Firestore o del campo `id` si existe.
- `userId`: Se toma del usuario autenticado en sesión, NO necesariamente del documento JSON.
- `note`: Sale de `description`, `descripcion`, `note`, `title` o `nombre` proveniente del legado.
- `categoryId`: Puede venir `null` en caso de no especificarse.
- `updatedAt`: Usa fallback a `createdAt` si no fue registrado.
- `deletedAt`: Puede ser `null`.
- `version`: Maneja como un entero de default `1`.
- `deviceId`: Es opcional y representa el dispositivo de origen.

## 6. Manejo de Documentos Inválidos (Fallbacks y Logging)

Es mandatorio no utilizar fallbacks silenciosos que oculten anomalías graves en la base de datos de producción. Si un documento recuperado de la red carece de información vital, el sistema emitirá alertas utilizando `dart:developer` logs (etiquetados con `'LegacyMapper'`) para asegurar la trazabilidad y aplicará las siguientes reglas rígidamente:

1. **Monto Vacío o No Parseable:** Se forzará `amount = 0.0`. Se emite un Log de Alerta Grave advirtiendo la pérdida de datos numéricos.
2. **Tipo de Transacción Inexistente o Corrupto:**
   - Si no existe (llaves en null o vacías), se emite Alerta Crítica y se infiere consultando el **signo** del monto documentado (`amount >= 0` -> Income, caso contrario Expense).
   - Independientemente del tipo inferido, el monto local se guarda purificado con `.abs()` para cumplir las matemáticas del offline-first.
3. **Fecha Faltante:** Se forzará `DateTime.now()`. Se emite Log de Alerta Grave indicando que el documento perdió su cronología y afectará los reportes.
4. **Falta de Texto / Descripción:** Si tras limpiar espacios (`trim()`), el texto es vacío, se fuerza en código la constante del UI: `'Sin descripción'` y se emite un Log Menor de Advertencia.
