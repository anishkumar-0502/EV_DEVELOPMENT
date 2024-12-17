import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.green.shade700.withOpacity(0)],
            begin: Alignment.topCenter,  // Start gradient from the top center
            end: Alignment.bottomLeft,  // End gradient towards the bottom left
            stops: [0.4, 1.0],          // Black at 40% and green at 100%
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
                      "Hello 👋",
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Please review our Privacy Policy before continuing.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20.0, left: 15, right: 15, bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E).withOpacity(0.8),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                  child: const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Privacy Policy",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Last updated: 16 December 2024",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "We value your privacy and are committed to protecting your personal data. This Privacy Policy outlines how we collect, use, and protect your information when you use our EV charging mobile application.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "1. Information We Collect",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Personal Information: When you register an account, we collect your mobile number and email address.\n\nUser Credentials: We encrypt your password and store it securely in our database.\n\nPayment Information: We do not store or process sensitive payment information (e.g., credit card numbers, UPI IDs). All payment transactions are securely processed through Razorpay.\n\nLocation Information: We do not collect or store location data. The App uses Google Maps APIs solely to help you find nearby EV chargers.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "2. How We Use Your Data",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We use your mobile number and email address for account creation, login, and password recovery purposes.\n\nNo promotional emails or marketing messages will be sent to you, except for essential notifications like password reset emails.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "3. Data Security",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We take reasonable measures to protect your personal data from unauthorized access or disclosure. Passwords are stored using encryption, and access to personal information is restricted to authorized personnel only.\n\nWe recommend that you do not jailbreak or root your device, as it may compromise security and interfere with the App's functionality.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "4. Third-Party Services",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "The App integrates Razorpay for payment processing. Razorpay handles all sensitive payment data, and you are bound by their privacy policy when making payments through the App.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "5. Data Retention",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We retain your personal data as long as your account is active. If you wish to delete your account, you can contact our support team, and your data will be permanently deleted.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "6. User Rights",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "You have the right to access, update, or delete your account information at any time. Contact us at [Support Email Address] for assistance with any data-related requests.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "7. Changes to This Privacy Policy",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We may update this Privacy Policy from time to time. Any changes will be posted on this page, and your continued use of the App will signify your acceptance of the updated terms.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "8. Account Deletion",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "To delete your account, you can either click the \"Delete Account\" option within the app or send an email to info@outdidunified.com. Your account will be permanently deleted upon email confirmation, and all your data will be permanently removed.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
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
