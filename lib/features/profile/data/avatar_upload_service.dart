import 'package:image_picker/image_picker.dart';

class AvatarUploadService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }
}
