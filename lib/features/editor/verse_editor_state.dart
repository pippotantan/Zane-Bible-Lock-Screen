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
    this.fontFamily = 'Roboto', // default font family name from pubspec.yaml
  });

  VerseEditorState copyWith({
    double? fontSize,
    TextAlign? textAlign,
    Color? textColor,
    String? fontFamily,
  }) {
    return VerseEditorState(
      fontSize: fontSize ?? this.fontSize,
      textAlign: textAlign ?? this.textAlign,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
