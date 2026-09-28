# Reglas de ProGuard / R8 para CS2 Tracker.
# El plugin flutter_local_notifications (v17.x) usa gson para persistir
# notificaciones programadas en SharedPreferences. R8 elimina los type
# parameters de las colecciones genéricas durante la minificación y al
# restaurarlas en el BootReceiver falla con "Missing type parameter".
# Conservamos su firma intacta.
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
# Gson type tokens
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
# Mantenemos nuestro código de modelo intacto
-keep class com.cs2tracker.cs2_tracker.** { *; }
