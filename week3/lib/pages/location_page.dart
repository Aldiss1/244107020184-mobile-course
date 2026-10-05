import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Position? _currentPosition;
  String _statusMessage = 'Tekan tombol untuk mengambil lokasi';
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengecek izin lokasi...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Layanan lokasi (GPS) tidak aktif.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'Izin lokasi ditolak.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage =
              'Izin lokasi ditolak permanen. Silakan atur di Settings.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _statusMessage = 'Mengambil koordinat...');

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _statusMessage = 'Lokasi berhasil didapatkan!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mengambil lokasi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, size: 70, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_currentPosition != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('Latitude'),
                      subtitle: Text('${_currentPosition!.latitude}'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('Longitude'),
                      subtitle: Text('${_currentPosition!.longitude}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.gps_fixed),
              label: Text(_isLoading ? 'Memuat...' : 'Dapatkan Lokasi Saya'),
            ),
          ),
          if (_statusMessage.contains('ditolak') || _statusMessage.contains('denied')) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan Privasi Lokasi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
