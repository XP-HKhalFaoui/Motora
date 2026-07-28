# flutter_local_notifications serialises its scheduled notifications with
# Gson, which resolves them reflectively — R8 would otherwise strip the
# model classes and pending reminders would fail to restore after a reboot.
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation @interface com.google.gson.annotations.SerializedName
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
