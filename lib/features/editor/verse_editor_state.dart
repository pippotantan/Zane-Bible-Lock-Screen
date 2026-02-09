import 'package:flutter/material.dart';

class VerseEditorState {
  double fontSize;
  TextAlign textAlign;
  Color textColor;
  String fontFamily;

  VerseEditorState({
    this.fontSize = 22,
    this.textAlign = TextAlign.center,
    this.textColor = Colors.white,
    this.fontFamily = 'sans',
  });
}