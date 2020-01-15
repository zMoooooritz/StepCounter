
import 'package:flutter/material.dart';

enum ConnectionStatus {
  BluetoothOff,
  BluetoothOn,
  Connected,
  Unknown,
  Disconnected,
  DeviceFound,
  DeviceNotFound,
  None
}

extension ConnectionStatusExtension on ConnectionStatus {

  String get statusMessage {
    switch (this) {
      case ConnectionStatus.BluetoothOff:
        return 'Bluetooth Nicht Aktiv';
      case ConnectionStatus.BluetoothOn:
        return 'Bluetooth Aktiv';
      case ConnectionStatus.Connected:
        return 'Verbunden mit';
      case ConnectionStatus.Unknown:
        return 'Unbekannt';
      case ConnectionStatus.Disconnected:
        return 'Nicht Verbunden';
      case ConnectionStatus.DeviceFound:
        return 'Gerät Gefunden';
      case ConnectionStatus.DeviceNotFound:
        return 'Gerät Nicht Gefunden';
      case ConnectionStatus.None:
        return '';
      default:
        return '';
    }
  }

  Color get statusColor {
    switch (this) {
      case ConnectionStatus.BluetoothOff:
        return Colors.red[700];
      case ConnectionStatus.BluetoothOn:
        return Colors.green[400];
      case ConnectionStatus.Connected:
        return Colors.green[700];
      case ConnectionStatus.Unknown:
        return Colors.amber;
      case ConnectionStatus.Disconnected:
        return Colors.red[600];
      case ConnectionStatus.DeviceFound:
        return Colors.green[500];
      case ConnectionStatus.DeviceNotFound:
        return Colors.red[600];
      case ConnectionStatus.None:
        return Colors.grey[700];
      default:
        return Colors.grey[700];
    }
  }

}
