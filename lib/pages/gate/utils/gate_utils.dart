import 'package:flutter/material.dart';

IconData getGateIconData(String name) {
  switch (name) {
    case 'history_edu_rounded':
      return Icons.history_edu_rounded;
    case 'school_rounded':
      return Icons.school_rounded;
    case 'quiz_rounded':
      return Icons.quiz_rounded;
    case 'picture_as_pdf_rounded':
      return Icons.picture_as_pdf_rounded;
    case 'menu_book_rounded':
      return Icons.menu_book_rounded;
    case 'auto_stories_rounded':
      return Icons.auto_stories_rounded;
    case 'computer_rounded':
      return Icons.computer_rounded;
    case 'question_answer_rounded':
      return Icons.question_answer_rounded;
    case 'functions_rounded':
      return Icons.functions_rounded;
    case 'play_circle_rounded':
      return Icons.play_circle_rounded;
    case 'smart_display_rounded':
      return Icons.smart_display_rounded;
    case 'ondemand_video_rounded':
      return Icons.ondemand_video_rounded;
    case 'video_library_rounded':
      return Icons.video_library_rounded;
    case 'timer_rounded':
      return Icons.timer_rounded;
    case 'calculate_rounded':
      return Icons.calculate_rounded;
    case 'assignment_rounded':
      return Icons.assignment_rounded;
    case 'list_alt_rounded':
      return Icons.list_alt_rounded;
    default:
      return Icons.description_rounded;
  }
}
