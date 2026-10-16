import 'package:toktok/config/upload_settings.dart';
import 'package:toktok/infrastructure/storage/cloudinary_video_storage.dart';
import 'package:toktok/infrastructure/storage/firebase_video_storage.dart';
import 'package:toktok/infrastructure/storage/video_file_storage.dart';

VideoFileStorage buildVideoFileStorage() {
  switch (UploadSettings.backend) {
    case VideoUploadBackend.firebaseStorage:
      return FirebaseVideoStorage();
    case VideoUploadBackend.cloudinary:
      return CloudinaryVideoStorage(
        cloudName: UploadSettings.cloudinaryCloudName,
        uploadPreset: UploadSettings.cloudinaryUploadPreset,
      );
  }
}
