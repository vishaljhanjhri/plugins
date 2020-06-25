
import 'package:camera/camer_overlay.dart';
import 'package:flutter/material.dart';

class CropPainter extends CustomPainter {
  final Rect view;
  final Rect area;
  final CameraOverlayConfig config;

  final double textContainerWidth = 128;
  final double textContainerHeight = 30;

  CropPainter({this.view, this.area, this.config});

  @override
  bool shouldRepaint(CropPainter oldDelegate) {
    return oldDelegate.view != view || oldDelegate.area != area;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.save();
    canvas.translate(rect.left, rect.top);

    final paint = Paint()..isAntiAlias = false;

    final boundaries = Rect.fromLTWH(
      rect.width * area.left,
      rect.height * area.top,
      rect.width * area.width,
      rect.height * area.height,
    );

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0.0, 0.0, rect.width, rect.height));
    canvas.restore();

    paint.color = config.boxBackgroundColor;

    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, rect.width, boundaries.top), paint);
    canvas.drawRect(
        Rect.fromLTRB(0.0, boundaries.bottom, rect.width, rect.height), paint);
    canvas.drawRect(
        Rect.fromLTRB(0.0, boundaries.top, boundaries.left, boundaries.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTRB(
            boundaries.right, boundaries.top, rect.width, boundaries.bottom),
        paint);

    if (!boundaries.isEmpty) {
      _drawHandles(canvas, boundaries);
      _drawBottomHandleExtension(canvas, size, boundaries);
    }

    _createTextInfo(
        canvas, boundaries.top - textContainerHeight - 10, rect.width);
    canvas.restore();
  }

  _drawBottomHandleExtension(Canvas canvas, Size size, Rect boundaries) {
    double width = 6;
    double padding = 13;

    Offset bottomRight = boundaries.bottomRight.translate(-padding, -padding);
    double initialX = bottomRight.dx;
    double initialY = bottomRight.dy;
    final paint = Paint()
      ..color = config.borderHandleColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path p = Path();
    p.moveTo(initialX, initialY);
    p.lineTo(initialX - width, initialY);
    p.lineTo(initialX, initialY - width);
    p.lineTo(initialX, initialY);

    p.moveTo(initialX - width - 4, initialY - 1);
    p.lineTo(initialX - 1, initialY - width - 4);

    canvas.drawPath(p, paint);
  }

  void _drawHandles(Canvas canvas, Rect boundaries) {
    double width = 20;
    double padding = 8;

    Offset topRight = boundaries.topRight.translate(-padding, padding);
    Offset topLeft = boundaries.topLeft.translate(padding, padding);
    Offset bottomRight = boundaries.bottomRight.translate(-padding, -padding);
    Offset bottomLeft = boundaries.bottomLeft.translate(padding, -padding);

    //Horizontal lines
    _drawHandleBorder(canvas, topLeft, topLeft.translate(width, 0));
    _drawHandleBorder(canvas, topRight, topRight.translate(-width, 0));
    _drawHandleBorder(canvas, bottomRight, bottomRight.translate(-width, 0));
    _drawHandleBorder(canvas, bottomLeft, bottomLeft.translate(width, 0));

    _drawHandleBorder(canvas, topLeft, topLeft.translate(0, width));
    _drawHandleBorder(canvas, topRight, topRight.translate(0, width));
    _drawHandleBorder(canvas, bottomRight, bottomRight.translate(0, -width));
    _drawHandleBorder(canvas, bottomLeft, bottomLeft.translate(0, -width));

    _ovalWithBorder(canvas, topRight);
    _ovalWithBorder(canvas, topLeft);
    _ovalWithBorder(canvas, bottomRight);
    _ovalWithBorder(canvas, bottomLeft);
  }

  void _drawHandleBorder(Canvas canvas, Offset p1, Offset p2) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = config.borderHandleColor
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;

    canvas.drawLine(p1, p2, paint);
  }

  void _ovalWithBorder(Canvas canvas, Offset center, {double radius = 1}) {
    Paint paintCircle = Paint()..color = Color(0xffffffff);

    Paint paintBorder = Paint()
      ..color = config.borderHandleColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintBorder);
  }

  _createTextInfo(
      Canvas canvas, double textContainerTop, double containerWidth) {
    final TextStyle pillTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14.0,
    );
    final textSpan = TextSpan(text: config.overlayTitle, style: pillTextStyle);
    final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    textPainter.layout();

    final textContainerHeight = textPainter.height + 16;
    final textContainerRect = Rect.fromLTWH(
        (containerWidth - textPainter.width) / 2,
        textContainerTop,
        textPainter.width + 16,
        textContainerHeight);

    textPainter.paint(
        canvas, Offset(textContainerRect.left + 8, textContainerRect.top + 8));
  }
}
