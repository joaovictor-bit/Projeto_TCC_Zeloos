import 'package:flutter/services.dart';
import 'package:flutter_app/utils/phone_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneInputFormatter.format', () {
    test('retorna vazio para texto vazio', () {
      expect(PhoneInputFormatter.format(''), '');
    });

    test('formata celular com 11 dígitos', () {
      expect(PhoneInputFormatter.format('11987654321'), '(11) 98765-4321');
    });

    test('formata telefone fixo com 10 dígitos', () {
      expect(PhoneInputFormatter.format('1134567890'), '(11) 3456-7890');
    });

    test('formata progressivamente enquanto o usuário digita', () {
      expect(PhoneInputFormatter.format('1'), '(1');
      expect(PhoneInputFormatter.format('11'), '(11');
      expect(PhoneInputFormatter.format('119'), '(11) 9');
      expect(PhoneInputFormatter.format('1198765'), '(11) 9876-5');
    });

    test('remove caracteres não numéricos', () {
      expect(PhoneInputFormatter.format('(11) 98765-4321'), '(11) 98765-4321');
      expect(PhoneInputFormatter.format('11a98b76c54d321'), '(11) 98765-4321');
    });

    test('limita a 11 dígitos', () {
      expect(PhoneInputFormatter.format('119876543210000'), '(11) 98765-4321');
    });
  });

  group('PhoneInputFormatter.isValid', () {
    test('aceita vazio (campo opcional)', () {
      expect(PhoneInputFormatter.isValid(''), isTrue);
    });

    test('aceita 10 ou 11 dígitos', () {
      expect(PhoneInputFormatter.isValid('(11) 3456-7890'), isTrue);
      expect(PhoneInputFormatter.isValid('(11) 98765-4321'), isTrue);
    });

    test('rejeita números incompletos', () {
      expect(PhoneInputFormatter.isValid('(11) 9876'), isFalse);
      expect(PhoneInputFormatter.isValid('123'), isFalse);
    });
  });

  group('PhoneInputFormatter.formatEditUpdate', () {
    test('aplica a máscara e posiciona o cursor no final', () {
      final result = PhoneInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11987654321'),
      );

      expect(result.text, '(11) 98765-4321');
      expect(result.selection, const TextSelection.collapsed(offset: 15));
    });
  });
}
