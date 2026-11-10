# google_mlkit_text_recognition references the optional Chinese/Japanese/
# Korean/Devanagari recognizer classes for every script, even though this
# app only uses TextRecognitionScript.latin and never pulls those optional
# ML Kit modules in as dependencies. R8 can't find them; they're unused.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
