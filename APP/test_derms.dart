import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final pdBytes = File('assets/templates/dermatomes_PD.png').readAsBytesSync();
  final pd = img.decodeImage(pdBytes)!;
  final piBytes = File('assets/templates/dermatomes_PI.png').readAsBytesSync();
  final pi = img.decodeImage(piBytes)!;
  
  // Find Saphenous (Label 50) in PD
  int minX_PD = 9999, maxX_PD = -1;
  for (int y = 0; y < pd.height; y++) {
    for (int x = 0; x < pd.width; x++) {
      if (pd.getPixel(x, y).r == 50) {
        if (x < minX_PD) minX_PD = x;
        if (x > maxX_PD) maxX_PD = x;
      }
    }
  }
  print('PD: Saphenous (50) is between x=$minX_PD and x=$maxX_PD (Width=${pd.width})');

  // Find Saphenous (Label 50 or 51? Left usually has +1 so maybe 50 or 51)
  int minX_PI = 9999, maxX_PI = -1;
  for (int y = 0; y < pi.height; y++) {
    for (int x = 0; x < pi.width; x++) {
      if (pi.getPixel(x, y).r == 50 || pi.getPixel(x, y).r == 51) {
        if (x < minX_PI) minX_PI = x;
        if (x > maxX_PI) maxX_PI = x;
      }
    }
  }
  print('PI: Saphenous (50/51) is between x=$minX_PI and x=$maxX_PI (Width=${pi.width})');
}
