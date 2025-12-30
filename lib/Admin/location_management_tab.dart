
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

class LocationManagementTab extends StatelessWidget {
  const LocationManagementTab({super.key});

  static const _bg = Color(0xFFF6F7FA);

  // ---------- UI Helpers ----------
  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  InputDecoration _fieldDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'ClashGrotesk',
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ---------- Dialog ----------
  Future<void> _openEditDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? existing,
  }) async {
    final nameController =
        TextEditingController(text: (existing?['name'] ?? '').toString());

    final radiusController = TextEditingController(
      text: (existing?['allowedRadiusMeters'] ?? 100).toString(),
    );

    GeoPoint? gp;
    final exLoc = existing?['allowedLocation'];
    if (exLoc is GeoPoint) gp = exLoc;

    final latController = TextEditingController(text: gp?.latitude.toString() ?? '');
    final lngController = TextEditingController(text: gp?.longitude.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) {
        bool saving = false;

        Future<void> save() async {
          final name = nameController.text.trim();
          final lat = double.tryParse(latController.text.trim());
          final lng = double.tryParse(lngController.text.trim());
          final radius = double.tryParse(radiusController.text.trim());

          if (name.isEmpty || lat == null || lng == null || radius == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fill all fields with valid numbers')),
            );
            return;
          }

          saving = true;
          (context as Element).markNeedsBuild();

          try {
            await FbLocationRepo.upsertLocation(
              id: id,
              name: name,
              lat: lat,
              lng: lng,
              radiusMeters: radius,
            );
            Navigator.of(context).pop();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Save failed: $e')),
            );
          }
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: _cardShell(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id == null ? 'Add Location' : 'Edit Location',
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nameController,
                  decoration: _fieldDeco('Name'),
                  style: const TextStyle(fontFamily: 'ClashGrotesk'),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDeco('Latitude'),
                        style: const TextStyle(fontFamily: 'ClashGrotesk'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDeco('Longitude'),
                        style: const TextStyle(fontFamily: 'ClashGrotesk'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: radiusController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDeco('Radius (meters)'),
                  style: const TextStyle(fontFamily: 'ClashGrotesk'),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
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
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
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
        );
      },
    );
  }

  // ---------- Card item (left gradient spine like attendance) ----------
  Widget _locationCard({
    required double s,
    required String name,
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
          // left gradient spine
          Container(
            width: 9 * s,
            height: 92 * s,
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
                  // text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            fontSize: 15 * s,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            color: const Color(0xFF6B7280),
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // actions
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

  // ---------- Main ----------
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
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                // just triggers rebuild by re-subscribing
                await Future<void>.delayed(const Duration(milliseconds: 250));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s + padBottom),
                children: [
                  // Header
                  // Text(
                  //   'Locations',
                  //   style: TextStyle(
                  //     fontFamily: 'ClashGrotesk',
                  //     fontSize: 20 * s,
                  //     fontWeight: FontWeight.w900,
                  //     color: const Color(0xFF0F172A),
                  //   ),
                  // ),
                  SizedBox(height: 12 * s),

                  if (docs.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 70 * s),
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
                      final name = (data['name'] ?? d.id).toString();

                      final gp = data['allowedLocation'] is GeoPoint
                          ? data['allowedLocation'] as GeoPoint
                          : null;

                      final rad = (data['allowedRadiusMeters'] ?? '').toString();

                      final subtitle = gp == null
                          ? 'Radius: $rad m'
                          : '(${gp.latitude}, ${gp.longitude}) • Radius: $rad m';

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12 * s),
                        child: _locationCard(
                          s: s,
                          name: name,
                          subtitle: subtitle,
                          onEdit: () => _openEditDialog(context, id: d.id, existing: data),
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text(
                                  'Delete location?',
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                content: Text(
                                  'Delete "$name"?',
                                  style: const TextStyle(fontFamily: 'ClashGrotesk'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontFamily: 'ClashGrotesk'),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(fontFamily: 'ClashGrotesk'),
                                    ),
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
        backgroundColor: const Color(0xFF0F172A),
        onPressed: () => _openEditDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
