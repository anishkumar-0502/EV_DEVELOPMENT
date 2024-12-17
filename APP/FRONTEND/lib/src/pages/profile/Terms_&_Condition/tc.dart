import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Applying BoxDecoration to the Container
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
                  "Before you create an account, please read and accept our Terms & Conditions",
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
                            "Terms & Conditions",
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
                            "1. Service Overview",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "The App provides a platform for users to locate and charge their electric vehicles at designated stations. Payment for charging services is facilitated through Razorpay, an integrated payment gateway.\n\nBy using the App, you agree to comply with these terms and any local regulations governing EV charging.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "2. User Account Responsibilities",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "You are required to create an account to use the App. Your account must be linked to a valid mobile number and email address.\n\nYou are responsible for maintaining the security of your account by using a strong password. Any unauthorized use of your account should be reported to our support team immediately.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "3. Payment Processing",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "All payments are processed by Razorpay. We do not store or handle any sensitive payment data, such as credit card numbers or UPI IDs. Razorpay’s terms and conditions govern all payment-related activities, and you are responsible for any issues arising from payment disputes.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "4. App Permissions",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "The App requires certain device permissions, such as access to location services to help you find nearby chargers and camera access to scan QR codes at the charging stations. By granting these permissions, you acknowledge that the App can function correctly.\n\nWe do not collect location data; it is used solely to facilitate the location of charging stations via Google Maps APIs.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "5. App Updates and Modifications",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We reserve the right to modify or update the App at any time to improve its functionality, fix bugs, or introduce new features. It is your responsibility to keep the App updated to ensure it works as intended.\n\nWe may choose to discontinue the App without prior notice. Upon termination of service, your rights to use the App will end, and any related licenses will be revoked.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "6. Liability Disclaimer",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "While we strive to provide accurate information and reliable functionality, the App may sometimes rely on third-party services (e.g., Razorpay, Google Maps) for certain features. We are not responsible for any losses or damages caused by service interruptions, incorrect data, or reliance on third-party services.\n\nUsers are responsible for ensuring their devices are charged and functional. We are not liable for any issues caused by your device being offline or out of battery during a charging session.",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "7. Changes to These Terms",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We may update these Terms of Service from time to time. Continued use of the App after changes have been made indicates acceptance of the updated terms.",
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
