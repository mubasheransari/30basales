import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

class SupervisorManagementTab extends StatelessWidget {
  const SupervisorManagementTab({super.key});

  static const _bg = Color(0xFFF6F7FA);
  static const _txtDark = Color(0xFF0F172A);
  static const _txtDim = Color(0xFF64748B);

  /// ✅ Same gradient you want
  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ========================== Common Shell ==========================
  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // ========================== Input Deco (Base) ==========================
  InputDecoration _fieldDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'ClashGrotesk',
        fontWeight: FontWeight.w800,
        color: _txtDim,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  // ========================== Gradient Prefix Icon ==========================
  Widget _gradPrefix(IconData icon) {
    return Container(
      height: 36,
      width: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  InputDecoration _fieldDecoGrad(
    String label, {
    required IconData icon,
    String? errorText,
  }) {
    return _fieldDeco(label).copyWith(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: _gradPrefix(icon),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      errorText: errorText,
    );
  }

  // ========================== Small UI helpers ==========================
  Widget _gradIconBox(double s, IconData icon) {
    return Container(
      height: 40 * s,
      width: 40 * s,
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(14 * s),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18 * s),
    );
  }

  Widget _chip(double s, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * s, color: _txtDim),
          SizedBox(width: 6 * s),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11.2 * s,
              fontWeight: FontWeight.w800,
              color: _txtDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryGradButton({
    required String text,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48, // ✅ ensures visible height inside Row/Expanded
          decoration: BoxDecoration(
            gradient: loading ? null : _grad,
            color: loading ? const Color(0xFFE5E7EB) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /*

  // ========================== Primary Gradient Button ==========================
  Widget _primaryGradButton({
    required String text,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: loading ? null : _grad,
          color: loading ? const Color(0xFFE5E7EB) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }*/

  Future<void> _openAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cnicCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool saving = false;
        String? error;

        final formKey = GlobalKey<FormState>();

        String? reqV(String? v, {String label = 'This field'}) {
          if ((v ?? '').trim().isEmpty) return '$label is required';
          return null;
        }

        String? emailV(String? v) {
          final s = (v ?? '').trim();
          if (s.isEmpty) return 'Email is required';
          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
          if (!ok) return 'Enter a valid email';
          return null;
        }

        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> save() async {
              FocusScope.of(ctx).unfocus();

              final ok = formKey.currentState?.validate() ?? false;
              if (!ok) return;

              final pass = passCtrl.text;
              final conf = confirmCtrl.text;

              if (pass != conf) {
                setState(
                  () => error = 'Password and confirm password must match',
                );
                return;
              }

              setState(() {
                saving = true;
                error = null;
              });

              try {
                await FbSupervisorRepo.createSupervisor(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  cnic: cnicCtrl.text.trim(),
                  city: cityCtrl.text.trim(), // ✅ city picked from picker
                  password: pass,
                );

                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
              } catch (e) {
                setState(() {
                  error = e.toString();
                  saving = false;
                });
              } finally {
                if (ctx.mounted) setState(() => saving = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              child: _cardShell(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: _grad,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.supervisor_account_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add Supervisor',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Name',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) => reqV(v, label: 'Name'),
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Email',
                            icon: Icons.email_outlined,
                          ),
                          validator: emailV,
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: cnicCtrl,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'CNIC',
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) => reqV(v, label: 'CNIC'),
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        // ✅ CITY PICKER (same pattern as LocationManagementTab)
                        Stack(
                          children: [
                            _CityPickerField(
                              controller: cityCtrl,
                              enabled: !saving,
                              onPick: () async {
                                final picked = await _openPakistanCityPicker(
                                  ctx,
                                  initial: cityCtrl.text.trim(),
                                );

                                if (picked != null && picked.isNotEmpty) {
                                  setState(() => cityCtrl.text = picked);
                                  formKey.currentState
                                      ?.validate(); // ✅ refresh validation
                                }
                              },
                              decoration: _fieldDecoGrad(
                                'City',
                                icon: Icons.location_city_outlined,
                              ),
                            ),

                            // ✅ hidden validator so form validation works
                            Opacity(
                              opacity: 0,
                              child: SizedBox(
                                height: 0,
                                child: TextFormField(
                                  controller: cityCtrl,
                                  validator: (v) => reqV(v, label: 'City'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Password',
                            icon: Icons.lock_outline,
                          ),
                          validator: (v) => reqV(v, label: 'Password'),
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: confirmCtrl,
                          obscureText: true,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Confirm Password',
                            icon: Icons.lock_reset_outlined,
                          ),
                          validator: (v) => reqV(v, label: 'Confirm Password'),
                          textInputAction: TextInputAction.done,
                          enabled: !saving,
                        ),

                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFC2C7),
                              ),
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

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.of(dialogCtx).pop(),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
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
                              child: _primaryGradButton(
                                text: 'Create',
                                loading: saving,
                                onPressed: saving ? null : save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
   // required String message,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: _cardShell(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: _grad,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Delete',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: _txtDark,
                ),
              ),
              const SizedBox(height: 6),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

    if (ok == true) await onDelete();
  }

  // ========================== Build ==========================
  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<List<FbSupervisorProfile>>(
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

            return RefreshIndicator(
              onRefresh: () async =>
                  Future<void>.delayed(const Duration(milliseconds: 250)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16 * s,
                  12 * s,
                  16 * s,
                  24 * s + padBottom + 90 * s,
                ),
                children: [
                  // Top summary card (same as Location tab style)
                  _cardShell(
                    padding: EdgeInsets.all(14 * s),
                    child: Row(
                      children: [
                        _gradIconBox(s, Icons.supervisor_account_rounded),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supervisors',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w900,
                                  color: _txtDark,
                                ),
                              ),
                              SizedBox(height: 4 * s),
                              Text(
                                'Manage supervisor profiles (name, email, CNIC, city).',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  fontSize: 12.2 * s,
                                  fontWeight: FontWeight.w700,
                                  color: _txtDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * s,
                            vertical: 7 * s,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            '${list.length} total',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontSize: 11.4 * s,
                              fontWeight: FontWeight.w900,
                              color: _txtDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14 * s),

                  if (list.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 120 * s),
                        child: Text(
                          'No supervisors yet. Tap + to add.',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 13.5 * s,
                            fontWeight: FontWeight.w800,
                            color: _txtDim,
                          ),
                        ),
                      ),
                    )
                  else
                    ...list.map((sup) {
                      final title = sup.name.trim().isEmpty
                          ? sup.email
                          : sup.name;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12 * s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18 * s),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(14 * s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _gradIconBox(s, Icons.person_outline),
                                    SizedBox(width: 10 * s),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'ClashGrotesk',
                                          fontSize: 15.2 * s,
                                          fontWeight: FontWeight.w900,
                                          color: _txtDark,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10 * s),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(
                                        14 * s,
                                      ),
                                      onTap: () async {
                                        await _confirmDelete(
                                          context,
                                          title:      'Delete "${sup.name.isEmpty ? sup.email : sup.name}"?', //'Delete supervisor?',
                                          // message:
                                          //     'Delete "${sup.name.isEmpty ? sup.email : sup.name}"?',
                                          onDelete: () =>
                                              FbSupervisorRepo.deleteSupervisor(
                                                sup.uid,
                                              ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(10 * s),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(
                                            14 * s,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFECACA),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18 * s,
                                          color: const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12 * s),

                                Wrap(
                                  spacing: 8 * s,
                                  runSpacing: 8 * s,
                                  children: [
                                    _chip(s, Icons.email_outlined, sup.email),
                                    _chip(
                                      s,
                                      Icons.badge_outlined,
                                      'CNIC: ${sup.cnic}',
                                    ),
                                    _chip(
                                      s,
                                      Icons.location_city_outlined,
                                      'City: ${sup.city}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),

      // FAB (same action, modern gradient)
      floatingActionButton: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAddDialog(context),
        child: Container(
          height: 56,
          width: 56,
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
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _CityPickerField extends StatelessWidget {
  const _CityPickerField({
    required this.controller,
    required this.onPick,
    required this.decoration,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onPick;
  final InputDecoration decoration;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPick : null,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          enabled: enabled,
          readOnly: true,
          decoration: decoration.copyWith(
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          style: const TextStyle(fontFamily: 'ClashGrotesk'),
        ),
      ),
    );
  }
}

Future<String?> _openPakistanCityPicker(
  BuildContext context, {
  String? initial,
}) async {
  // ✅ Pinned on top
  const pinned = ['Karachi', 'Lahore', 'Islamabad'];

  const allCitiesRaw = <String>[
    'Karachi',
    'Lahore',
    'Islamabad',
    'Ahmed Nager',
    'Ahmadpur East',
    'Ali Khan',
    'Alipur',
    'Arifwala',
    'Attock',
    'Bhera',
    'Bhalwal',
    'Bahawalnagar',
    'Bahawalpur',
    'Bhakkar',
    'Burewala',
    'Chillianwala',
    'Chakwal',
    'Chichawatni',
    'Chiniot',
    'Chishtian',
    'Daska',
    'Darya Khan',
    'Dera Ghazi',
    'Dhaular',
    'Dina',
    'Dinga',
    'Dipalpur',
    'Faisalabad',
    'Fateh Jhang',
    'Ghakhar Mandi',
    'Gojra',
    'Gujranwala',
    'Gujrat',
    'Gujar Khan',
    'Hafizabad',
    'Haroonabad',
    'Hasilpur',
    'Haveli',
    'Lakha',
    'Jalalpur',
    'Jattan',
    'Jampur',
    'Jaranwala',
    'Jhang',
    'Jhelum',
    'Kalabagh',
    'Karor Lal',
    'Kasur',
    'Kamalia',
    'Kamoke',
    'Khanewal',
    'Khanpur',
    'Kharian',
    'Khushab',
    'Kot Adu',
    'Jauharabad',
    'Lalamusa',
    'Layyah',
    'Liaquat Pur',
    'Lodhran',
    'Malakwal',
    'Mamoori',
    'Mailsi',
    'Mandi Bahauddin',
    'mian Channu',
    'Mianwali',
    'Multan',
    'Murree',
    'Muridke',
    'Mianwali Bangla',
    'Muzaffargarh',
    'Narowal',
    'Okara',
    'Renala Khurd',
    'Pakpattan',
    'Pattoki',
    'Pir Mahal',
    'Qaimpur',
    'Qila Didar',
    'Rabwah',
    'Raiwind',
    'Rajanpur',
    'Rahim Yar',
    'Rawalpindi',
    'Sadiqabad',
    'Safdarabad',
    'Sahiwal',
    'Sangla Hill',
    'Sarai Alamgir',
    'Sargodha',
    'Shakargarh',
    'Sheikhupura',
    'Sialkot',
    'Sohawa',
    'Soianwala',
    'Siranwali',
    'Talagang',
    'Taxila',
    'Toba Tek',
    'Vehari',
    'Wah Cantonment',
    'Wazirabad',

    // --- Sindh ---
    'Badin',
    'Bhirkan',
    'Rajo Khanani',
    'Chak',
    'Dadu',
    'Digri',
    'Diplo',
    'Dokri',
    'Ghotki',
    'Haala',
    'Hyderabad',
    'Islamkot',
    'Jacobabad',
    'Jamshoro',
    'Jungshahi',
    'Kandhkot',
    'Kandiaro',
    'Kashmore',
    'Keti Bandar',
    'Khairpur',
    'Kotri',
    'Larkana',
    'Matiari',
    'Mehar',
    'Mirpur Khas',
    'Mithani',
    'Mithi',
    'Mehrabpur',
    'Moro',
    'Nagarparkar',
    'Naudero',
    'Naushahro Feroze',
    'Naushara',
    'Nawabshah',
    'Nazimabad',
    'Qambar',
    'Qasimabad',
    'Ranipur',
    'Ratodero',
    'Rohri',
    'Sakrand',
    'Sanghar',
    'Shahbandar',
    'Shahdadkot',
    'Shahdadpur',
    'Shahpur Chakar',
    'Shikarpaur',
    'Sukkur',
    'Tangwani',
    'Tando Adam',
    'Tando Allahyar',
    'Tando Muhammad',
    'Thatta',
    'Umerkot',
    'Warah',
    'Abbottabad',
    'Adezai',
    'Alpuri',
    'Akora Khattak',
    'Ayubia',
    'Banda Daud',
    'Bannu',
    'Batkhela',
    'Battagram',
    'Birote',
    'Chakdara',
    'Charsadda',
    'Chitral',
    'Daggar',
    'Dargai',
    'dera Ismail',
    'Doaba',
    'Dir',
    'Drosh',
    'Hangu',
    'Haripur',
    'Karak',
    'Kohat',
    'Kulachi',
    'Lakki Marwat',
    'Latamber',
    'Madyan',
    'Mansehra',
    'Mardan',
    'Mastuj',
    'Mingora',
    'Nowshera',
    'Paharpur',
    'Pabbi',
    'Peshawar',
    'Saidu Sharif',
    'Shorkot',
    'Shewa Adda',
    'Swabi',
    'Swat',
    'Tangi',
    'Tank',
    'Thall',
    'Timergara',
    'Tordher',
    'Awaran',
    'Barkhan',
    'Chagai',
    'Dera Bugti',
    'Gwadar',
    'Harnai',
    'Jafarabad',
    'Jhal Magsi',
    'Kacchi',
    'Kalat',
    'Kech',
    'Kharan',
    'Khuzdar',
    'Killa Abdullah',
    'Killa Saifullah',
    'Kohlu',
    'Lasbela',
    'Lehri',
    'Loralai',
    'Mastung',
    'Musakhel',
    'Nasirabad',
    'Nushki',
    'Panjgur',
    'Pishin valley',
    'Quetta',
    'Sherani',
    'Sibi',
    'Sohbatpur',
    'Washuk',
    'Zhob',
    'Ziarat',
  ];

  final set = <String>{};
  final list = <String>[];

  for (final c in pinned) {
    final x = c.trim();
    if (x.isNotEmpty && set.add(x)) list.add(x);
  }

  final rest = <String>[];
  for (final c in allCitiesRaw) {
    final x = c.trim();
    if (x.isNotEmpty && set.add(x)) rest.add(x);
  }
  rest.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  list.addAll(rest);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CityPickerSheet(cities: list, initial: initial),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.cities, this.initial});

  final List<String> cities;
  final String? initial;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  // Use your same gradient
  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    final q = _q.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.cities
        : widget.cities.where((c) => c.toLowerCase().contains(q)).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22 * s),
              topRight: Radius.circular(22 * s),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                height: 64 * s,
                margin: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 10 * s),
                padding: EdgeInsets.symmetric(horizontal: 14 * s),
                decoration: BoxDecoration(
                  gradient: _grad,
                  borderRadius: BorderRadius.circular(16 * s),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      color: Colors.white,
                      size: 20 * s,
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Text(
                        'Select City',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 18 * s,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: EdgeInsets.all(6 * s),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22 * s,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 10 * s),
                child: Container(
                  height: 54 * s,
                  padding: EdgeInsets.symmetric(horizontal: 12 * s),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF111827)),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _q = v),
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 15 * s,
                            color: const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search city...',
                            hintStyle: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                              fontSize: 15 * s,
                            ),
                          ),
                        ),
                      ),
                      if (_q.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _q = '');
                          },
                          child: const Icon(Icons.close, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              ),

              // List
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 14 * s),
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8 * s),
                  itemBuilder: (context, i) {
                    final city = filtered[i];
                    final selected = (widget.initial ?? '') == city;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14 * s),
                      onTap: () => Navigator.pop(context, city),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * s,
                          vertical: 12 * s,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14 * s),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0AA2FF)
                                : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 9 * s,
                              height: 34 * s,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10 * s),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C6FF),
                                    Color(0xFF7F53FD),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * s),
                            Expanded(
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5 * s,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0AA2FF),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
