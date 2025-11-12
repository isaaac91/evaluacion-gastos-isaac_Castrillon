import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'package:uuid/uuid.dart'; 
import 'dart:collection'; 


class Gasto {
  String id;
  String descripcion;
  double monto;
  String categoria;
  DateTime fecha;

  Gasto({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.categoria,
    required this.fecha,
  });
}


const List<String> categorias = [
  'Comida',
  'Transporte',
  'Entretenimiento',
  'Salud',
  'Educación',
  'Hogar',
  'Otros',
];


const Map<String, IconData> categoriaIconos = {
  'Comida': Icons.fastfood,
  'Transporte': Icons.directions_car,
  'Entretenimiento': Icons.movie,
  'Salud': Icons.local_hospital,
  'Educación': Icons.school,
  'Hogar': Icons.home,
  'Otros': Icons.category,
};

class GastosProvider extends ChangeNotifier {
  final List<Gasto> _gastos = [];

  String _filtroCategoria = 'Todas';

  List<Gasto> get gastosFiltrados {
    if (_filtroCategoria == 'Todas') {
      return UnmodifiableListView(_gastos);
    }
    return UnmodifiableListView(
        _gastos.where((g) => g.categoria == _filtroCategoria).toList());
  }

  String get filtroCategoria => _filtroCategoria;

  double get totalMesActual {
    final ahora = DateTime.now();
    return _gastos
        .where((g) =>
            g.fecha.month == ahora.month && g.fecha.year == ahora.year)
        .fold(0.0, (sum, g) => sum + g.monto);
  }

  Map<String, double> get desgloseCategoriasMesActual {
    final ahora = DateTime.now();
    final gastosMes = _gastos.where(
        (g) => g.fecha.month == ahora.month && g.fecha.year == ahora.year);

    final mapa = <String, double>{};
    for (var g in gastosMes) {
      mapa.update(g.categoria, (valor) => valor + g.monto,
          ifAbsent: () => g.monto);
    }
    return mapa;
  }

  void agregarGasto(Gasto gasto) {
    _gastos.add(gasto);
    _ordenarGastos();
    notifyListeners();
  }

  void editarGasto(Gasto gastoActualizado) {
    final index =
        _gastos.indexWhere((g) => g.id == gastoActualizado.id);
    if (index != -1) {
      _gastos[index] = gastoActualizado;
      _ordenarGastos();
      notifyListeners();
    }
  }

  void eliminarGasto(String id) {
    _gastos.removeWhere((g) => g.id == id);
    notifyListeners();
  }


  void cambiarFiltro(String nuevaCategoria) {
    _filtroCategoria = nuevaCategoria;
    notifyListeners();
  }


  void _ordenarGastos() {
    _gastos.sort((a, b) => b.fecha.compareTo(a.fecha));
  }
}


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GastosProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Gastos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),

      debugShowCheckedModeBanner: false,
      home: const PantallaNavegacion(),
    );
  }
}


class PantallaNavegacion extends StatefulWidget {
  const PantallaNavegacion({super.key});

  @override
  State<PantallaNavegacion> createState() => _PantallaNavegacionState();
}

class _PantallaNavegacionState extends State<PantallaNavegacion> {
  int _indiceSeleccionado = 0;


  static const List<Widget> _pantallas = <Widget>[
    PantallaPrincipal(),
    PantallaResumen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_indiceSeleccionado == 0
            ? 'Mis Gastos'
            : 'Resumen Mensual'),
      ),
      body: Center(
        child: _pantallas.elementAt(_indiceSeleccionado),
      ),

      floatingActionButton: _indiceSeleccionado == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaFormularioGasto(),
                  ),
                );
              },
              tooltip: 'Agregar Gasto',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Resumen',
          ),
        ],
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<GastosProvider>();

    final fMoneda = NumberFormat.currency(locale: 'es_VE', symbol: 'Bs');

    final List<String> categoriasFiltro = ['Todas', ...categorias];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtrar por:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.filtroCategoria,
                    items: categoriasFiltro.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (String? nuevoValor) {
                      if (nuevoValor != null) {

                        context
                            .read<GastosProvider>()
                            .cambiarFiltro(nuevoValor);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total del Mes:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        fMoneda.format(provider.totalMesActual),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: provider.gastosFiltrados.isEmpty
              ? const Center(
                  child: Text(
                    'No hay gastos registrados.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: provider.gastosFiltrados.length,
                  itemBuilder: (context, index) {
                    final gasto = provider.gastosFiltrados[index];
                    return Dismissible(
                      key: Key(gasto.id),
                      direction: DismissDirection.endToStart,

                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar'),
                              content: const Text(
                                  '¿Estás seguro de que deseas eliminar este gasto?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      onDismissed: (direction) {
                        context.read<GastosProvider>().eliminarGasto(gasto.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gasto eliminado')),
                        );
                      },

                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              categoriaIconos[gasto.categoria] ??
                                  Icons.category,
                            ),
                          ),
                          title: Text(gasto.descripcion),
                          subtitle: Text(
                              '${gasto.categoria} - ${DateFormat('dd/MM/yyyy').format(gasto.fecha)}'),
                          trailing: Text(
                            fMoneda.format(gasto.monto),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PantallaFormularioGasto(gasto: gasto),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}


class PantallaResumen extends StatelessWidget {
  const PantallaResumen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastosProvider>();
    final desglose = provider.desgloseCategoriasMesActual;
    final fMoneda = NumberFormat.currency(locale: 'es_VE', symbol: 'Bs ');
    final desgloseOrdenado = desglose.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Total Gastado este Mes',
                      style:
                          TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fMoneda.format(provider.totalMesActual),
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Desglose por Categoría',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: desgloseOrdenado.isEmpty
                ? const Center(
                    child: Text(
                      'No hay gastos este mes.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: desgloseOrdenado.length,
                    itemBuilder: (context, index) {
                      final item = desgloseOrdenado[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(
                            categoriaIconos[item.key] ?? Icons.category,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(item.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(
                            fMoneda.format(item.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class PantallaFormularioGasto extends StatefulWidget {

  final Gasto? gasto;
  const PantallaFormularioGasto({super.key, this.gasto});

  @override
  State<PantallaFormularioGasto> createState() =>
      _PantallaFormularioGastoState();
}

class _PantallaFormularioGastoState extends State<PantallaFormularioGasto> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  late String _categoriaSeleccionada;
  late DateTime _fechaSeleccionada;
  late bool _esEdicion;

  @override
  void initState() {
    super.initState();

    _esEdicion = widget.gasto != null;
    _descripcionController =
        TextEditingController(text: _esEdicion ? widget.gasto!.descripcion : '');
    _montoController = TextEditingController(
        text: _esEdicion ? widget.gasto!.monto.toString() : '');
    _categoriaSeleccionada =
        _esEdicion ? widget.gasto!.categoria : categorias[0];
    _fechaSeleccionada = _esEdicion ? widget.gasto!.fecha : DateTime.now();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)), 
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  void _guardarGasto() {
    if (_formKey.currentState!.validate()) {
      final monto = double.tryParse(_montoController.text);
      if (monto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, ingresa un monto válido.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      final provider = context.read<GastosProvider>();

      if (_esEdicion) {
        final gastoActualizado = Gasto(
          id: widget.gasto!.id,
          descripcion: _descripcionController.text,
          monto: monto,
          categoria: _categoriaSeleccionada,
          fecha: _fechaSeleccionada,
        );
        provider.editarGasto(gastoActualizado);
      } else {
        final nuevoGasto = Gasto(
          id: const Uuid().v4(), 
          descripcion: _descripcionController.text,
          monto: monto,
          categoria: _categoriaSeleccionada,
          fecha: _fechaSeleccionada,
        );
        provider.agregarGasto(nuevoGasto);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Gasto' : 'Agregar Gasto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( 
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  icon: Icon(Icons.description),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  icon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un monto.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'El monto debe ser mayor a cero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  icon: Icon(Icons.category),
                ),
                items: categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _categoriaSeleccionada = nuevoValor!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _seleccionarFecha(context),
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),

                  ElevatedButton(
                    onPressed: _guardarGasto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}