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
    this.listenAlways = false,
    @required this.listener,
    @required this.child,
  })  : assert(minDaysSinceInstall != null || minDaysSinceInstall > 0),
        assert(minLaunchCount != null || minLaunchCount > 0),
        assert(listenAlways != null),
        assert(listener != null),
        assert(child != null),
        super(key: key);

  /// Minimum days since the install date to call [listener].
  final int minDaysSinceInstall;

  /// Minium launch count to call [listener].
  final int minLaunchCount;

  /// App Store ID is required to open store listing on iOS and MacOS.
  final String appStoreId;

  /// Microsoft ID is required to open store listing on Windows.
  final String microsoftStoreId;

  /// Always call [listener] if true regardless of conditions, set true for development.
  /// [listener] will not be called if the device is unable to use in-app review even if [listenAlways] is set to true.
  final bool listenAlways;

  /// [listener] will be called when the app start if conditions are met.
  /// [listener] never gets called more than once.
  final ReviewPromptWidgetListener listener;
  final Widget child;

  /// review_prompt uses Hive under the hood to store condition data.
  /// Keep in mind that these key values are reserved for this package and avoid the same values
  /// if you are using Hive.
  static const _boxKey = 'review_prompt';
  static const _installDateKey = 'install_date';
  static const _launchCountKey = 'launch_count';
  static const _didPromptReviewKey = 'did_prompt_review';

  @override
  _ReviewPromptListenerState createState() => _ReviewPromptListenerState();
}

class _ReviewPromptListenerState extends State<ReviewPromptListener> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await _shouldPromptReview()) {
        widget.listener(context, _reviewInApp, _openStoreListing);
      }
    });
  }

  Future<bool> _shouldPromptReview() async {
    if (!await InAppReview.instance.isAvailable()) return false;
    if (widget.listenAlways) return true;

    await Hive.initFlutter();
    final box = await Hive.openBox(ReviewPromptListener._boxKey);
    final didPromptReview = box.get(ReviewPromptListener._didPromptReviewKey, defaultValue: false);
    if (didPromptReview) return false;

    final installDate = box.get(ReviewPromptListener._installDateKey, defaultValue: DateTime.now());
    final launchCount = box.get(ReviewPromptListener._launchCountKey, defaultValue: 1);
    if (!box.containsKey(ReviewPromptListener._installDateKey)) {
      box.put(ReviewPromptListener._installDateKey, DateTime.now());
    }
    box.put(ReviewPromptListener._launchCountKey, launchCount + 1);
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    final shouldPromptReview = daysSinceInstall >= widget.minDaysSinceInstall && launchCount >= widget.minLaunchCount;
    if (shouldPromptReview) {
      box.put(ReviewPromptListener._didPromptReviewKey, true);
    }
    await Hive.close();

    return shouldPromptReview;
  }

  Future<void> _reviewInApp() async {
    await InAppReview.instance.requestReview();
  }

  Future<void> _openStoreListing() async {
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
