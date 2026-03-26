import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'hidtool.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HID support
  await Hid.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HID Device Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HidDeviceHomePage(),
    );
  }
}

class HidDeviceHomePage extends StatefulWidget {
  const HidDeviceHomePage({super.key});

  @override
  State<HidDeviceHomePage> createState() => _HidDeviceHomePageState();
}

class _HidDeviceHomePageState extends State<HidDeviceHomePage> {
  List<HidDevice> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  HidDevice? _selectedDevice;
  bool _deviceOpen = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devices = await Hid.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _openDevice(HidDevice device) async {
    try {
      await device.open();
      setState(() {
        _selectedDevice = device;
        _deviceOpen = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened: ${device.productName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _closeDevice() async {
    if (_selectedDevice != null) {
      try {
        await _selectedDevice!.close();
        setState(() {
          _selectedDevice = null;
          _deviceOpen = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Device closed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _sendTestReport() async {
    if (_selectedDevice == null || !_deviceOpen) return;

    try {
      final testData = Uint8List(64);
      await _selectedDevice!.sendReport(testData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('HID Device Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Refresh devices',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _devices.isEmpty
                ? const Center(child: Text('No HID devices found'))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = _selectedDevice == device;

                      return ListTile(
                        selected: isSelected,
                        title: Text(
                          device.productName.isNotEmpty
                              ? device.productName
                              : 'Unknown Device',
                        ),
                        subtitle: Text(
                          'VID: 0x${device.vendorId.toRadixString(16).padLeft(4, '0')}, '
                          'PID: 0x${device.productId.toRadixString(16).padLeft(4, '0')}\n'
                          'Serial: ${device.serialNumber}\n'
                          'Manufacturer: ${device.manufacturer}',
                        ),
                        onTap: () => setState(() {
                          _selectedDevice = device;
                        }),
                        trailing: isSelected && _deviceOpen
                            ? const Chip(label: Text('Open'))
                            : null,
                      );
                    },
                  ),
          ),

          if (_selectedDevice != null)
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Device: ${_selectedDevice!.productName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vendor ID: 0x${_selectedDevice!.vendorId.toRadixString(16).padLeft(4, '0')}',
                    ),
                    Text(
                      'Product ID: 0x${_selectedDevice!.productId.toRadixString(16).padLeft(4, '0')}',
                    ),
                    Text('Serial: ${_selectedDevice!.serialNumber}'),
                    Text(
                      'Usage Page: 0x${_selectedDevice!.usagePage.toRadixString(16)}',
                    ),
                    Text(
                      'Usage: 0x${_selectedDevice!.usage.toRadixString(16)}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _deviceOpen
                              ? _closeDevice
                              : () => _openDevice(_selectedDevice!),
                          child: Text(_deviceOpen ? 'Close' : 'Open'),
                        ),
                        ElevatedButton(
                          onPressed: _deviceOpen ? _sendTestReport : null,
                          child: const Text('Send Test Report'),
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

  @override
  void dispose() {
    if (_deviceOpen && _selectedDevice != null) {
      _selectedDevice!.close();
    }
    super.dispose();
  }
}
