// lib/ui/admin/customer_qr_panel.dart
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// 웹에서 qr_flutter [QrImageView]가 비는 경우가 있어 CustomPaint로 직접 그립니다.
class CustomerQrPanel extends StatelessWidget {
  const CustomerQrPanel({
    super.key,
    required this.data,
    this.size = 200,
  });

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _QrPainter(data),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.data)
      : _image = QrImage(
          QrCode.fromData(
            data: data,
            errorCorrectLevel: QrErrorCorrectLevel.M,
          ),
        );

  final String data;
  final QrImage _image;

  @override
  void paint(Canvas canvas, Size size) {
    final module = size.width / _image.moduleCount;
    final on = Paint()..color = Colors.black;
    final off = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, off);
    for (var row = 0; row < _image.moduleCount; row++) {
      for (var col = 0; col < _image.moduleCount; col++) {
        if (_image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * module, row * module, module, module),
            on,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.data != data;
}
