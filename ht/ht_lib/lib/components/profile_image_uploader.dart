import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/ui_constants.dart';
import '../providers/user/user_details_provider.dart';
import '../theme/app_theme.dart';
import '../utils/secure_storage_utils.dart';
import '../core/api_endpoints.dart';

class ProfileImageUploader extends StatefulWidget {
  final int? userId;
  const ProfileImageUploader({super.key, this.userId});

  @override
  State<ProfileImageUploader> createState() => _ProfileImageUploaderState();
}

class _ProfileImageUploaderState extends State<ProfileImageUploader> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? errorMessage='';

  // 🚨 NEW FUNCTION – FIX FOR ANDROID 13/14 CAMERA CRASH
  Future<void> captureFromCamera() async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final String filePath = "${dir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? captured = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (!mounted) return;

      if (captured != null) {
        File saved = await File(captured.path).copy(filePath); // 🔥 Always stored safely
        errorMessage = "";
        setState(() => _selectedImage = saved);
      }
    } catch (e) {
      print("Camera Error ===> $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera failed: $e")),
        );
      }
    }
  }

  // 🚨 Gallery selector (unchanged)
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      errorMessage = "";
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final token = await SecureStorageUtils().read("auth_token");
      if (token == null) throw Exception("Token Missing");

      var url = Uri.parse(ApiEndpoints.uploadUserProfileImage(widget.userId));
      File? compressedImg = await compressImage(_selectedImage!, targetSizeKB: 300);

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('file', compressedImg!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image uploaded!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(errorMessage!,style: AppTheme.body14.copyWith(
            color: Colors.red
        ),),
        _selectedImage != null
            ? Image.file(
            _selectedImage!,
            width: deviceWidth(context) > 750 ? 120 : 100,
            height: deviceWidth(context) > 750 ? 120 : 100,
            fit: BoxFit.cover)
            :  Icon(Icons.account_circle, size: deviceWidth(context) > 750 ? 120 : 100, color: Colors.grey),

        SizedBox(height: deviceWidth(context) > 750 ? 60 : 20),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: captureFromCamera,  // 🔥 UPDATED
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickFromGallery,  // 🔥 UPDATED
                icon: const Icon(Icons.photo_library),
                label: const Text("Gallery"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () async {
                  if( _selectedImage == null){
                    errorMessage = "Select Camera or Gallery to upload";
                    setState(() {

                    });
                    return;
                  }
                  final notifier = ref.read(userDetailsDataProvider.notifier);
                  await _uploadImage();
                  if (!mounted) return;

                  Navigator.pop(context);
                  String? token = await SecureStorageUtils().read("auth_token");
                  notifier.loadUser(token: token);
                },
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload"),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<File?> compressImage(File file, {int targetSizeKB = 300}) async {
    final tempDir = await getTemporaryDirectory();
    final outPath = "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    int quality = 90;

    while (true) {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        outPath,
        quality: quality,
        format: CompressFormat.jpeg, // 👈 Force JPEG to avoid .heic/.png issues
      );

      if (result == null) return null;

      File compressed = File(result.path);

      if ((compressed.lengthSync() ~/ 1024) <= targetSizeKB || quality <= 10) {
        return compressed;
      }

      quality -= 10;
    }
  }

}
