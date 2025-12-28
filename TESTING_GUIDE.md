# 🎵 REMUH - Guía de Pruebas

Esta guía te ayudará a ejecutar y probar la aplicación REMUH en tu emulador Android o en tu celular físico.

---

## ⚡ Tu Configuración Actual

**✅ Dispositivo conectado:** `RF8R609JL0W`

### Comandos Rápidos para Tu Dispositivo

```powershell
# Navegar al proyecto
cd C:\Users\leora\Documents\REMUH

# Verificar que tu dispositivo esté conectado
flutter devices

# Ejecutar REMUH en tu celular (RF8R609JL0W)
flutter run -d RF8R609JL0W

# Ejecutar en modo release (más rápido, sin debug)
flutter run -d RF8R609JL0W --release

# Limpiar y ejecutar desde cero
flutter clean && flutter pub get && flutter run -d RF8R609JL0W
```

### Durante la Ejecución
- **`r`** → Recarga el código (Hot Reload) sin reiniciar
- **`R`** → Reinicia la app completamente (Hot Restart)  
- **`q`** → Detener la aplicación
- **`d`** → Detach (desconectar debugger pero mantener app corriendo)

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de tener instalado:

### 1. Flutter SDK
```powershell
# Verificar instalación de Flutter
flutter doctor
```

Si Flutter no está instalado, descárgalo desde: https://docs.flutter.dev/get-started/install/windows

### 2. Android Studio o Visual Studio Code
- **Android Studio**: Incluye el Android SDK y emuladores
- **VSCode**: Más ligero, requiere extensiones de Flutter/Dart

### 3. Android SDK
```powershell
# Verificar que el SDK esté configurado
flutter doctor --android-licenses
```

---

## 🖥️ Opción 1: Ejecutar en Emulador Android

### Paso 1: Crear un Emulador (si no tienes uno)

#### Desde Android Studio:
1. Abre **Android Studio**
2. Ve a **Tools** > **Device Manager** (o **AVD Manager**)
3. Haz clic en **Create Virtual Device**
4. Selecciona un dispositivo (ejemplo: Pixel 5)
5. Descarga e instala una imagen del sistema (recomendado: **API 33** o superior)
6. Completa la configuración y crea el emulador

#### Desde la línea de comandos:
```powershell
# Listar emuladores disponibles
flutter emulators

# Crear un nuevo emulador (requiere Android Studio)
flutter emulators --create

# O usar avdmanager directamente
avdmanager create avd -n remuh_test -k "system-images;android-33;google_apis;x86_64"
```

### Paso 2: Iniciar el Emulador

```powershell
# Listar emuladores disponibles
flutter emulators

# Iniciar un emulador específico
flutter emulators --launch <nombre_del_emulador>

# O desde Android Studio: Device Manager > ▶️ (Play button)
```

### Paso 3: Verificar Dispositivo Conectado

```powershell
# Ver dispositivos conectados
flutter devices
```

Deberías ver algo como:
```
emulator-5554 • sdk gphone64 arm64 • android-arm64 • Android 13 (API 33) (emulator)
```

### Paso 4: Ejecutar la Aplicación

```powershell
# Navegar al directorio del proyecto
cd C:\Users\leora\Documents\REMUH

# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# O ejecutar en un dispositivo específico
flutter run -d emulator-5554
```

---

## 📱 Opción 2: Ejecutar en Celular Físico (Android)

### Paso 1: Habilitar Modo Desarrollador

1. Ve a **Configuración** > **Acerca del teléfono**
2. Toca **Número de compilación** **7 veces** hasta que aparezca "Eres un desarrollador"
3. Regresa a **Configuración** > **Sistema** > **Opciones de desarrollador**

### Paso 2: Habilitar Depuración USB

1. En **Opciones de desarrollador**, activa:
   - ✅ **Depuración USB**
   - ✅ **Instalar vía USB** (si está disponible)
   - ✅ **Deshabilitar verificación de permisos** (opcional, facilita instalación)

### Paso 3: Conectar el Celular al PC

1. Conecta tu celular al PC mediante **cable USB**
2. En tu celular, autoriza la conexión:
   - Aparecerá un mensaje "¿Permitir depuración USB?"
   - Marca **"Permitir siempre desde este equipo"**
   - Toca **Permitir**

### Paso 4: Verificar Conexión

```powershell
# Ver dispositivos conectados
flutter devices

# También puedes usar adb directamente
adb devices
```

Deberías ver algo como:
```
XXXXXXXXXX • Redmi Note 11 • android-arm64 • Android 12 (API 31)
```

> **⚠️ Nota**: Si no aparece, revisa:
> - Que el cable USB soporte transferencia de datos (no solo carga)
> - Que hayas autorizado la depuración USB
> - Reinicia el servidor adb: `adb kill-server` y luego `adb start-server`

### Paso 5: Ejecutar la Aplicación

```powershell
# Navegar al directorio del proyecto
cd C:\Users\leora\Documents\REMUH

# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# O ejecutar en un dispositivo específico
flutter run -d <ID_DEL_DISPOSITIVO>
```

---

## 🚀 Comandos Útiles de Flutter

### Ejecución
```powershell
# Ejecutar en modo debug (hot reload habilitado)
flutter run

# Ejecutar en modo release (optimizado, sin debug)
flutter run --release

# Ejecutar en modo profile (para análisis de rendimiento)
flutter run --profile

# Ejecutar y ver logs detallados
flutter run -v
```

### Hot Reload (Durante ejecución)
- Presiona **`r`** en la terminal para hacer Hot Reload (recarga código)
- Presiona **`R`** en la terminal para hacer Hot Restart (reinicia app)
- Presiona **`q`** para detener la aplicación

### Pruebas
```powershell
# Ejecutar todos los tests
flutter test

# Ejecutar un test específico
flutter test test/widget_test.dart
```

### Limpieza y Reconstrucción
```powershell
# Limpiar archivos de compilación
flutter clean

# Obtener dependencias nuevamente
flutter pub get

# Reconstruir todo
flutter clean && flutter pub get && flutter run
```

### Información del Sistema
```powershell
# Ver estado del entorno Flutter
flutter doctor

# Ver información detallada
flutter doctor -v

# Ver dispositivos conectados
flutter devices

# Ver emuladores disponibles
flutter emulators
```

---

## 🔧 Troubleshooting

### Problema: "No devices found"

**Solución para emulador:**
```powershell
# Verificar que Android SDK esté configurado
flutter doctor

# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators --launch <nombre>
```

**Solución para celular físico:**
1. Verifica que la depuración USB esté habilitada
2. Autoriza la conexión en tu celular
3. Reinicia el servidor adb:
```powershell
adb kill-server
adb start-server
adb devices
```

### Problema: "Gradle build failed"

```powershell
# Limpiar y reconstruir
flutter clean
flutter pub get

# Si persiste, elimina manualmente:
rd /s /q android\.gradle
rd /s /q build
flutter run
```

### Problema: "SDK location not found"

1. Abre `android/local.properties`
2. Agrega la ruta de tu Android SDK:
```properties
sdk.dir=C:\\Users\\leora\\AppData\\Local\\Android\\Sdk
```

### Problema: Permisos de Audio (just_audio)

Si la app no reproduce audio:
1. Verifica que `android/app/src/main/AndroidManifest.xml` incluya:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

2. Asegúrate de tener un archivo de audio de prueba válido

### Problema: Hot Reload no funciona

```powershell
# Hacer un Hot Restart completo
# Presiona 'R' en la terminal

# O detén y vuelve a ejecutar
# Presiona 'q' y luego 'flutter run'
```

---

## 📝 Notas Importantes

### Para Emulador:
- **Recomendación**: Usa API 29 o superior (Android 10+) para mejor compatibilidad
- **Rendimiento**: Los emuladores x86_64 son más rápidos que ARM en PCs con Intel/AMD
- **RAM**: Asigna al menos 2GB de RAM al emulador para un mejor rendimiento

### Para Celular Físico:
- **Cable**: Asegúrate de usar un cable USB que soporte datos, no solo carga
- **Driver**: En Windows, puede que necesites instalar drivers USB específicos del fabricante
- **Batería**: Durante pruebas extensas, mantén el celular conectado a la corriente

### Sobre REMUH:
- La app usa `just_audio` para reproducción de audio
- Actualmente configurada con `minSdk 29` (Android 10)
- Requiere permisos de Internet para cargar audio online

---

## 🎯 Próximos Pasos

Una vez que la app esté corriendo:

1. **Verifica la UI**: Asegúrate de que el título "REMUH" aparece
2. **Prueba el botón Play**: Toca el botón de reproducción
3. **Revisa los logs**: Observa la salida en la terminal para errores
4. **Hot Reload**: Haz cambios en el código y presiona `r` para ver actualizaciones instantáneas

---

## 📚 Recursos Adicionales

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [Android Debug Bridge (adb)](https://developer.android.com/tools/adb)

---

**¿Problemas?** Ejecuta `flutter doctor -v` y revisa los mensajes de error específicos.
