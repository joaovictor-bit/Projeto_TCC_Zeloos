import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  static String format(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == (digits.length == 11 ? 7 : 6)) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static bool isValid(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty || digits.length >= 10;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
