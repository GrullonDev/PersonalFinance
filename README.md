# 💰 Personal Finance - Tu Gestor Inteligente

[![Flutter Version](https://img.shields.io/badge/Flutter-3.27.4-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.7.0-blue.svg?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FVM](https://img.shields.io/badge/FVM-Enabled-green.svg)](https://fvm.app)

**Personal Finance** es una solución móvil premium diseñada para transformar la manera en que gestionas tu dinero. Construida con tecnologías de vanguardia y una arquitectura robusta, ofrece una experiencia fluida, segura y profesional para alcanzar la libertad financiera.

---

## ✨ Características Premium

- **Gestión Inteligente**: Registro instantáneo de ingresos y gastos con categorización avanzada.
- **Visualización Pro**: Reportes dinámicos y gráficos interactivos de alta calidad.
- **Personalización**: Sistema de avatares con iconos/emojis para una experiencia única.
- **Educación Financiera**: Consejos diarios integrados para mejorar tus hábitos financieros.
- **Seguridad Moderna**: Preparada para biometría y protección de datos avanzada.
- **Multiplataforma**: Experiencia nativa optimizada para **Android** e **iOS**.

---

## 🏗️ Arquitectura y Calidad de Código

El proyecto sigue los más altos estándares de desarrollo en la industria:

- **Clean Architecture**: Separación clara de responsabilidades (Data, Domain, Presentation).
- **SOLID Principles**: Código escalable, mantenible y testeable.
- **BLoC Pattern**: Gestión de estado predecible y robusta.
- **Dependency Injection**: Uso de `GetIt` para un código desacoplado.
- **Offline First**: Persistencia ultra rápida usando `Hive`.

---

## 🚀 Guía de Configuración Pro (FVM)

Este proyecto utiliza [FVM](https://fvm.app/) (Flutter Version Management) para garantizar la consistencia entre desarrolladores.

### 1. Instalación de FVM
Si aún no tienes FVM:
```bash
dart pub global activate fvm
```

### 2. Configurar el Proyecto
Clona e inicializa con la versión específica de Flutter (`3.38.0`):
```bash
git clone https://github.com/GrullonDev/personal_finance.git
cd personal_finance
fvm install 3.38.0
fvm use 3.38.0
```

### 3. Obtener Dependencias
```bash
fvm flutter pub get
```

### 4. Lanzamiento
Ejecuta el entorno de desarrollo:
```bash
fvm flutter run
```

---

## 📦 Generación de Entregables

### Android (APK & Bundles)
```bash
fvm flutter build apk --release
fvm flutter build appbundle --release
```

### iOS (IPA)
```bash
fvm flutter build ipa --release
```

---

## 🤝 Contribución Experta

1. **Estandar de Versión**: Siempre utiliza `fvm flutter` en lugar de `flutter`.
2. **Feature Branching**: 
   ```bash
   git checkout -b feature/nombre-mejora
   ```
3. **Calidad de Código**: Asegúrate de pasar el análisis antes de enviar:
   ```bash
   fvm flutter analyze
   ```

---

## 👤 Autor & Lead Developer

**Jorge Marroquín** - [GitHub @GrullonDev](https://github.com/GrullonDev)

---

## 📄 Licencia

Este software se distribuye bajo la **Licencia MIT**. Siéntete libre de usarlo, aprender de él y mejorarlo.

---
¡Si este proyecto te ha servido, no olvides darle una ⭐️ en GitHub para apoyarnos!
