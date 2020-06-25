import 'dart:ui';

import 'package:camera/crop_overlay_painter.dart';
import 'package:flutter/material.dart';

// const _kCropGridColumnCount = 3;
// const _kCropGridRowCount = 3;
// const _kCropGridColor = Color.fromRGBO(0xd0, 0xd0, 0xd0, 0.9);
// const _kCropOverlayColor = Color.fromRGBO(0x0, 0x0, 0x0, 0.3);
const _kCropHandleSize = 10.0;
const _kCropHandleHitSize = 48.0;
const _kCropMinFraction = 0.0;

enum _CropHandleSide {
  none,
  top,
  left,
  right,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
}

class CameraOverlaySizeResult {
  Rect rect;
  Size forSize;

  CameraOverlaySizeResult(this.rect, this.forSize);

//NOTE: Commecting code for infuture debug
  Rect getRect(Size newSize, double scale) {
    // print("&&&&& +++++++++++++++++++++++");

    // double aspectRatio = newSize.aspectRatio;
    double scaledWidth = newSize.width / scale;
    
    // double widthPadding = ((newSize.width - forSize.width) / 2);
    // double hightPadding = ((newSize.width - forSize.width) / 2);
  //   print("&&&&& aspectRatio ${aspectRatio}");
  //   print("&&&&& scale ${scale}");
  //   print("&&&&& forSize $forSize");
  //   print("&&&&& newSize ${newSize}");
  //   print("&&&&& =======================");
  //   print("&&&&& rect $rect");
  //   print("&&&&& rect.width ${rect.width}");
  //   print("&&&&& rect.height ${rect.height}");
  //   print("&&&&& rect.left ${rect.left}");
    

  //   Rect newRect = Rect.fromLTWH(
  //       (rect.left * forSize.width + widthPadding) / newSize.width,
  //       (rect.top),
  //       (rect.width * forSize.width) / newSize.width,
  //       (rect.height));

  //   Rect rect2 = Rect.fromLTWH(
  //       (rect.left * scale),
  //       (rect.top),
  //       (rect.width / scale) ,
  //       (rect.height));
  //  double l = rect.left * aspectRatio;
  //   Rect rect3 = Rect.fromLTWH(
  //       l,
  //       (rect.top),
  //       (1 - (2 * l)) ,
        // (rect.height));

    double r4WidthPadding = (newSize.width - scaledWidth) / 2;
    Rect r4 = Rect.fromLTWH(
        (rect.left * scaledWidth + r4WidthPadding) / newSize.width,
        (rect.top),
        (rect.width * scaledWidth) / newSize.width,
        (rect.height));

    // print("&&&&& =======================");
    // print("&&&&& newRect ${newRect}");
    // print("&&&&& newRect.left ${newRect.left}");
    // print("&&&&& newRect.height ${newRect.height}");
    // print("&&&&& newRect.width ${newRect.width}");
    // print("&&&&& =======================");
    // print("&&&&& rect2 ${rect2}");
    // print("&&&&& rect2.left ${rect2.left}");
    // print("&&&&& rect2.height ${rect2.height}");
    // print("&&&&& rect2.width ${rect2.width}");
    // print("&&&&& =======================");
    // print("&&&&& rect3 ${rect3}");
    // print("&&&&& rect3.left ${rect3.left}");
    // print("&&&&& rect3.height ${rect3.height}");
    // print("&&&&& rect3.width ${rect3.width}");
    // print("&&&&& =======================");
    // print("&&&&& r4 ${r4}");
    // print("&&&&& r4.left ${r4.left}");
    // print("&&&&& r4.height ${r4.height}");
    // print("&&&&& r4.width ${r4.width}");
    // print("&&&&& +++++++++++++++++++++++");


    return r4;
  }
}

class CameraOverlayConfig {
  Color boxBackgroundColor;
  bool isExpandingEnabled;
  EdgeInsets overlayPadding;
  String overlayTitle;
  double initalHeightScale;
  double initalWidthScale;
  Color borderHandleColor = Colors.white;
  double minimumHeightScale;
  double minimumWidthScale;

  CameraOverlayConfig({
    this.boxBackgroundColor = Colors.black45,
    this.isExpandingEnabled = true,
    this.overlayPadding = const EdgeInsets.fromLTRB(0, 0, 0, 0),
    this.overlayTitle = "Take a clear picture of your question",
    this.initalHeightScale = 0.3,
    this.initalWidthScale = 0.80,
    this.minimumHeightScale = 0.1,
    this.minimumWidthScale = 0.2,
  });
}

class CameraOverlay extends StatefulWidget {
  final CameraOverlayConfig config;
  final Function(Offset tapPoint, Offset scalledPoint) tapCallback;

  CameraOverlay(Key key, {this.config, this.tapCallback}) : super(key: key);

  @override
  CameraOverlayState createState() => CameraOverlayState();
}

class CameraOverlayState extends State<CameraOverlay>
    with TickerProviderStateMixin {
  CameraOverlayConfig _config;

  final GlobalKey _gestureKey = GlobalKey();
  bool get _isEnabled => _config.isExpandingEnabled;
  AnimationController _settleController;
  Tween<Rect> _viewTween;
  _CropHandleSide _handle = _CropHandleSide.none;
  Offset _lastFocalPoint = Offset.zero;
  Rect _view = Rect.zero;
  Rect _area;
  Rect _previousArea;

  CameraOverlaySizeResult get cropArea {
    EdgeInsets overlayPadding = _config.overlayPadding;
    final RenderBox box = context.findRenderObject();
    Size size = box.size;
    var area = _area ?? _previousArea ?? Rect.zero;
    Size cropOverlaySize = Size(size.width - overlayPadding.horizontal,
        size.height - overlayPadding.vertical);

    double left = ((area.left * cropOverlaySize.width) + overlayPadding.left) /
        size.width;
    double top = ((area.top * cropOverlaySize.height) + overlayPadding.top) /
        size.height;
    double width = (area.width * cropOverlaySize.width) / size.width;
    double height = (area.height * cropOverlaySize.height) / size.height;

    Rect finalRect = Rect.fromLTWH(left, top, width, height);
    return CameraOverlaySizeResult(finalRect, size);
  }

  Offset _getLocalPoint(Offset point) {
    final RenderBox box = _gestureKey.currentContext.findRenderObject();
    return box.globalToLocal(point);
  }

  Size get _getGestureBoundaries => _gestureKey.currentContext.size;

  Size get _boundaries =>
      _getGestureBoundaries - Offset(_kCropHandleSize, _kCropHandleSize);

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? CameraOverlayConfig();
    _calculateArea();
    _previousArea = Rect.fromLTWH(0.09, 0.02, 0.82, 0.96);

    _settleController = AnimationController(vsync: this)
      ..addListener(_settleAnimationChanged);
  }

  _calculateArea() {
    double left = (1 - _config.initalWidthScale) / 2;
    double top = (1 - _config.initalHeightScale) / 2;
    _area = Rect.fromLTWH(
        left, top, _config.initalWidthScale, _config.initalHeightScale);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _config.overlayPadding,
      child: GestureDetector(
        key: _gestureKey,
        behavior: HitTestBehavior.opaque,
        onScaleStart: _isEnabled ? _handleScaleStart : null,
        onScaleUpdate: _isEnabled ? _handleScaleUpdate : null,
        onScaleEnd: _isEnabled ? _handleScaleEnd : null,
        onTapUp: (TapUpDetails details) {
          final RenderBox box = context.findRenderObject();
          final Offset localPoint = box.globalToLocal(details.globalPosition);
          final Offset scaledPoint =
              localPoint.scale(1 / box.size.width, 1 / box.size.height);
          if (widget.tapCallback != null) {
            widget.tapCallback(localPoint, scaledPoint);
          }
        },
        child: CustomPaint(
          painter: CropPainter(
            view: _view,
            area: _area,
            config: _config,
          ),
        ),
      ),
    );
  }

  void _settleAnimationChanged() {
    setState(() {
      _view = _viewTween.transform(_settleController.value);
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _settleController.stop(canceled: false);
    _lastFocalPoint = details.focalPoint;
    _handle = _hitCropHandle(_getLocalPoint(details.focalPoint));
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.focalPoint - _lastFocalPoint;
    _lastFocalPoint = details.focalPoint;

    final dx = delta.dx / _boundaries.width;
    final dy = delta.dy / _boundaries.height;

    if (_handle == _CropHandleSide.top) {
      _updateArea(top: dy, bottom: -dy);
    } else if (_handle == _CropHandleSide.left) {
      _updateArea(left: dx, right: -dx);
    } else if (_handle == _CropHandleSide.right) {
      _updateArea(right: dx, left: -dx);
    } else if (_handle == _CropHandleSide.bottom) {
      _updateArea(bottom: dy, top: -dy);
    } else if (_handle == _CropHandleSide.topLeft) {
      _updateArea(left: dx, top: dy, right: -dx, bottom: -dy);
    } else if (_handle == _CropHandleSide.topRight) {
      _updateArea(top: dy, right: dx, left: -dx, bottom: -dy);
    } else if (_handle == _CropHandleSide.bottomLeft) {
      _updateArea(left: dx, bottom: dy, right: -dx, top: -dy);
    } else if (_handle == _CropHandleSide.bottomRight) {
      _updateArea(right: dx, bottom: dy, left: -dx, top: -dy);
    }
  }

  void _updateArea({double left, double top, double right, double bottom}) {
    var areaLeft = _area.left + (left ?? 0.0);
    var areaTop = _area.top + (top ?? 0.0);
    var areaRight = _area.right + (right ?? 0.0);
    var areaBottom = _area.bottom + (bottom ?? 0.0);

    // ensure minimum rectangle
    if (areaRight - areaLeft < _kCropMinFraction) {
      if (left != null) {
        areaLeft = areaRight - _kCropMinFraction;
      } else {
        areaRight = areaLeft + _kCropMinFraction;
      }
    }

    if (areaBottom - areaTop < _kCropMinFraction) {
      if (top != null) {
        areaTop = areaBottom - _kCropMinFraction;
      } else {
        areaBottom = areaTop + _kCropMinFraction;
      }
    }

    // ensure to remain within bounds of the view
    if (areaLeft < _previousArea.left) {
      areaLeft = _area.left;
      areaRight = _area.right;
    } else if (areaRight > _previousArea.right) {
      areaLeft = _area.right - _area.width;
      areaRight = _area.right;
    }

    if (areaTop < _previousArea.top) {
      areaTop = _area.top;
      areaBottom = _area.bottom;
    } else if (areaBottom > _previousArea.bottom) {
      areaTop = _area.bottom - _area.height;
      areaBottom = _area.bottom;
    }

    Rect newArea = Rect.fromLTRB(areaLeft, areaTop, areaRight, areaBottom);
    if (newArea.height > _config.minimumHeightScale &&
        newArea.width > _config.minimumWidthScale) {
      setState(() {
        _area = newArea;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {}

  // void _activate() {
  //   _activeController.animateTo(
  //     1.0,
  //     curve: Curves.fastOutSlowIn,
  //     duration: const Duration(milliseconds: 250),
  //   );
  // }

  _CropHandleSide _hitCropHandle(Offset localPoint) {
    final boundaries = _boundaries;
    final viewRect = Rect.fromLTWH(
      boundaries.width * _area.left,
      boundaries.height * _area.top,
      boundaries.width * _area.width,
      boundaries.height * _area.height,
    ).deflate(_kCropHandleSize / 2);

    if (Rect.fromLTWH(
      viewRect.left + _kCropHandleHitSize / 2,
      viewRect.bottom - _kCropHandleHitSize / 2,
      viewRect.width - _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.bottom;
    }

    if (Rect.fromLTWH(
      viewRect.left + _kCropHandleHitSize / 2,
      viewRect.top - _kCropHandleHitSize / 2,
      viewRect.width - _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.top;
    }

    if (Rect.fromLTWH(
      viewRect.left - _kCropHandleHitSize / 2,
      viewRect.top + _kCropHandleHitSize,
      _kCropHandleHitSize,
      viewRect.height - _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.left;
    }

    if (Rect.fromLTWH(
      viewRect.right - _kCropHandleHitSize / 2,
      viewRect.top + _kCropHandleHitSize,
      _kCropHandleHitSize,
      viewRect.height - _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.right;
    }

    if (Rect.fromLTWH(
      viewRect.left - _kCropHandleHitSize / 2,
      viewRect.top - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.topLeft;
    }

    if (Rect.fromLTWH(
      viewRect.right - _kCropHandleHitSize / 2,
      viewRect.top - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.topRight;
    }

    if (Rect.fromLTWH(
      viewRect.left - _kCropHandleHitSize / 2,
      viewRect.bottom - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.bottomLeft;
    }

    if (Rect.fromLTWH(
      viewRect.right - _kCropHandleHitSize / 2,
      viewRect.bottom - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.bottomRight;
    }

    return _CropHandleSide.none;
  }
}