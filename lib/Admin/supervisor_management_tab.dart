
import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

class SupervisorManagementTab extends StatelessWidget {
  const SupervisorManagementTab({super.key});

  static const _bg = Color(0xFFF6F7FA);

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---- small helper: consistent text field design ----
  InputDecoration _dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'ClashGrotesk',
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF6B7280), size: 20),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7F53FD), width: 1.2),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cnicCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool saving = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogCtx) {
        Future<void> save() async {
          final name = nameCtrl.text.trim();
          final email = emailCtrl.text.trim();
          final cnic = cnicCtrl.text.trim();
          final city = cityCtrl.text.trim();
          final pass = passCtrl.text;
          final conf = confirmCtrl.text;

          if (name.isEmpty || email.isEmpty || cnic.isEmpty || city.isEmpty || pass.isEmpty) {
            error = 'Please fill all fields';
            (dialogCtx as Element).markNeedsBuild();
            return;
          }
          if (pass != conf) {
            error = 'Password and confirm password must match';
            (dialogCtx as Element).markNeedsBuild();
            return;
          }

          saving = true;
          error = null;
          (dialogCtx as Element).markNeedsBuild();

          try {
            await FbSupervisorRepo.createSupervisor(
              name: name,
              email: email,
              cnic: cnic,
              city: city,
              password: pass,
            );
            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
          } catch (e) {
            error = e.toString();
            saving = false;
            if (dialogCtx is Element) {
              // ignore: invalid_use_of_protected_member
              dialogCtx.markNeedsBuild();
            }
          }
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Gradient header (like your design language)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: const BoxDecoration(gradient: _grad),
                  child: Row(
                    children: const [
                      Icon(Icons.supervisor_account_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add Supervisor',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: _dec('Name', icon: Icons.person_outline),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec('Email', icon: Icons.email_outlined),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cnicCtrl,
                          decoration: _dec('CNIC', icon: Icons.badge_outlined),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cityCtrl,
                          decoration: _dec('City', icon: Icons.location_city_outlined),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: _dec('Password', icon: Icons.lock_outline),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmCtrl,
                          obscureText: true,
                          decoration: _dec('Confirm Password', icon: Icons.lock_reset_outlined),
                        ),

                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFC2C7)),
                            ),
                            child: Text(
                              error!,
                              style: const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB42318),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ✅ Actions (clean buttons)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.of(dialogCtx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: saving ? null : save,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: saving ? null : _grad,
                              color: saving ? const Color(0xFFE5E7EB) : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Create',
                                      style: TextStyle(
                                        fontFamily: 'ClashGrotesk',
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _grad,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Confirm Delete',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      await onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<List<FbSupervisorProfile>>(
        stream: FbSupervisorRepo.watchSupervisors(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          final list = snap.data ?? const <FbSupervisorProfile>[];

          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No supervisors yet. Tap + to add.',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 120 * s + padBottom),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: 12 * s),
            itemBuilder: (_, i) {
              final sup = list[i];
              final title = sup.name.isEmpty ? sup.email : sup.name;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14 * s),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // left gradient spine
                    Container(
                      width: 9 * s,
                      height: 92 * s,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 12 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                fontSize: 15 * s,
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            _InfoRow(s: s, icon: Icons.email_outlined, text: sup.email),
                            SizedBox(height: 6 * s),
                            _InfoRow(
                              s: s,
                              icon: Icons.badge_outlined,
                              text: 'CNIC: ${sup.cnic}',
                            ),
                            SizedBox(height: 6 * s),
                            _InfoRow(
                              s: s,
                              icon: Icons.location_city_outlined,
                              text: 'City: ${sup.city}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 6 * s, right: 8 * s),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                        onPressed: () async {
                          await _confirmDelete(
                            context,
                            title: 'Delete supervisor?',
                            message:
                                'Delete "${sup.name.isEmpty ? sup.email : sup.name}"?\n\nNote: This deletes only Firestore profile.',
                            onDelete: () => FbSupervisorRepo.deleteSupervisor(sup.uid),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // ✅ Floating button styled like your gradient UI
      floatingActionButton: InkWell(
        onTap: () => _openAddDialog(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final double s;
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.s,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16 * s, color: const Color(0xFF6B7280)),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              fontSize: 12.8 * s,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
