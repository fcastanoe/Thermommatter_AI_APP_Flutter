// registration_service.dart  –  v4 (Thin Plate Splines)
//
// El registro no rígido se implementa con TPS (Thin Plate Splines):
//   1. Se crean puntos de control en una rejilla normalizada dentro del pie.
//   2. El punto correspondiente en la plantilla es la misma posición relativa
//      (u, v) dentro del espacio de la plantilla.
//   3. TPS calcula una función de deformación SUAVE que pasa por todos los
//      puntos de control → equivalente al registro deformable de SimpleITK.
//   4. Para cada píxel dentro de la máscara del pie, TPS mapea al punto
//      correspondiente en la plantilla y copia la etiqueta.
//
// Corrección izquierdo/derecho:
//   - Plantilla base (dermatomes.png) = PIE DERECHO.
//   - Pie izquierdo = flip horizontal de la plantilla + etiquetas +1.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class RegistrationService {
  static const Map<int, String> dermatomeLabels = {
    10: 'Medial PD',   11: 'Medial PI',
    20: 'Lateral PD',  21: 'Lateral PI',
    30: 'Sural PD',    31: 'Sural PI',
    40: 'Tibial PD',   41: 'Tibial PI',
    50: 'Saphenous PD',51: 'Saphenous PI',
  };

  // Plantilla base = pie derecho. Pie izquierdo = flip + labels+1.
  static img.Image? _templateRight;
  static img.Image? _templateLeft;

  // ══════════════════════════════════════════════════════════════════
  // TPS KERNEL  U(r²) = r² · ln(r²),  U(0) = 0
  // ══════════════════════════════════════════════════════════════════
  static double _tpsKernel(double r2) {
    if (r2 < 1e-10) return 0.0;
    return r2 * math.log(r2);
  }

  // ══════════════════════════════════════════════════════════════════
  // ELIMINACIÓN GAUSSIANA CON PIVOTEO PARCIAL
  // Resuelve A·x = b. Devuelve x, o null si el sistema es singular.
  // ══════════════════════════════════════════════════════════════════
  static List<double>? _solveLinear(List<List<double>> A, List<double> b) {
    final int n = b.length;
    // Matriz aumentada [A|b]
    final List<List<double>> m =
        List.generate(n, (i) => [...A[i], b[i]]);

    for (int col = 0; col < n; col++) {
      // Pivoteo parcial
      int maxRow = col;
      double maxVal = m[col][col].abs();
      for (int row = col + 1; row < n; row++) {
        if (m[row][col].abs() > maxVal) {
          maxVal = m[row][col].abs();
          maxRow = row;
        }
      }
      if (maxVal < 1e-10) return null; // singular
      final tmp = m[col]; m[col] = m[maxRow]; m[maxRow] = tmp;

      // Eliminación
      for (int row = col + 1; row < n; row++) {
        final double f = m[row][col] / m[col][col];
        for (int k = col; k <= n; k++) m[row][k] -= f * m[col][k];
      }
    }

    // Sustitución regresiva
    final List<double> x = List<double>.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      x[i] = m[i][n];
      for (int j = i + 1; j < n; j++) x[i] -= m[i][j] * x[j];
      x[i] /= m[i][i];
    }
    return x;
  }

  // ══════════════════════════════════════════════════════════════════
  // AJUSTE TPS
  // dstPts: puntos en el espacio del pie (destino).
  // srcPts: puntos correspondientes en el espacio de la plantilla (origen).
  // Devuelve [coefX, coefY], cada uno de longitud N+3, o null si falla.
  // ══════════════════════════════════════════════════════════════════
  static List<List<double>>? _fitTPS(
    List<math.Point<double>> dstPts,
    List<math.Point<double>> srcPts,
  ) {
    final int N = dstPts.length;
    final int M = N + 3;

    // Construir matriz K  (M×M)
    final List<List<double>> K =
        List.generate(M, (_) => List<double>.filled(M, 0.0));

    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        if (i == j) continue;
        final double dx = dstPts[i].x - dstPts[j].x;
        final double dy = dstPts[i].y - dstPts[j].y;
        K[i][j] = _tpsKernel(dx * dx + dy * dy);
      }
      // Bloque polinómico P
      K[i][N]     = 1.0;
      K[i][N + 1] = dstPts[i].x;
      K[i][N + 2] = dstPts[i].y;
      // Transpuesta P^T
      K[N][i]     = 1.0;
      K[N + 1][i] = dstPts[i].x;
      K[N + 2][i] = dstPts[i].y;
    }

    final List<double> bx = [...srcPts.map((p) => p.x), 0.0, 0.0, 0.0];
    final List<double> by = [...srcPts.map((p) => p.y), 0.0, 0.0, 0.0];

    final List<double>? cx = _solveLinear(K, bx);
    if (cx == null) return null;
    final List<double>? cy = _solveLinear(K, by);
    if (cy == null) return null;
    return [cx, cy];
  }

  // ══════════════════════════════════════════════════════════════════
  // EVALUACIÓN TPS en un punto (px, py)
  // Devuelve (u, v) en el espacio de la plantilla.
  // ══════════════════════════════════════════════════════════════════
  static (double, double) _evalTPS(
    double px,
    double py,
    List<math.Point<double>> dstPts,
    List<double> coefX,
    List<double> coefY,
  ) {
    final int N = dstPts.length;
    double u = coefX[N] + coefX[N + 1] * px + coefX[N + 2] * py;
    double v = coefY[N] + coefY[N + 1] * px + coefY[N + 2] * py;
    for (int i = 0; i < N; i++) {
      final double dx = px - dstPts[i].x;
      final double dy = py - dstPts[i].y;
      final double phi = _tpsKernel(dx * dx + dy * dy);
      u += coefX[i] * phi;
      v += coefY[i] * phi;
    }
    return (u, v);
  }

  // ══════════════════════════════════════════════════════════════════
  // PUNTOS DE CONTROL  (rejilla normalizada dentro de la máscara del pie)
  //
  // Estrategia: dividir la bounding-box del pie en una rejilla de
  // gridSteps×gridSteps. Cada punto de la rejilla que caiga DENTRO de
  // la máscara se usa como punto de control en el espacio del pie.
  // El punto correspondiente en la plantilla es la misma posición
  // relativa (u,v) escalada al tamaño de la plantilla.
  //
  // Esta correspondencia es correcta porque pie y plantilla representan
  // la misma topología: talón abajo, dedos arriba, borde medial/lateral
  // en sus respectivos lados.
  // ══════════════════════════════════════════════════════════════════
  static (List<math.Point<double>>, List<math.Point<double>>) _buildControlPoints(
    img.Image footMask,
    int tmplW,
    int tmplH, {
    int gridSteps = 10,
    int threshold = 120,
  }) {
    final int bW = footMask.width;
    final int bH = footMask.height;
    final List<math.Point<double>> dstPts = [];
    final List<math.Point<double>> srcPts = [];

    for (int gi = 0; gi <= gridSteps; gi++) {
      for (int gj = 0; gj <= gridSteps; gj++) {
        final double u = gi / gridSteps; // 0..1
        final double v = gj / gridSteps; // 0..1
        final int px = (u * (bW - 1)).round();
        final int py = (v * (bH - 1)).round();

        if (footMask.getPixel(px, py).r.toInt() > threshold) {
          dstPts.add(math.Point<double>(px.toDouble(), py.toDouble()));
          srcPts.add(math.Point<double>(
            u * (tmplW - 1),
            v * (tmplH - 1),
          ));
        }
      }
    }
    return (dstPts, srcPts);
  }

  // ══════════════════════════════════════════════════════════════════
  // DETECCIÓN DE PIES (flood-fill → 2 componentes más grandes)
  // ══════════════════════════════════════════════════════════════════
  static List<Map<String, int>> _findFootBoxes(
    img.Image mask, {
    int threshold = 120,
  }) {
    final int W = mask.width, H = mask.height;
    final List<List<bool>> vis =
        List.generate(H, (_) => List<bool>.filled(W, false));
    final List<Map<String, int>> comps = [];
    const List<int> dx4 = [1, -1, 0, 0];
    const List<int> dy4 = [0, 0, 1, -1];

    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        if (!vis[y][x] && mask.getPixel(x, y).r.toInt() > threshold) {
          int x0 = x, x1 = x, y0 = y, y1 = y, cnt = 0;
          final q = [[x, y]];
          vis[y][x] = true;
          while (q.isNotEmpty) {
            final p = q.removeLast();
            final int cx = p[0], cy = p[1];
            if (cx < x0) x0 = cx; if (cx > x1) x1 = cx;
            if (cy < y0) y0 = cy; if (cy > y1) y1 = cy;
            cnt++;
            for (int i = 0; i < 4; i++) {
              final int nx = cx + dx4[i], ny = cy + dy4[i];
              if (nx >= 0 && nx < W && ny >= 0 && ny < H &&
                  !vis[ny][nx] &&
                  mask.getPixel(nx, ny).r.toInt() > threshold) {
                vis[ny][nx] = true;
                q.add([nx, ny]);
              }
            }
          }
          comps.add({
            'x': x0, 'y': y0,
            'width': x1 - x0 + 1, 'height': y1 - y0 + 1,
            'count': cnt,
          });
        }
      }
    }
    if (comps.isEmpty) return [];
    comps.sort((a, b) => b['count']!.compareTo(a['count']!));
    final sel = comps.take(2).toList();
    // Ordenar por x ascendente: menor x → pie derecho (en imagen)
    if (sel.length == 2) sel.sort((a, b) => a['x']!.compareTo(b['x']!));
    return sel;
  }

  // ══════════════════════════════════════════════════════════════════
  // REGISTRO DE UN PIE CON TPS
  //
  // foot     : recorte binario del pie (bounding-box de la máscara).
  // template : plantilla ya orientada al pie (right/left), en su
  //            resolución original (se redimensiona internamente).
  // ══════════════════════════════════════════════════════════════════
  static img.Image _registerOneFoot(img.Image foot, img.Image template) {
    final int W = foot.width, H = foot.height;

    // Redimensionar plantilla al tamaño del recorte del pie
    final img.Image tmpl = img.copyResize(
      template,
      width: W,
      height: H,
      interpolation: img.Interpolation.nearest,
    );

    // 1. Generar puntos de control
    final (dstPts, srcPts) = _buildControlPoints(foot, W, H);
    final int N = dstPts.length;
    print('📌 [TPS] Puntos de control: $N');

    final img.Image out = img.Image(width: W, height: H, numChannels: 3);

    // Necesitamos al menos 4 puntos para TPS (3 afines + 1 radial)
    if (N < 4) {
      print('⚠️ [TPS] Muy pocos puntos de control, usando resize directo.');
      return tmpl;
    }

    // 2. Ajustar TPS
    final List<List<double>>? coefs = _fitTPS(dstPts, srcPts);
    if (coefs == null) {
      print('⚠️ [TPS] Sistema singular, usando resize directo.');
      return tmpl;
    }
    final List<double> coefX = coefs[0];
    final List<double> coefY = coefs[1];

    // 3. Evaluar TPS en cada píxel dentro de la máscara del pie
    for (int py = 0; py < H; py++) {
      for (int px = 0; px < W; px++) {
        // Solo píxeles dentro del pie
        if (foot.getPixel(px, py).r.toInt() <= 120) continue;

        // Mapear al espacio de la plantilla vía TPS
        final (double u, double v) =
            _evalTPS(px.toDouble(), py.toDouble(), dstPts, coefX, coefY);

        final int sx = u.round().clamp(0, W - 1);
        final int sy = v.round().clamp(0, H - 1);

        final int label = tmpl.getPixel(sx, sy).r.toInt();
        if (label > 0) {
          out.setPixelRgb(px, py, label, 0, 0);
        }
      }
    }

    // 4. Relleno por vecindad: cualquier píxel dentro de la máscara del pie
    //    que haya quedado sin etiqueta (label==0) hereda la etiqueta del
    //    vecino 4-conectado más cercano. Se itera hasta que no haya cambios
    //    (máx 60 pasadas para acotar el tiempo). Esto elimina todos los gaps
    //    causados por TPS mapeando a zonas de fondo de la plantilla.
    const int maxPasses = 60;
    for (int pass = 0; pass < maxPasses; pass++) {
      bool changed = false;
      for (int py = 0; py < H; py++) {
        for (int px = 0; px < W; px++) {
          if (foot.getPixel(px, py).r.toInt() <= 120) continue; // fuera del pie
          if (out.getPixel(px, py).r.toInt() > 0) continue;    // ya etiquetado
          // Buscar etiqueta en vecinos 4-conectados
          int lbl = 0;
          if (px > 0)     lbl = out.getPixel(px - 1, py).r.toInt();
          if (lbl == 0 && px < W - 1) lbl = out.getPixel(px + 1, py).r.toInt();
          if (lbl == 0 && py > 0)     lbl = out.getPixel(px, py - 1).r.toInt();
          if (lbl == 0 && py < H - 1) lbl = out.getPixel(px, py + 1).r.toInt();
          if (lbl > 0) {
            out.setPixelRgb(px, py, lbl, 0, 0);
            changed = true;
          }
        }
      }
      if (!changed) break; // convergió, no hay más huecos
    }

    // Fallback si quedó vacío
    bool hasAny = false;
    outer:
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        if (out.getPixel(x, y).r.toInt() > 0) { hasAny = true; break outer; }
      }
    }
    if (!hasAny) {
      print('⚠️ [TPS] Resultado vacío, usando resize directo.');
      return tmpl;
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════
  // PUNTO DE ENTRADA PRINCIPAL
  // ══════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> runRegistration({
    required String imagePath,
    required String maskPath,
    required double minTemp,
    required double maxTemp,
    required String outputDir,
  }) async {
    print('🔄 [RegistrationService v4 TPS] Iniciando...');

    // — Cargar imágenes —
    img.Image? origImg =
        img.decodeImage(await File(imagePath).readAsBytes());
    img.Image? footMask =
        img.decodeImage(await File(maskPath).readAsBytes());
    if (origImg == null || footMask == null) {
      throw Exception('Error cargando imágenes de entrada.');
    }

    // — Igualar dimensiones —
    if (origImg.width != footMask.width ||
        origImg.height != footMask.height) {
      print('⚠️ Redimensionando imagen a ${footMask.width}×${footMask.height}');
      origImg = img.copyResize(
        origImg,
        width: footMask.width,
        height: footMask.height,
        interpolation: img.Interpolation.linear,
      );
    }
    final int W = footMask.width, H = footMask.height;

    // — Plantilla de dermatomas —
    final ByteData tmplDataPD =
        await rootBundle.load('assets/templates/dermatomes_PD.png');
    final img.Image? basePD = img.decodeImage(tmplDataPD.buffer.asUint8List());
    if (basePD == null) throw Exception('Plantilla PD no encontrada en assets.');

    final ByteData tmplDataPI =
        await rootBundle.load('assets/templates/dermatomes_PI.png');
    final img.Image? basePI = img.decodeImage(tmplDataPI.buffer.asUint8List());
    if (basePI == null) throw Exception('Plantilla PI no encontrada en assets.');
    
    if (_templateRight == null || _templateLeft == null) {
      // PD (isRight = true) -> Pantalla izquierda
      _templateRight = img.Image.from(basePD);

      // PI (isRight = false) -> Pantalla derecha
      _templateLeft = img.Image.from(basePI);
      
      // Asegurar que las etiquetas de PI sean impares (sumamos +1 si son pares)
      for (int y = 0; y < _templateLeft!.height; y++) {
        for (int x = 0; x < _templateLeft!.width; x++) {
          final int v = _templateLeft!.getPixel(x, y).r.toInt();
          if (v != 0 && v % 2 == 0) {
            _templateLeft!.setPixelRgb(x, y, v + 1, 0, 0);
          }
        }
      }

      print('✅ [TPS] Plantillas inicializadas '
            '(PD cargada de dermatomes_PD, PI cargada de dermatomes_PI).');
    }

    // — Detectar pies (2 componentes más grandes) —
    final List<Map<String, int>> boxes = _findFootBoxes(footMask);
    if (boxes.isEmpty) throw Exception('No se detectaron pies en la máscara.');

    // Mapa global de etiquetas registradas
    final img.Image regDerms =
        img.Image(width: W, height: H, numChannels: 3);

    for (int fi = 0; fi < boxes.length; fi++) {
      final Map<String, int> box = boxes[fi];
      final int bx = box['x']!, by = box['y']!;
      final int bw = box['width']!, bh = box['height']!;
      if (bw <= 1 || bh <= 1) continue;

      // boxes ordenados por x ascendente: índice 0 = menor x = izquierda en pantalla
      final bool isScreenLeft = fi == 0;
      
      // La plantilla PD tiene el medial a la derecha, por lo que encaja con el pie izquierdo en pantalla.
      // La plantilla PI tiene el medial a la izquierda, por lo que encaja con el pie derecho en pantalla.
      final img.Image baseTmpl = isScreenLeft ? _templateRight! : _templateLeft!;
      
      print('🦶 Registrando pie en pantalla ${isScreenLeft ? "Izquierda (usa PD)" : "Derecha (usa PI)"} '
            '(x=$bx y=$by w=$bw h=$bh)');

      // Recortar máscara del pie
      final img.Image footCrop =
          img.copyCrop(footMask, x: bx, y: by, width: bw, height: bh);

      // Registro TPS
      final img.Image registered = _registerOneFoot(footCrop, baseTmpl);

      // Copiar al mapa global
      for (int y = 0; y < bh; y++) {
        for (int x = 0; x < bw; x++) {
          final int lbl = registered.getPixel(x, y).r.toInt();
          if (lbl > 0) regDerms.setPixelRgb(bx + x, by + y, lbl, 0, 0);
        }
      }
    }

    // — Overlay: B&N + contornos rojos de dermatomas —
    final img.Image overlayBw = img.Image(width: W, height: H);
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        final p = origImg.getPixel(x, y);
        final int g = ((p.r + p.g + p.b) / 3.0).round();
        overlayBw.setPixelRgb(x, y, g, g, g);
      }
    }
    for (int y = 1; y < H - 1; y++) {
      for (int x = 1; x < W - 1; x++) {
        final int c  = regDerms.getPixel(x, y).r.toInt();
        if (c == 0) continue;
        final int r  = regDerms.getPixel(x + 1, y).r.toInt();
        final int d  = regDerms.getPixel(x, y + 1).r.toInt();
        final int l  = regDerms.getPixel(x - 1, y).r.toInt();
        final int u  = regDerms.getPixel(x, y - 1).r.toInt();
        if ((r != 0 && r != c) || (d != 0 && d != c) ||
            (l != 0 && l != c) || (u != 0 && u != c) ||
            r == 0 || d == 0 || l == 0 || u == 0) {
          overlayBw.setPixelRgb(x, y, 255, 0, 0);
        }
      }
    }

    // — Temperaturas por zona —
    final Map<int, List<double>> zoneVals = {};
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        final int lbl = regDerms.getPixel(x, y).r.toInt();
        if (lbl > 0) {
          final p = origImg.getPixel(x, y);
          final double intensity = ((p.r + p.g + p.b) / 3.0) / 255.0;
          zoneVals.putIfAbsent(lbl, () => [])
              .add(minTemp + (maxTemp - minTemp) * intensity);
        }
      }
    }
    final Map<String, double> temps = {};
    zoneVals.forEach((lbl, vals) {
      if (vals.isNotEmpty && dermatomeLabels.containsKey(lbl)) {
        temps[dermatomeLabels[lbl]!] =
            vals.reduce((a, b) => a + b) / vals.length;
      }
    });

    // — Plantillas coloreadas con colormap (en lugar de overlay con contornos) —
    final img.Image coloredTemplates = _generateColoredTemplates(temps, minTemp, maxTemp);


    // — Guardar overlay (plantillas coloreadas) —
    final String coloredOutPath =
        '$outputDir/derm_colored_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(coloredOutPath).writeAsBytes(img.encodePng(coloredTemplates));

    // — Guardar overlay B&N con contornos rojos —
    final String bwOutPath =
        '$outputDir/derm_bw_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(bwOutPath).writeAsBytes(img.encodePng(overlayBw));

    print('💾 Plantillas coloreadas guardadas: $coloredOutPath');
    print('💾 Overlay B&N guardado: $bwOutPath');
    print('🌡️ Temperaturas: $temps');

    return {
      'status': 'success',
      'derm_overlay_png': coloredOutPath,
      'derm_bw_png': bwOutPath,
      'temps_json': temps,
      'colored_path': imagePath,
    };
  }

  // ══════════════════════════════════════════════════════════════════
  // GENERAR IMAGEN DE PLANTILLAS COLOREADAS
  // ══════════════════════════════════════════════════════════════════
  static img.Color _mapTempToColor(double temp, double minTemp, double maxTemp) {
    if (temp < minTemp) temp = minTemp;
    if (temp > maxTemp) temp = maxTemp;
    double t = (maxTemp == minTemp) ? 0.5 : (temp - minTemp) / (maxTemp - minTemp);
    int r = (255 * t).round();
    int g = 0;
    int b = (255 * (1 - t)).round();
    return img.ColorRgb8(r, g, b);
  }

  static img.Image _generateColoredTemplates(Map<String, double> temps, double minT, double maxT) {
    if (_templateRight == null || _templateLeft == null) {
      return img.Image(width: 100, height: 100);
    }
    final img.Image pd = _templateRight!;
    final img.Image pi = _templateLeft!;
    
    int W = pd.width;
    int H = pd.height;
    int padding = 60; // espacio para la colorbar
    int gap = 20; // espacio entre pies
    
    img.Image out = img.Image(width: W * 2 + gap + padding, height: H + 40);
    out.clear(img.ColorRgb8(255, 255, 255)); // Fondo blanco
    
    // Dibujar Pie Izquierdo en pantalla (PD template)
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
        // Dibujar Pie Derecho en pantalla (PI template)
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
    
    // Dibujar Colorbar
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
    
    // (Opcional) Dibuja bordes a la colorbar
    for (int y = 0; y < cbH; y++) {
      out.setPixel(cbX, cbY + y, img.ColorRgb8(0, 0, 0));
      out.setPixel(cbX + cbW - 1, cbY + y, img.ColorRgb8(0, 0, 0));
    }
    for (int x = 0; x < cbW; x++) {
      out.setPixel(cbX + x, cbY, img.ColorRgb8(0, 0, 0));
      out.setPixel(cbX + x, cbY + cbH - 1, img.ColorRgb8(0, 0, 0));
    }

    return out;
  }
}
