import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class AdminStaffPage extends StatefulWidget {
  final AppState appState;
  final Function(StaffData, String) onAddStaff;
  final Function(StaffData) onDeleteStaff;
  final Function(StaffData oldStaff, StaffData newStaff) onUpdateStaff;

  const AdminStaffPage({
    super.key,
    required this.appState,
    required this.onAddStaff,
    required this.onDeleteStaff,
    required this.onUpdateStaff,
  });

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddStaffSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tambah Staff Baru', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C3E))),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildFieldLabel('NAMA LENGKAP'),
                _buildTextInput(Icons.person_outline_rounded, 'Masukkan nama lengkap', controller: nameCtrl),
                const SizedBox(height: 20),

                _buildFieldLabel('USERNAME'),
                _buildTextInput(Icons.alternate_email_rounded, 'e.g. janesmith', controller: usernameCtrl),
                const SizedBox(height: 20),

                _buildFieldLabel('EMAIL'),
                _buildTextInput(Icons.email_outlined, 'jane@laundryku.com', controller: emailCtrl),
                const SizedBox(height: 20),

                _buildFieldLabel('PASSWORD AWAL'),
                _buildTextInput(Icons.lock_outline_rounded, '••••••••', controller: passwordCtrl, isPassword: true),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        _showError('Nama wajib diisi!');
                        return;
                      }
                      if (usernameCtrl.text.trim().isEmpty) {
                        _showError('Username wajib diisi!');
                        return;
                      }
                      if (emailCtrl.text.trim().isEmpty) {
                        _showError('Email wajib diisi!');
                        return;
                      }
                      if (passwordCtrl.text.trim().isEmpty) {
                        _showError('Password wajib diisi!');
                        return;
                      }

                      // Check duplicate username
                      final dupUser = widget.appState.staffList.any((s) => s.username.toLowerCase() == usernameCtrl.text.trim().toLowerCase());
                      if (dupUser) {
                        _showError('Username sudah digunakan!');
                        return;
                      }

                      final hash = nameCtrl.text.trim().hashCode.abs() % 100;
                      widget.onAddStaff(
                        StaffData(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          imgUrl: 'https://i.pravatar.cc/150?u=staff$hash',
                          isActive: true,
                        ),
                        passwordCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Staff "${nameCtrl.text.trim()}" berhasil ditambahkan!', style: GoogleFonts.inter()),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('Tambah Staff', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditStaffSheet(StaffData staff) {
    final nameCtrl = TextEditingController(text: staff.name);
    final emailCtrl = TextEditingController(text: staff.email);
    final usernameCtrl = TextEditingController(text: staff.username);
    bool isActive = staff.isActive;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Staff', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C3E))),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar preview
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(staff.imgUrl),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFieldLabel('NAMA LENGKAP'),
                  _buildTextInput(Icons.person_outline_rounded, 'Nama lengkap', controller: nameCtrl),
                  const SizedBox(height: 20),

                  _buildFieldLabel('USERNAME'),
                  _buildTextInput(Icons.alternate_email_rounded, 'Username', controller: usernameCtrl),
                  const SizedBox(height: 20),

                  _buildFieldLabel('EMAIL'),
                  _buildTextInput(Icons.email_outlined, 'Email', controller: emailCtrl),
                  const SizedBox(height: 20),

                  // Active status toggle
                  _buildFieldLabel('STATUS'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(isActive ? 'Aktif' : 'Tidak Aktif', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setModalState(() => isActive = v),
                          activeTrackColor: const Color(0xFF0D47A1),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          _showError('Nama wajib diisi!');
                          return;
                        }
                        if (emailCtrl.text.trim().isEmpty) {
                          _showError('Email wajib diisi!');
                          return;
                        }

                        widget.onUpdateStaff(staff, StaffData(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          imgUrl: staff.imgUrl,
                          isActive: isActive,
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Staff "${nameCtrl.text.trim()}" berhasil diupdate!', style: GoogleFonts.inter()),
                          backgroundColor: const Color(0xFF0D47A1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.all(16),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Simpan Perubahan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteStaff(StaffData staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Staff', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus staff "${staff.name}"?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDeleteStaff(staff);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Staff "${staff.name}" dihapus', style: GoogleFonts.inter()),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(16),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isPhone = screenWidth < 600;
    final staffList = widget.appState.staffList;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 20.0 : 32.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Staff',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E)),
                    ),
                    Text(
                      'Kelola dan pantau tim operasional Anda.',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 32),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'TOTAL STAFF',
                            value: '${widget.appState.totalStaff}',
                            color: const Color(0xFFF1F4F9),
                            textColor: const Color(0xFF1A1C3E),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            label: 'AKTIF SEKARANG',
                            value: '${widget.appState.activeStaff}',
                            color: const Color(0xFF0D47A1),
                            textColor: Colors.white,
                            showDot: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Staff List
                    if (staffList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Belum ada staff', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...staffList.map((staff) => _StaffCard(
                        staff: staff,
                        onEdit: () => _showEditStaffSheet(staff),
                        onDelete: () => _confirmDeleteStaff(staff),
                      )),

                    const SizedBox(height: 120),
                  ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin')),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LaundryKu', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1))),
                  Text('ADMIN PORTAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0D47A1), size: 24),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 22),
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showAddStaffSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF1A1C3E), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withAlpha(150), letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (showDot)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                ),
              Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildTextInput(IconData icon, String hint, {TextEditingController? controller, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}

// ==================== STAFF CARD ====================
class _StaffCard extends StatelessWidget {
  final StaffData staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({required this.staff, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage(staff.imgUrl)),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: staff.isActive ? const Color(0xFF4CAF50) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
                  Text(staff.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: staff.isActive ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      staff.isActive ? 'Aktif' : 'Tidak Aktif',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: staff.isActive ? const Color(0xFF2E7D32) : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF0D47A1), size: 22),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 22),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
