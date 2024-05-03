import 'package:cloud_firestore/cloud_firestore.dart';

class Reserva {
  String id;
  DateTime date;
  DateTime dateArrive;
  DateTime dateOut;
  String model;
  String plate;
  String status;
  double total;
  String typeVehicle;
  String? nombreCliente;
  String? nombreParqueo;
  String? apellidoCliente;
  String? nombrePlaza;
  String? idCliente;
  String? idDuenio;
  String? idPlaza;

  Reserva({
    required this.id,
    required this.date,
    required this.dateArrive,
    required this.dateOut,
    required this.model,
    required this.plate,
    required this.status,
    required this.total,
    required this.typeVehicle,
    this.nombreCliente,
    this.nombreParqueo,
    this.apellidoCliente,
    this.nombrePlaza,
    this.idCliente,
    this.idDuenio,
    this.idPlaza,
  });
}
