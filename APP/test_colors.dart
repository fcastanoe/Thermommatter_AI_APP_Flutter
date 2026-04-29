import 'dart:io';
import 'package:image/image.dart' as img;

img.Color _mapTempToColor(double temp, double minTemp, double maxTemp) {
  if (temp < minTemp) temp = minTemp;
  if (temp > maxTemp) temp = maxTemp;
  double t = (maxTemp == minTemp) ? 0.5 : (temp - minTemp) / (maxTemp - minTemp);
  int r = (255 * t).round();
  int g = 0;
  int b = (255 * (1 - t)).round();
  return img.ColorRgb8(r, g, b);
}

void main() async {
  final pdBytes = File('assets/templates/dermatomes_PD.png').readAsBytesSync();
  final pd = img.decodeImage(pdBytes)!;
  final piBytes = File('assets/templates/dermatomes_PI.png').readAsBytesSync();
  final pi = img.decodeImage(piBytes)!;
  
  Map<int, String> dermatomeLabels = {
    10: 'Medial PD',   11: 'Medial PI',
    20: 'Lateral PD',  21: 'Lateral PI',
    30: 'Sural PD',    31: 'Sural PI',
    40: 'Tibial PD',   41: 'Tibial PI',
    50: 'Saphenous PD',51: 'Saphenous PI',
  };
  
  Map<String, double> temps = {
    'Medial PD': 31.5, 'Medial PI': 31.2,
    'Lateral PD': 31.1, 'Lateral PI': 31.6,
    'Saphenous PD': 31.0, 'Saphenous PI': 30.2,
    'Sural PD': 29.7, 'Sural PI': 29.7,
    'Tibial PD': 30.3, 'Tibial PI': 31.2,
  };
  
  double minT = 29.7;
  double maxT = 31.6;
  
  int W = pd.width;
  int H = pd.height;
  int padding = 100;
  int gap = 20;
  img.Image out = img.Image(width: W * 2 + gap + padding, height: H + 40);
  out.clear(img.ColorRgb8(255, 255, 255));
  
  for (int y = 1; y < H - 1; y++) {
    for (int x = 1; x < W - 1; x++) {
      int lbl = pd.getPixel(x, y).r.toInt();
      if (lbl > 0) {
        String? name = dermatomeLabels[lbl];
        double t = name != null ? (temps[name] ?? minT) : minT;
        out.setPixel(x, y + 20, _mapTempToColor(t, minT, maxT));
        
        if (pd.getPixel(x+1, y).r.toInt() != lbl || pd.getPixel(x, y+1).r.toInt() != lbl) {
           out.setPixel(x, y + 20, img.ColorRgb8(0, 0, 0));
        }
      }
      
      lbl = pi.getPixel(x, y).r.toInt();
      if (lbl > 0) {
        String? name = dermatomeLabels[lbl];
        double t = name != null ? (temps[name] ?? minT) : minT;
        out.setPixel(W + gap + x, y + 20, _mapTempToColor(t, minT, maxT));
        
        if (pi.getPixel(x+1, y).r.toInt() != lbl || pi.getPixel(x, y+1).r.toInt() != lbl) {
           out.setPixel(W + gap + x, y + 20, img.ColorRgb8(0, 0, 0));
        }
      }
    }
  }
  
  int cbX = W * 2 + gap + 20;
  int cbY = 20;
  int cbW = 20;
  int cbH = H;
  for (int y = 0; y < cbH; y++) {
    double t = minT + (maxT - minT) * (1.0 - (y / cbH));
    img.Color c = _mapTempToColor(t, minT, maxT);
    for (int x = 0; x < cbW; x++) {
      out.setPixel(cbX + x, cbY + y, c);
    }
  }
  
  File('test_colored.png').writeAsBytesSync(img.encodePng(out));
}
