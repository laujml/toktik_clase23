enum VideoUploadBackend {
  /// Requires the Firebase Blaze plan. New projects cannot use Storage on Spark.
  firebaseStorage,

  /// Free unsigned upload. Needs a Cloudinary cloud name and upload preset.
  cloudinary,
}

class UploadSettings {
  const UploadSettings._();

  /// Cloudinary is the active backend because Firebase Storage on a new
  /// project requires Blaze. Switch to [VideoUploadBackend.firebaseStorage]
  /// after upgrading the Firebase project.
  static const VideoUploadBackend backend = VideoUploadBackend.cloudinary;

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
}
