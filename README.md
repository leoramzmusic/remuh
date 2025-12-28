# REMUH - Música Minimalista Sincronizada 🎵

REMUH es un reproductor de música moderno, minimalista y potente construido con **Flutter**. Enfocado en la velocidad, la elegancia y la personalización de letras sincronizadas.

## ✨ Características Principales

### 🎧 Reproducción Inteligente
- **Escaneo Inteligente**: Indexación automática de archivos locales con detección de cambios (Pull-to-refresh).
- **Gestos Avanzados**:
  - Desliza horizontalmente para cambiar de canción.
  - Desliza hacia abajo para ver la cola de reproducción ("A continuación").
  - Desliza hacia arriba para volver a la biblioteca.
- **Segundo Plano**: Soporte completo para controles en la pantalla de bloqueo y notificaciones del sistema.

### 🎤 Karaoke & Letras
- **LRC Sync**: Soporte nativo para archivos de letras sincronizadas (.lrc).
- **Editor LRC Integrado**: Crea tus propias sincronizaciones mientras escuchas la canción con el botón de "Marcado Rápido".
- **Búsqueda Automática**: Busca automáticamente archivos de letras en la carpeta de la canción.

### 📂 Organización
- **Playlists Personalizadas**: Crea, edita y gestiona tus propias listas de reproducción guardadas localmente.
- **Cola Dinámica**: Reordena o elimina canciones de la cola actual mediante Drag & Drop.

## 🛠️ Arquitectura
El proyecto sigue los principios de **Clean Architecture** y **Riverpod** para la gestión de estado reactiva:
- **Core**: Constantes, temas y utilidades.
- **Data**: Implementación de repositorios y fuentes de datos (SQLite, on_audio_query).
- **Domain**: Entidades de negocio y casos de uso.
- **Presentation**: UI reactiva organizada en Providers, Screens y Widgets.

## 🚀 Instalación y Uso

1. **Clonar**: `git clone https://github.com/leora/REMUH`
2. **Dependencias**: `flutter pub get`
3. **Ejecutar**: `flutter run`

### Guía del Editor de Letras
1. Abre una canción en el reproductor.
2. Toca el icono de letras -> **Editar letras (LRC)**.
3. Pega el texto de la letra.
4. Dale a Play.
5. Cada vez que escuches el inicio de una frase, toca **"Insertar Tiempo Actual"**.
6. Guarda con el icono superior y ¡disfruta de tu Karaoke personalizado!

---
*Desarrollado con ❤️ para amantes de la música.*
