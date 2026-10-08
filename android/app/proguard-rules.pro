# Reglas para R8 (la herramienta que reduce el tamaño del APK de la versión final).
#
# Google Mobile Ads (AdMob) usa WorkManager, que crea su base de datos Room por
# reflexión al arrancar la app (androidx.work.impl.WorkDatabase_Impl). Sin estas
# reglas R8 la elimina y la app se cierra al abrirse:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
# (en el Xiaomi 15T Pro / Android 16 se veía como pantalla negra).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer { <init>(); }
-dontwarn androidx.work.**
-dontwarn androidx.room.**
