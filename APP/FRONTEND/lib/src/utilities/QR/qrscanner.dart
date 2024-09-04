import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../pages/home.dart';

class QRViewExample extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function(String) handleSearchRequestCallback;
  final String username;
  final int? userId;

  const QRViewExample({
    Key? key,
    required this.handleSearchRequestCallback,
    required this.username,
    this.userId,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isProcessing = false;
  bool _isDisposed = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 500 ||
            MediaQuery.of(context).size.height < 500)
        ? 300.0
        : 300.0;

    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
        ),
        Positioned(
          top: 45,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 35),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    username: widget.username,
                    userId: widget.userId,
                    email: '',
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 45,
          right: 10,
          child: FutureBuilder(
            future: controller?.getFlashStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                bool isFlashOn = snapshot.data == true;
                return IconButton(
                  icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white, size: 35),
                  onPressed: () async {
                    if (!_isDisposed) {
                      await controller?.toggleFlash();
                      setState(() {});
                    }
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
void _onQRViewCreated(QRViewController controller) {
  setState(() {
    this.controller = controller;
  });

  controller.scannedDataStream.listen((scanData) async {
    if (!_isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });
      controller.pauseCamera();

      // Call the callback and await the result
      final response = await widget.handleSearchRequestCallback(scanData.code!);
      print("response: $response  ");
      print(scanData.code );
    

      setState(() {
        _isProcessing = false;
      });
    }
  });
}


  @override
  void dispose() {
    _isDisposed = true;
    controller?.dispose();
    super.dispose();
  }
}
