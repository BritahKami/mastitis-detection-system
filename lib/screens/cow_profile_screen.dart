// import 'package:flutter/material.dart';
// import '../constants/theme_constants.dart';
// import '../models/mds_models.dart';
// import '../widgets/app_header.dart';
// import '../widgets/custom_primary_button.dart';
// import 'detection_result_screen.dart';

// /// Screen 3: Cow Profile Screen
// ///
// /// Specifications:
// /// - Layout: White card layout with AppHeader ("Cow profile").
// /// - Metadata Card: A light grey bounded container featuring "Tag number: [ID]" (Bold),
// ///   "Breed: [String]", "Age: [Int] years".
// /// - Actions: CustomPrimaryButton ("Select cow to test").
// /// - Content: "History" section title. A ListView.builder displaying past test dates
// ///   on the left and colored text (e.g., "Mastitis present" in red, "Mastitis absent" in green)
// ///   on the right.
// /// - Diagnostic Routing: Tapping "Select cow to test" simulates a test or pushes directly
// ///   to Screen 4 (Detection Result).
// class CowProfileScreen extends StatefulWidget {
//   final Cow cow;

//   const CowProfileScreen({
//     super.key,
//     required this.cow,
//   });

//   @override
//   State<CowProfileScreen> createState() => _CowProfileScreenState();
// }

// class _CowProfileScreenState extends State<CowProfileScreen> {
//   bool _isTesting = false;

//   void _runDiagnosticTest() {
//     setState(() {
//       _isTesting = true;
//     });

//     // Simulate diagnostic sensor capture
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (!mounted) return;
//       setState(() {
//         _isTesting = false;
//       });

//       final DetectionResult result = widget.cow.status == StatusType.atRisk
//           ? DetectionResult.sampleForCow(widget.cow.displayTag)
//           : DetectionResult.healthySampleForCow(widget.cow.displayTag);

//       Navigator.of(context).push(
//         MaterialPageRoute(
//           settings: const RouteSettings(name: '/detection_result'),
//           builder: (context) => DetectionResultScreen(
//             result: result,
//             cow: widget.cow,
//           ),
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundSurface,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSpacing.horizontalScreenMargin,
//             vertical: AppSpacing.verticalScreenMargin,
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: AppRadii.containerBorderRadius,
//               border: Border.all(
//                 color: AppColors.borderNeutral,
//                 width: 1.0,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.03),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: AppRadii.containerBorderRadius,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // AppHeader ("Cow profile")
//                   AppHeader(
//                     title: 'Cow profile',
//                     showBackButton: true,
//                     onBackPressed: () => Navigator.of(context).pop(),
//                   ),

//                   Expanded(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           // Metadata Card: Light grey bounded container
//                           Container(
//                             padding: const EdgeInsets.all(16.0),
//                             decoration: BoxDecoration(
//                               color: AppColors.backgroundSurface,
//                               borderRadius: AppRadii.containerBorderRadius,
//                               border: Border.all(
//                                 color: AppColors.borderNeutral,
//                                 width: 1.0,
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // "Tag number: [ID]" (Bold, H2: 16px to 18px)
//                                 Row(
//                                   children: [
//                                     const Text(
//                                       'Tag number: ',
//                                       style: AppTypography.h2,
//                                     ),
//                                     Text(
//                                       widget.cow.rawTagId,
//                                       style: AppTypography.h2.copyWith(
//                                         color: AppColors.primaryTheme,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 10),

//                                 // "Breed: [String]"
//                                 Row(
//                                   children: [
//                                     const Text(
//                                       'Breed: ',
//                                       style: TextStyle(
//                                         fontFamily: AppTypography.fontFamily,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: AppColors.textPrimary,
//                                       ),
//                                     ),
//                                     Text(
//                                       widget.cow.breed,
//                                       style: AppTypography.bodyRegularDark,
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 6),

//                                 // "Age: [Int] years"
//                                 Row(
//                                   children: [
//                                     const Text(
//                                       'Age: ',
//                                       style: TextStyle(
//                                         fontFamily: AppTypography.fontFamily,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: AppColors.textPrimary,
//                                       ),
//                                     ),
//                                     Text(
//                                       '${widget.cow.age} years',
//                                       style: AppTypography.bodyRegularDark,
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 20),

//                           // Actions: CustomPrimaryButton ("Select cow to test")
//                           CustomPrimaryButton(
//                             label: 'Select cow to test',
//                             isLoading: _isTesting,
//                             leadingIcon: const Icon(
//                               Icons.biotech_outlined,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                             onPressed: _runDiagnosticTest,
//                           ),
//                           const SizedBox(height: 24),

//                           // Section Header: "History" (H2: 16px to 18px, Font Weight 600)
//                           const Text(
//                             'History',
//                             style: AppTypography.h2,
//                           ),
//                           const SizedBox(height: 12),

//                           // History ListView.builder
//                           if (widget.cow.history.isEmpty)
//                             Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 24.0),
//                               child: Center(
//                                 child: Text(
//                                   'No test history available',
//                                   style: AppTypography.bodyRegular,
//                                 ),
//                               ),
//                             )
//                           else
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: AppRadii.containerBorderRadius,
//                                 border: Border.all(
//                                   color: AppColors.borderNeutral,
//                                   width: 1.0,
//                                 ),
//                               ),
//                               child: ListView.separated(
//                                 shrinkWrap: true,
//                                 physics: const NeverScrollableScrollPhysics(),
//                                 itemCount: widget.cow.history.length,
//                                 separatorBuilder: (context, index) =>
//                                     const Divider(
//                                   color: AppColors.borderNeutral,
//                                   height: 1.0,
//                                   thickness: 1.0,
//                                 ),
//                                 itemBuilder: (context, index) {
//                                   final record = widget.cow.history[index];
//                                   final Color statusColor = record.mastitisPresent
//                                       ? AppColors.badgeAtRiskText
//                                       : AppColors.badgeHealthyText;

//                                   return Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 16.0,
//                                       vertical: 14.0,
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         // Past test dates on the left
//                                         Text(
//                                           record.date,
//                                           style: AppTypography.bodyRegular,
//                                         ),
//                                         // Colored text on the right
//                                         Text(
//                                           record.label,
//                                           style: TextStyle(
//                                             fontFamily: AppTypography.fontFamily,
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w600,
//                                             color: statusColor,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_primary_button.dart';
import 'detection_result_screen.dart';
import '../constants/api_constants.dart';

/// Screen 3: Cow Profile Screen
class CowProfileScreen extends StatefulWidget {
  final Cow cow;

  const CowProfileScreen({
    super.key,
    required this.cow,
  });

  @override
  State<CowProfileScreen> createState() => _CowProfileScreenState();
}

class _CowProfileScreenState extends State<CowProfileScreen> {
  bool _isTesting = false;

  // Replace with your local machine's local IP or 10.0.2.2 for Android Emulator
  static const String baseUrl = 'http://192.168.4.165:8000'; 

  Future<void> _runDiagnosticTest() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // 1. Step 1: Trigger active 3-minute test session lock on FastAPI
      final startTestUri = Uri.parse(ApiConstants.initiateTestEndpoint(widget.cow.id));
      final startResponse = await http.post(
        startTestUri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (startResponse.statusCode != 200) {
        throw Exception('Failed to lock test session on server.');
      }

      // 2. Step 2: Show user prompt to submerge sensors into milk sample
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test session active. Please submerge sensors into milk sample.'),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.primaryTheme,
        ),
      );

      // 3. Step 3: Brief delay to allow ESP32 hardware to post telemetry
      await Future.delayed(const Duration(seconds: 3));

      // 4. Step 4: Fetch latest live reading from backend
      final latestReadingUri = Uri.parse('$baseUrl/cows/${widget.cow.id}/latest-reading');
      final readingResponse = await http.get(latestReadingUri).timeout(const Duration(seconds: 15));

      if (readingResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(readingResponse.body);
        final DetectionResult liveResult = DetectionResult.fromJson(data);

        if (!mounted) return;

        // 5. Step 5: Navigate to Detection Result Screen with live ML prediction
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/detection_result'),
            builder: (context) => DetectionResultScreen(
              result: liveResult,
              cow: widget.cow,
            ),
          ),
        );
      } else {
        throw Exception('No recent reading received from ESP32.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalScreenMargin,
            vertical: AppSpacing.verticalScreenMargin,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.containerBorderRadius,
              border: Border.all(
                color: AppColors.borderNeutral,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadii.containerBorderRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Cow profile',
                    showBackButton: true,
                    onBackPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Metadata Card
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSurface,
                              borderRadius: AppRadii.containerBorderRadius,
                              border: Border.all(
                                color: AppColors.borderNeutral,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Tag number: ',
                                      style: AppTypography.h2,
                                    ),
                                    Text(
                                      widget.cow.rawTagId,
                                      style: AppTypography.h2.copyWith(
                                        color: AppColors.primaryTheme,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Breed: ',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      widget.cow.breed,
                                      style: AppTypography.bodyRegularDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text(
                                      'Age: ',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${widget.cow.age} years',
                                      style: AppTypography.bodyRegularDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Actions: CustomPrimaryButton ("Select cow to test")
                          CustomPrimaryButton(
                            label: _isTesting ? 'Awaiting Sensor Data...' : 'Select cow to test',
                            isLoading: _isTesting,
                            leadingIcon: const Icon(
                              Icons.biotech_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _isTesting ? null : _runDiagnosticTest,
                          ),
                          const SizedBox(height: 24),

                          // Section Header: "History"
                          const Text(
                            'History',
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 12),

                          // History ListView.builder (Limited to 5 most recent entries)
                          if (widget.cow.history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'No test history available',
                                  style: AppTypography.bodyRegular,
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppRadii.containerBorderRadius,
                                border: Border.all(
                                  color: AppColors.borderNeutral,
                                  width: 1.0,
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.cow.history.length > 5 ? 5 : widget.cow.history.length,
                                separatorBuilder: (context, index) => const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 1.0,
                                  thickness: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  final record = widget.cow.history[index];
                                  final Color statusColor = record.mastitisPresent
                                      ? AppColors.badgeAtRiskText
                                      : AppColors.badgeHealthyText;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 14.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          record.date,
                                          style: AppTypography.bodyRegular,
                                        ),
                                        Text(
                                          record.label,
                                          style: TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
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
}
