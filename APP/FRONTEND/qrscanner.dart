import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../pages/home.dart';

class QRViewExample extends StatefulWidget {
  final Function(String) handleSearchRequestCallback;
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
  bool _isDialogShown = false;

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
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, p),
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
        await widget.handleSearchRequestCallback(scanData.code!);
        if (!_isDisposed) {
          Navigator.of(context).pop(scanData.code);
        }
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p && !_isDialogShown) {
      _isDialogShown = true;
      CoolAlert.show(
        context: context,
        type: CoolAlertType.custom,
        widget: Column(
          children: [
            const SizedBox(height: 16.0),
            const Text(
              'Permission Denied',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'To Scan QR codes, allow this app access to your camera. Tap Settings > Permissions, and turn Camera on.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        confirmBtnText: 'Settings',
        cancelBtnText: 'Cancel',
        showCancelBtn: true,
        confirmBtnColor: Colors.blue,
        barrierDismissible: false, // This prevents closing by tapping outside
        onConfirmBtnTap: () {
          openAppSettings();
        },
        onCancelBtnTap: () {
          Navigator.of(context).pop(); // Close the alert
          if (!_isDisposed) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  username: widget.username,
                  userId: widget.userId,
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    controller?.dispose();
    super.dispose();
  }
}
