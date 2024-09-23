import 'package:flutter/material.dart';
import 'Transaction_Details/transactionhistory.dart'; // Make sure to import the TransactionHistoryPage


class AccountPage extends StatefulWidget {
  final String username;
  final int? userId;

  const AccountPage({super.key, required this.username, this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void _showTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: TransactionHistoryPage(
              username: widget.username, // Pass the username correctly
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.yellow, size: 25),
                  const SizedBox(width: 10),
                  const Text(
                    "Are You Sure?",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: const Text(
              "Once deleted, you won't be able to recover your account. Confirm to delete?",
            style: TextStyle(color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                // Add your account deletion logic here
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.green.shade700.withOpacity(0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomLeft,
            stops: [0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                
              ),
              CustomGradientDivider(),
              GestureDetector(
                onTap: _showTransactionModal, // Use function reference
                child: Container(
                  margin: const EdgeInsets.only(top: 20.0, left: 15, right: 15, bottom: 10),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E).withOpacity(0.8),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.currency_rupee, color: Colors.white70),
                      SizedBox(width: 20),
                      Text(
                        'Payment Details',
                        style: TextStyle(color: Colors.white70, fontSize: 17),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showDeleteAccount, // Use function reference
                child: Container(
                  margin: const EdgeInsets.only( left: 15, right: 15, bottom: 10),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E).withOpacity(0.8),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 20),
                      Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red, fontSize: 17),
                      ),
                      Spacer(),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      child: CustomPaint(
        painter: GradientPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.75),
          Color.fromRGBO(0, 128, 0, 0.75),
          Colors.green,
        ],
        end: Alignment.center,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.0)
      ..quadraticBezierTo(size.width / 3, 0, size.width, size.height * 0.99)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}