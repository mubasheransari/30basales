import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

   const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

class LocationManagementTab extends StatelessWidget {
  const LocationManagementTab({super.key});

  static const _bg = Color(0xFFF6F7FA);
  static const _txtDark = Color(0xFF0F172A);
  static const _txtDim = Color(0xFF64748B);

  static const _kGrad = LinearGradient(
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

  // ========================== Existing Input Deco ==========================

  InputDecoration _fieldDeco(String label, {IconData? icon}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF7F53FD)),
    );
  }

  // ========================== Validations (same as your last) ==========================

  String? _reqV(String? v, {String label = 'This field'}) {
    if ((v ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  String? _latV(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Latitude is required';
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid latitude';
    if (n < -90 || n > 90) return 'Latitude must be between -90 and 90';
    return null;
  }

  String? _lngV(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Longitude is required';
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid longitude';
    if (n < -180 || n > 180) return 'Longitude must be between -180 and 180';
    return null;
  }

  String? _radiusV(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Radius is required';
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid radius';
    if (n < 50) return 'Radius must be at least 50 meters';
    if (n > 50000) return 'Radius must be <= 50,000 meters';
    return null;
  }

  // ========================== Gradient Prefix Icon (same working style) ==========================

  Widget _gradPrefix(IconData icon) {
    return Container(
      height: 36,
      width: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: _kGrad,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
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

  // ========================== ✅ YOUR WORKING EDIT DIALOG (KEPT) ==========================

  Future<void> _openEditDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? existing,
  }) async {
    final existingMart =
        (existing?['martName'] ?? existing?['name'] ?? '').toString();
    final existingCity = (existing?['cityName'] ?? '').toString();
    final existingArea = (existing?['areaName'] ?? '').toString();

    final nameController = TextEditingController(text: existingMart);
    final cityController = TextEditingController(text: existingCity);
    final areaController = TextEditingController(text: existingArea);

    final radiusController = TextEditingController(
      text: (existing?['allowedRadiusMeters'] ??
              existing?['radiusMeters'] ??
              50)
          .toString(),
    );

    GeoPoint? gp;
    final exLoc = existing?['allowedLocation'] ?? existing?['location'];
    if (exLoc is GeoPoint) gp = exLoc;

    final latController =
        TextEditingController(text: gp?.latitude.toString() ?? '');
    final lngController =
        TextEditingController(text: gp?.longitude.toString() ?? '');

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;

        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> save() async {
              FocusScope.of(ctx).unfocus();

              final ok = formKey.currentState?.validate() ?? false;
              if (!ok) return;

              final martName = nameController.text.trim();
              final cityName = cityController.text.trim();
              final areaName = areaController.text.trim();

              final lat = double.parse(latController.text.trim());
              final lng = double.parse(lngController.text.trim());
              final radius = double.parse(radiusController.text.trim());

              setState(() => saving = true);

              try {
                await FbLocationRepo.upsertLocation(
                  id: id,
                  martName: martName,
                  cityName: cityName,
                  areaName: areaName,
                  lat: lat,
                  lng: lng,
                  radiusMeters: radius,
                );

                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Save failed: $e')),
                );
              } finally {
                if (ctx.mounted) setState(() => saving = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: _kGrad,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                id == null ? 'Add Location' : 'Edit Location',
                                style: const TextStyle(
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

                        // Mart
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Mart Name',
                            icon: Icons.storefront_rounded,
                          ),
                          validator: (v) => _reqV(v, label: 'Mart Name'),
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        // Area
                        TextFormField(
                          controller: areaController,
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Area Name',
                            icon: Icons.map_rounded,
                          ),
                          validator: (v) => _reqV(v, label: 'Area Name'),
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                        ),
                        const SizedBox(height: 10),

                        // City picker (same as your last working)
                        Stack(
                          children: [
                            _CityPickerField(
                              controller: cityController,
                              enabled: !saving,
                              onPick: () async {
                                final picked = await _openPakistanCityPicker(
                                  ctx,
                                  initial: cityController.text.trim(),
                                );
                                if (picked != null && picked.isNotEmpty) {
                                  setState(() => cityController.text = picked);
                                  formKey.currentState?.validate();
                                }
                              },
                              decoration: _fieldDecoGrad(
                                'City Name',
                                icon: Icons.location_city_rounded,
                              ),
                            ),

                            // hidden validator for form
                            Opacity(
                              opacity: 0,
                              child: SizedBox(
                                height: 0,
                                child: TextFormField(
                                  controller: cityController,
                                  validator: (v) => _reqV(v, label: 'City'),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Lat/Lng
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: latController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                style: const TextStyle(fontFamily: 'ClashGrotesk'),
                                decoration: _fieldDecoGrad(
                                  'Latitude',
                                  icon: Icons.my_location_rounded,
                                ),
                                validator: _latV,
                                enabled: !saving,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: lngController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                style: const TextStyle(fontFamily: 'ClashGrotesk'),
                                decoration: _fieldDecoGrad(
                                  'Longitude',
                                  icon: Icons.explore_rounded,
                                ),
                                validator: _lngV,
                                enabled: !saving,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Radius
                        TextFormField(
                          controller: radiusController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: false),
                          style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          decoration: _fieldDecoGrad(
                            'Radius (meters)',
                            icon: Icons.radar_rounded,
                          ),
                          validator: _radiusV,
                          enabled: !saving,
                        ),

                        const SizedBox(height: 14),

                        // Buttons
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
                              child: _PrimaryGradButton(
                                text: 'Save',
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

  // ========================== Modern UI card helpers ==========================

  Widget _gradIconBox(double s, IconData icon) {
    return Container(
      height: 40 * s,
      width: 40 * s,
      decoration: BoxDecoration(
        gradient: _kGrad,
        borderRadius: BorderRadius.circular(14 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
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

  String _fmtNum(double v) {
    final s = v.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  // ========================== Build ==========================

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FbLocationRepo.streamLocations(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(fontFamily: 'ClashGrotesk'),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            return RefreshIndicator(
              onRefresh: () async =>
                  Future<void>.delayed(const Duration(milliseconds: 250)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16 * s,
                  12 * s,
                  16 * s,
                  24 * s + padBottom,
                ),
                children: [
                  // Top summary card (UI only)
                  _cardShell(
                    padding: EdgeInsets.all(14 * s),
                    child: Row(
                      children: [
                        _gradIconBox(s, Icons.place_rounded),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Locations',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w900,
                                  color: _txtDark,
                                ),
                              ),
                              SizedBox(height: 4 * s),
                              Text(
                                'Manage marts, cities, areas, geo & radius.',
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
                            '${docs.length} total',
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

                  if (docs.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 120 * s),
                        child: Text(
                          'No locations yet. Tap + to add.',
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
                    ...docs.map((d) {
                      final data = d.data();

                      final martName =
                          (data['martName'] ?? data['name'] ?? d.id).toString();
                      final cityName = (data['cityName'] ?? '').toString();
                      final areaName = (data['areaName'] ?? '').toString();

                      final rawLoc = data['allowedLocation'] ?? data['location'];
                      final gp = rawLoc is GeoPoint ? rawLoc : null;

                      final radRaw =
                          data['allowedRadiusMeters'] ?? data['radiusMeters'] ?? 0;
                      final rad = (radRaw is num)
                          ? radRaw.toDouble()
                          : double.tryParse(radRaw.toString()) ?? 0.0;

                      final citySafe = cityName.trim().isEmpty ? '--' : cityName.trim();
                      final areaSafe = areaName.trim().isEmpty ? '--' : areaName.trim();

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
                                    _gradIconBox(s, Icons.storefront_rounded),
                                    SizedBox(width: 10 * s),
                                    Expanded(
                                      child: Text(
                                        martName,
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
                                      borderRadius: BorderRadius.circular(14 * s),
                                      onTap: () => _openEditDialog(
                                        context,
                                        id: d.id,
                                        existing: data,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(10 * s),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(14 * s),
                                          border: Border.all(color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: Icon(Icons.edit_rounded,
                                            size: 18 * s, color: _txtDark),
                                      ),
                                    ),
                                    SizedBox(width: 8 * s),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(14 * s),
                                      onTap: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Delete location?'),
                                            content: Text('Delete "$martName"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (ok == true) {
                                          await FbLocationRepo.deleteLocation(d.id);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(10 * s),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(14 * s),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: Icon(Icons.delete_outline_rounded,
                                            size: 18 * s, color: const Color(0xFFEF4444)),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12 * s),

                                Wrap(
                                  spacing: 8 * s,
                                  runSpacing: 8 * s,
                                  children: [
                                    _chip(s, Icons.location_city_rounded, citySafe),
                                    _chip(s, Icons.map_rounded, areaSafe),
                                    _chip(s, Icons.radar_rounded, '${rad.toStringAsFixed(0)} m'),
                                  ],
                                ),

                                if (gp != null) ...[
                                  SizedBox(height: 10 * s),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12 * s,
                                      vertical: 10 * s,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16 * s),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      children: [
                                        _gradIconBox(s, Icons.my_location_rounded),
                                        SizedBox(width: 10 * s),
                                        Expanded(
                                          child: Text(
                                            'Lat: ${_fmtNum(gp.latitude)}   •   Lng: ${_fmtNum(gp.longitude)}',
                                            style: TextStyle(
                                              fontFamily: 'ClashGrotesk',
                                              fontSize: 12.5 * s,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

      // FAB (same action)
      floatingActionButton: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openEditDialog(context),
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: _kGrad,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

/*
class LocationManagementTab extends StatelessWidget {
  const LocationManagementTab({super.key});

  static const _bg = Color(0xFFF6F7FA);
  static const _txtDark = Color(0xFF0F172A);
  static const _txtDim = Color(0xFF6B7280);

  static const _kGrad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'ClashGrotesk',
        fontWeight: FontWeight.w800,
        color: _txtDim,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF7F53FD)),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  // ---- Validation helpers ----
String? _reqV(String? v, {String label = 'This field'}) {
  if ((v ?? '').trim().isEmpty) return '$label is required';
  return null;
}

String? _latV(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Latitude is required';
  final n = double.tryParse(s);
  if (n == null) return 'Enter a valid latitude';
  if (n < -90 || n > 90) return 'Latitude must be between -90 and 90';
  // Optional tighter validation for Pakistan-ish latitude
  // if (n < 23 || n > 37.5) return 'Latitude looks outside Pakistan range';
  return null;
}

String? _lngV(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Longitude is required';
  final n = double.tryParse(s);
  if (n == null) return 'Enter a valid longitude';
  if (n < -180 || n > 180) return 'Longitude must be between -180 and 180';
  // Optional tighter validation for Pakistan-ish longitude
  // if (n < 60 || n > 78.5) return 'Longitude looks outside Pakistan range';
  return null;
}

String? _radiusV(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Radius is required';
  final n = double.tryParse(s);
  if (n == null) return 'Enter a valid radius';
  if (n < 50) return 'Radius must be at least 50 meters';
  if (n > 50000) return 'Radius must be <= 50,000 meters';
  return null;
}

// ---- Gradient icon wrapper (matches your theme) ----
Widget _gradIcon(IconData icon, {double size = 18}) {
  return ShaderMask(
    shaderCallback: (bounds) => _kGrad.createShader(bounds),
    blendMode: BlendMode.srcIn,
    child: Icon(icon, size: size, color: Colors.white),
  );
}

// ---- Gradient prefix container (consistent with your input cards) ----
Widget _gradPrefix(IconData icon) {
  return Container(
    height: 34,
    width: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: _kGrad,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
      ],
    ),
    child: Icon(icon, size: 18, color: Colors.white),
  );
}

// ---- Field decoration that injects a gradient prefix icon (keeps your look) ----
InputDecoration _fieldDecoGrad(
  String label, {
  required IconData icon,
  String? errorText,
}) {
  // If you already have _fieldDeco, you can just replace calls with this one.
  return _fieldDeco(label, icon: icon).copyWith(
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 10, right: 10,bottom: 0),
      child: _gradPrefix(icon),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    errorText: errorText,
  );
}


  Future<void> _openEditDialog(
  BuildContext context, {
  String? id,
  Map<String, dynamic>? existing,
}) async {
  final existingMart =
      (existing?['martName'] ?? existing?['name'] ?? '').toString();
  final existingCity = (existing?['cityName'] ?? '').toString();
  final existingArea = (existing?['areaName'] ?? '').toString();

  final nameController = TextEditingController(text: existingMart);
  final cityController = TextEditingController(text: existingCity);
  final areaController = TextEditingController(text: existingArea);

  final radiusController = TextEditingController(
    text: (existing?['allowedRadiusMeters'] ??
            existing?['radiusMeters'] ??
            50)
        .toString(),
  );

  GeoPoint? gp;
  final exLoc = existing?['allowedLocation'] ?? existing?['location'];
  if (exLoc is GeoPoint) gp = exLoc;

  final latController =
      TextEditingController(text: gp?.latitude.toString() ?? '');
  final lngController =
      TextEditingController(text: gp?.longitude.toString() ?? '');

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      bool saving = false;

      // ✅ Form + field-level validation
      final formKey = GlobalKey<FormState>();

      // Optional: if you want city must be from list, keep a map/set
      // final citiesSet = allCitiesRaw.map((e) => e.toLowerCase()).toSet();

      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> save() async {
            FocusScope.of(ctx).unfocus();

            // ✅ validate all fields first
            final ok = formKey.currentState?.validate() ?? false;
            if (!ok) return;

            final martName = nameController.text.trim();
            final cityName = cityController.text.trim();
            final areaName = areaController.text.trim();

            final lat = double.parse(latController.text.trim());
            final lng = double.parse(lngController.text.trim());
            final radius = double.parse(radiusController.text.trim());

            setState(() => saving = true);

            try {
              await FbLocationRepo.upsertLocation(
                id: id,
                martName: martName,
                cityName: cityName,
                areaName: areaName,
                lat: lat,
                lng: lng,
                radiusMeters: radius,
              );

              if (Navigator.of(dialogCtx).canPop()) {
                Navigator.of(dialogCtx).pop();
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Save failed: $e')),
              );
            } finally {
              if (ctx.mounted) setState(() => saving = false);
            }
          }

          return Dialog(
            
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: _cardShell(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Header pill (same theme)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _kGrad,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              id == null ? 'Add Location' : 'Edit Location',
                              style: const TextStyle(
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
                  
                      // ✅ Mart name
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(fontFamily: 'ClashGrotesk'),
                        decoration: _fieldDecoGrad(
                          'Mart Name',
                          icon: Icons.storefront_rounded,
                        ),
                        validator: (v) => _reqV(v, label: 'Mart Name'),
                        textInputAction: TextInputAction.next,
                        enabled: !saving,
                      ),
                      const SizedBox(height: 10),
                  
                      // ✅ Area
                      TextFormField(
                        controller: areaController,
                        style: const TextStyle(fontFamily: 'ClashGrotesk'),
                        decoration: _fieldDecoGrad(
                          'Area Name',
                          icon: Icons.map_rounded,
                        ),
                        validator: (v) => _reqV(v, label: 'Area Name'),
                        textInputAction: TextInputAction.next,
                        enabled: !saving,
                      ),
                      const SizedBox(height: 10),
                  
                      // ✅ City (searchable picker field)
                      // NOTE: This uses your _CityPickerField + _openPakistanCityPicker.
                      // We validate the controller value using a hidden validator.
                      Stack(
                        children: [
                          _CityPickerField(
                            controller: cityController,
                            enabled: !saving,
                            onPick: () async {
                              final picked = await _openPakistanCityPicker(
                                ctx,
                                initial: cityController.text.trim(),
                              );
                              if (picked != null && picked.isNotEmpty) {
                                setState(() => cityController.text = picked);
                                // revalidate after selection
                                formKey.currentState?.validate();
                              }
                            },
                            decoration: _fieldDecoGrad(
                              'City Name',
                              icon: Icons.location_city_rounded,
                            ),
                          ),
                  
                          // ✅ Hidden validator field (so city is part of Form validation)
                          Opacity(
                            opacity: 0,
                            child: SizedBox(
                              height: 0,
                              child: TextFormField(
                                controller: cityController,
                                validator: (v) {
                                  final msg = _reqV(v, label: 'City');
                                  if (msg != null) return msg;
                  
                                  // Optional strict check: only allow from your list
                                  // final ok = citiesSet.contains((v ?? '').trim().toLowerCase());
                                  // if (!ok) return 'Please pick a city from the list';
                  
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                  
                      const SizedBox(height: 10),
                  
                      // ✅ Lat/Lng with proper range checks
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              style: const TextStyle(fontFamily: 'ClashGrotesk'),
                              decoration: _fieldDecoGrad(
                                'Latitude',
                                icon: Icons.my_location_rounded,
                              ),
                              validator: _latV,
                              enabled: !saving,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: lngController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              style: const TextStyle(fontFamily: 'ClashGrotesk'),
                              decoration: _fieldDecoGrad(
                                'Longitude',
                                icon: Icons.explore_rounded,
                              ),
                              validator: _lngV,
                              enabled: !saving,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                  
                      // ✅ Radius
                      TextFormField(
                        controller: radiusController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: false),
                        style: const TextStyle(fontFamily: 'ClashGrotesk'),
                        decoration: _fieldDecoGrad(
                          'Radius (meters)',
                          icon: Icons.radar_rounded,
                        ),
                        validator: _radiusV,
                        enabled: !saving,
                      ),
                  
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
                                side:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                            child: _PrimaryGradButton(
                              text: 'Save',
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


//   Future<void> _openEditDialog(
//   BuildContext context, {
//   String? id,
//   Map<String, dynamic>? existing,
// }) async {

  
//   final existingMart =
//       (existing?['martName'] ?? existing?['name'] ?? '').toString();
//   final existingCity = (existing?['cityName'] ?? '').toString();
//   final existingArea = (existing?['areaName'] ?? '').toString();

//   final nameController = TextEditingController(text: existingMart);
//   final cityController = TextEditingController(text: existingCity);
//   final areaController = TextEditingController(text: existingArea);

//   final radiusController = TextEditingController(
//     text: (existing?['allowedRadiusMeters'] ??
//             existing?['radiusMeters'] ??
//             1000)
//         .toString(),
//   );

//   GeoPoint? gp;
//   final exLoc = existing?['allowedLocation'] ?? existing?['location'];
//   if (exLoc is GeoPoint) gp = exLoc;

//   final latController =
//       TextEditingController(text: gp?.latitude.toString() ?? '');
//   final lngController =
//       TextEditingController(text: gp?.longitude.toString() ?? '');

//   await showDialog(
//     context: context,
//     builder: (dialogCtx) {
//       bool saving = false;

      

//       return StatefulBuilder(
//         builder: (ctx, setState) {
//           Future<void> save() async {
            
//             final martName = nameController.text.trim();
//             final cityName = cityController.text.trim();
//             final areaName = areaController.text.trim();

//             final lat = double.tryParse(latController.text.trim());
//             final lng = double.tryParse(lngController.text.trim());
//             final radius = double.tryParse(radiusController.text.trim());

//             if (martName.isEmpty ||
//                 cityName.isEmpty ||
//                 areaName.isEmpty ||
//                 lat == null ||
//                 lng == null ||
//                 radius == null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Fill all fields with valid values')),
//               );
//               return;
//             }

//             setState(() => saving = true);

//             try {
//               await FbLocationRepo.upsertLocation(
//                 id: id,
//                 martName: martName,
//                 cityName: cityName,
//                 areaName: areaName,
//                 lat: lat,
//                 lng: lng,
//                 radiusMeters: radius,
//               );

//               Navigator.of(dialogCtx).pop();
//             } catch (e) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Save failed: $e')),
//               );
//             } finally {
//               if (ctx.mounted) setState(() => saving = false);
//             }
//           }

//           return Dialog(
//             backgroundColor: Colors.transparent,
//             insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//             child: _cardShell(
//               padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       gradient: _kGrad,
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.place_rounded, color: Colors.white, size: 18),
//                         const SizedBox(width: 8),
//                         Text(
//                           id == null ? 'Add Location' : 'Edit Location',
//                           style: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             color: Colors.white,
//                             fontWeight: FontWeight.w900,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 14),

//                   TextField(
//                     controller: nameController,
//                     decoration: _fieldDeco('Mart Name', icon: Icons.storefront_rounded),
//                     style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                   ),
//                   const SizedBox(height: 10),

//                   TextField(
//                     controller: areaController,
//                     decoration: _fieldDeco('Area Name', icon: Icons.map_rounded),
//                     style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                   ),
//                   const SizedBox(height: 10),

//                   // ✅ REPLACED: City textfield -> searchable picker field
//                   _CityPickerField(
//                     controller: cityController,
//                     enabled: !saving,
//                     onPick: () async {
//                       final picked = await _openPakistanCityPicker(ctx, initial: cityController.text.trim());
//                       if (picked != null && picked.isNotEmpty) {
//                         setState(() => cityController.text = picked);
//                       }
//                     },
//                     decoration: _fieldDeco('City Name', icon: Icons.location_city_rounded),
//                   ),

//                   const SizedBox(height: 10),

//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: latController,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           decoration: _fieldDeco('Latitude', icon: Icons.my_location_rounded),
//                           style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: TextField(
//                           controller: lngController,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           decoration: _fieldDeco('Longitude', icon: Icons.explore_rounded),
//                           style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),

//                   TextField(
//                     controller: radiusController,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     decoration: _fieldDeco('Radius (meters)', icon: Icons.radar_rounded),
//                     style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                   ),

//                   const SizedBox(height: 14),

//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: saving ? null : () => Navigator.of(dialogCtx).pop(),
//                           style: OutlinedButton.styleFrom(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                             side: const BorderSide(color: Color(0xFFE5E7EB)),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                           ),
//                           child: const Text(
//                             'Cancel',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontWeight: FontWeight.w900,
//                               color: Color(0xFF111827),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: _PrimaryGradButton(
//                           text: 'Save',
//                           loading: saving,
//                           onPressed: saving ? null : save,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }



  Widget _locationCard({
    required double s,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
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
          Container(
            width: 9 * s,
            height: 118 * s,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
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
              padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 10 * s, 10 * s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w900,
                            color: _txtDark,
                            fontSize: 15 * s,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            color: _txtDim,
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, color: Color(0xFF111827)),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtNum(double v) {
    final s = v.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FbLocationRepo.streamLocations(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(fontFamily: 'ClashGrotesk'),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            return RefreshIndicator(
              onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 250)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s + padBottom),
                children: [
                  SizedBox(height: 12 * s),
                  if (docs.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.30),
                      child: const Center(
                        child: Text(
                          'No locations yet. Tap + to add.',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    ...docs.map((d) {
                      final data = d.data();

                      final martName = (data['martName'] ?? data['name'] ?? d.id).toString();
                      final cityName = (data['cityName'] ?? '').toString();
                      final areaName = (data['areaName'] ?? '').toString();

                      final rawLoc = data['allowedLocation'] ?? data['location'];
                      final gp = rawLoc is GeoPoint ? rawLoc : null;

                      final radRaw = data['allowedRadiusMeters'] ?? data['radiusMeters'] ?? 0;
                      final rad = (radRaw is num)
                          ? radRaw.toDouble()
                          : double.tryParse(radRaw.toString()) ?? 0.0;

                      final subtitle = gp == null
                          ? 'City: ${cityName.isEmpty ? '--' : cityName}\n'
                              'Area: ${areaName.isEmpty ? '--' : areaName}\n'
                              'Radius: ${rad.toStringAsFixed(0)} m'
                          : 'City: ${cityName.isEmpty ? '--' : cityName}\n'
                              'Area: ${areaName.isEmpty ? '--' : areaName}\n'
                              'Lat: ${_fmtNum(gp.latitude)}  •  Lng: ${_fmtNum(gp.longitude)}\n'
                              'Radius: ${rad.toStringAsFixed(0)} m';

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12 * s),
                        child: _locationCard(
                          s: s,
                          title: martName,
                          subtitle: subtitle,
                          onEdit: () => _openEditDialog(context, id: d.id, existing: data),
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete location?'),
                                content: Text('Delete "$martName"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (ok == true) {
                              await FbLocationRepo.deleteLocation(d.id);
                            }
                          },
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
    //    backgroundColor: const Color(0xFF0F172A),
        onPressed: () => _openEditDialog(context),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: _grad,
           borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child:const Icon(Icons.add, color: Colors.white),
        ),//const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}*/

Future<String?> _openPakistanCityPicker(BuildContext context, {String? initial}) async {
  // ✅ Pinned on top
  const pinned = ['Karachi', 'Lahore', 'Islamabad'];

  // ✅ Replace this with FULL Pakistan cities list
  // const allCitiesRaw = <String>[
  //   'Karachi', 'Lahore', 'Islamabad',
  //   'Rawalpindi', 'Faisalabad', 'Multan', 'Peshawar', 'Quetta',
  //   'Hyderabad', 'Gujranwala', 'Sialkot', 'Bahawalpur', 'Sargodha',
  //   'Sukkur', 'Larkana', 'Mardan', 'Abbottabad', 'Okara',
  //   // ... add ALL cities here ...
  // ];
  // ✅ Pakistan Cities (Top pinned first: Karachi, Lahore, Islamabad)
const allCitiesRaw = <String>[
  'Karachi',
  'Lahore',
  'Islamabad',

  // --- remaining cities (dataset order) ---
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

  // --- KPK / North ---
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

  // --- Balochistan ---
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


  // Dedupe + pinned-first + A-Z
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
    builder: (ctx) => _CityPickerSheet(
      cities: list,
      initial: initial,
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.cities,
    this.initial,
  });

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
                    Icon(Icons.location_city_rounded, color: Colors.white, size: 20 * s),
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
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 22 * s),
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
                        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14 * s),
                          border: Border.all(
                            color: selected ? const Color(0xFF0AA2FF) : Colors.transparent,
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
                                  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
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
                              const Icon(Icons.check_circle, color: Color(0xFF0AA2FF)),
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


class _PrimaryGradButton extends StatelessWidget {
  const _PrimaryGradButton({
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  static const LinearGradient _kGrad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _kGrad,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F53FD).withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
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
