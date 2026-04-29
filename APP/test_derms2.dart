import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final pdBytes = File('assets/templates/dermatomes_PD.png').readAsBytesSync();
  final pd = img.decodeImage(pdBytes)!;
  
  Map<int, List<int>> labelBounds = {};
  for (int y = 0; y < pd.height; y++) {
    for (int x = 0; x < pd.width; x++) {
      int r = pd.getPixel(x, y).r.toInt();
      if (r > 0) {
        if (!labelBounds.containsKey(r)) {
          labelBounds[r] = [9999, -1];
        }
        if (x < labelBounds[r]![0]) labelBounds[r]![0] = x;
        if (x > labelBounds[r]![1]) labelBounds[r]![1] = x;
      }
    }
  }
  print('Width: ${pd.width}');
  labelBounds.forEach((k, v) {
    print('Label $k is between x=${v[0]} and x=${v[1]}');
  });
}
