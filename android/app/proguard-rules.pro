# Flutter plugin keep rules
-keep class io.flutter.plugins.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-keep class com.karde.app.** { *; }

# flutter_local_notifications serialises scheduled notifications with Gson, and
# R8 strips the generic type information those adapters need. Without this, the
# expiry reminders schedule without complaint and never arrive.
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
