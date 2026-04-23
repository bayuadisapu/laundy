import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class Sidebar extends StatelessWidget {
  final String activeLabel;
  final Function(String) onItemSelected;

  const Sidebar({
    super.key,
    required this.activeLabel,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SidebarContent(activeLabel: activeLabel, onItemSelected: onItemSelected);
  }
}

class _SidebarContent extends StatefulWidget {
  final String activeLabel;
  final Function(String) onItemSelected;

  const _SidebarContent({required this.activeLabel, required this.onItemSelected});

  @override
  State<_SidebarContent> createState() => _SidebarContentState();
}

class _SidebarContentState extends State<_SidebarContent> {
  bool _isLoggingOut = false;

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoggingOut = true);
      try {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logout: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              'Portal Staf',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 40),
          // Nav Items
          NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isActive: widget.activeLabel == 'Dashboard',
            onTap: () => widget.onItemSelected('Dashboard'),
          ),
          NavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Pesanan',
            isActive: widget.activeLabel == 'Pesanan',
            onTap: () => widget.onItemSelected('Pesanan'),
          ),
          NavItem(
            icon: Icons.qr_code_scanner,
            label: 'Scan Barcode',
            isActive: widget.activeLabel == 'Scan Barcode',
            onTap: () => widget.onItemSelected('Scan Barcode'),
          ),
          const SizedBox(height: 8),
          NavItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isActive: false,
            textColor: const Color(0xFFD32F2F),
            iconColor: const Color(0xFFD32F2F),
            onTap: _isLoggingOut ? () {} : _handleLogout,
            child: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F)),
                  )
                : null,
          ),
          const Spacer(),
          // Shift Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent, color: Color(0xFF1E88E5), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dukungan Siap',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                      ),
                      Text(
                        'Pemimpin Shift: Hendra',
                        style: TextStyle(fontSize: 10, color: Color(0xFF607D8B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? child;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.textColor,
    this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2962FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: iconColor != null
            ? Icon(icon, color: iconColor)
            : Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor ?? (isActive ? Colors.white : Colors.grey.shade600),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
