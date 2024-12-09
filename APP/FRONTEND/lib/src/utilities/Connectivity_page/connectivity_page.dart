
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class InternetErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fetch screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No Internet Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wifi,
                    size: screenWidth * 0.30, // Adjust size dynamically
                    color: Colors.blueGrey,
                  ),
                  Icon(
                    Icons.close,
                    size: screenWidth * 0.17, // Adjust size dynamically
                    color: Colors.red,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05), // Adjust spacing
              // Title
              Text(
                "Ooops!",
                style: TextStyle(
                  fontSize: screenWidth * 0.07, // Adjust font size dynamically
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  "It seems you are offline. Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              // Retry Button
              ElevatedButton(
                onPressed: () async {
                  // Check the internet connection status
                  var connectivityResult = await Connectivity().checkConnectivity();

                  if (connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi) {
                    // Internet is available, close the page
                    Navigator.of(context).pop(); // Close the current page
                  } else {
                    // Internet is still not available, retry the connection check
                    _showRetryMessage(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1, // Adjust padding dynamically
                    vertical: screenHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Try Again",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Close App Button
              TextButton(
                onPressed: () {
                  // Close the app (pop the current page)
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Back to App",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
void _showRetryMessage(BuildContext context) {
  // Dismiss any existing snack bars before showing a new one
  ScaffoldMessenger.of(context).clearSnackBars();
  
  // Show the new retry message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No internet connection. Please try again later.'),
      duration: Duration(seconds: 2),
    ),
  );
}

}
