# Guía de Diagnóstico de Notificaciones

Esta guía te ayudará a verificar que el mini-player aparezca correctamente en el centro de notificaciones.

## Paso 1: Compilar e Instalar la App

```bash
flutter build apk --debug
flutter install
```

## Paso 2: Verificar Permisos de Notificación

### En el Dispositivo

1. Abre la app REMUH
2. **Importante**: Si aparece un diálogo solicitando permiso de notificaciones, **ACEPTA**
3. Ve a **Configuración** del dispositivo → **Apps** → **REMUH** → **Notificaciones**
4. Verifica que:
   - Las notificaciones estén **ACTIVADAS** ✓
   - El canal "Music Playback" esté **ACTIVADO** ✓

### Usando ADB

```bash
# Verificar que el canal de notificación se creó
adb shell cmd notification list_channels com.leo.remuh
```

**Resultado esperado**: Debe aparecer `com.leo.remuh.channel.audio.v2`

## Paso 3: Probar el Mini-Player

1. Abre la app REMUH
2. Selecciona y **reproduce una canción**
3. Presiona el botón **Home** para minimizar la app
4. Desliza hacia abajo para abrir el **centro de notificaciones**
5. **Verifica que aparece el mini-player** con:
   - ✓ Título de la canción
   - ✓ Artista
   - ✓ Carátula del álbum
   - ✓ Controles: anterior, play/pause, siguiente

## Paso 4: Verificar en Pantalla de Bloqueo

1. Con música reproduciéndose, **bloquea el dispositivo**
2. **Verifica que aparecen los controles** en la pantalla de bloqueo

## Paso 5: Revisar Logs (Opcional)

Si el mini-player no aparece, revisa los logs:

```bash
adb logcat | grep -E "(AudioService|MediaSession|Notification|REMUH)"
```

**Busca estos mensajes**:
- ✓ "Syncing Audio State: playing=true"
- ✓ "Broadcasting PlaybackState"
- ✓ "Updating MediaItem"
- ✓ Mensajes de creación de notificación del sistema Android

## Solución de Problemas

### El diálogo de permisos no aparece

Si no aparece el diálogo solicitando permiso de notificaciones:

```bash
# Desinstalar la app completamente
adb uninstall com.leo.remuh

# Reinstalar
flutter install
```

### Las notificaciones están desactivadas

Si las notificaciones están desactivadas en configuración:

1. Ve a **Configuración** → **Apps** → **REMUH** → **Notificaciones**
2. **Activa** las notificaciones
3. **Activa** el canal "Music Playback"

### El canal no aparece en la lista

Si el comando ADB no muestra el canal:

```bash
# Verificar logs durante el inicio de la app
adb logcat | grep -i "notification"
```

Busca mensajes de error relacionados con la creación del canal.

## Comandos Útiles

```bash
# Ver todas las notificaciones activas
adb shell dumpsys notification

# Limpiar todas las notificaciones
adb shell cmd notification clear com.leo.remuh

# Reiniciar la app
adb shell am force-stop com.leo.remuh
adb shell am start -n com.leo.remuh/.MainActivity
```
