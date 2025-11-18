import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final bool showBack;

  const CustomAppBar({
    super.key,
    required this.userName,
    this.showBack = false, // default: tidak tampilkan tombol back
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("Halo, ${userName ?? 'Pengguna'} 👋"),
      backgroundColor: const Color(0xFF0E8F6A),
      elevation: 0,
      automaticallyImplyLeading: showBack, // tampilkan hanya jika true
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
