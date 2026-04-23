import 'package:flutter/material.dart';

import 'sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String activeLabel;
  final Function(String) onItemSelected;

  const MainLayout({
    super.key,
    required this.child,
    required this.activeLabel,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF1E88E5)),
              title: Text(
                'LaundryKu',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF1E88E5),
                ),
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                activeLabel: activeLabel,
                onItemSelected: onItemSelected,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              activeLabel: activeLabel,
              onItemSelected: onItemSelected,
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

