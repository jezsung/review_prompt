part of 'review_prompt.dart';

class ReviewPromptError extends Error {
  final String message;

  ReviewPromptError({this.message});

  @override
  String toString() {
    if (message == null) {
      return 'ReviewPrompt Error';
    }
    return message;
  }
}
