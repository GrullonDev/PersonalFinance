# 📋 Política de Privacidad - Personal Finance

Este directorio contiene todos los archivos necesarios para cumplir con los requisitos de política de privacidad de Google Play Store.

## 📁 Archivos Incluidos

### 1. `privacy_policy.html` (Raíz del proyecto)
- **Propósito**: Política completa para revisar durante el desarrollo
- **Ubicación**: `/privacy_policy.html`
- **Uso**: Referencia completa con todos los detalles legales

### 2. `assets/privacy_policy.md`
- **Propósito**: Versión incluida en la aplicación Flutter
- **Ubicación**: `/assets/privacy_policy.md`
- **Uso**: Se muestra dentro de la app mediante `PrivacyPolicyPage`

### 3. `web_privacy/index.html`
- **Propósito**: Versión web para hospedar en tu sitio web
- **Ubicación**: `/web_privacy/index.html`
- **Uso**: Sube este archivo a tu servidor web

### 4. `lib/features/privacy/pages/privacy_policy_page.dart`
- **Propósito**: Página Flutter para mostrar la política dentro de la app
- **Ubicación**: `/lib/features/privacy/pages/privacy_policy_page.dart`
- **Uso**: Integra en tu app para acceso desde configuraciones

## 🚀 Pasos para Implementar en Google Play

### Paso 1: Subir la Política Web
1. Sube el archivo `web_privacy/index.html` a tu servidor web
2. Asegúrate de que sea accesible vía HTTPS
3. Ejemplo de URL: `https://tudominio.com/privacy-policy`
4. Verifica que carga correctamente

### Paso 2: Configurar en Google Play Console
1. Ve a **Google Play Console**
2. Selecciona tu aplicación
3. Ve a **Política** → **Política de privacidad**
4. Ingresa la URL de tu política web
5. Guarda los cambios

### Paso 3: Integrar en la Aplicación (Opcional pero Recomendado)
```dart
// En tu drawer o página de configuraciones, agrega:
ListTile(
  leading: Icon(Icons.privacy_tip),
  title: Text('Política de Privacidad'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  },
),
```

## ⚙️ Configuración del Archivo Assets

El archivo `pubspec.yaml` ya está configurado para incluir la política:

```yaml
assets:
  - assets/logo.png
  - assets/privacy_policy.md
```

## 🌐 Opciones de Hosting Web

### Opción 1: GitHub Pages (Gratis)
1. Crea un repositorio `tu-usuario.github.io`
2. Sube el archivo como `privacy-policy.html`
3. URL resultante: `https://tu-usuario.github.io/privacy-policy.html`

### Opción 2: Netlify (Gratis)
1. Crea cuenta en Netlify
2. Arrastra la carpeta `web_privacy` al panel
3. URL personalizada disponible

### Opción 3: Vercel (Gratis)
1. Crea cuenta en Vercel
2. Conecta con GitHub
3. Despliega automáticamente

### Opción 4: Tu Propio Dominio
1. Sube `index.html` a tu servidor
2. Configura HTTPS
3. Usa tu dominio personalizado

## 📝 Personalización Necesaria

### ⚠️ IMPORTANTE: Actualiza estos datos antes de publicar

1. **Email de contacto**: Cambia `privacy@grullondev.com` por tu email real
2. **Información del desarrollador**: Actualiza datos de GrullonDev
3. **URL del sitio web**: Reemplaza `https://yourwebsite.com` con tu URL real
4. **Información legal**: Agrega tu información de registro empresarial si corresponde

### Archivos a editar:
- `privacy_policy.html` (líneas con contacto)
- `assets/privacy_policy.md` (sección de contacto)
- `web_privacy/index.html` (información de contacto)
- `lib/features/privacy/pages/privacy_policy_page.dart` (emails de contacto)

## 🔍 Verificación antes de Publicar

### Checklist de Cumplimiento:
- [ ] URL de política accesible vía HTTPS
- [ ] Política carga correctamente en móvil y desktop
- [ ] Información de contacto actualizada y funcional
- [ ] Email de privacidad configurado y funcionando
- [ ] Política integrada en la aplicación
- [ ] URL agregada en Google Play Console
- [ ] Fechas de actualización correctas

### Testing:
1. Verifica que la URL carga en diferentes navegadores
2. Prueba en móvil y desktop
3. Confirma que los emails funcionan
4. Revisa que todos los enlaces internos funcionen

## 📊 Cumplimiento Legal

Esta política cumple con:
- ✅ **GDPR** (Unión Europea)
- ✅ **CCPA** (California)
- ✅ **LGPD** (Brasil)
- ✅ **PIPEDA** (Canadá)
- ✅ **Google Play Policy**
- ✅ **Apple App Store Guidelines**

## 🆘 Resolución de Problemas Comunes

### Error: "URL no accesible"
- Verifica que la URL use HTTPS
- Confirma que el archivo esté correctamente subido
- Prueba la URL en modo incógnito

### Error: "Política incompleta"
- Asegúrate de incluir todas las secciones requeridas
- Verifica que la información de contacto sea válida
- Confirma que menciones el manejo de datos de menores

### Error: "Información de contacto inválida"
- Usa un email real y funcional
- Incluye información completa del desarrollador
- Agrega tiempo de respuesta realista

## 📞 Soporte

Si necesitas ayuda con la implementación:
1. Revisa la documentación de Google Play Console
2. Consulta las guías de GDPR y CCPA
3. Considera consultar con un abogado especializado en privacidad digital

---

**Nota**: Esta política es un punto de partida sólido, pero siempre es recomendable que un profesional legal revise el documento final, especialmente si manejas datos sensibles o operas en múltiples jurisdicciones.
