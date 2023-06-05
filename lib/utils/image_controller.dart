import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_cropping/image_cropping.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageController {
  static Future<void> pickAndCropImage(Function saveFunction, String fileName, BuildContext context) async {
    Uint8List? imageBytes;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 25);

    if (image != null) {
      imageBytes = await image.readAsBytes();
      // ignore: use_build_context_synchronously
      final croppedBytes = await ImageCropping.cropImage(
          context: context,
          imageBytes: imageBytes,
          onImageDoneListener: (data) {
            imageBytes = data;
          },
          
          // customAspectRatios: [
          //   const CropAspectRatio(
          //     ratioX: 4,
          //     ratioY: 5,
          //   ),
          // ],
          selectedImageRatio:CropAspectRatio(ratioX: 9, ratioY: 16),
          onImageStartLoading: () => EasyLoading.show(status: "loading..."),
          onImageEndLoading: () => EasyLoading.dismiss(),
          visibleOtherAspectRatios: true,
          squareBorderWidth: 2,
          isConstrain: false,
          squareCircleColor: Colors.teal,
          defaultTextColor: Colors.black,
          selectedTextColor: Colors.teal,
          colorForWhiteSpace: Colors.white,
          makeDarkerOutside: true,
          outputImageFormat: OutputImageFormat.jpg,
          encodingQuality: 40);

      if (croppedBytes != null) {
        String dir = (await getApplicationDocumentsDirectory()).path;
        String fullPath = '$dir/$fileName.png';
        print("local file full path ${fullPath}");
        File file = File(fullPath);
        await file.writeAsBytes(croppedBytes);
        await saveFunction(fullPath: fullPath);
        EasyLoading.dismiss();
      }
    }
  }
}
