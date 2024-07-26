import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  final StreamController<bool> _bluetoothStateController =
      StreamController<bool>.broadcast();
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;

  BluetoothService() {
    _initialize();
  }

  FlutterBluetoothSerial get bluetooth => _bluetooth;
  Stream<bool> get bluetoothStateStream => _bluetoothStateController.stream;
  bool get bluetoothState => _bluetoothState;
  bool get isConnecting => _isConnecting;
  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get deviceConnected => _deviceConnected;
  BluetoothConnection? get connection => _connection;

  Future<void> _initialize() async {
    await _requestPermission();

    _bluetooth.state.then((state) {
      _bluetoothState = state.isEnabled;
      _bluetoothStateController.add(_bluetoothState);
    });

    _bluetooth.onStateChanged().listen((state) {
      if (state == BluetoothState.STATE_OFF) {
        _bluetoothState = false;
      } else if (state == BluetoothState.STATE_ON) {
        _bluetoothState = true;
      }
      _bluetoothStateController.add(_bluetoothState);
    });
  }

  Future<void> _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  Future<void> getDevices() async {
    _devices = await _bluetooth.getBondedDevices();
  }

  void sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(utf8.encode(data));
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    _connection = await BluetoothConnection.toAddress(device.address);
    _deviceConnected = device;
    _devices = [];
    _isConnecting = false;
  }

  Future<void> disconnect() async {
    await _connection?.finish();
    _deviceConnected = null;
  }

  void dispose() {
    _bluetoothStateController.close();
  }
}
