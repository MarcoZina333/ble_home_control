 /*
Applicazione di controllo di un ESP32 tramite protocollo Bluetooth Low Energy (BLE)
Dev: Phoenix
*/


//librerie dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:ble_home_control/connection_status.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEController {

  static final BLEController _singleton = BLEController._();

  factory BLEController() => _singleton;

  BLEController._();


  BLEConnectionStatus _status = BLEConnectionStatus.unknown ;

  BLEConnectionStatus getStatus() => _status;


  // Bluetooth related variables
  late DiscoveredDevice _myDevice;

  //inizzializzo il singleton
  final _flutterReactiveBle = FlutterReactiveBle();
  
  late QualifiedCharacteristic _rxCharacteristic;
  
  // UUIDs of your device
  final Uuid _serviceUuid = Uuid.parse("d8c38db4-e40f-48e6-aac4-57e40b14d3c1");
  final Uuid _characteristicUuidTx = Uuid.parse("4e56b8c1-096c-4a58-97b8-0e262462b219");
  //final Uuid _characteristicUuidRx = Uuid.parse("2f6c1ff8-258c-4454-9269-25f1d9cb1309");

  // Metti il nome assegnato all'ESP
  static const String deviceName = "HomeControl0.1";

  

  Stream<BLEConnectionStatus> startScan() async* {
    // Gestione permessi per piattaforma
    bool permGranted = false;
    _status = BLEConnectionStatus.scanning;
    //yield _status;
    PermissionStatus locPermission;
    //PermissionStatus connPermission;
    if (Platform.isAndroid) {
      locPermission = await LocationPermissions().requestPermissions();
      if (locPermission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }
    // Logica di scan
    if (permGranted) {
      Stream<DiscoveredDevice> currentScanStream = _flutterReactiveBle
          .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
      await for (DiscoveredDevice device in currentScanStream)
          {
            yield _status;
            if (device.name == deviceName) {
              //print('trovato: ${device.name}');
              _myDevice = device;
              _status = BLEConnectionStatus.connecting;
              yield _status;
              break;
            }
          }
    }
  }

  Stream<BLEConnectionStatus> connectToDevice() async* {
    if (_status == BLEConnectionStatus.connecting) {
      // Let's listen to our connection so we can make updates on a state change
      Stream<ConnectionStateUpdate> currentConnectionStream = _flutterReactiveBle
        .connectToAdvertisingDevice(
            id: _myDevice.id,
            prescanDuration: const Duration(seconds: 5),
            withServices: [_serviceUuid]).asBroadcastStream();
      await for (ConnectionStateUpdate event in currentConnectionStream) {
        switch (event.connectionState) {
          // We're connected and good to go!
          case DeviceConnectionState.connected:
            {
              _rxCharacteristic = QualifiedCharacteristic(
              serviceId: _serviceUuid,
              characteristicId: _characteristicUuidTx,
              deviceId: event.deviceId);
              _status = BLEConnectionStatus.connected;
              break;
            }
          case DeviceConnectionState.disconnecting:
            {
              //_status = BLEConnectionStatus.unknown;
              break;
            }
          // Can add various state state updates on disconnect
          case DeviceConnectionState.disconnected:
            {
              _status = BLEConnectionStatus.scanfail;
              break;
            }
          default:
        }
        yield _status;
        if (event.connectionState == DeviceConnectionState.disconnected) {
          break;
        }
      }
    }
  }

  Stream<BLEConnectionStatus> scanAndConnectionStream() async* {
    await for (BLEConnectionStatus scanEvent in startScan()) {
      yield scanEvent;
      if (scanEvent == BLEConnectionStatus.connecting) {
        break;
      }
    }
    await for (BLEConnectionStatus connectEvent in connectToDevice()) {
      yield connectEvent;
      if (connectEvent == BLEConnectionStatus.unknown) {
      }
    }
  }





  void sendCommand(String command) {
    //per mandare stringhe serve codificarle come lista interi (ASCII)
    //verificare se usare write con o senza risposta
    if (_status == BLEConnectionStatus.connected) {
      /*
      parte messa un po' a caso che servirebbe per ricevere dati dal server
      final characteristic = QualifiedCharacteristic(serviceId: _serviceUuid, characteristicId: _characteristicUuidRx, deviceId: _myDevice.id);
      final response = await _flutterReactiveBle.readCharacteristic(characteristic);*/
      _flutterReactiveBle
          .writeCharacteristicWithoutResponse(_rxCharacteristic, value: 
        ascii.encode(command),
      );
    }
  }

  void disconnectDevice() {
    sendCommand("EXIT");
  }

  void manualLedValue(int value) {
    sendCommand("L?$value");
  }


  void powerOnLed() {
    sendCommand("L_DUCCIO");
  }


  void chillLedMode() {
    sendCommand("L_CHILL");
  }

  void powerOffLed() {
    sendCommand("L_OFF");
  }



}
 