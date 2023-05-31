/*
Applicazione di controllo di un ESP32 tramite protocollo Bluetooth Low Energy (BLE)
Dev: Phoenix
TO DO: implementare disconnessione e verificare funzionamento con ESP
*/

import 'package:flutter/material.dart';
import'home.dart';
void main() {
  return runApp(
    const MaterialApp(home: HomePage()),
  );
}
