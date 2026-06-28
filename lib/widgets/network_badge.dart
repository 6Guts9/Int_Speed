import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';

class NetworkBadge extends StatefulWidget {
  const NetworkBadge({super.key});

  @override
  State<NetworkBadge> createState() => _NetworkBadgeState();
}

class _NetworkBadgeState extends State<NetworkBadge> {
  String _connectionType = 'Checking...';
  IconData _icon = Icons.wifi_rounded;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Listen for connection changes in real time
    Connectivity().onConnectivityChanged.listen(_updateFromResult);
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateFromResult(results);
  }

  void _updateFromResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return;
    
    final result = results.first;

    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionType = 'Wi-Fi';
          _icon = Icons.wifi_rounded;
          break;
        case ConnectivityResult.mobile:
          _connectionType = 'Cellular';
          _icon = Icons.signal_cellular_alt_rounded;
          break;
        case ConnectivityResult.ethernet:
          _connectionType = 'Ethernet';
          _icon = Icons.cable_rounded;
          break;
        default:
          _connectionType = 'No connection';
          _icon = Icons.wifi_off_rounded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfacelight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: AppTheme.accentBlue, size: 14),
          const SizedBox(width: 5),
          Text(
            _connectionType,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}