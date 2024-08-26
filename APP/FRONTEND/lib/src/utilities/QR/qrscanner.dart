import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; // Import the permission handler
import '../../pages/home.dart'; // Import your HomeContent widget

class QRViewExample extends StatefulWidget {
  final Function(String) handleSearchRequestCallback;
  final String username;
  final int? userId;

  const QRViewExample({Key? key, required this.handleSearchRequestCallback, required this.username, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isProcessing = false;
  bool _isDisposed = false; // Flag to track if the controller is disposed
  bool _isDialogShown = false; // Flag to track if the permission dialog has been shown

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
    var scanArea = (MediaQuery.of(context).size.width < 500 || MediaQuery.of(context).size.height < 500)
        ? 300.0
        : 300.0;

    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.green,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
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
                    username: widget.username, // Pass your actual username here
                    userId: widget.userId, // Pass your actual userId here
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
                  icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 35),
                  onPressed: () async {
                    if (!_isDisposed) { // Check if not disposed
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
        await widget.handleSearchRequestCallback(scanData.code!);
        if (!_isDisposed) { // Check if not disposed
          Navigator.of(context).pop(scanData.code);
        }
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p && !_isDialogShown) { // Check if permission is denied and the dialog has not been shown yet
      _isDialogShown = true; // Set the flag to true to prevent multiple dialogs
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside the dialog
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text('Camera permission is required to scan QR codes.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  if (!_isDisposed) { // Check if not disposed
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          username: widget.username, // Pass your actual username here
                          userId: widget.userId, // Pass your actual userId here
                        ),
                      ),
                    );
                  }
                },
              ),
              TextButton(
                child: const Text('Settings'),
                onPressed: () {
                  openAppSettings(); // Navigate to the phone's application settings
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Set the disposed flag
    controller?.dispose();
    super.dispose();
  }
}
