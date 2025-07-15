# Personal Finance

Personal Finance es una aplicación móvil desarrollada en Flutter que te ayuda a gestionar tus finanzas personales de manera sencilla y eficiente. Con esta app podrás registrar tus ingresos y gastos, visualizar reportes y tomar mejores decisiones financieras.

---

## 👤 Autor

Proyecto creado y mantenido por **[Jorge Marroquín](https://github.com/GrullonDev)**.  
¿Tienes sugerencias, dudas o deseas colaborar? ¡Contáctame a través de mi perfil de GitHub!

---

## 🚀 Características principales

- Registro rápido de ingresos y gastos
- Visualización de reportes y gráficos interactivos
- Categorías personalizables para tus transacciones
- Consejos financieros diarios integrados
- Onboarding educativo para nuevos usuarios
- Interfaz intuitiva, profesional y responsiva
- Soporte multiplataforma: **Android** e **iOS**
- Persistencia local con Hive
- Arquitectura limpia y escalable (Clean Architecture, SOLID)
- Actualización instantánea de la información

---

## 🛠️ Tecnologías utilizadas

- **Flutter**: 3.32.4
- **Dart**: >=3.0.0
- **FVM** (Flutter Version Management) para gestionar versiones de Flutter
- **Hive** para almacenamiento local
- **Provider** para gestión de estado
- **Firebase** (opcional, para autenticación)
- **Syncfusion Flutter Charts** para gráficos

---

## ⚙️ Configuración del proyecto

### 1. Clona el repositorio

```bash
git clone https://github.com/tu-usuario/personal_finance.git
cd personal_finance
```

### 2. Instala FVM y configura la versión de Flutter

Se recomienda usar [FVM](https://fvm.app/) para garantizar la versión correcta de Flutter:

```bash
dart pub global activate fvm
fvm install 3.32.4
fvm use 3.32.4
```

> **Nota:** Si no tienes FVM, puedes instalarlo siguiendo la [guía oficial](https://fvm.app/docs/getting_started/installation/).

### 3. Instala las dependencias

```bash
fvm flutter pub get
```

### 4. Ejecuta la aplicación

```bash
fvm flutter run
```

---

## 📦 Cómo generar APK (Android) y IPA (iOS)

### Generar APK para Android

```bash
fvm flutter build apk --release
```
El archivo APK se generará en `build/app/outputs/flutter-apk/app-release.apk`.

### Generar IPA para iOS

1. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Selecciona tu equipo de desarrollo y dispositivo.
3. Ejecuta:
   ```bash
   fvm flutter build ipa --release
   ```
4. Sigue el flujo de Xcode para firmar y exportar el IPA.

> **Nota:** Para compilar en iOS necesitas una Mac y una cuenta de desarrollador de Apple.

---

## 📝 Reglas para contribuir

1. **Usa FVM y la versión especificada de Flutter.**
2. Crea una rama para tu feature o corrección:
   ```bash
   git checkout -b nombre-de-tu-rama
   ```
3. Realiza tus cambios y asegúrate de que todo funcione correctamente.
4. Haz commit y push de tus cambios:
   ```bash
   git add .
   git commit -m "Descripción clara de los cambios"
   git push origin nombre-de-tu-rama
   ```
5. Abre un **Pull Request** describiendo detalladamente tus aportes.
6. Espera la revisión y feedback antes de fusionar.

---

## 📬 Envío de cambios

- Todos los cambios deben pasar por revisión antes de ser fusionados.
- Mantén una comunicación clara y proporciona contexto sobre tus aportes.
- Si tienes dudas, abre un issue o contacta directamente.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## 📚 Recursos útiles

- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [FVM - Flutter Version Management](https://fvm.app/)
- [Hive - Documentación](https://docs.hivedb.dev/)
- [Syncfusion Flutter Charts](https://pub.dev/packages/syncfusion_flutter_charts)

---

¡Gracias por tu interés y por ayudar a crecer este proyecto!  
Si te gusta, dale ⭐️ al repositorio y compártelo.
