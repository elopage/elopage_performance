import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ValueCard extends StatelessWidget {
  const ValueCard({
    Key? key,
    required this.value,
    required this.title,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  final String value;
  final String title;
  final bool isLoading;
  final VoidCallback? onTap;

  TextStyle get valueStyle => GoogleFonts.lato(fontSize: 36, fontWeight: FontWeight.w700);
  TextStyle get titleStyle => GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 1.5,
          child: Container(
            constraints: const BoxConstraints(minWidth: 175, maxWidth: 300),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(value, style: valueStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      Text(title, style: titleStyle),
                    ],
                  ),
          ),
        ),
      );
}
