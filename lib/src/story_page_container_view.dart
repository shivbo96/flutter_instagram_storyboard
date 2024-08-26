import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';
import 'package:flutter_instagram_storyboard/src/first_build_mixin.dart';

class StoryPageContainerView extends StatefulWidget {
  final StoryButtonData buttonData;
  final Function() onStoryComplete;
  final PageController? pageController;
  final VoidCallback? onClosePressed;

  const StoryPageContainerView({
    Key? key,
    required this.buttonData,
    required this.onStoryComplete,
    this.pageController,
    this.onClosePressed,
  }) : super(key: key);

  @override
  State<StoryPageContainerView> createState() => _StoryPageContainerViewState();
}

class _StoryPageContainerViewState extends State<StoryPageContainerView> with FirstBuildMixin {
  late StoryTimelineController _storyController;
  final Stopwatch _stopwatch = Stopwatch();
  Offset _pointerDownPosition = Offset.zero;
  int _pointerDownMillis = 0;
  double _pageValue = 0.0;

  @override
  void initState() {
    _storyController = widget.buttonData.storyController ?? StoryTimelineController();
    _stopwatch.start();
    _storyController.addListener(_onTimelineEvent);
    super.initState();
  }

  @override
  void didFirstBuildFinish(BuildContext context) {
    widget.pageController?.addListener(_onPageControllerUpdate);
  }

  void _onPageControllerUpdate() {
    if (widget.pageController?.hasClients != true) {
      return;
    }
    _pageValue = widget.pageController?.page ?? 0.0;
    _storyController._setTimelineAvailable(_timelineAvailable);
  }

  bool get _timelineAvailable {
    return _pageValue % 1.0 == 0.0;
  }

  void _onTimelineEvent(StoryTimelineEvent event, String storyId) {
    if (event == StoryTimelineEvent.storyComplete) {
      widget.onStoryComplete.call();
    }
    setState(() {});
  }

  Widget _buildCloseButton() {
    Widget closeButton;
    if (widget.buttonData.closeButton != null) {
      closeButton = widget.buttonData.closeButton!;
    } else {
      closeButton = SizedBox(
        height: 40.0,
        width: 40.0,
        child: MaterialButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (widget.onClosePressed != null) {
              widget.onClosePressed!.call();
            } else {
              Navigator.of(context).pop();
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: SizedBox(
            height: 40.0,
            width: 40.0,
            child: Icon(
              Icons.close,
              size: 28.0,
              color: widget.buttonData.defaultCloseButtonColor,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          if (widget.buttonData.showStoryViewedUsersIcon)
            InkWell(
              onTap: () {
                _pointerDownMillis = _stopwatch.elapsedMilliseconds;
                _storyController.pause();
                widget.buttonData.onStorySeenUsersIconPressedCallback?.call();
                onStorySeenUsersIconCountPressed();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
                        if ((widget.buttonData.storyViewedUserList?[widget.buttonData.currentSegmentIndex] ?? [])
                            .isNotEmpty)
                          SizedBox(width: 5),
                        if ((widget.buttonData.storyViewedUserList?[widget.buttonData.currentSegmentIndex] ?? [])
                            .isNotEmpty)
                          Text(
                              '${(widget.buttonData.storyViewedUserList?[widget.buttonData.currentSegmentIndex] ?? []).length}',
                              style: TextStyle(fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          closeButton,
        ],
      ),
    );
  }

  void onStorySeenUsersIconCountPressed() {
    _pointerDownMillis = _stopwatch.elapsedMilliseconds;
    _storyController.pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(16), right: Radius.circular(16))),
      builder: (BuildContext context) {
        return _buildBottomSheet(
            context, widget.buttonData.storyViewedUserList?[widget.buttonData.currentSegmentIndex] ?? []);
      },
    ).then(
      (value) {
        _storyController.unpause();
      },
    );
  }

  Widget _buildBottomSheet(BuildContext context, List<ReadUserModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Views (${users.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.buttonData.showMoreOptionInBottomSheet)
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.buttonData.moreOptionInBottomSheetCallBack,
                  )
              ],
            ),
          ),
          Expanded(
            child: users.isNotEmpty
                ? ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: Container(
                          height: 30,
                          width: 30,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: CachedNetworkImage(
                              imageUrl: '${user.profile}',
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person_2_outlined, size: 30, color: Colors.white),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              user.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            if (user.showBadge)
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 16.0,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          user.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No view yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.buttonData.timlinePadding?.top ?? 15.0,
        left: widget.buttonData.timlinePadding?.left ?? 15.0,
        right: widget.buttonData.timlinePadding?.left ?? 15.0,
        bottom: widget.buttonData.timlinePadding?.bottom ?? 5.0,
      ),
      child: StoryTimeline(
        controller: _storyController,
        buttonData: widget.buttonData,
      ),
    );
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

  Widget _buildPageContent() {
    if (widget.buttonData.storyPages.isEmpty) {
      return Container(
        color: Colors.orange,
        child: const Center(
          child: Text('No pages'),
        ),
      );
    }
    return widget.buttonData.storyPages[_curSegmentIndex];
  }

  bool _isLeftPartOfStory(Offset position) {
    if (!mounted) {
      return false;
    }
    final storyWidth = context.size!.width;
    return position.dx <= (storyWidth * .499);
  }

  Widget _buildPageStructure() {
    return Listener(
      key: UniqueKey(),
      onPointerDown: (PointerDownEvent event) {
        _pointerDownMillis = _stopwatch.elapsedMilliseconds;
        _pointerDownPosition = event.position;
        _storyController.pause();
      },
      onPointerUp: (PointerUpEvent event) {
        if (event.localPosition.dy > 36 && event.localPosition.dy < 83) {
          _pointerDownMillis = _stopwatch.elapsedMilliseconds;
          _storyController.pause();
          return;
        } else {
          _storyController.unpause();
        }
        final pointerUpMillis = _stopwatch.elapsedMilliseconds;
        final maxPressMillis = kPressTimeout.inMilliseconds * 2;
        final diffMillis = pointerUpMillis - _pointerDownMillis;
        if (diffMillis <= maxPressMillis) {
          final position = event.position;
          final distance = (position - _pointerDownPosition).distance;
          if (distance < 5.0) {
            final isLeft = _isLeftPartOfStory(position);
            if (isLeft) {
              _storyController.previousSegment();
            } else {
              _storyController.nextSegment();
            }
          }
        }
        _storyController.unpause();
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            _buildPageContent(),
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeline(),
                  _buildCloseButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageControllerUpdate);
    _stopwatch.stop();
    _storyController.removeListener(_onTimelineEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildPageStructure(),
    );
  }
}

enum StoryTimelineEvent {
  storyComplete,
  segmentComplete,
  segmentPause,
  segmentResume,
}

typedef StoryTimelineCallback = Function(StoryTimelineEvent, String);

class StoryTimelineController {
  _StoryTimelineState? _state;

  final HashSet<StoryTimelineCallback> _listeners = HashSet<StoryTimelineCallback>();

  void addListener(StoryTimelineCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(StoryTimelineCallback callback) {
    _listeners.remove(callback);
  }

  void _onStoryComplete(String storyId) {
    _notifyListeners(StoryTimelineEvent.storyComplete, storyId: storyId);
  }

  void _onSegmentComplete(String storyId) {
    _notifyListeners(StoryTimelineEvent.segmentComplete, storyId: storyId);
  }

  void _notifyListeners(StoryTimelineEvent event, {required String storyId}) {
    for (var e in _listeners) {
      e.call(event, storyId);
    }
  }

  void nextSegment() {
    _state?.nextSegment();
  }

  void previousSegment() {
    _state?.previousSegment();
  }

  void pause() {
    _state?.pause();
  }

  void _setTimelineAvailable(bool value) {
    _state?._setTimelineAvailable(value);
  }

  void unpause() {
    _state?.unpause();
  }

  void dispose() {
    _listeners.clear();
  }
}

class StoryTimeline extends StatefulWidget {
  final StoryTimelineController controller;
  final StoryButtonData buttonData;

  const StoryTimeline({
    Key? key,
    required this.controller,
    required this.buttonData,
  }) : super(key: key);

  @override
  State<StoryTimeline> createState() => _StoryTimelineState();
}

class _StoryTimelineState extends State<StoryTimeline> {
  late Timer _timer;
  int _accumulatedTime = 0;
  int _maxAccumulator = 0;
  bool _isPaused = false;
  bool _isTimelineAvailable = true;

  @override
  void initState() {
    _maxAccumulator = widget.buttonData.segmentDuration[widget.buttonData.currentSegmentIndex].inMilliseconds;
    _timer = Timer.periodic(
      const Duration(
        milliseconds: kStoryTimerTickMillis,
      ),
      _onTimer,
    );
    widget.controller._state = this;
    super.initState();
    if (widget.buttonData.storyWatchedContract == StoryWatchedContract.onStoryStart) {
      widget.buttonData.markAsWatched();
    }
  }

  void _setTimelineAvailable(bool value) {
    _isTimelineAvailable = value;
  }

  void _onTimer(timer) {
    if (_isPaused || !_isTimelineAvailable) {
      return;
    }
    if (_accumulatedTime + kStoryTimerTickMillis <= _maxAccumulator) {
      _accumulatedTime += kStoryTimerTickMillis;
      if (_accumulatedTime >= _maxAccumulator) {
        if (_isLastSegment) {
          _maxAccumulator = widget.buttonData.segmentDuration[widget.buttonData.currentSegmentIndex].inMilliseconds;
          _onStoryComplete();
        } else {
          _accumulatedTime = 0;
          _onSegmentComplete();
          _curSegmentIndex++;
          _maxAccumulator = widget.buttonData.segmentDuration[widget.buttonData.currentSegmentIndex].inMilliseconds;
        }
      }
      setState(() {});
    }
  }

  void _onStoryComplete() {
    if (widget.buttonData.storyWatchedContract == StoryWatchedContract.onStoryEnd) {
      widget.buttonData.markAsWatched();
    }
    widget.controller._onStoryComplete("${widget.buttonData.storyIds?[widget.buttonData.currentSegmentIndex] ?? ''}");
    widget.buttonData.currentSegmentIndex = 0;
  }

  void _onSegmentComplete() {
    if (widget.buttonData.storyWatchedContract == StoryWatchedContract.onSegmentEnd) {
      widget.buttonData.markAsWatched();
    }
    widget.controller._onSegmentComplete("${widget.buttonData.storyIds?[widget.buttonData.currentSegmentIndex] ?? ''}");
  }

  bool get _isLastSegment {
    return _curSegmentIndex == _numSegments - 1;
  }

  int get _numSegments {
    return widget.buttonData.storyPages.length;
  }

  set _curSegmentIndex(int value) {
    if (value >= _numSegments) {
      value = _numSegments - 1;
    } else if (value < 0) {
      value = 0;
    }
    widget.buttonData.currentSegmentIndex = value;
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

  int currentSegmentIndex() => _curSegmentIndex;

  void nextSegment() {
    if (_isLastSegment) {
      _accumulatedTime = _maxAccumulator;
      widget.controller._onStoryComplete("${widget.buttonData.storyIds?[widget.buttonData.currentSegmentIndex] ?? ''}");
      widget.buttonData.currentSegmentIndex = 0;
    } else {
      _accumulatedTime = 0;
      _onSegmentComplete();
      _curSegmentIndex++;
      _maxAccumulator = widget.buttonData.segmentDuration[widget.buttonData.currentSegmentIndex].inMilliseconds;
    }
  }

  void previousSegment() {
    if (_accumulatedTime == _maxAccumulator) {
      _accumulatedTime = 0;
    } else {
      _accumulatedTime = 0;
      _curSegmentIndex--;
      _maxAccumulator = widget.buttonData.segmentDuration[widget.buttonData.currentSegmentIndex].inMilliseconds;
      _onSegmentComplete();
    }
  }

  void pause() {
    _isPaused = true;
  }

  void unpause() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.0,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(
          fillColor: widget.buttonData.timelineFillColor,
          backgroundColor: widget.buttonData.timelineBackgroundColor,
          curSegmentIndex: _curSegmentIndex,
          numSegments: _numSegments,
          percent: _accumulatedTime / _maxAccumulator,
          spacing: widget.buttonData.timelineSpacing,
          thikness: widget.buttonData.timelineThikness,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final Color fillColor;
  final Color backgroundColor;
  final int curSegmentIndex;
  final int numSegments;
  final double percent;
  final double spacing;
  final double thikness;

  _TimelinePainter({
    required this.fillColor,
    required this.backgroundColor,
    required this.curSegmentIndex,
    required this.numSegments,
    required this.percent,
    required this.spacing,
    required this.thikness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = backgroundColor
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = fillColor
      ..style = PaintingStyle.stroke;

    final maxSpacing = (numSegments - 1) * spacing;
    final maxSegmentLength = (size.width - maxSpacing) / numSegments;

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      final end = Offset(
        start.dx + maxSegmentLength,
        0.0,
      );

      canvas.drawLine(
        start,
        end,
        bgPaint,
      );
    }

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      var endValue = start.dx;
      if (curSegmentIndex > i) {
        endValue = start.dx + maxSegmentLength;
      } else if (curSegmentIndex == i) {
        endValue = start.dx + (maxSegmentLength * percent);
      }
      final end = Offset(
        endValue,
        0.0,
      );
      if (endValue == start.dx) {
        continue;
      }
      canvas.drawLine(
        start,
        end,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
