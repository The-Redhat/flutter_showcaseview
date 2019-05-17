import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:showcaseview/custom_paint.dart';

class TargetWidget extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final ShapeBorder shapeBorder;
  final TextStyle titleTextStyle;
  final TextStyle descTextStyle;
  final GlobalKey key;

  const TargetWidget({
    this.key,
    @required this.child,
    @required this.title,
    @required this.description,
    this.shapeBorder,
    this.titleTextStyle,
    this.descTextStyle,
  });

  @override
  _TargetWidgetState createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<TargetWidget>
    with TickerProviderStateMixin {
  bool _showShowCase = false;
  Animation<double> _slideAnimation;
  Animation<double> _widthAnimation;

  AnimationController _slideAnimationController;
  AnimationController _widthAnimationController;

  @override
  void initState() {
    super.initState();
    _widthAnimationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _widthAnimation = CurvedAnimation(
      parent: _widthAnimationController,
      curve: Curves.easeInOut,
    );

    _widthAnimationController.addListener(() {
      setState(() {});
    });

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _slideAnimationController.reverse();
        }
        if (_slideAnimationController.isDismissed) {
          _slideAnimationController.forward();
        }
      });

    _slideAnimation = CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _slideAnimationController.dispose();
    _widthAnimationController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showOverlay();
  }

  void showOverlay() {
    GlobalKey activeStep = ShowCase.activeTargetWidget(context);
    setState(() {
      _showShowCase = activeStep == widget.key;
    });

    if (activeStep == widget.key) {
      _slideAnimationController.forward();
      _widthAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnchoredOverlay(
      overlayBuilder: (BuildContext context, Rect rectBound, Offset offset) =>
          buildOverlayOnTarget(offset, rectBound.size, rectBound, size),
      showOverlay: true,
      child: widget.child,
    );
  }

  _onTargetTap() {
    ShowCase.dismiss(context);
    setState(() {
      _showShowCase = false;
      print(_showShowCase);
    });
  }

  _nextIfAny() {
    ShowCase.completed(context, widget.key);
    _slideAnimationController.forward();
    _widthAnimationController.forward();
  }

  buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize,
  ) =>
      Visibility(
        visible: _showShowCase,
        maintainAnimation: true,
        maintainState: true,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _onTargetTap,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                // color: Colors.grey.withOpacity(0.3),
                child: CustomPaint(
                  painter: ShapePainter(key: widget.key,shapeBorder: widget.shapeBorder),
                ),
              ),
            ),
            _TargetWidget(
              offset: offset,
              size: size,
              widthAnimation: _widthAnimation,
              onTap: _nextIfAny,
              shapeBorder: widget.shapeBorder,
            ),
            _Content(
              offset: offset,
              screenSize: screenSize,
              title: widget.title,
              description: widget.description,
              animationOffset: _slideAnimation,
              titleTextStyle: widget.titleTextStyle,
              descTextStyle: widget.descTextStyle,
            ),
          ],
        ),
      );
}

class _Content extends StatelessWidget {
  final Offset offset;
  final Size screenSize;
  final String title;
  final String description;
  final Animation<double> animationOffset;
  final TextStyle titleTextStyle;
  final TextStyle descTextStyle;

  _Content({
    this.offset,
    this.screenSize,
    this.title,
    this.description,
    this.animationOffset,
    this.titleTextStyle,
    this.descTextStyle,
  });

  bool isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88 || (screenSize.height - position.dy) <= 88;
  }

  bool isOnTopHalfOfScreen(Offset position) {
    return position.dy < (screenSize.height / 2);
  }

  String findPositionForContent(Offset position) {
    if (isCloseToTopOrBottom(position)) {
      if (isOnTopHalfOfScreen(position)) {
        return "B";
      } else {
        return "A";
      }
    } else {
      if (isOnTopHalfOfScreen(position)) {
        return "A";
      } else {
        return "B";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentOrientation = findPositionForContent(offset);
    final contentOffsetMultiplier = contentOrientation == "B" ? 1.0 : -1.0;
    final contentY = offset.dy + (contentOffsetMultiplier * 48);
    final contentFractionalOffset = contentOffsetMultiplier.clamp(-1.0, 0.0);
    return Positioned(
      top: contentY,
      right: 16,
      left: 16,
      child: FractionalTranslation(
        translation: Offset(0.0, contentFractionalOffset),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, contentFractionalOffset / 5),
            end: Offset(0.0, 0.100), //controls the opening of the slice
          ).animate(animationOffset),
          child: Container(
            width: screenSize.width,
            child: Material(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, right: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 8),
                      child: Text(
                        title,
                        style:
                            titleTextStyle ?? Theme.of(context).textTheme.title,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        description,
                        style: descTextStyle ??
                            Theme.of(context).textTheme.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetWidget extends StatelessWidget {
  final Offset offset;
  final Size size;
  final Animation<double> widthAnimation;
  final VoidCallback onTap;
  final ShapeBorder shapeBorder;

  _TargetWidget({
    Key key,
    @required this.offset,
    this.size,
    this.widthAnimation,
    this.onTap,
    this.shapeBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: FractionalTranslation(
        translation: Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: size.height + 16,
            width: Tween<double>(
              begin: 0,
              end: size.width + 16, //controls the opening of the slice
            ).animate(widthAnimation).value,
            decoration: ShapeDecoration(
              shape: shapeBorder ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnchoredOverlay extends StatelessWidget {
  final bool showOverlay;
  final Widget Function(BuildContext, Rect anchorBounds, Offset anchor)
      overlayBuilder;
  final Widget child;

  AnchoredOverlay({
    key,
    this.showOverlay = false,
    this.overlayBuilder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return OverlayBuilder(
          showOverlay: showOverlay,
          overlayBuilder: (BuildContext overlayContext) {
            // To calculate the "anchor" point we grab the render box of
            // our parent Container and then we find the center of that box.
            RenderBox box = context.findRenderObject() as RenderBox;
            final topLeft =
                box.size.topLeft(box.localToGlobal(const Offset(0.0, 0.0)));
            final bottomRight =
                box.size.bottomRight(box.localToGlobal(const Offset(0.0, 0.0)));
            final Rect anchorBounds = Rect.fromLTRB(
              topLeft.dx,
              topLeft.dy,
              bottomRight.dx,
              bottomRight.dy,
            );
            final anchorCenter = box.size.center(topLeft);
            return overlayBuilder(overlayContext, anchorBounds, anchorCenter);
          },
          child: child,
        );
      },
    );
  }
}

class OverlayBuilder extends StatefulWidget {
  final bool showOverlay;
  final Widget Function(BuildContext) overlayBuilder;
  final Widget child;

  OverlayBuilder({
    key,
    this.showOverlay = false,
    this.overlayBuilder,
    this.child,
  }) : super(key: key);

  @override
  _OverlayBuilderState createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<OverlayBuilder> {
  OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();

    if (widget.showOverlay) {
      // showOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) => showOverlay());
    }
  }

  @override
  void didUpdateWidget(OverlayBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // syncWidgetAndOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) => syncWidgetAndOverlay());
  }

  @override
  void reassemble() {
    super.reassemble();
    // syncWidgetAndOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) => syncWidgetAndOverlay());
  }

  @override
  void dispose() {
    if (isShowingOverlay()) {
      hideOverlay();
    }

    super.dispose();
  }

  bool isShowingOverlay() => _overlayEntry != null;

  void showOverlay() {
    if (_overlayEntry == null) {
      // Create the overlay.
      _overlayEntry = OverlayEntry(
        builder: widget.overlayBuilder,
      );
      addToOverlay(_overlayEntry);
    } else {
      // Rebuild overlay.
      buildOverlay();
    }
  }

  void addToOverlay(OverlayEntry overlayEntry) async {
    Overlay.of(context).insert(overlayEntry);
    final overlay = Overlay.of(context);
    if (overlayEntry == null)
      WidgetsBinding.instance
          .addPostFrameCallback((_) => overlay.insert(overlayEntry));
  }

  void hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry.remove();
      _overlayEntry = null;
    }
  }

  void syncWidgetAndOverlay() {
    if (isShowingOverlay() && !widget.showOverlay) {
      hideOverlay();
    } else if (!isShowingOverlay() && widget.showOverlay) {
      showOverlay();
    }
  }

  void buildOverlay() async {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _overlayEntry?.markNeedsBuild());
  }

  @override
  Widget build(BuildContext context) {
    buildOverlay();

    return widget.child;
  }
}