import 'dart:async';
import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wear_os_plugin.dart';

/// the scroll view listen to the rotary input from the [WearOsPlugin]
/// and control a scrollable view like [ListView] using a shared [ScrollController]
class WearOsScrollView extends StatefulWidget {
  /// the shared [ScrollController] which is also used in the scrollable view like [ListView]
  final ScrollController controller;
  final Widget child;

  /// autoHide: true means automatically blend out the bars, false means scrollbars are always visible
  final bool autoHide;

  /// threshold to avoid jittering
  final double threshold = 0.2;

  ///  bezel correction for Samsung devices
  final double bezelCorrection = 0.5;

  /// scroll amount in screen dimensions
  final double speed = 50.0;

  /// padding of scroll bar
  final double padding = 8.0;

  /// width of scroll bar
  final double width = 8.0;

  /// animation curve for blending the scroll bar in or out
  final Curve opacityAnimationCurve = Curves.easeInOut;

  /// animation duration for blending the scroll bar in or out
  final Duration opacityAnimationDuration = const Duration(milliseconds: 500);

  /// duration for keeping the scroll bar visible
  final Duration autoHideDuration = const Duration(milliseconds: 1500);

  const WearOsScrollView(
      {super.key,
      required this.controller,
      required this.child,
      this.autoHide = true});

  @override
  State<WearOsScrollView> createState() => _WearOsScrollView();
}

class _WearOsScrollView extends State<WearOsScrollView> {
  // internal states:
  double _position = 0; // 0-1
  double _currentPosition = 0;
  double _maxPosition = 0;
  double _thumbSize = 0; // 0-1, 1=full length
  bool _isScrollBarShown = false;
  StreamController<MotionData>? _motionEventStream;

  void _onScrolled() {
    if (widget.controller.hasClients) {
      _currentPosition = widget.controller.offset;

      setState(() {
        _isScrollBarShown = true;
        _updateScrollValues();
      });

      _hideAfterDelay();
    }
  }

  // event driven scrolling: ----------------------------------------------
  double _movement = 0;
  bool? _isClockWise;
  int lastFeedback = 0;

  bool? checkClockWise(double? v) =>
      (v == null || v == 0) ? null : (v < 0 ? true : false);

  void _onMotionEvent(MotionData d) {
    final isClockWise = checkClockWise(d.scroll);

    // direction changed, restart movement:
    if (isClockWise != _isClockWise) {
      _movement = -widget.threshold; // start with threshold to avoid jittering
      _isClockWise = isClockWise;
    }

    // HINT: correct steps for SAMSUNG bezel, which produces steps with exact 1.0:
    double step = (d.scroll ?? 0).abs();
    if (step == 1.0) step *= widget.bezelCorrection;

    // calc movement:
    _movement += step;

    // movement -> scrolling:
    if (_movement > 0) {
      final oldPos = _currentPosition;
      bool atEnd = false;
      if (_isClockWise == true) {
        _currentPosition += _movement * widget.speed;
        if (_currentPosition > _maxPosition) {
          _currentPosition = _maxPosition;
          atEnd = _currentPosition != oldPos; // only at end, on first arrive
        }
      } else if (_isClockWise == false) {
        _currentPosition -= _movement * widget.speed;
        if (_currentPosition < 0) {
          _currentPosition = 0;
          atEnd = _currentPosition != oldPos; // only at end, on first arrive
        }
      }
      _movement = 0;
      // scroll directly to position:
      widget.controller.jumpTo(_currentPosition);

      // check duration since last haptic feedback and do haptic feedback:
      final ticks = DateTime.now().millisecondsSinceEpoch;
      if (atEnd || ticks - lastFeedback > 200) {
        WearOsPlugin.instance.vibrate(effect: 'click');
        lastFeedback = ticks;
      }
    }
  }

  Timer? _hideTimer;

  void _hideAfterDelay() {
    if (widget.autoHide) {
      // clear previous timer:
      _hideTimer?.cancel();
      // start a new timeout:
      _hideTimer = Timer(widget.autoHideDuration, () {
        setState(() => _isScrollBarShown = false);
        _hideTimer = null;
      });
    }
  }

  void _updateScrollValues() {
    _maxPosition = widget.controller.position.maxScrollExtent;
    _thumbSize =
        1 / ((_maxPosition / widget.controller.position.viewportDimension) + 1);
    _position = widget.controller.offset / math.max(_maxPosition, 1);
  }

  // ----------------------------------------------------------------------

  @override
  void initState() {
    widget.controller.addListener(_onScrolled);
    _motionEventStream = WearOsPlugin.instance.registerForMotionEvents;
    _motionEventStream?.stream.listen(_onMotionEvent);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollValues();
      setState(() {}); // show new values
      _hideAfterDelay();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WearOsPlugin.instance.unregisterFromMotionEvents(_motionEventStream);
    _motionEventStream = null;
    widget.controller.removeListener(_onScrolled);
    super.dispose();
  }

  // painting: -------------------------------------------------------------

  Widget _addAnimatedOpacity({required Widget child}) {
    return widget.autoHide
        ? AnimatedOpacity(
            opacity: _isScrollBarShown ? 1 : 0,
            duration: widget.opacityAnimationDuration,
            curve: widget.opacityAnimationCurve,
            child: child,
          )
        : child;
  }

  _buildTrack(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _RoundProgressBarPainter(
        color: Theme.of(context).highlightColor.withOpacity(0.2),
        trackPadding: widget.padding,
        trackWidth: widget.width,
      ),
    );
  }

  _buildThumb(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _RoundProgressBarPainter(
        start: _position * (1 - _thumbSize),
        length: _thumbSize,
        color: Theme.of(context).highlightColor.withOpacity(1.0),
        trackPadding: widget.padding,
        trackWidth: widget.width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      IgnorePointer(
        child: _addAnimatedOpacity(
          child: Stack(
            children: [_buildTrack(context), _buildThumb(context)],
          ),
        ),
      )
    ]);
  }
}

class _RoundProgressBarPainter extends CustomPainter {
  // starts at the 2pm marker on an analog watch
  static const _startingAngle = (math.pi * 2) * (-2 / 24);

  // finishes at the 4pm marker on an analog watch
  static const _angleLength = (math.pi * 2) * (2 / 12);

  final Color color;
  final double trackWidth;
  final double trackPadding;
  final double start;
  final double length;

  _RoundProgressBarPainter(
      {required this.color,
      required this.trackPadding,
      required this.trackWidth,
      this.start = 0,
      this.length = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = trackWidth.toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (WearOsPlugin.screenRound != false) {
      final centerOffset = Offset(
        size.width / 2,
        size.height / 2,
      );

      final innerWidth = size.width - trackPadding * 2 - trackWidth;
      final innerHeight = size.height - trackPadding * 2 - trackWidth;

      final path = Path()
        ..arcTo(
          Rect.fromCenter(
            center: centerOffset,
            width: innerWidth,
            height: innerHeight,
          ),
          _startingAngle + _angleLength * start,
          _angleLength * length,
          true,
        );

      canvas.drawPath(path, paint);
    } else {
      // rectangular:
      final space = trackPadding - trackWidth / 2;
      final h = size.height - space * 2;
      Offset top = Offset(size.width - space, space + h * start);
      Offset bottom = Offset(size.width - space, space + h * (start + length));

      canvas.drawLine(top, bottom, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoundProgressBarPainter oldDelegate) {
    return color != oldDelegate.color ||
        start != oldDelegate.start ||
        length != oldDelegate.length ||
        trackWidth != oldDelegate.trackWidth ||
        trackPadding != oldDelegate.trackPadding;
  }
}
