import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/confetti.dart';

class ScannerScreenNew extends StatefulWidget {
  final dynamic race;

  const ScannerScreenNew({super.key, required this.race});

  @override
  State<ScannerScreenNew> createState() => _ScannerScreenNewState();
}

class _ScannerScreenNewState extends State<ScannerScreenNew> {
  MobileScannerController? _controller;
  String? _lastScanMessage;
  Timer? _messageTimer;
  bool _isProcessing = false;
  bool _hasCameraError = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: true,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.race.status != 'active') {
      return _buildRaceNotActiveView();
    }

    return Stack(
      children: [
        _buildScannerView(),
        // Sync status indicator
        Positioned(
          top: 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('Syncing', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRaceNotActiveView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.race.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
            size: 100,
            color: widget.race.isCompleted ? Colors.grey : Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            widget.race.isCompleted ? 'Race Completed' : 'Race Not Started',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              widget.race.isCompleted
                  ? 'This race has finished. View results in the Results tab.'
                  : 'Start the race to begin scanning runners.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_isProcessing) return;

            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!);
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
                  const Icon(Icons.camera_alt, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Camera Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(error.errorCode?.name ?? 'Unknown error', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
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
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.blue.shade400, width: 4),
                            left: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.blue.shade400, width: 4),
                            right: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, left: 0,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.blue.shade400, width: 4),
                            left: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.blue.shade400, width: 4),
                            right: BorderSide(color: Colors.blue.shade400, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Align QR code within frame',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        // Success message
        if (_lastScanMessage != null)
          Positioned(
            top: 80,
            left: 24,
            right: 24,
            child: _buildScanOverlay(),
          ),
        // Flash button
        Positioned(
          top: 60,
          right: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Builder(
              builder: (context) {
                final controller = _controller;
                final isEnabled = controller != null && !_hasCameraError;
                return IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: isEnabled ? () => controller.toggleTorch() : null,
                  iconSize: 28,
                );
              },
            ),
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
            child: Text(
              _lastScanMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String qrData) async {
    setState(() => _isProcessing = true);

    try {
      // TODO: Parse QR and record scan
      // For now, just show success
      final runnerName = 'Runner ${qrData.substring(0, 8)}';
      _showMessage('✅ $runnerName - Lap 1');
      
      // Trigger confetti
      if (mounted) {
        showConfetti(context, particleCount: 80);
      }

      // Haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message) {
    setState(() => _lastScanMessage = message);
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _lastScanMessage = null);
      }
    });
  }
}
