import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    return picked?.path;
  }

  Future<String?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return picked?.path;
  }
}
