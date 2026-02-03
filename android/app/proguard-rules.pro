# ═══════════════════════════════════════════════════════════════════════════
# PROGUARD RULES FOR OLVORA EXPENSE APP
# Optimized for minimum APK size while preserving functionality
# ═══════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# FLUTTER CORE
# ─────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# FIREBASE
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─────────────────────────────────────────────────────────────────────────────
# ML KIT (OCR)
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ─────────────────────────────────────────────────────────────────────────────
# GOOGLE SIGN IN
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# SECURE STORAGE
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# SPEECH TO TEXT
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.csdcorp.speech_to_text.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# IMAGE PICKER / CROPPER
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# ─────────────────────────────────────────────────────────────────────────────
# PDF / PRINTING
# ─────────────────────────────────────────────────────────────────────────────
-keep class android.print.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# KOTLIN
# ─────────────────────────────────────────────────────────────────────────────
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ─────────────────────────────────────────────────────────────────────────────
# GOOGLE PLAY CORE (Required for Flutter deferred components)
# ─────────────────────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

-keep class com.google.android.play.core.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# GENERAL OPTIMIZATIONS
# ─────────────────────────────────────────────────────────────────────────────
# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}

# Remove Kotlin null checks for release (smaller bytecode)
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    public static void checkNotNull(...);
    public static void checkNotNullParameter(...);
    public static void checkParameterIsNotNull(...);
    public static void checkNotNullExpressionValue(...);
    public static void checkExpressionValueIsNotNull(...);
    public static void checkReturnedValueIsNotNull(...);
    public static void throwUninitializedPropertyAccessException(...);
}

# Optimize enums
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# ─────────────────────────────────────────────────────────────────────────────
# PREVENT STRIPPING SERIALIZABLE CLASSES
# ─────────────────────────────────────────────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

