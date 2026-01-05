import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_amst_flutter/Firebase/fb_journey_plan_repo.dart' as jrepo;
import 'package:new_amst_flutter/Model/fb_journey_stop.dart';
import 'package:new_amst_flutter/Model/super_journeyplan_model.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kShadow = Color(0x14000000);

// const _kGrad = LinearGradient(
//   colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//   begin: Alignment.topLeft,
//   end: Alignment.bottomRight,
// );

// // ✅ HARD LOCK: supervisor must be within 50 meters to submit a visit.
// // If a stop has a smaller radius configured, we respect the smaller radius.
// const double kVisitRadiusMeters = 50.0;

// const String _pendingVisitKey = 'pending_visit_v1';
// const String _pendingVisitCheckInKey = 'pending_visit_checkin_v1';
// const String _journeyDateKey = 'journey_date_v1';

// String _visitedKeyFor(String date) => 'visited_$date';
// String _endedKeyFor(String date) => 'journey_ended_$date';
// String _visitDetailsKeyFor(String date) => 'visit_details_$date';

// String _dateKey(DateTime dt) {
//   final y = dt.year.toString();
//   final m = dt.month.toString().padLeft(2, '0');
//   final d = dt.day.toString().padLeft(2, '0');
//   return '$y-$m-$d';
// }

// String formatTimeHM(DateTime dt) {
//   final hh = dt.hour.toString().padLeft(2, '0');
//   final mm = dt.minute.toString().padLeft(2, '0');
//   return '$hh:$mm';
// }

// double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
//   final d = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
//   return d / 1000.0;
// }

// class _JourneyWithDistance {
//   final JourneyPlanSupervisor supervisor;
//   final double distanceKm;
//   _JourneyWithDistance({required this.supervisor, required this.distanceKm});
// }

// class JourneyPlanMapScreen extends StatefulWidget {
//   const JourneyPlanMapScreen({super.key});

//   @override
//   State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
// }

// class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
//   Position? _currentPos;
//   String? _error;
//   bool _loading = true;

//   bool _mapCreated = false;
//   bool _locationReady = false;
//   bool _showSplash = true;

//   late List<JourneyPlanSupervisor> _all;

//   String? _planId;
//   List<_JourneyWithDistance> _items = [];

//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};

//   final GetStorage _box = GetStorage();
//   late String _todayKey;

//   int get _totalLocations => _all.length;
//   int get _completedLocations => _all.where((x) => x.isVisited == true).length;

//   @override
//   void initState() {
//     super.initState();
//     _all = <JourneyPlanSupervisor>[];
//     _todayKey = _dateKey(DateTime.now());

//     _restoreDayState();
//     _boot();
//   }

//   Future<void> _boot() async {
//     // ✅ Wait for auth to be ready
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() {
//         _error = 'Not signed in. Please login again.';
//         _loading = false;
//         _showSplash = false;
//       });
//       return;
//     }

//     // start location first (safe)
//     await _initLocation();

//     // then load plan (needs auth + rules)
//     await _loadTodayPlan(uid: user.uid);

//     await _restorePendingPopup();
//     _maybeShowJourneyEnded();
//   }

//   Future<void> _loadTodayPlan({required String uid}) async {
//     try {
//       final plan = await jrepo.FbJourneyPlanRepo.fetchActivePlanOnce(
//         supervisorId: uid,
//         now: DateTime.now(),
//       );

//       if (plan == null) {
//         setState(() {
//           _error = 'No journey plan assigned for today.';
//           _loading = false;
//           _showSplash = false;
//         });
//         return;
//       }

//       _planId = plan.id;

//       String _dayKey(DateTime dt) {
//   final y = dt.year.toString().padLeft(4, '0');
//   final m = dt.month.toString().padLeft(2, '0');
//   final d = dt.day.toString().padLeft(2, '0');
//   return '$y-$m-$d';
// }

//       // ✅ NEW structure support (days + locationsSnapshot):
//       // Show today's assigned stops.
//       final stops = await jrepo.FbJourneyPlanRepo.fetchStopsForDay(
//        planId: plan.id,
//   dayKey: _dayKey(DateTime.now()),
//       );

//       _all = stops
//           .map(
//             (s) => JourneyPlanSupervisor(
//               name: s.name,
//               lat: s.lat,
//               lng: s.lng,
//               locationId: s.locationId,
//               radiusMeters: s.radiusMeters,
//               isVisited: s.isVisited,
//               checkIn: s.checkIn,
//               checkOut: s.checkOut,
//               durationMinutes: s.durationMinutes,
//             ),
//           )
//           .toList(growable: true);

//       _restoreDayState();

//       // Stops returned above are already decorated with visited state + timings.

//       if (!mounted) return;

//       if (_currentPos != null) _computeDistancesAndMarkers();

//       setState(() {
//         _loading = false;
//         _error = null;
//       });
//     } on FirebaseException catch (e) {
//       setState(() {
//         _error = 'Firestore error: ${e.code} (${e.message ?? ''})';
//         _loading = false;
//         _showSplash = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load journey plan: $e';
//         _loading = false;
//         _showSplash = false;
//       });
//     }
//   }

//   void _restoreDayState() {
//     final lastDate = _box.read<String>(_journeyDateKey);
//     if (lastDate != _todayKey) {
//       _box.write(_journeyDateKey, _todayKey);
//       _box.remove(_pendingVisitKey);
//       _box.remove(_pendingVisitCheckInKey);
//       if (lastDate != null) {
//         _box.remove(_visitedKeyFor(lastDate));
//         _box.remove(_endedKeyFor(lastDate));
//         _box.remove(_visitDetailsKeyFor(lastDate));
//       }
//       for (final item in _all) {
//         item.isVisited = false;
//         item.checkIn = null;
//         item.checkOut = null;
//         item.durationMinutes = null;
//       }
//     } else {
//       final raw = _box.read<List>(_visitedKeyFor(_todayKey)) ?? [];
//       final visitedNames = raw.cast<String>();

//       final rawDetails = _box.read(_visitDetailsKeyFor(_todayKey));
//       Map<String, dynamic> details = {};
//       if (rawDetails is Map) details = Map<String, dynamic>.from(rawDetails);

//       for (final item in _all) {
//         item.isVisited = visitedNames.contains(item.name);

//         final entry = details[item.name];
//         if (entry is Map) {
//           final checkInStr = entry['checkIn'] as String?;
//           final checkOutStr = entry['checkOut'] as String?;
//           final dur = entry['durationMinutes'];

//           item.checkIn = checkInStr != null ? DateTime.tryParse(checkInStr) : null;
//           item.checkOut = checkOutStr != null ? DateTime.tryParse(checkOutStr) : null;
//           item.durationMinutes = (dur is int) ? dur : (dur is num) ? dur.toInt() : null;
//         }
//       }
//     }
//   }

//   Future<void> _initLocation() async {
//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _error = 'Location services are disabled.';
//           _loading = false;
//           _showSplash = false;
//         });
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         setState(() {
//           _error = 'Location permission denied.';
//           _loading = false;
//           _showSplash = false;
//         });
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _currentPos = pos;
//       _computeDistancesAndMarkers();

//       _locationReady = true;
//       _maybeHideSplash();
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to get location: $e';
//         _loading = false;
//         _showSplash = false;
//       });
//     }
//   }

//   void _computeDistancesAndMarkers() {
//     if (_currentPos == null) {
//       setState(() {
//         _error = 'Current location unavailable.';
//         _loading = false;
//       });
//       return;
//     }

//     final lat1 = _currentPos!.latitude;
//     final lon1 = _currentPos!.longitude;

//     _items = _all
//         .map((s) => _JourneyWithDistance(
//               supervisor: s,
//               distanceKm: distanceInKm(lat1, lon1, s.lat, s.lng),
//             ))
//         .toList()
//       ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

//     _buildMarkers();

//     setState(() {
//       _loading = false;
//       _error = null;
//     });

//     _mapController?.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: LatLng(lat1, lon1), zoom: 12.5),
//       ),
//     );
//   }

//   void _buildMarkers() {
//     final markers = <Marker>{};

//     if (_currentPos != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
//           infoWindow: const InfoWindow(title: 'You are here'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//         ),
//       );
//     }

//     for (final item in _items) {
//       final stop = item.supervisor;
//       markers.add(
//         Marker(
//           markerId: MarkerId(stop.name),
//           position: LatLng(stop.lat, stop.lng),
//           infoWindow: InfoWindow(
//             title: stop.name,
//             snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             stop.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers
//         ..clear()
//         ..addAll(markers);
//     });
//   }

//   void _maybeHideSplash() {
//     if (!_mapCreated || !_locationReady || !_showSplash) return;
//     Future.delayed(const Duration(seconds: 2), () {
//       if (!mounted) return;
//       setState(() => _showSplash = false);
//     });
//   }

//   void _onToggleVisited(_JourneyWithDistance item) {
//     final journeyEnded = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
//     if (journeyEnded) {
//       _maybeShowJourneyEnded();
//       return;
//     }

//     if (item.supervisor.isVisited) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('You have already checked out from ${item.supervisor.name} today.')),
//       );
//       return;
//     }

//     if (_currentPos == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Current location not available yet.')),
//       );
//       return;
//     }

//     // ✅ Use meters for precise geo-fence enforcement.
//     final dMeters = Geolocator.distanceBetween(
//       _currentPos!.latitude,
//       _currentPos!.longitude,
//       item.supervisor.lat,
//       item.supervisor.lng,
//     );

//     // ✅ Hard lock to 50m.
//     // If a stop is configured with a smaller radius, enforce the smaller one.
//     final configured = (item.supervisor.radiusMeters > 0)
//         ? item.supervisor.radiusMeters.toDouble()
//         : kVisitRadiusMeters;
//     final limitMeters = math.min(configured, kVisitRadiusMeters);

//     if (dMeters > limitMeters) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'You must be at ${item.supervisor.name} (within ${limitMeters.toStringAsFixed(0)} m).\n'
//             'Current distance: ${dMeters.toStringAsFixed(0)} m',
//           ),
//         ),
//       );
//       return;
//     }

//     _startVisitFlow(item.supervisor);
//   }

//   void _startVisitFlow(JourneyPlanSupervisor stop) {
//     final now = DateTime.now();
//     _box.write(_pendingVisitKey, stop.name);
//     _box.write(_pendingVisitCheckInKey, now.toIso8601String());
//     _showVisitPopup(stop);
//   }

//   Future<void> _restorePendingPopup() async {
//     final pendingName = _box.read<String>(_pendingVisitKey);
//     if (pendingName == null) return;

//     JourneyPlanSupervisor? stop;
//     for (final s in _all) {
//       if (s.name == pendingName) {
//         stop = s;
//         break;
//       }
//     }
//     if (stop == null) return;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showVisitPopup(stop!);
//     });
//   }

//   Future<void> _showVisitPopup(JourneyPlanSupervisor stop) async {
//     final result = await showDialog<Map<String, dynamic>?>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         XFile? pickedImage;
//         final commentCtrl = TextEditingController();
//         final stockQtyCtrl = TextEditingController();

//         // simple supervisor visit form fields
//         String outletCondition = 'Good'; // Good / Normal / Bad
//         bool stockAvailable = true;
//         bool displayOk = true;
//         bool submitting = false;

//         return WillPopScope(
//           onWillPop: () async => false,
//           child: StatefulBuilder(
//             builder: (ctx, setState) {
//               Future<void> _pickImage() async {
//                 final picker = ImagePicker();
//                 final img = await picker.pickImage(
//                   source: ImageSource.camera,
//                   imageQuality: 80,
//                 );
//                 if (img != null) setState(() => pickedImage = img);
//               }

//               final qty = int.tryParse(stockQtyCtrl.text.trim());

//               final canSubmit =
//                   pickedImage != null &&
//                   commentCtrl.text.trim().isNotEmpty &&
//                   qty != null &&
//                   qty >= 0 &&
//                   !submitting;

//               return AlertDialog(
//                 backgroundColor: Colors.white.withOpacity(0.59),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                 titlePadding: const EdgeInsets.only(top: 16, left: 20, right: 20),
//                 contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
//                 title: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Visit details',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w700,
//                         fontSize: 18,
//                         color: kText,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       stop.name,
//                       style: const TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 13,
//                         color: kMuted,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         height: 160,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.grey.shade300),
//                           color: Colors.grey.shade100,
//                         ),
//                         clipBehavior: Clip.antiAlias,
//                         child: pickedImage == null
//                             ? Center(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: const [
//                                     Icon(Icons.camera_alt_rounded, size: 32, color: kMuted),
//                                     SizedBox(height: 6),
//                                     Text(
//                                       'Capture outlet photo',
//                                       style: TextStyle(
//                                         fontFamily: 'ClashGrotesk',
//                                         color: kMuted,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
//                       ),
//                       const SizedBox(height: 12),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7F53FD),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           onPressed: _pickImage,
//                           icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
//                           label: const Text(
//                             'Take Photo',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // ✅ Supervisor visit form fields
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Outlet condition',
//                           style: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: kText,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF2F3F5),
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: outletCondition,
//                             isExpanded: true,
//                             onChanged: (v) => setState(() => outletCondition = v ?? 'Good'),
//                             items: const [
//                               DropdownMenuItem(value: 'Good', child: Text('Good')),
//                               DropdownMenuItem(value: 'Normal', child: Text('Normal')),
//                               DropdownMenuItem(value: 'Bad', child: Text('Bad')),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _pillToggle(
//                               label: 'Stock available',
//                               value: stockAvailable,
//                               onChanged: (v) => setState(() => stockAvailable = v),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _pillToggle(
//                               label: 'Display OK',
//                               value: displayOk,
//                               onChanged: (v) => setState(() => displayOk = v),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Stock quantity (approx.)',
//                           style: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: kText,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: stockQtyCtrl,
//                         keyboardType: TextInputType.number,
//                         onChanged: (_) => setState(() {}),
//                         decoration: InputDecoration(
//                           hintText: 'e.g. 12',
//                           hintStyle: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 12,
//                             color: kMuted,
//                           ),
//                           fillColor: const Color(0xFFF2F3F5),
//                           filled: true,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         style: const TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontSize: 13,
//                           color: kText,
//                         ),
//                       ),

//                       const SizedBox(height: 14),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Comments',
//                           style: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: kText,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: commentCtrl,
//                         maxLines: 4,
//                         minLines: 3,
//                         onChanged: (_) => setState(() {}),
//                         decoration: InputDecoration(
//                           hintText: 'Write 3–4 lines about display, stock, etc.',
//                           hintStyle: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 12,
//                             color: kMuted,
//                           ),
//                           fillColor: const Color(0xFFF2F3F5),
//                           filled: true,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         style: const TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontSize: 13,
//                           color: kText,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
//                 actions: [
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF00C6FF),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(18),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                       ),
//                       onPressed: canSubmit
//                           ? () {
//                               setState(() => submitting = true);
//                               Navigator.of(ctx).pop(<String, dynamic>{
//                                 'imagePath': pickedImage!.path,
//                                 'comment': commentCtrl.text.trim(),
//                                 'outletCondition': outletCondition,
//                                 'stockAvailable': stockAvailable,
//                                 'displayOk': displayOk,
//                                 'stockQty': int.tryParse(stockQtyCtrl.text.trim()) ?? 0,
//                               });
//                             }
//                           : null,
//                       child: submitting
//                           ? const SizedBox(
//                               height: 18,
//                               width: 18,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                           : const Text(
//                               'Submit',
//                               style: TextStyle(
//                                 fontFamily: 'ClashGrotesk',
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       },
//     );

//     if (result != null) {
//       final checkInIso = _box.read<String>(_pendingVisitCheckInKey);
//       final checkIn = checkInIso != null ? DateTime.tryParse(checkInIso) : null;

//       final checkOut = DateTime.now();
//       final durationMinutes = checkIn != null ? checkOut.difference(checkIn).inMinutes : 0;

//       _box.remove(_pendingVisitKey);
//       _box.remove(_pendingVisitCheckInKey);

//       final form = <String, dynamic>{
//         'outletCondition': (result['outletCondition'] ?? '').toString(),
//         'stockAvailable': result['stockAvailable'] == true,
//         'displayOk': result['displayOk'] == true,
//         'stockQty': (result['stockQty'] is num) ? (result['stockQty'] as num).toInt() : 0,
//       };

//       // Optional: encode photo to base64 (best-effort, size-guarded)
//       String? photoBase64;
//       final imgPath = (result['imagePath'] ?? '').toString();
//       if (imgPath.isNotEmpty) {
//         try {
//           final bytes = await File(imgPath).readAsBytes();
//           // Firestore doc limit is ~1MB. Keep a safe ceiling.
//           if (bytes.length <= 300 * 1024) {
//             photoBase64 = base64Encode(bytes);
//           }
//         } catch (_) {
//           // ignore (still allow visit submission)
//         }
//       }

//       _markVisitedPersist(
//         stop,
//         comment: (result['comment'] ?? '').toString(),
//         form: form,
//         photoBase64: photoBase64,
//         checkIn: checkIn,
//         checkOut: checkOut,
//         durationMinutes: durationMinutes,
//       );
//     }
//   }

//   Widget _pillToggle({
//     required String label,
//     required bool value,
//     required ValueChanged<bool> onChanged,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F3F5),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: kText,
//               ),
//             ),
//           ),
//           Switch.adaptive(
//             value: value,
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }

//   void _markVisitedPersist(
//     JourneyPlanSupervisor stop, {
//     required String comment,
//     required Map<String, dynamic> form,
//     String? photoBase64,
//     DateTime? checkIn,
//     DateTime? checkOut,
//     int? durationMinutes,
//   }) {
//     setState(() {
//       stop.isVisited = true;
//       stop.checkIn = checkIn;
//       stop.checkOut = checkOut;
//       stop.durationMinutes = durationMinutes;
//     });

//     final visitedKey = _visitedKeyFor(_todayKey);
//     final raw = _box.read<List>(visitedKey) ?? [];
//     final visited = raw.cast<String>();
//     if (!visited.contains(stop.name)) visited.add(stop.name);
//     _box.write(visitedKey, visited);

//     final detailsKey = _visitDetailsKeyFor(_todayKey);
//     final rawDetails = _box.read(detailsKey);
//     final details = (rawDetails is Map)
//         ? Map<String, dynamic>.from(rawDetails)
//         : <String, dynamic>{};

//     details[stop.name] = {
//       'checkIn': checkIn?.toIso8601String(),
//       'checkOut': checkOut?.toIso8601String(),
//       'durationMinutes': durationMinutes,
//       'comment': comment,
//       'form': form,
//     };
//     _box.write(detailsKey, details);

//     final planId = _planId;
//     final locId = stop.locationId;

//     if (planId != null && locId != null && locId.isNotEmpty) {
//       jrepo.FbJourneyPlanRepo.addVisit(
//         planId: planId,
//         stop: FbJourneyStop(
//           id: locId,
//           locationId: locId,
//           name: stop.name,
//           lat: stop.lat,
//           lng: stop.lng,
//           radiusMeters: stop.radiusMeters,
//         ),
//         comment: comment,
//         form: form,
//         photoBase64: photoBase64,
//         checkIn: checkIn,
//         checkOut: checkOut,
//       );
//     }

//     _buildMarkers();

//     if (_completedLocations == _totalLocations) {
//       _box.write(_endedKeyFor(_todayKey), true);
//       _maybeShowJourneyEnded();
//     }
//   }

//   void _maybeShowJourneyEnded() {
//     final ended = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
//     if (!ended) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) => _showJourneyEndedDialog());
//   }

//   Future<void> _showJourneyEndedDialog() async {
//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return WillPopScope(
//           onWillPop: () async => false,
//           child: AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: const Text(
//               "Today's journey ended",
//               style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w700),
//             ),
//             content: const Text(
//               'You have visited all outlets planned for today.\n\n'
//               'Please come back tomorrow to start a new journey.',
//               style: TextStyle(fontFamily: 'ClashGrotesk', fontSize: 13),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(ctx).pop(),
//                 child: const Text(
//                   'OK',
//                   style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ✅ FIX: logout MUST sign out Firebase
//   Future<void> _logout() async {
//     await _box.erase();
//     await FirebaseAuth.instance.signOut();

//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const AuthScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   void dispose() {
//     _mapController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasLocation = _currentPos != null;

//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(gradient: _kGrad),
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: hasLocation
//                       ? GoogleMap(
//                           initialCameraPosition: CameraPosition(
//                             target: LatLng(_currentPos!.latitude, _currentPos!.longitude),
//                             zoom: 12.0,
//                           ),
//                           myLocationEnabled: true,
//                           myLocationButtonEnabled: false,
//                           compassEnabled: true,
//                           markers: _markers,
//                           onMapCreated: (c) {
//                             _mapController = c;
//                             _mapCreated = true;
//                             _maybeHideSplash();
//                           },
//                         )
//                       : const Center(
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         ),
//                 ),

//                 Container(
//                   height: 96,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.black.withOpacity(0.4), Colors.transparent],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                   ),
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: 100,
//                         height: 30,
//                         child: _PrimaryGradientButton(
//                           text: 'Logout',
//                           onPressed: _logout,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 if (!_loading && _error != null)
//                   Center(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       margin: const EdgeInsets.symmetric(horizontal: 24),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.6),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         _error!,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontFamily: 'ClashGrotesk',
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),

//                 if (!_loading && _error == null)
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: BackdropFilter(
//                           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//                           child: Container(
//                             width: double.infinity,
//                             constraints: const BoxConstraints(maxHeight: 260),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.59),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.59),
//                                 width: 1.3,
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
//                                   child: Row(
//                                     children: [
//                                       const Text(
//                                         'Nearby Outlets',
//                                         style: TextStyle(
//                                           color: Colors.black,
//                                           fontWeight: FontWeight.w900,
//                                           fontSize: 15,
//                                           fontFamily: 'ClashGrotesk',
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Column(
//                                         crossAxisAlignment: CrossAxisAlignment.end,
//                                         children: [
//                                           Text(
//                                             'Stops: ${_items.length}',
//                                             style: const TextStyle(
//                                               color: Colors.black,
//                                               fontSize: 12,
//                                               fontWeight: FontWeight.w900,
//                                               fontFamily: 'ClashGrotesk',
//                                             ),
//                                           ),
//                                           Text(
//                                             'Done: $_completedLocations',
//                                             style: const TextStyle(
//                                               color: Colors.green,
//                                               fontSize: 12,
//                                               fontWeight: FontWeight.w900,
//                                               fontFamily: 'ClashGrotesk',
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Expanded(
//                                   child: ListView.separated(
//                                     padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
//                                     itemCount: _items.length,
//                                     separatorBuilder: (_, __) => const SizedBox(height: 8),
//                                     itemBuilder: (_, i) {
//                                       final item = _items[i];
//                                       return _GlassJourneyCard(
//                                         index: i + 1,
//                                         data: item,
//                                         onTap: () {
//                                           _mapController?.animateCamera(
//                                             CameraUpdate.newCameraPosition(
//                                               CameraPosition(
//                                                 target: LatLng(item.supervisor.lat, item.supervisor.lng),
//                                                 zoom: 15.5,
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                         onToggleVisited: () => _onToggleVisited(item),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           if (_showSplash)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.white,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     Icon(Icons.map_rounded, size: 72, color: Color(0xFF7F53FD)),
//                     SizedBox(height: 16),
//                     Text(
//                       'Loading map & outlets...',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: kText,
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     CircularProgressIndicator(),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _PrimaryGradientButton extends StatelessWidget {
//   const _PrimaryGradientButton({
//     Key? key,
//     required this.text,
//     required this.onPressed,
//     this.loading = false,
//   }) : super(key: key);

//   final String text;
//   final VoidCallback? onPressed;
//   final bool loading;

//   static const _grad = LinearGradient(
//     colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final disabled = loading || onPressed == null;

//     return Opacity(
//       opacity: disabled ? 0.6 : 1.0,
//       child: Container(
//         height: 54,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           gradient: _grad,
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF7F53FD).withOpacity(0.25),
//               blurRadius: 18,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(28),
//             onTap: disabled ? null : onPressed,
//             child: Center(
//               child: loading
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Text(
//                       text,
//                       style: const TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _GlassJourneyCard extends StatelessWidget {
//   const _GlassJourneyCard({
//     required this.index,
//     required this.data,
//     required this.onTap,
//     required this.onToggleVisited,
//   });

//   final int index;
//   final _JourneyWithDistance data;
//   final VoidCallback onTap;
//   final VoidCallback onToggleVisited;

//   @override
//   Widget build(BuildContext context) {
//     final stop = data.supervisor;
//     final distText = '${data.distanceKm.toStringAsFixed(1)} km';

//     String? timeText;
//     if (stop.checkIn != null && stop.checkOut != null) {
//       final inStr = formatTimeHM(stop.checkIn!);
//       final outStr = formatTimeHM(stop.checkOut!);
//       timeText = stop.durationMinutes != null ? '$inStr – $outStr • ${stop.durationMinutes} min' : '$inStr – $outStr';
//     } else if (stop.checkIn != null) {
//       timeText = 'Check-in: ${formatTimeHM(stop.checkIn!)}';
//     }

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.18),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: Colors.black.withOpacity(0.5),
//             width: 0.9,
//           ),
//         ),
//         padding: const EdgeInsets.all(10),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 34,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(colors: [Colors.white, Color(0xFFECFEFF)]),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Text(
//                   '$index',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w800,
//                     fontFamily: 'ClashGrotesk',
//                     color: kText,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     stop.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
//                       const SizedBox(width: 4),
//                       Text(
//                         distText,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'ClashGrotesk',
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (timeText != null) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       timeText,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w500,
//                         fontFamily: 'ClashGrotesk',
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             InkWell(
//               borderRadius: BorderRadius.circular(999),
//               onTap: onToggleVisited,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: stop.isVisited
//                       ? Colors.greenAccent.withOpacity(0.18)
//                       : Colors.orangeAccent.withOpacity(0.18),
//                   border: Border.all(
//                     color: stop.isVisited ? Colors.greenAccent : Colors.orangeAccent,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       stop.isVisited ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
//                       size: 16,
//                       color: stop.isVisited ? Colors.greenAccent : Colors.orangeAccent,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       stop.isVisited ? 'Visited' : 'Pending',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'ClashGrotesk',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }














const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ✅ HARD LOCK: supervisor must be within 50 meters to submit a visit.
// If a stop has a smaller radius configured, we respect the smaller radius.
const double kVisitRadiusMeters = 150.0;

const String _pendingVisitKey = 'pending_visit_v1';
const String _pendingVisitCheckInKey = 'pending_visit_checkin_v1';
const String _journeyDateKey = 'journey_date_v1';

String _visitedKeyFor(String date) => 'visited_$date';
String _endedKeyFor(String date) => 'journey_ended_$date';
String _visitDetailsKeyFor(String date) => 'visit_details_$date';

String _dateKey(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _dayKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatTimeHM(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
  final d = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  return d / 1000.0;
}

class _JourneyWithDistance {
  final JourneyPlanSupervisor supervisor;
  final double distanceKm;
  _JourneyWithDistance({required this.supervisor, required this.distanceKm});
}

class JourneyPlanMapScreen extends StatefulWidget {
  const JourneyPlanMapScreen({super.key});

  @override
  State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
}

class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
  Position? _currentPos;
  String? _error;

  /// ✅ Loading flags (ONLY show splash until all true)
  bool _loading = true;
  bool _planLoaded = false;
  bool _mapCreated = false;
  bool _locationReady = false;

  late List<JourneyPlanSupervisor> _all;
  String? _planId;

  List<_JourneyWithDistance> _items = [];
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final GetStorage _box = GetStorage();
  late String _todayKey;

  int get _totalLocations => _all.length;
  int get _completedLocations => _all.where((x) => x.isVisited == true).length;

  bool get _ready =>
      !_loading &&
      _error == null &&
      _locationReady &&
      _planLoaded &&
      _mapCreated;

  @override
  void initState() {
    super.initState();
    _all = <JourneyPlanSupervisor>[];
    _todayKey = _dateKey(DateTime.now());
    _restoreDayState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _error = null;
      _loading = true;
      _planLoaded = false;
      _locationReady = false;
      _mapCreated = false;
    });

    // ✅ Wait for auth to be ready
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not signed in. Please login again.';
        _loading = false;
      });
      return;
    }

    // location first
    await _initLocation();

    // plan load
    await _loadTodayPlan(uid: user.uid);

    // restore pending popup
    await _restorePendingPopup();
    _maybeShowJourneyEnded();

    // ✅ End loading (splash stays until _ready becomes true)
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTodayPlan({required String uid}) async {
    try {
      final plan = await jrepo.FbJourneyPlanRepo.fetchActivePlanOnce(
        supervisorId: uid,
        now: DateTime.now(),
      );

      if (plan == null) {
        setState(() {
          _error = 'No journey plan assigned for today.';
        });
        return;
      }

      _planId = plan.id;

      // ✅ NEW structure support (days + locationsSnapshot)
      final stops = await jrepo.FbJourneyPlanRepo.fetchStopsForDay(
        planId: plan.id,
        dayKey: _dayKey(DateTime.now()),
      );

      _all = stops
          .map(
            (s) => JourneyPlanSupervisor(
              name: s.name,
              lat: s.lat,
              lng: s.lng,
              locationId: s.locationId,
              radiusMeters: s.radiusMeters,
              isVisited: s.isVisited,
              checkIn: s.checkIn,
              checkOut: s.checkOut,
              durationMinutes: s.durationMinutes,
            ),
          )
          .toList(growable: true);

      _restoreDayState();

      if (!mounted) return;

      _planLoaded = true;

      // if location is already ready, compute markers now
      if (_currentPos != null) {
        _computeDistancesAndMarkers();
      }
    } on FirebaseException catch (e) {
      setState(() {
        _error = 'Firestore error: ${e.code} (${e.message ?? ''})';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load journey plan: $e';
      });
    }
  }

  void _restoreDayState() {
    final lastDate = _box.read<String>(_journeyDateKey);

    if (lastDate != _todayKey) {
      _box.write(_journeyDateKey, _todayKey);
      _box.remove(_pendingVisitKey);
      _box.remove(_pendingVisitCheckInKey);

      if (lastDate != null) {
        _box.remove(_visitedKeyFor(lastDate));
        _box.remove(_endedKeyFor(lastDate));
        _box.remove(_visitDetailsKeyFor(lastDate));
      }

      for (final item in _all) {
        item.isVisited = false;
        item.checkIn = null;
        item.checkOut = null;
        item.durationMinutes = null;
      }
      return;
    }

    final raw = _box.read<List>(_visitedKeyFor(_todayKey)) ?? [];
    final visitedNames = raw.cast<String>();

    final rawDetails = _box.read(_visitDetailsKeyFor(_todayKey));
    Map<String, dynamic> details = {};
    if (rawDetails is Map) details = Map<String, dynamic>.from(rawDetails);

    for (final item in _all) {
      item.isVisited = visitedNames.contains(item.name);

      final entry = details[item.name];
      if (entry is Map) {
        final checkInStr = entry['checkIn'] as String?;
        final checkOutStr = entry['checkOut'] as String?;
        final dur = entry['durationMinutes'];

        item.checkIn =
            checkInStr != null ? DateTime.tryParse(checkInStr) : null;
        item.checkOut =
            checkOutStr != null ? DateTime.tryParse(checkOutStr) : null;
        item.durationMinutes =
            (dur is int) ? dur : (dur is num) ? dur.toInt() : null;
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPos = pos;
      _locationReady = true;

      // if plan already loaded, compute markers now
      if (_planLoaded) _computeDistancesAndMarkers();
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }
  }

  void _computeDistancesAndMarkers() {
    if (_currentPos == null) return;

    final lat1 = _currentPos!.latitude;
    final lon1 = _currentPos!.longitude;

    _items = _all
        .map((s) => _JourneyWithDistance(
              supervisor: s,
              distanceKm: distanceInKm(lat1, lon1, s.lat, s.lng),
            ))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    _buildMarkers();

    // move camera once map exists
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat1, lon1), zoom: 12.5),
        ),
      );
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    if (_currentPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    for (final item in _items) {
      final stop = item.supervisor;
      markers.add(
        Marker(
          markerId: MarkerId(stop.name),
          position: LatLng(stop.lat, stop.lng),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            stop.isVisited
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _onToggleVisited(_JourneyWithDistance item) {
    final journeyEnded = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
    if (journeyEnded) {
      _maybeShowJourneyEnded();
      return;
    }

    if (item.supervisor.isVisited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already checked out from ${item.supervisor.name} today.',
          ),
        ),
      );
      return;
    }

    if (_currentPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available yet.')),
      );
      return;
    }

    final dMeters = Geolocator.distanceBetween(
      _currentPos!.latitude,
      _currentPos!.longitude,
      item.supervisor.lat,
      item.supervisor.lng,
    );

    final configured = (item.supervisor.radiusMeters > 0)
        ? item.supervisor.radiusMeters.toDouble()
        : kVisitRadiusMeters;

    final limitMeters = math.min(configured, kVisitRadiusMeters);

    if (dMeters > limitMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be at ${item.supervisor.name} (within ${limitMeters.toStringAsFixed(0)} m).\n'
            'Current distance: ${dMeters.toStringAsFixed(0)} m',
          ),
        ),
      );
      return;
    }

    _startVisitFlow(item.supervisor);
  }

  void _startVisitFlow(JourneyPlanSupervisor stop) {
    final now = DateTime.now();
    _box.write(_pendingVisitKey, stop.name);
    _box.write(_pendingVisitCheckInKey, now.toIso8601String());
    _showVisitPopup(stop);
  }

  Future<void> _restorePendingPopup() async {
    final pendingName = _box.read<String>(_pendingVisitKey);
    if (pendingName == null) return;

    JourneyPlanSupervisor? stop;
    for (final s in _all) {
      if (s.name == pendingName) {
        stop = s;
        break;
      }
    }
    if (stop == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVisitPopup(stop!);
    });
  }



Future<void> _showVisitPopup(JourneyPlanSupervisor stop) async {
  final result = await showDialog<Map<String, dynamic>?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final commentCtrl = TextEditingController();
      final stockQtyCtrl = TextEditingController(); // ✅ Stock textfield

      String shelfCondition = 'Good'; // Good / Normal / Bad
      int displayScore = 7; // 1..10
      bool submitting = false;

      // ✅ grey dropdown theme
      const dropdownBg = Color(0xFF6B7280); // slate/grey
      const dropdownTextStyle = TextStyle(
        color: Colors.white,
        fontFamily: 'ClashGrotesk',
        fontWeight: FontWeight.w600,
      );

      return WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final stockQty = int.tryParse(stockQtyCtrl.text.trim());

            // ✅ only required: stock must be number and comment not empty
            final canSubmit =
                (stockQty != null && stockQty >= 0) &&
                commentCtrl.text.trim().isNotEmpty &&
                !submitting;

            Widget _label(String text) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                );

            // ✅ Grey dropdown (white text) - selected + opened menu
            Widget _greyDropdown<T>({
              required T value,
              required List<DropdownMenuItem<T>> items,
              required ValueChanged<T?> onChanged,
            }) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: dropdownBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: dropdownBg, // ✅ opened background grey
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                    style: dropdownTextStyle, // ✅ selected text white
                    onChanged: onChanged,
                    items: items,
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.59),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.only(top: 16, left: 20, right: 20),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visit details',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    stop.name,
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: kText,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    // ✅ Shelf condition dropdown (grey)
                    _label('Shelf condition'),
                    const SizedBox(height: 6),
                    _greyDropdown<String>(
                      value: shelfCondition,
                      onChanged: (v) => setStateDialog(() {
                        shelfCondition = v ?? 'Good';
                      }),
                      items: const [
                        DropdownMenuItem(
                          value: 'Good',
                          child: Text('Good', style: dropdownTextStyle),
                        ),
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text('Normal', style: dropdownTextStyle),
                        ),
                        DropdownMenuItem(
                          value: 'Bad',
                          child: Text('Bad', style: dropdownTextStyle),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ Stock textfield
                    _label('Stock quantity (approx.)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: stockQtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. 12',
                        hintStyle: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 12,
                          color: kMuted,
                        ),
                        fillColor: const Color(0xFFF2F3F5),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 13,
                        color: kText,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Display score dropdown (1..10) grey
                    _label('Display (1 to 10)'),
                    const SizedBox(height: 6),
                    _greyDropdown<int>(
                      value: displayScore,
                      onChanged: (v) => setStateDialog(() {
                        displayScore = v ?? 7;
                      }),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}', style: dropdownTextStyle),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Comments
                    _label('Comments'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 4,
                      minLines: 3,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: 'Write 3–4 lines about stock & display...',
                        hintStyle: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 12,
                          color: kMuted,
                        ),
                        fillColor: const Color(0xFFF2F3F5),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 13,
                        color: kText,
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: canSubmit
                        ? () {
                            setStateDialog(() => submitting = true);
                            Navigator.of(ctx).pop(<String, dynamic>{
                              'comment': commentCtrl.text.trim(),
                              'shelfCondition': shelfCondition,
                              'stockQty': int.tryParse(stockQtyCtrl.text.trim()) ?? 0,
                              'displayScore': displayScore,
                            });
                          }
                        : null,
                    child: submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (result != null) {
    final checkInIso = _box.read<String>(_pendingVisitCheckInKey);
    final checkIn = checkInIso != null ? DateTime.tryParse(checkInIso) : null;

    final checkOut = DateTime.now();
    final durationMinutes =
        checkIn != null ? checkOut.difference(checkIn).inMinutes : 0;

    _box.remove(_pendingVisitKey);
    _box.remove(_pendingVisitCheckInKey);

    // ✅ Updated form (no image)
    final form = <String, dynamic>{
      'shelfCondition': (result['shelfCondition'] ?? '').toString(),
      'stockQty': (result['stockQty'] is num)
          ? (result['stockQty'] as num).toInt()
          : 0,
      'displayScore': (result['displayScore'] is num)
          ? (result['displayScore'] as num).toInt()
          : 0,
    };

    _markVisitedPersist(
      stop,
      comment: (result['comment'] ?? '').toString(),
      form: form,
      photoBase64: null,
      checkIn: checkIn,
      checkOut: checkOut,
      durationMinutes: durationMinutes,
    );
  }
}



  /*

  Future<void> _showVisitPopup(JourneyPlanSupervisor stop) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        XFile? pickedImage;
        final commentCtrl = TextEditingController();
        final stockQtyCtrl = TextEditingController();

        String outletCondition = 'Good';
        bool stockAvailable = true;
        bool displayOk = true;
        bool submitting = false;

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              Future<void> _pickImage() async {
                final picker = ImagePicker();
                final img = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (img != null) setStateDialog(() => pickedImage = img);
              }

              final qty = int.tryParse(stockQtyCtrl.text.trim());

              final canSubmit = pickedImage != null &&
                  commentCtrl.text.trim().isNotEmpty &&
                  qty != null &&
                  qty >= 0 &&
                  !submitting;

              return AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.59),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding:
                    const EdgeInsets.only(top: 16, left: 20, right: 20),
                contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit details',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      stop.name,
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kText,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                 /*     Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pickedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_rounded,
                                        size: 32, color: kMuted),
                                    SizedBox(height: 6),
                                    Text(
                                      'Capture outlet photo',
                                      style: TextStyle(
                                        fontFamily: 'ClashGrotesk',
                                        color: kMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Image.file(
                                File(pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F53FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt_rounded,
                              size: 18, color: Colors.white),
                          label: const Text(
                            'Take Photo',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),*/
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Shelf condition',
                          style: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: outletCondition,
                            isExpanded: true,
                            onChanged: (v) => setStateDialog(
                                () => outletCondition = v ?? 'Good'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Good', child: Text('Good')),
                              DropdownMenuItem(
                                  value: 'Normal', child: Text('Normal')),
                              DropdownMenuItem(value: 'Bad', child: Text('Bad')),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _pillToggle(
                              label: 'Stock available',
                              value: stockAvailable,
                              onChanged: (v) =>
                                  setStateDialog(() => stockAvailable = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pillToggle(
                              label: 'Display OK',
                              value: displayOk,
                              onChanged: (v) =>
                                  setStateDialog(() => displayOk = v),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Stock quantity (approx.)',
                          style: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: stockQtyCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: InputDecoration(
                          hintText: 'e.g. 12',
                          hintStyle: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 12,
                            color: kMuted,
                          ),
                          fillColor: const Color(0xFFF2F3F5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 13,
                          color: kText,
                        ),
                      ),

                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Comments',
                          style: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: commentCtrl,
                        maxLines: 4,
                        minLines: 3,
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: InputDecoration(
                          hintText: 'Write 3–4 lines about display, stock, etc.',
                          hintStyle: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 12,
                            color: kMuted,
                          ),
                          fillColor: const Color(0xFFF2F3F5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 13,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: canSubmit
                          ? () {
                              setStateDialog(() => submitting = true);
                              Navigator.of(ctx).pop(<String, dynamic>{
                                'imagePath': pickedImage!.path,
                                'comment': commentCtrl.text.trim(),
                                'outletCondition': outletCondition,
                                'stockAvailable': stockAvailable,
                                'displayOk': displayOk,
                                'stockQty':
                                    int.tryParse(stockQtyCtrl.text.trim()) ?? 0,
                              });
                            }
                          : null,
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      final checkInIso = _box.read<String>(_pendingVisitCheckInKey);
      final checkIn =
          checkInIso != null ? DateTime.tryParse(checkInIso) : null;

      final checkOut = DateTime.now();
      final durationMinutes =
          checkIn != null ? checkOut.difference(checkIn).inMinutes : 0;

      _box.remove(_pendingVisitKey);
      _box.remove(_pendingVisitCheckInKey);

      final form = <String, dynamic>{
        'outletCondition': (result['outletCondition'] ?? '').toString(),
        'stockAvailable': result['stockAvailable'] == true,
        'displayOk': result['displayOk'] == true,
        'stockQty': (result['stockQty'] is num)
            ? (result['stockQty'] as num).toInt()
            : 0,
      };

      String? photoBase64;
      final imgPath = (result['imagePath'] ?? '').toString();
      if (imgPath.isNotEmpty) {
        try {
          final bytes = await File(imgPath).readAsBytes();
          if (bytes.length <= 300 * 1024) {
            photoBase64 = base64Encode(bytes);
          }
        } catch (_) {}
      }

      _markVisitedPersist(
        stop,
        comment: (result['comment'] ?? '').toString(),
        form: form,
        photoBase64: photoBase64,
        checkIn: checkIn,
        checkOut: checkOut,
        durationMinutes: durationMinutes,
      );
    }
  }*/

  Widget _pillToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  void _markVisitedPersist(
    JourneyPlanSupervisor stop, {
    required String comment,
    required Map<String, dynamic> form,
    String? photoBase64,
    DateTime? checkIn,
    DateTime? checkOut,
    int? durationMinutes,
  }) {
    setState(() {
      stop.isVisited = true;
      stop.checkIn = checkIn;
      stop.checkOut = checkOut;
      stop.durationMinutes = durationMinutes;
    });

    final visitedKey = _visitedKeyFor(_todayKey);
    final raw = _box.read<List>(visitedKey) ?? [];
    final visited = raw.cast<String>();
    if (!visited.contains(stop.name)) visited.add(stop.name);
    _box.write(visitedKey, visited);

    final detailsKey = _visitDetailsKeyFor(_todayKey);
    final rawDetails = _box.read(detailsKey);
    final details = (rawDetails is Map)
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};

    details[stop.name] = {
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'comment': comment,
      'form': form,
    };
    _box.write(detailsKey, details);

    final planId = _planId;
    final locId = stop.locationId;

    if (planId != null && locId != null && locId.isNotEmpty) {
      jrepo.FbJourneyPlanRepo.addVisit(
        planId: planId,
        stop: FbJourneyStop(
          id: locId,
          locationId: locId,
          name: stop.name,
          lat: stop.lat,
          lng: stop.lng,
          radiusMeters: stop.radiusMeters,
        ),
        comment: comment,
        form: form,
        photoBase64: photoBase64,
        checkIn: checkIn,
        checkOut: checkOut,
      );
    }

    _buildMarkers();

    if (_completedLocations == _totalLocations) {
      _box.write(_endedKeyFor(_todayKey), true);
      _maybeShowJourneyEnded();
    }
  }

  void _maybeShowJourneyEnded() {
    final ended = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
    if (!ended) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showJourneyEndedDialog();
    });
  }
  Future<void> _showJourneyEndedDialog() async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: kShadow,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.60),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Icon bubble (matches theme)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: _kGrad,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7F53FD).withOpacity(0.20),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Today's journey ended",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: kText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'You have visited all outlets planned for today.\n\n'
                        'Please come back tomorrow to start a new journey.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Full-width gradient button (same family as your logout button)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: _PrimaryGradientButton(
                          text: 'OK',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _logout() async {
    await _box.erase();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _retry() {
    _mapController?.dispose();
    _mapController = null;
    _markers.clear();
    _items.clear();
    _boot();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentPos != null;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Underlay can build normally (map initializes), but user sees splash above.
          Container(
            decoration: const BoxDecoration(gradient: _kGrad),
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasLocation
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPos!.latitude,
                              _currentPos!.longitude,
                            ),
                            zoom: 12.0,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          compassEnabled: true,
                          markers: _markers,
                          onMapCreated: (c) {
                            _mapController = c;
                            if (!_mapCreated) {
                              setState(() => _mapCreated = true);
                            }
                            // compute camera if data already present
                            if (_currentPos != null && _planLoaded) {
                              _computeDistancesAndMarkers();
                            }
                          },
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                ),

                // Top fade
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Logout
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 30,
                        child: _PrimaryGradientButton(
                          text: 'Logout',
                          onPressed: _logout,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom list panel
                if (_error == null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.59),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.59),
                                width: 1.3,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Nearby Outlets',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          fontFamily: 'ClashGrotesk',
                                        ),
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Stops: ${_items.length}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'ClashGrotesk',
                                            ),
                                          ),
                                          Text(
                                            'Done: $_completedLocations',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'ClashGrotesk',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 4, 12, 12),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final item = _items[i];
                                      return _GlassJourneyCard(
                                        index: i + 1,
                                        data: item,
                                        onTap: () {
                                          _mapController?.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                target: LatLng(
                                                  item.supervisor.lat,
                                                  item.supervisor.lng,
                                                ),
                                                zoom: 15.5,
                                              ),
                                            ),
                                          );
                                        },
                                        onToggleVisited: () =>
                                            _onToggleVisited(item),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ✅ HARD SPLASH LOCK (only thing user sees until _ready)
          if (!_ready)
            Positioned.fill(
              child: _SplashView(
                text: _error == null ? 'Loading map & outlets...' : _error!,
                isError: _error != null,
                onRetry: _error != null ? _retry : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({
    required this.text,
    required this.isError,
    this.onRetry,
  });

  final String text;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _kGrad),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 22),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 18, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.map_rounded,
                size: 64,
                color: isError ? Colors.redAccent : const Color(0xFF7F53FD),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isError ? Colors.redAccent : kText,
                ),
              ),
              const SizedBox(height: 12),
              if (!isError)
                const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (isError && onRetry != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F53FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onRetry,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  }) : super(key: key);

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  static const _grad = LinearGradient(
    colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: _grad,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F53FD).withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

class _GlassJourneyCard extends StatelessWidget {
  const _GlassJourneyCard({
    required this.index,
    required this.data,
    required this.onTap,
    required this.onToggleVisited,
  });

  final int index;
  final _JourneyWithDistance data;
  final VoidCallback onTap;
  final VoidCallback onToggleVisited;

  @override
  Widget build(BuildContext context) {
    final stop = data.supervisor;
    final distText = '${data.distanceKm.toStringAsFixed(1)} km';

    String? timeText;
    if (stop.checkIn != null && stop.checkOut != null) {
      final inStr = formatTimeHM(stop.checkIn!);
      final outStr = formatTimeHM(stop.checkOut!);
      timeText = stop.durationMinutes != null
          ? '$inStr – $outStr • ${stop.durationMinutes} min'
          : '$inStr – $outStr';
    } else if (stop.checkIn != null) {
      timeText = 'Check-in: ${formatTimeHM(stop.checkIn!)}';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.5),
            width: 0.9,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFECFEFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ClashGrotesk',
                    color: kText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        distText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ClashGrotesk',
                        ),
                      ),
                    ],
                  ),
                  if (timeText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'ClashGrotesk',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggleVisited,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: stop.isVisited
                      ? Colors.greenAccent.withOpacity(0.18)
                      : Colors.orangeAccent.withOpacity(0.18),
                  border: Border.all(
                    color:
                        stop.isVisited ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stop.isVisited
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: stop.isVisited
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stop.isVisited ? 'Visited' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ClashGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
