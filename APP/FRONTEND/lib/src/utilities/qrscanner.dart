// import 'dart:io';
// import 'package:ev_app/src/pages/Auth/Forgot_password/forgot_password.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import '../../pages/home.dart';
//  // Import your LoadingOverlay class

// class QRViewExample extends StatefulWidget {
//   final Future<Map<String, dynamic>?> Function(String) handleSearchRequestCallback;
//   final String username;
//   final int? userId;

//   const QRViewExample({
//     Key? key,
//     required this.handleSearchRequestCallback,
//     required this.username,
//     this.userId,
//   }) : super(key: key);

//   @override
//   State<StatefulWidget> createState() => _QRViewExampleState();
// }

// class _QRViewExampleState extends State<QRViewExample> {
//   Barcode? result;
//   QRViewController? controller;
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   bool _isProcessing = false;
//   bool _isDisposed = false;
//   bool _showLoadingOverlay = false; // Loading state variable

//   @override
//   void initState() {
//     super.initState();
//     _checkCameraPermission();
//   }

//   // Function to check camera permission
//   Future<void> _checkCameraPermission() async {
//     PermissionStatus status = await Permission.camera.status;

//     if (status.isDenied) {
//       // Show custom dialog if permission is denied
//       _showCameraPermissionDialog();
//     }
//   }

//   // Function to show a custom dialog if permission is denied
//   void _showCameraPermissionDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color(0xFF1E1E1E),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           // ignore: prefer_const_constructors
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.camera_alt, color: Colors.blue, size: 35),
//                   SizedBox(width: 10),
//                   Text(
//                     "Permission Denied",
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//             ],
//           ),
//           content: const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'To scan QR codes, allow this app access to your camera. Tap Settings > Permissions, and turn Camera on.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.white70),
//               ),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                                 Navigator.of(context).pop();

//               },
//               child: const Text("Cancel", style: TextStyle(color: Colors.white)),
//             ),
//             TextButton(
//               onPressed: () {
//                 openAppSettings(); // Opens app settings to enable camera
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Settings", style: TextStyle(color: Colors.blue)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LoadingOverlay(
//       showAlertLoading: _showLoadingOverlay,
//       child: Scaffold(
//         body: Column(
//           children: <Widget>[
//             Expanded(flex: 4, child: _buildQrView(context)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQrView(BuildContext context) {
//     var scanArea = (MediaQuery.of(context).size.width < 500 ||
//             MediaQuery.of(context).size.height < 500)
//         ? 300.0
//         : 300.0;

//     return Stack(
//       children: [
//         QRView(
//           key: qrKey,
//           onQRViewCreated: _onQRViewCreated,
//           overlay: QrScannerOverlayShape(
//             borderColor: Colors.red,
//             borderRadius: 10,
//             borderLength: 30,
//             borderWidth: 10,
//             cutOutSize: scanArea,
//           ),
//         ),
//         Positioned(
//           top: 45,
//           left: 10,
//           child: IconButton(
//             icon: const Icon(Icons.close, color: Colors.white, size: 35),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => HomePage(
//                     username: widget.username,
//                     userId: widget.userId,
//                     email: '',
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         Positioned(
//           top: 45,
//           right: 10,
//           child: FutureBuilder(
//             future: controller?.getFlashStatus(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const CircularProgressIndicator();
//               } else {
//                 bool isFlashOn = snapshot.data == true;
//                 return IconButton(
//                   icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off,
//                       color: Colors.white, size: 35),
//                   onPressed: () async {
//                     if (!_isDisposed) {
//                       await controller?.toggleFlash();
//                       setState(() {});
//                     }
//                   },
//                 );
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });

//     controller.scannedDataStream.listen((scanData) async {
//       if (!_isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
//         setState(() {
//           _isProcessing = true;
//           _showLoadingOverlay = true; // Show loading overlay
//         });
//         controller.pauseCamera();

//         // Call the callback and await the result
//         final response = await widget.handleSearchRequestCallback(scanData.code!);
//         print("response: $response");
//         print(scanData.code);

//         setState(() {
//           _isProcessing = false;
//           _showLoadingOverlay = false; // Hide loading overlay
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     controller?.dispose();
//     super.dispose();
//   }
// }
