import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/local_race.dart';
import '../widgets/confetti.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController? _controller;
  String? _lastScanMessage;
  Timer? _messageTimer;
  bool _isProcessing = false;
  bool _hasCameraError = false;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: true,
    );

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scanAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeOut),
    );
  }

  void _retryCamera() {
    setState(() => _hasCameraError = false);
    _controller?.dispose();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: true,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _messageTimer?.cancel();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.currentRaceId == null) {
          return _buildNoRaceView();
        }

        final race = appState.currentLocalRace;
        if (race == null) {
          return _buildNoRaceView();
        }

        if (race.status != 'active') {
          return _buildRaceNotActiveView(race);
        }

        return Stack(
          children: [
            _buildScannerView(appState),
            // Sync status indicator (subtle)
            if (appState.isConnectedToServer)
              Positioned(
                top: 8,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Syncing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoRaceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a Race First',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back and select a race to start scanning',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRaceNotActiveView(LocalRace race) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            race.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
            size: 100,
            color: race.isCompleted ? Colors.grey : Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            race.isCompleted ? 'Race Completed' : 'Race Not Started',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              race.isCompleted
                  ? 'This race has finished. View results in the Results tab.'
                  : 'Start the race from the race dashboard to begin scanning runners.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(AppState appState) {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_isProcessing) return;

            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!, appState);
                break;
              }
            }
          },
          errorBuilder: (context, error, child) {
            setState(() => _hasCameraError = true);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.errorCode?.name ?? 'Unknown error',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Scan overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
              radius: 1.5,
              center: const Alignment(0, -0.3),
            ),
          ),
        ),

        // Success message with animation
        if (_lastScanMessage != null)
          Positioned(
            top: 80,
            left: 24,
            right: 24,
            child: ScaleTransition(
              scale: _scanAnimation,
              child: _buildScanOverlay(),
            ),
          ),

        // Flash button
        Positioned(
          top: 60,
          right: 24,
          child: Builder(
            builder: (context) {
              final controller = _controller;
              final isEnabled = controller != null && !_hasCameraError;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: isEnabled ? () => controller.toggleTorch() : null,
                  iconSize: 28,
                ),
              );
            },
          ),
        ),

        // Scan area guide
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Corner accents
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.blue.shade400, width: 4),
                            left: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.blue.shade400, width: 4),
                            right: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.blue.shade400, width: 4),
                            left: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.blue.shade400, width: 4),
                            right: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Align QR code within frame',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade600.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastScanMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String qrData, AppState appState) async {
    setState(() => _isProcessing = true);

    try {
      // Parse QR data and record scan
      final runner = appState.parseRunnerQRCode(qrData);

      // Check if we can scan (10 second cooldown)
      if (!appState.canScanRunner(runner.id)) {
        final cooldown = appState.getCooldownSeconds(runner.id);
        _showMessage('Wait ${cooldown}s before scanning again');
        setState(() => _isProcessing = false);
        return;
      }

      // Record the scan
      await appState.recordScan(runner);

      // Show success message with animation
      _showMessage('✅ ${runner.name} - Lap ${appState.getLapNumber(runner.id)}');

      // Trigger confetti
      if (mounted) {
        showConfetti(context, particleCount: 80);
      }

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Speak the announcement
      appState.speakAnnouncement(runner.name, runner.id);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message) {
    setState(() => _lastScanMessage = message);
    _scanAnimationController.forward(from: 0);
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _lastScanMessage = null);
      }
    });
  }
}
