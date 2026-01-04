# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audio_service rules
-keep class com.ryanheise.audioservice.** { *; }

# just_audio rules
-keep class com.ryanheise.just_audio.** { *; }

# on_audio_query rules
-keep class com.drenther.on_audio_query.** { *; }

# sqflite rules
-keep class com.tekartik.sqflite.** { *; }

# Prevent obfuscation of entities/models used for JSON serialization if any
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
