import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String messageText;

  const LoadingDialog({super.key, required this.messageText});

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.black87,
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.04), // Responsive margin (4% of screen width)
        width: screenWidth * 0.8, // 80% of the screen width
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // Responsive border radius
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding (4% of screen width)
          child: Row(
            children: [
              SizedBox(width: screenWidth * 0.02), // Responsive spacing

              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: screenWidth * 0.02, // Responsive size for CircularProgressIndicator
              ),

              SizedBox(width: screenWidth * 0.04), // Responsive spacing

              // Make sure the text wraps and has responsive size
              Flexible(
                child: Text(
                  messageText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04, // Responsive font size (4% of screen width)
                    color: Colors.white,
                  ),
                  maxLines: 2, // Optional: limit to 2 lines
                  overflow: TextOverflow.ellipsis, // Optional: add ellipsis if text overflows
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
