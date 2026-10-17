# Release uses R8. These plugins are reached from the generated registrant,
# and the hardware encoder must stay intact when the video is closed.
-keep class com.lib.flutter_quick_video_encoder.** { *; }
-keep class com.llfbandit.record.** { *; }
-dontwarn com.lib.flutter_quick_video_encoder.**
-dontwarn com.llfbandit.record.**
