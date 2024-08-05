import 'dart:io';
import 'package:face_net_authentication/pages/widgets/BluetoothService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'sala_page.dart';
import 'cocina_page.dart';
import 'garage_page.dart';
import 'home.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';

class Profile extends StatefulWidget {
  const Profile(this.username, {Key? key, required this.imagePath})
      : super(key: key);
  final String username;
  final String imagePath;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late BluetoothService _bluetoothService;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BluetoothService();
    _bluetoothService.bluetoothStateStream.listen((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es', null);

    String formattedDate =
        DateFormat('d \'de\' MMMM \'del\' yyyy', 'es').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, // Desplazamiento vertical
          child: Container(
            color: Colors.black, // Fondo negro
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Desplazamiento horizontal
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width:
                            160, // Ajusta el ancho según el tamaño del avatar y el borde
                        height:
                            160, // Ajusta la altura según el tamaño del avatar y el borde
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF272727), // El color del borde
                            width: 10, // El grosor del borde
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 80, // Tamaño del avatar
                          backgroundImage: FileImage(File(widget.imagePath)),
                        ),
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${widget.username}',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildBluetoothControl(),
                _buildDeviceInfo(),
                _buildDeviceList(),
                SizedBox(height: 20),
                 SizedBox(height: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(Icons.meeting_room, 'SALA', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SalaPage()),
                      );
                    }),
                    _buildIconButton(Icons.kitchen, 'COCINA', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CocinaPage()),
                      );
                    }),
                    _buildIconButton(Icons.garage, 'GARAGE', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GaragePage()),
                      );
                    }),
                  ],
                ),
              ),
                AppButton(
                  text: "Salir",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  color: Color(0xFFFF6161),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothControl() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetoothService.bluetooth.requestEnable();
        } else {
          await _bluetoothService.bluetooth.requestDisable();
        }
        setState(() {
          _bluetoothState = value;
        });
      },
      tileColor: Colors.white,
      title: Text(
        _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return ListTile(
      tileColor: Colors.white,
      title: Text(
          "Conectado a: ${_bluetoothService.deviceConnected?.name ?? "ninguno"}"),
      trailing: _bluetoothService.connection?.isConnected ?? false
          ? TextButton(
              onPressed: () async {
                await _bluetoothService.disconnect();
                setState(() {
                  _deviceConnected = null;
                });
              },
              child: const Text("Desconectar"),
            )
          : TextButton(
              onPressed: () async {
                await _bluetoothService.getDevices();
                setState(() {
                  _devices = _bluetoothService.devices;
                });
              },
              child: const Text("Ver dispositivos"),
            ),
    );
  }

  Widget _buildDeviceList() {
    return _bluetoothService.isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  ...[
                    for (final device in _devices)
                      ListTile(
                        title: Text(device.name ?? device.address),
                        trailing: TextButton(
                          child: const Text('conectar'),
                          onPressed: () async {
                            await _bluetoothService.connectToDevice(device);
                            setState(() {
                              _deviceConnected =
                                  _bluetoothService.deviceConnected;
                              _devices = [];
                            });
                          },
                        ),
                      )
                  ]
                ],
              ),
            ),
          );
  }


  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 30, color: Colors.white),
          onPressed: onPressed,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}

