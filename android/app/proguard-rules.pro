-keep class com.google.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.example.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keep class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
