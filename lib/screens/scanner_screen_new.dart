import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../presentation/bloc/scan/scan_bloc.dart';
import '../presentation/bloc/scan/scan_event.dart';
import '../presentation/bloc/scan/scan_state.dart';

class ScannerScreenNew extends StatefulWidget {
  final dynamic race;

  const ScannerScreenNew({super.key, required this.race});

  @override
  State<ScannerScreenNew> createState() => _ScannerScreenNewState();
}

class _ScannerScreenNewState extends State<ScannerScreenNew> with TickerProviderStateMixin {
  MobileScannerController? _controller;
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
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.race.status != 'active') {
      return _buildRaceNotActiveView();
    }

    return BlocBuilder<ScanBloc, ScanState>(
      builder: (context, state) {
        return Stack(
          children: [
            _buildScannerView(),
            // Success message with animation
            if (state is ScanSuccess)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: ScaleTransition(
                  scale: _scanAnimation,
                  child: _buildScanOverlay(state.message),
                ),
              ),
            // Cooldown message
            if (state is ScanCooldown)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildCooldownOverlay(state.secondsRemaining),
              ),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
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
            // Scan area guide - centered in available space
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            _buildCorner(0, 0, true, true),
                            _buildCorner(0, null, true, false),
                            _buildCorner(null, 0, false, true),
                            _buildCorner(null, null, false, false),
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
              ),
            ),
            // Flash button
            Positioned(
              top: 16,
              right: 16,
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
      },
    );
  }

  Widget _buildCorner(double? top, double? bottom, bool isLeft, bool isTop) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: Colors.blue.shade400, width: 4) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: Colors.blue.shade400, width: 4) : BorderSide.none,
            left: isLeft ? BorderSide(color: Colors.blue.shade400, width: 4) : BorderSide.none,
            right: !isLeft ? BorderSide(color: Colors.blue.shade400, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isLeft && isTop ? const Radius.circular(8) : Radius.zero,
            topRight: !isLeft && isTop ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLeft && !isTop ? const Radius.circular(8) : Radius.zero,
            bottomRight: !isLeft && !isTop ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(String message) {
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
              message,
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
      // Parse QR data - expecting runner GUID format
      // Format: runner-guid or JSON with runner info
      String runnerId;
      String runnerName;
      
      if (qrData.contains('{')) {
        // JSON format - parse it
        // For now, just use the raw data
        runnerId = qrData;
        runnerName = 'Runner ${qrData.substring(0, 8)}';
      } else {
        // Plain GUID format
        runnerId = qrData;
        runnerName = 'Runner ${qrData.substring(0, 8)}';
      }

      debugPrint('📱 SCANNER: Scanned $runnerName ($runnerId)');

      // Record scan via BLoC
      if (mounted) {
        context.read<ScanBloc>().add(
          RecordScan(
            runnerId: runnerId,
            runnerName: runnerName,
            raceId: widget.race.id,
          ),
        );

        // Trigger success animation
        _scanAnimationController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('❌ SCANNER: Error processing scan - $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildCooldownOverlay(int seconds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade700.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'Wait ${seconds}s before scanning again',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
