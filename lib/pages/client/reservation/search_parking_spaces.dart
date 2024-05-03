import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_project/models/to_use/parking.dart';
import 'package:parking_project/models/to_use/vehicle.dart';
import 'package:parking_project/pages/client/reservation/enable_place.dart';
import 'package:parking_project/services/temporal.dart';
import 'package:parking_project/utilities/toast.dart';

class ParkingSpaces extends StatefulWidget {
  final DataReservationSearch dataSearch;

  const ParkingSpaces({super.key, required this.dataSearch});

  @override
  State<ParkingSpaces> createState() => _ParkingSpacesState();
}

class _ParkingSpacesState extends State<ParkingSpaces> {
  TextEditingController fechaInicioController = TextEditingController();
  TextEditingController fechaFinController = TextEditingController();
  TextEditingController tarifaAutomovilController = TextEditingController();
  TextEditingController tarifaMotoController = TextEditingController();
  TextEditingController tarifaOtrosController = TextEditingController();
  TextEditingController totalController = TextEditingController();

  List<bool> vehiclesAllowed = [false, false, false];
  List<double> tarifaAutomovil = [0.0, 0.0];
  List<double> tarifaMoto = [0.0, 0.0];
  List<double> tarifaOtro = [0.0, 0.0];
  bool radioValue = false;
  String typeVehicle = "";
  String? url;
  String direccion = '';
  String nombreParqueo = '...';
  DateTime arriveDate = DateTime.now();
  DateTime exitDate = DateTime.now();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  String urlImage = "";

  List<DateTime?> selectedDate = [null, null];
  List<TimeOfDay?> selectedTime = [null, null];

//Para las dimenciones----------------------------------------------------------------------
  Map<String, dynamic> dimensiones = {};
  List<VehicleData> options = [];
  String? _selectedVehicle ;
  bool valiAuto = false;
  int tipomensaje = 1;
  //--------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    loadDataParqueo();
  }

  Future<void> loadDataParqueo() async {
    try {
      /*
            DocumentSnapshot<Map<String, dynamic>> parqueoDoc =
          await widget.dataSearch.idParqueo.get()
              as DocumentSnapshot<Map<String, dynamic>>;

      Map<String, dynamic> data = parqueoDoc.data() as Map<String, dynamic>;
       */
      DocumentSnapshot parqueoDoc = await widget.dataSearch.idParqueo.get();

      Map<String, dynamic> data = parqueoDoc.data() as Map<String, dynamic>;
      setState(() {
        radioValue = data['tieneCobertura'];
        vehiclesAllowed[0] = data['vehiculosPermitidos']['Motos'];
        vehiclesAllowed[1] = data['vehiculosPermitidos']['Autos'];
        vehiclesAllowed[2] = data['vehiculosPermitidos']['Otros'];
        urlImage = data['url'];

        tarifaAutomovil[0] = data['tarifaAutomovil']['Hora'].toDouble();
        tarifaAutomovil[1] = data['tarifaAutomovil']['Dia'].toDouble();
        tarifaAutomovilController.text = "Hora: " +
            tarifaAutomovil[0].toString() +
            "Bs / Dia: " +
            tarifaAutomovil[1].toString() +
            "Bs";

        tarifaMoto[0] = data['tarifaMoto']['Hora'].toDouble();
        tarifaMoto[1] = data['tarifaMoto']['Dia'].toDouble();
        tarifaMotoController.text = "Hora: " +
            tarifaMoto[0].toString() +
            "Bs / Dia: " +
            tarifaMoto[1].toString() +
            "Bs";

        tarifaOtro[0] = data['tarifaOtro']['Hora'].toDouble();
        tarifaOtro[1] = data['tarifaOtro']['Dia'].toDouble();
        tarifaOtrosController.text = "Hora: " +
            tarifaOtro[0].toString() +
            "Bs / Dia: " +
            tarifaOtro[1].toString() +
            "Bs";

        direccion = data['direccion'];
        nombreParqueo = data['nombre'];
        startDate = data['horaApertura'].toDate();
        endDate = data['horaCierre'].toDate();

        //reccuperar las dimenciones para poder comparar

         //-----------------------------------------------------------------------
         dimensiones['autoAltura'] = data['dimensiones']['autoAltura'];
         dimensiones['autoAncho'] = data['dimensiones']['autoAncho'];
         dimensiones['autoLargo'] = data['dimensiones']['autoLargo'];



         dimensiones['motoAltura'] = data['dimensiones']['motoAltura'];
         dimensiones['motoAncho'] = data['dimensiones']['motoAncho'];
         dimensiones['motoLargo'] = data['dimensiones']['motoLargo'];


          dimensiones['otroAltura'] = data['dimensiones']['otroAltura'];
          dimensiones['otroAncho'] = data['dimensiones']['otroAncho'];
          dimensiones['otroLargo'] = data['dimensiones']['otroLargo'];
          //------------------------------------------------------------------------------------
        //
      });
    } catch (e) {
      if (!context.mounted) return;
      Toast.show(context, e.toString());
    }
  }

  double getTotal() {
    // Segunda fecha

    // Restar las fechas para obtener la diferencia
    Duration diferencia = exitDate.difference(arriveDate);

    // Calcular la cantidad de días, horas y minutos
    int dias = diferencia.inDays;
    int horas = diferencia.inHours - (dias * 24);
    int minutos = diferencia.inMinutes - (dias * 24 * 60) - (horas * 60);
    double total = 0.0;
    if (typeVehicle == 'Automovil') {
      total = dias * tarifaAutomovil[1] +
          horas * tarifaAutomovil[0] +
          (tarifaAutomovil[0] * minutos / 60) +
          0.0;
    } else if (typeVehicle == 'Moto') {
      total = dias * tarifaMoto[1] +
          horas * tarifaMoto[0] +
          (tarifaMoto[0] * minutos / 60) +
          0.0;
    } else if (typeVehicle == 'Otro') {
      total = dias * tarifaOtro[1] +
          horas * tarifaOtro[0] +
          (tarifaOtro[0] * minutos / 60) +
          0.0;
    }
    return total;
  }

  Future<void> _selectDateAndTimeInitial(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate[0] ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 20)));
    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
          helpText: 'Seleccione la hora',
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(selectedDate[0] ?? DateTime.now()));
      if (pickedTime != null) {
        if (pickedTime.hour > startDate.hour &&
            pickedTime.hour < endDate.hour) {
          setState(() {
            selectedDate[0] = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            arriveDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            selectedTime[0] = pickedTime;
            if (exitDate.difference(arriveDate).inMinutes < 60) {
              fechaFinController.text = 'Selecciona Fecha y Hora';
              selectedDate[1] = null;
              totalController.text = "Total: 0.00 Bs";
              return;
            }
            if (fechaFinController.text != 'Selecciona Fecha y Hora') {
              totalController.text =
                  "Total: " + getTotal().toStringAsFixed(2) + " Bs";
            }
          });
        } else {
          if (!context.mounted) return;
          Toast.show(context, 'Horario no disponible');
        }
      }
    }
  }

  void updatePrice() {
    if (exitDate.difference(arriveDate).inMinutes < 0) {
      fechaFinController.text = 'Selecciona Fecha y Hora';
    }
    if (selectedDate[0] != null && selectedDate[1] != null) {
      totalController.text = "Total: " + getTotal().toStringAsFixed(2) + " Bs";
    }
  }

  Future<void> _selectDateAndTimeFinal(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      helpText: 'Seleccione una fecha',
      context: context,
      initialDate: selectedDate[0] ??
          DateTime.now().add(
            const Duration(hours: 1),
          ),
      firstDate: selectedDate[0] ??
          DateTime.now().add(
            const Duration(hours: 1),
          ),
      lastDate: selectedDate[0]?.add(
            const Duration(days: 20),
          ) ??
          DateTime.now().add(
            const Duration(days: 20),
          ),
    );
    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
          helpText: 'Seleccione la hora',
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(selectedDate[0] ?? DateTime.now()));
      if (pickedTime != null) {
        if (pickedTime.hour > startDate.hour &&
            pickedTime.hour < endDate.hour) {
          var ex = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (ex.difference(arriveDate).inMinutes < 60 &&
              pickedDate.day == selectedDate[0]!.day) {
            if (!context.mounted) return;
            Toast.show(context, 'Lapso de reserva minimo 1 hr');
            return;
          }
          if ((pickedTime.minute == 0 && pickedTime.hour == endDate.hour - 1) ||
              (pickedTime.hour != endDate.hour - 1)) {
            setState(() {
              selectedDate[1] = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              exitDate = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              selectedTime[1] = pickedTime;
              totalController.text =
                  "Total: " + getTotal().toStringAsFixed(2) + " Bs";
            });
          } else {
            if (!context.mounted) return;
            Toast.show(context, 'Limite de horario Excedido');
          }
        } else {
          if (!context.mounted) return;
          Toast.show(context, 'Horario no disponible');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        titleTextStyle: const TextStyle(
            fontSize: 25, color: Color.fromARGB(255, 7, 17, 128)),
        title: const Text(
          'Reserva',
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          iconSize: 30,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: <Widget>[
                      Image.network(
                        // url!,
                        urlImage,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4.0,
                          color: const Color.fromARGB(158, 245, 245, 245),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.all(16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombreParqueo,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 10.0),
                                    const Text(
                                      '5.0',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          direccion,
                                          style: const TextStyle(
                                            color:
                                                Color.fromARGB(255, 0, 0, 255),
                                          ),
                                        ),
                                        const Text(
                                          "-----------------------",
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 0, 0, 255),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
                height: 50.0), // Espacio entre el Card y el nuevo texto
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 14, left: 14),
              decoration: BoxDecoration(
                color: Colors.grey[300], // Color gris
                borderRadius: BorderRadius.circular(10.0), // Bordes redondeados
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(


                    'Seleccione su Vehículo',


                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Row(
                    children: [
                      Row(
                        children: <Widget>[
                          Radio(
                            value: 'Automovil',
                            groupValue: typeVehicle,
                            onChanged: (val) {
                              setState(() {
                                //------------------------------
                                updatePrice();
                                typeVehicle = val!;
                                updateList(typeVehicle);
                                valiAuto = false;
                                tipomensaje = 1;
                                //--------------------------------
                              });
                            },
                          ),
                          const Text('Automóvil'),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Radio(
                            value: 'Moto',
                            groupValue: typeVehicle,
                            onChanged: (value) {
                              setState(() {
                                //--------------------------------
                                typeVehicle = value!;
                                updatePrice();
                                updateList(typeVehicle);
                                valiAuto = false;
                                tipomensaje = 1;
                                //---------------------------------
                              });
                            },
                          ),
                          const Text('Moto'),
                        ],
                      ),



                      Row(
                        children: <Widget>[
                          Radio(
                            value: 'Otro',
                            groupValue: typeVehicle,
                            onChanged: (value) {
                              setState(() {
                                //---------------------------------------
                                typeVehicle = value!;
                                updatePrice();
                                updateList(typeVehicle);
                                valiAuto = false;
                                tipomensaje = 1;
                                //--------------------------------------------
                              });
                            },
                          ),
                          const Text('Otro'),
                        ],
                      ),
                    ],
                  ),
                








///--------------------------------------------------------------------------------------------------------
                 Column(
                      children: [
                      const Text(
                          'Vehículos Disponibles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10), // Espacio entre el título y el contenido
                        options.isEmpty
                            ? const Text('No hay vehículos disponibles')
                            : Column(
                                children: options.map((vehicle) {
                                  return RadioListTile<String>(
                                    title: Text("Placa: ${vehicle.placa} - Tipo: ${vehicle.tipo}"),
                                    value: vehicle.id,
                                    groupValue: _selectedVehicle,
                                    onChanged: (String? value) async {
                                      setState(() {
                                        _selectedVehicle = value;                                    
                                      });
                                         // Verifica las dimensiones del vehículo seleccionado
                                        bool isValid = await verificarDim(value!);

                                        if (isValid) {
                                          tipomensaje = 2; // Verdadero
                                        } else {
                                          tipomensaje = 3; // Falso
                                        }
                                        
                                         // Actualiza el estado nuevamente con el resultado de la verificación
                                        setState(() {
                                          valiAuto = isValid;
                                        });
                                    },
                                  );
                                }).toList(),
                              ),
                      ],
                    ),


                    Column(
                            children: [
                              // Aquí se mostrará este Text si el booleano es verdadero
                              if (tipomensaje == 1)
                                 const  Text(
                                  '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              

                              if (tipomensaje == 2)
                                const Text(
                                  'Su vehículo cumple perfectamente con las dimensiones requeridas para el tipo de vehículo seleccionado.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                     backgroundColor: Color.fromRGBO(9, 180, 29, 0.949) 
                                  ),
                                ),


                                if (tipomensaje == 3)
                                const Text(
                                  'Su vehículo no cumple con las dimensiones requeridas para el tipo de vehículo seleccionado.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    backgroundColor: Color.fromRGBO(221, 35, 2, 0.951)
                                  ),
                                ),
                            ],
                          )


    //-------------------------------------------------------------------------------------------------------------            

                ],
              ),
            ),




            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(220, 217, 217, 217),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tarifas",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: Text(
                      'Autos',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tarifaAutomovilController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            // Ajusta estos valores según tus necesidades
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: Text(
                      'Motos',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tarifaMotoController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            // Ajusta estos valores según tus necesidades
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: Text(
                      'Otros',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tarifaOtrosController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            // Ajusta estos valores según tus necesidades
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha Llegada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.only(top: 14, left: 14, bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.lightBlue, // Color del borde
                      width: 2.0, // Ancho del borde
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _selectDateAndTimeInitial(context),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today), // Ícono de calendario
                            const SizedBox(
                                width: 8), // Espacio entre el ícono y el texto
                            Text(
                              selectedDate[0] != null
                                  ? DateFormat('dd/MM/yyyy HH:mm')
                                      .format(selectedDate[0]!)
                                  : 'Selecciona Fecha y Hora',
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha Salida',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.only(top: 14, left: 14, bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.lightBlue, // Color del borde
                      width: 2.0, // Ancho del borde
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => {
                          if (selectedDate[0] != null)
                            {_selectDateAndTimeFinal(context)}
                          else
                            {
                              Toast.show(context,
                                  'Primero seleccione la fecha inicial')
                            }
                        },
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today), // Ícono de calendario
                            const SizedBox(
                                width: 8), // Espacio entre el ícono y el texto
                            Text(
                              selectedDate[1] != null
                                  ? DateFormat('dd/MM/yyyy HH:mm')
                                      .format(selectedDate[1]!)
                                  : 'Selecciona Fecha y Hora',
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: totalController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Total 0 Bs',
                hintStyle: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 18,
                ),
                filled: true,
                fillColor: const Color(0xFFE8ECF4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 30),


          //-------------------------------------------------------------------------------------------
           ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.only(left: 80, right: 80, top: 20, bottom: 20),
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(
                    valiAuto ? Colors.red[500]! : Colors.grey, // cambia el color del botón según el estado del booleano
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),

             
                onPressed: valiAuto
                    ? () async {
                        // código para ejecutar cuando el botón está habilitado
                        DataReservationSearch dataSearch = DataReservationSearch(
                          idParqueo: widget.dataSearch.idParqueo,
                          fechaInicio: Timestamp.fromDate(selectedDate[0]!),
                          fechaFin: Timestamp.fromDate(selectedDate[1]!),
                          tipoVehiculo: typeVehicle,
                          total: getTotal(),
                          idVehiculo: _selectedVehicle,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectSpaceScreen(dataSearch: dataSearch),
                          ),
                        );
                      }                     
                    : null,

                      child: const Text(
                          'Buscar',
                          style: TextStyle(fontSize: 20),
                        ), // establece null cuando el botón está deshabilitado
                      ),

                        ],
                      ),
                    ),
                  );
                }
                //-------------------------------------------------------------------------------------------



//-------------------------------------------------------------------------------------------------------------
 Future<bool> verificarDim(String vehicle) async {
  VehicleData? data = await getVehicleDataById(vehicle);
  if (data != null) {
    typeVehicle = data.tipo;
    double alto = data.alto;
    double ancho = data.ancho;
    double largo = data.largo;

    if (data.tipo == "Automovil") {
      return alto < dimensiones['autoAltura'] &&
          ancho < dimensiones['autoAncho'] &&
          largo < dimensiones['autoLargo'];
    } else if (data.tipo == "Moto") {
      return alto < dimensiones['motoAltura'] &&
          ancho < dimensiones['motoAncho'] &&
          largo < dimensiones['motoLargo'];
    } else {
      return alto < dimensiones['otroAltura'] &&
          ancho < dimensiones['otroAncho'] &&
          largo < dimensiones['otroLargo'];
    }
  } else {
    return false;
  }
}


  void updateList(String tipovalor) {
  // Llamar a getFilteredVehicles con el tipo de vehículo seleccionado
  getFilteredVehicles(tipovalor).then((filteredVehicles) {
    setState(() {
      // Actualizar la lista de opciones con los vehículos filtrados
      options = filteredVehicles;
    });
  });
}
//------------------------------------------------------------------------------------------------------------

}



