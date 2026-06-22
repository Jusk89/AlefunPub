import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(isOwner: true);
  }
}
