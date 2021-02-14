library review_prompt;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

part 'review_prompt_error.dart';

typedef ReviewPromptWidgetListener = void Function(BuildContext, Future<void> Function(), Future<void> Function());

class ReviewPromptListener extends StatefulWidget {
  const ReviewPromptListener({
    Key key,
    this.minDaysSinceInstall = 1,
    this.minLaunchCount = 3,
    this.appStoreId,
    this.microsoftStoreId,
    @required this.listener,
    @required this.child,
  })  : assert(minDaysSinceInstall != null || minDaysSinceInstall > 0),
        assert(minLaunchCount != null || minLaunchCount > 0),
        assert(listener != null),
        assert(child != null),
        super(key: key);

  final int minDaysSinceInstall;
  final int minLaunchCount;
  final String appStoreId;
  final String microsoftStoreId;
  final ReviewPromptWidgetListener listener;
  final Widget child;

  static _ReviewPromptListenerState of(BuildContext context) =>
      context.findAncestorStateOfType<_ReviewPromptListenerState>();
  static const boxKey = 'review_prompt';
  static const installDateKey = 'install_date';
  static const launchCountKey = 'launch_count';
  static const didPromptReviewKey = 'did_prompt_review';

  @override
  _ReviewPromptListenerState createState() => _ReviewPromptListenerState();
}

class _ReviewPromptListenerState extends State<ReviewPromptListener> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await shouldPromptReview()) {
        widget.listener(context, reviewInApp, openStoreListing);
      }
    });
  }

  Future<bool> shouldPromptReview() async {
    if (!await InAppReview.instance.isAvailable()) return false;

    await Hive.initFlutter();
    final box = await Hive.openBox(ReviewPromptListener.boxKey);
    final didPromptReview = box.get(ReviewPromptListener.didPromptReviewKey, defaultValue: false);
    if (didPromptReview) return false;

    final installDate = box.get(ReviewPromptListener.installDateKey, defaultValue: DateTime.now());
    final launchCount = box.get(ReviewPromptListener.launchCountKey, defaultValue: 1);
    if (!box.containsKey(ReviewPromptListener.installDateKey)) {
      box.put(ReviewPromptListener.installDateKey, DateTime.now());
    }
    box.put(ReviewPromptListener.launchCountKey, launchCount + 1);
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    final shouldPromptReview = daysSinceInstall >= widget.minDaysSinceInstall && launchCount >= widget.minLaunchCount;
    if (shouldPromptReview) {
      box.put(ReviewPromptListener.didPromptReviewKey, true);
    }
    await Hive.close();

    return shouldPromptReview;
  }

  Future<void> reviewInApp() async {
    await InAppReview.instance.requestReview();
  }

  Future<void> openStoreListing() async {
    if (Platform.isIOS || Platform.isMacOS && widget.appStoreId == null) {
      throw ReviewPromptError(message: 'appStoreId is required to open store listing on iOS and MacOS');
    } else if (Platform.isWindows && widget.microsoftStoreId == null) {
      throw ReviewPromptError(message: 'microsoftStoreId is required to open store listing on Windows');
    }
    await InAppReview.instance.openStoreListing(
      appStoreId: widget.appStoreId,
      microsoftStoreId: widget.microsoftStoreId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
