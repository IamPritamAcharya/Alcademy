class EditorState {
  final String title;
  final String content;
  final int titleCursorPosition;
  final int contentCursorPosition;

  EditorState({
    required this.title,
    required this.content,
    required this.titleCursorPosition,
    required this.contentCursorPosition,
  });

  EditorState copy() {
    return EditorState(
      title: title,
      content: content,
      titleCursorPosition: titleCursorPosition,
      contentCursorPosition: contentCursorPosition,
    );
  }
}
