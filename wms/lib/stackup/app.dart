import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'domain.dart';
import 'store.dart';
import 'importer.dart';

const teal = Color(0xff008c87);
const ink = Color(0xff142d3b);
void message(BuildContext context, Object text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$text'), behavior: SnackBarBehavior.floating),
    );
Future<bool> confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ??
    false;

class StackUpApp extends StatelessWidget {
  final WarehouseStore store;
  const StackUpApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StackUp',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff4f7f8),
      colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff4f7f8),
        foregroundColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    home: ListenableBuilder(
      listenable: store,
      builder: (_, _) =>
          store.role == null ? AccessPage(store: store) : Shell(store: store),
    ),
  );
}

class AccessPage extends StatefulWidget {
  final WarehouseStore store;
  const AccessPage({super.key, required this.store});
  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  final pin = TextEditingController(), repeat = TextEditingController();
  bool working = false;
  @override
  void dispose() {
    pin.dispose();
    repeat.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    setState(() => working = true);
    try {
      if (!widget.store.configured) {
        if (pin.text != repeat.text) {
          throw WarehouseError('Los PIN no coinciden.');
        }
        await widget.store.setup(pin.text);
      } else {
        widget.store.loginAdmin(pin.text);
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.inventory_2_outlined, color: teal, size: 68),
                const SizedBox(height: 12),
                const Text(
                  'StackUp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const Text(
                  'Cada caja, en su lugar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                const Notice(
                  'Prototipo local · datos ficticios iniciales.\nLos cambios se guardan en este teléfono. Sin sincronización Wi-Fi todavía.',
                ),
                const SizedBox(height: 20),
                if (!widget.store.configured)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Configura el acceso administrativo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextField(
                  controller: pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: widget.store.configured
                        ? 'PIN de administrador'
                        : 'Crea un PIN de 6 dígitos',
                  ),
                  onSubmitted: (_) {
                    if (widget.store.configured) enter();
                  },
                ),
                if (!widget.store.configured) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: repeat,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Repite el PIN',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: working ? null : enter,
                  child: Text(
                    widget.store.configured
                        ? 'Entrar como administrador'
                        : 'Crear PIN y comenzar',
                  ),
                ),
                if (widget.store.configured) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.store.loginWorker,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Entrar como trabajador'),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'El trabajador puede consultar y cuadrar cualquier vehículo. Administración requiere PIN. Acceso local de demostración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Shell extends StatefulWidget {
  final WarehouseStore store;
  const Shell({super.key, required this.store});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final admin = widget.store.admin;
    final pages = [
      Dashboard(store: widget.store),
      SearchPage(store: widget.store),
      RoutesPage(store: widget.store),
      if (admin) AdminPage(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          admin
              ? ['Inicio', 'Consultas', 'Rutas', 'Administración'][tab]
              : 'Rutas',
        ),
        actions: [
          Center(
            child: Text(
              admin ? 'Admin' : 'Trabajador',
              style: const TextStyle(color: teal),
            ),
          ),
          IconButton(
            tooltip: 'Cambiar usuario',
            onPressed: widget.store.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: admin
          ? IndexedStack(index: tab, children: pages)
          : RoutesPage(store: widget.store),
      bottomNavigationBar: !admin
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (v) => setState(() => tab = v),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Consultas',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  label: 'Rutas',
                ),
                if (admin)
                  const NavigationDestination(
                    icon: Icon(Icons.admin_panel_settings_outlined),
                    label: 'Admin',
                  ),
              ],
            ),
    );
  }
}

class Notice extends StatelessWidget {
  final String text;
  final bool warning;
  const Notice(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xfffff0dc) : const Color(0xffe4f3f3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xff805000) : const Color(0xff195b60),
      ),
    ),
  );
}

class Empty extends StatelessWidget {
  final String text;
  final IconData icon;
  const Empty(this.text, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.blueGrey),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class Ring extends StatelessWidget {
  final int value, total;
  final String label;
  final double size;
  const Ring({
    super.key,
    required this.value,
    required this.total,
    required this.label,
    this.size = 170,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : (value / total).clamp(0, 1),
                strokeWidth: size > 150 ? 15 : 10,
                backgroundColor: const Color(0xffe3e9e9),
                color: teal,
                strokeCap: StrokeCap.round,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: size > 150 ? 38 : 25,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    Text(
                      'de $total',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class Dashboard extends StatelessWidget {
  final WarehouseStore store;
  const Dashboard({super.key, required this.store});
  Widget metric(String text, int n, IconData icon) => ListTile(
    leading: Icon(icon, color: teal),
    title: Text(text),
    trailing: Text(
      '$n',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final w = store.data;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          w.reception,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Ring(
                  value: w.total('stored'),
                  total: w.total('expected'),
                  label: 'Recibidas pendientes de cuadre',
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final lot in [19, 22])
                      Ring(
                        value: w.total('stored', lot: lot),
                        total: w.total('expected', lot: lot),
                        label: 'Lote $lot',
                        size: 108,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              metric(
                'Esperadas según Excel',
                w.total('expected'),
                Icons.table_chart_outlined,
              ),
              metric(
                'Recibidas',
                w.total('received'),
                Icons.inventory_2_outlined,
              ),
              metric(
                'Sin recibir',
                w.total('expected') - w.total('received'),
                Icons.move_to_inbox_outlined,
              ),
              metric(
                'Verificadas para rutas',
                w.total('verified'),
                Icons.check_circle_outline,
              ),
              metric(
                'En revisión',
                w.total('review'),
                Icons.report_problem_outlined,
              ),
              metric(
                'Especiales recibidas',
                w.total('special'),
                Icons.view_in_ar_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        const Notice(
          'Los círculos aumentan al recibir y disminuyen al verificar para rutas. Revisión y especiales ya están incluidas. Cuadrar no confirma la salida del vehículo.',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SearchPage extends StatefulWidget {
  final WarehouseStore store;
  const SearchPage({super.key, required this.store});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  int? lot;
  @override
  Widget build(BuildContext context) {
    final list = widget.store.data.orders
        .where(
          (o) =>
              (lot == null || o.lot == lot) &&
              '${o.contact} ${o.guide} ${o.name}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Consejera, guía o nombre',
                ),
                onChanged: (v) => setState(() => query = v.trim()),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final l in <int?>[null, 19, 22])
                    ChoiceChip(
                      label: Text(l == null ? 'Todos' : 'Lote $l'),
                      selected: lot == l,
                      onSelected: (_) => setState(() => lot = l),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Empty('No hay pedidos con esos datos.', Icons.search_off)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (c, i) => OrderTile(
                    order: list[i],
                    onTap: () => openOrder(c, widget.store, list[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

class StatusCounts extends StatelessWidget {
  final Order order;
  const StatusCounts({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      if (order.awaiting > 0)
        badge(Colors.grey, '${order.awaiting} pendientes'),
      if (order.review > 0)
        badge(Colors.amber.shade800, '${order.review} en revisión'),
      if (order.verified > 0)
        badge(Colors.green.shade700, '${order.verified} verificadas'),
      if (order.expected > order.received)
        badge(
          Colors.blueGrey,
          '${order.expected - order.received} sin recibir',
        ),
    ],
  );
  Widget badge(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 9, color: color),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final bool verified, showLocations;
  const OrderTile({
    super.key,
    required this.order,
    required this.onTap,
    this.verified = false,
    this.showLocations = false,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      title: Text(
        '${order.contact} · Lote ${order.lot}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (!showLocations) Text('${order.name} · ${order.vehicle}'),
          if (showLocations) ...[
            Text(
              verified
                  ? '${order.verified} verificadas'
                  : '${order.pending} pendientes de cuadre',
            ),
            const SizedBox(height: 6),
            Text(
              order.locations.isEmpty
                  ? 'Sin ubicación registrada'
                  : order.locations.entries
                        .map(
                          (e) =>
                              '${e.key == "REVISION" ? "Administración" : e.key}: ${e.value}',
                        )
                        .join(' · '),
            ),
            const Text(
              'Ubicaciones de recepción',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ] else ...[
            const SizedBox(height: 8),
            StatusCounts(order: order),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

void openOrder(BuildContext context, WarehouseStore store, String id) =>
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPage(store: store, id: id),
      ),
    );

class OrderPage extends StatelessWidget {
  final WarehouseStore store;
  final String id;
  const OrderPage({super.key, required this.store, required this.id});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final matches = store.data.orders.where((o) => o.id == id);
      if (matches.isEmpty) {
        return Scaffold(
          appBar: AppBar(),
          body: const Empty(
            'Pedido fuera de la campaña actual.',
            Icons.info_outline,
          ),
        );
      }
      final o = matches.first;
      return Scaffold(
        appBar: AppBar(title: const Text('Ubicaciones del pedido')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              o.contact,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            Text(o.name, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Lote ${o.lot} · ${o.vehicle}\nGuía ${o.guide}'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  '${o.expected} esperadas · ${o.received} recibidas\n${o.verified} verificadas · ${o.pending} pendientes',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubicaciones de recepción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (o.locations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Todavía no se registran cajas de este pedido.'),
              ),
            for (final e in o.locations.entries)
              Card(
                child: ListTile(
                  leading: Icon(
                    e.key == 'REVISION'
                        ? Icons.warning_amber
                        : Icons.place_outlined,
                    color: teal,
                  ),
                  title: Text(
                    e.key == 'REVISION'
                        ? 'Administración · En revisión'
                        : e.key,
                  ),
                  trailing: Text('${e.value} cajas'),
                ),
              ),
            const SizedBox(height: 12),
            const Notice(
              'Ubicaciones registradas al recibir. Las cajas verificadas no se descuentan de una zona específica porque sus etiquetas son iguales. Buscar no modifica cantidades.',
            ),
            const SizedBox(height: 16),
            SelectableText('Código de prueba: ${o.barcode}'),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: o.barcode));
                message(context, 'Código copiado.');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código'),
            ),
            if (store.admin)
              OutlinedButton.icon(
                onPressed: () => moveDialog(context, store, o),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Corregir ubicación / revisión'),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> moveDialog(
  BuildContext context,
  WarehouseStore store,
  Order o,
) async {
  if (o.locations.isEmpty) {
    message(context, 'Primero registra la recepción.');
    return;
  }
  String from = o.locations.keys.first, to = 'REVISION';
  int quantity = 1;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: const Text('Corregir ubicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: from,
                decoration: const InputDecoration(labelText: 'Desde'),
                items: o.locations.keys
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
                onChanged: (v) => set(() => from = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: to,
                decoration: const InputDecoration(labelText: 'Hacia'),
                items: store.data.zones
                    .map(
                      (z) =>
                          DropdownMenuItem(value: z.code, child: Text(z.code)),
                    )
                    .toList(),
                onChanged: (v) => set(() => to = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                onChanged: (v) => quantity = int.tryParse(v) ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    try {
      await store.change(
        (w) => w.move(o.id, from, to, quantity),
        adminOnly: true,
      );
    } catch (e) {
      if (context.mounted) message(context, e);
    }
  }
}

class RoutesPage extends StatefulWidget {
  final WarehouseStore store;
  const RoutesPage({super.key, required this.store});
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  bool done = false;
  String search = '';
  @override
  Widget build(BuildContext context) {
    final w = widget.store.data;
    final routes = w.vehicles
        .where((v) => w.complete(v) == done && v.contains(search.toUpperCase()))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar vehículo',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v.trim()),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      'Pendientes (${w.vehicles.where((v) => !w.complete(v)).length})',
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      'Cuadradas (${w.vehicles.where(w.complete).length})',
                    ),
                  ),
                ],
                selected: {done},
                onSelectionChanged: (v) => setState(() => done = v.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: routes.isEmpty
              ? Empty(
                  done
                      ? 'Todavía no hay rutas cuadradas.'
                      : 'No hay rutas pendientes con ese filtro.',
                  Icons.local_shipping_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (c, i) {
                    final vehicle = routes[i];
                    final orders = w.route(vehicle);
                    final expected = orders.fold(0, (a, o) => a + o.expected);
                    return Card(
                      color: done ? const Color(0xffe6f5ec) : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: Icon(
                          done
                              ? Icons.check_circle
                              : Icons.local_shipping_outlined,
                          color: done ? Colors.green : teal,
                          size: 32,
                        ),
                        title: Text(
                          vehicle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${orders.length} pedidos · $expected cajas\n${done ? 'Cuadrada · consultar detalle' : 'Pendiente de cuadrar'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutePage(
                              store: widget.store,
                              vehicle: vehicle,
                            ),
                          ),
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

class RoutePage extends StatefulWidget {
  final WarehouseStore store;
  final String vehicle;
  const RoutePage({super.key, required this.store, required this.vehicle});
  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  bool verified = false;
  String query = "";
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final orders = widget.store.data.route(widget.vehicle);
      final expected = orders.fold(0, (a, o) => a + o.expected),
          count = orders.fold(0, (a, o) => a + o.verified);
      final list = orders
          .where(
            (o) =>
                (verified ? o.verified > 0 : o.pending > 0) &&
                '${o.contact} ${o.guide} ${o.name}'.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
      final done = widget.store.data.complete(widget.vehicle);
      return Scaffold(
        appBar: AppBar(title: Text(widget.vehicle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Notice(
                    done
                        ? '✓ Ruta cuadrada · $count de $expected cajas verificadas'
                        : '$expected cajas esperadas · $count verificadas · ${expected - count} pendientes',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('route-search'),
                    decoration: const InputDecoration(
                      hintText: 'Buscar consejera en este vehículo',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => query = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Pendientes')),
                      ButtonSegment(value: true, label: Text('Verificadas')),
                    ],
                    selected: {verified},
                    onSelectionChanged: (v) =>
                        setState(() => verified = v.first),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Empty(
                      verified
                          ? 'No hay verificadas que coincidan.'
                          : 'No hay pendientes que coincidan.',
                      Icons.inventory_2_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (c, i) => OrderTile(
                        order: list[i],
                        verified: verified,
                        showLocations: true,
                        onTap: () => openOrder(c, widget.store, list[i].id),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanPage(
                          store: widget.store,
                          vehicle: widget.vehicle,
                        ),
                      ),
                    ),
                    icon: Icon(
                      done ? Icons.fact_check_outlined : Icons.qr_code_scanner,
                    ),
                    label: Text(done ? 'Ver cuadre' : 'Cuadrar ruta'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class ScanPage extends StatefulWidget {
  final WarehouseStore store;
  final String? vehicle;
  const ScanPage({super.key, required this.store, this.vehicle});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final input = TextEditingController();
  final focus = FocusNode();
  String? zone;
  String feedback = 'Escanea el código de la primera zona.';
  bool failed = false;
  int queued = 0;
  Future<void> pipeline = Future.value();
  bool get receiving => widget.vehicle == null;
  @override
  void initState() {
    super.initState();
    if (!receiving) feedback = 'Escanea cada caja una sola vez.';
  }

  @override
  void dispose() {
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> scan(String raw) {
    final code = raw.trim();
    if (code.isEmpty) return Future.value();
    input.clear();
    focus.requestFocus();
    setState(() => queued++);
    // Procesa todas las lecturas en orden incluso si SQLite aún está guardando.
    pipeline = pipeline.then((_) => process(code)).whenComplete(() {
      if (mounted) setState(() => queued--);
    });
    return pipeline;
  }

  Future<void> process(String raw) async {
    if (!mounted) return;
    try {
      final w = widget.store.data;
      final code = raw.toUpperCase().replaceFirst(RegExp(r'^Z:'), '');
      if (receiving && w.zones.any((z) => z.code == code)) {
        if (!widget.store.admin) throw WarehouseError('Acceso restringido.');
        if (w.zoneFull(code)) {
          throw WarehouseError(
            'Zona $code completa (15/15). Escanea otra zona.',
          );
        }
        setState(() {
          zone = code;
          feedback = 'Zona $code lista. Escanea las cajas.';
          failed = false;
        });
      } else {
        String result = '';
        await widget.store.change((data) {
          if (receiving && zone == null) {
            throw WarehouseError(
              'Escanea primero el código de la siguiente zona.',
            );
          }
          final o = receiving
              ? data.receive(raw, zone!)
              : data.verify(raw, widget.vehicle!);
          result = receiving
              ? '✓ ${o.contact} · Lote ${o.lot}\n${o.received}/${o.expected} cajas recibidas del pedido'
              : '✓ ${o.contact} · ${o.verified}/${o.expected} verificadas';
        }, adminOnly: receiving);
        if (!mounted) return;
        setState(() {
          feedback = result;
          failed = false;
          if (receiving && zone != null && widget.store.data.zoneFull(zone!)) {
            feedback =
                '$result\nZona $zone completa: 15/15. Escanea la siguiente zona.';
            zone = null;
          }
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          failed = true;
          feedback = '$e';
        });
      }
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> camera() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );
    if (code != null && mounted) await scan(code);
    if (mounted) focus.requestFocus();
  }

  Future<void> undo() async {
    if (!await confirm(
      context,
      'Deshacer última lectura',
      'Se descontará la última lectura válida de ${receiving ? 'recepción' : 'esta ruta'}.',
    )) {
      return;
    }
    try {
      await widget.store.change(
        (w) =>
            w.undo(receiving ? 'receive' : 'verify', vehicle: widget.vehicle),
        adminOnly: receiving,
      );
      if (mounted) {
        setState(() {
          feedback =
              'Lectura deshecha.${receiving && zone == null ? ' Escanea la zona para continuar.' : ''}';
          failed = false;
        });
      }
    } catch (e) {
      if (mounted) message(context, e);
    }
    if (mounted) focus.requestFocus();
  }

  Future<void> chooseZone() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Elegir zona manualmente')),
            for (final z in widget.store.data.zones)
              ListTile(
                title: Text(z.code),
                subtitle: Text(
                  widget.store.data.zoneFull(z.code)
                      ? 'Completa'
                      : '${widget.store.data.zoneCount(z.code)} registradas',
                ),
                enabled: !widget.store.data.zoneFull(z.code),
                onTap: () => Navigator.pop(c, z.code),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) await scan('Z:$selected');
  }

  Future<void> example() async {
    final orders = receiving
        ? widget.store.data.orders
        : widget.store.data.route(widget.vehicle!);
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(c).height * .65,
          child: Column(
            children: [
              const ListTile(
                title: Text('Simular una lectura'),
                subtitle: Text('Cuenta como una caja en esta prueba.'),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final o in orders)
                      ListTile(
                        title: Text('${o.contact} · Lote ${o.lot}'),
                        subtitle: Text(
                          '${receiving ? o.received : o.verified}/${o.expected}',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(c, o.barcode),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (code != null && mounted) await scan(code);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      if (receiving && !widget.store.admin) {
        return const Scaffold(body: Empty('Acceso restringido.', Icons.lock));
      }
      final w = widget.store.data;
      final orders = receiving ? w.orders : w.route(widget.vehicle!);
      final expected = orders.fold(0, (n, o) => n + o.expected);
      final count = orders.fold(
        0,
        (n, o) => n + (receiving ? o.received : o.verified),
      );
      final complete = !receiving && w.complete(widget.vehicle!);
      final capacity = zone == null ? null : w.zoneCapacity(zone!);
      return PopScope(
        canPop: queued == 0,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              receiving ? 'Escanear recepción' : 'Cuadrar · ${widget.vehicle}',
            ),
            actions: [
              PopupMenuButton<String>(
                enabled: queued == 0,
                onSelected: (value) {
                  switch (value) {
                    case 'undo':
                      undo();
                    case 'zone':
                      chooseZone();
                    case 'demo':
                      example();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'undo',
                    child: Text('Deshacer última lectura'),
                  ),
                  if (receiving)
                    const PopupMenuItem(
                      value: 'zone',
                      child: Text('Elegir zona manualmente'),
                    ),
                  const PopupMenuItem(
                    value: 'demo',
                    child: Text('Simular una lectura'),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (receiving)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          zone == null
                              ? Icons.qr_code_scanner
                              : Icons.place_outlined,
                          color: teal,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          zone == null ? 'Esperando zona' : 'Zona $zone',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (zone != null)
                          Text(
                            '${w.zoneCount(zone!)}${capacity == null ? ' cajas · sin límite' : ' / $capacity cajas'}',
                            style: const TextStyle(fontSize: 22),
                          ),
                        if (zone != null && capacity != null) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: w.zoneCount(zone!) / capacity,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: complete ? const Color(0xffe6f5ec) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (complete)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 42,
                          ),
                        Text(
                          complete ? 'Ruta cuadrada' : '$count / $expected',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          complete
                              ? 'Todos los pedidos completos'
                              : 'Cajas verificadas',
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: expected == 0
                              ? 0
                              : (count / expected).clamp(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!complete) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('scanner-input'),
                  controller: input,
                  focusNode: focus,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: receiving && zone == null
                        ? 'Escanear código de zona'
                        : 'Escanear caja',
                    helperText:
                        'Lectura automática con Enter · sin confirmar cada caja',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.barcode_reader),
                    suffixIcon: IconButton(
                      tooltip: 'Leer con cámara',
                      onPressed: queued == 0 ? camera : null,
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: scan,
                ),
                const SizedBox(height: 16),
              ],
              Notice(feedback, warning: failed),
              if (queued > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Guardando $queued lectura(s)…'),
                ),
              const SizedBox(height: 16),
              if (receiving)
                Text(
                  'Campaña: $count de $expected cajas recibidas',
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              if (!receiving && !complete) ...[
                const Text(
                  'Pendientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                for (final o in orders.where((o) => o.pending > 0))
                  ListTile(
                    title: Text('${o.contact} · Lote ${o.lot}'),
                    subtitle: Text(
                      '${o.pending} pendientes${o.review > 0 ? ' · revisar Administración' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openOrder(context, widget.store, o.id),
                  ),
              ],
              if (complete)
                FilledButton(
                  onPressed: queued == 0 ? () => Navigator.pop(context) : null,
                  child: const Text('Finalizar'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final controller = MobileScannerController();
  bool captured = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Escanear una etiqueta'),
      actions: [
        IconButton(
          onPressed: controller.toggleTorch,
          icon: const Icon(Icons.flash_on),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Lee una caja y vuelve a captura. Para otra caja, abre la cámara de nuevo.',
          ),
        ),
        Expanded(
          child: MobileScanner(
            controller: controller,
            errorBuilder: (c, e) => const Empty(
              'No se pudo abrir la cámara. Revisa el permiso o usa la pistola en modo teclado.',
              Icons.no_photography_outlined,
            ),
            onDetect: (capture) {
              final codes = capture.barcodes.where(
                (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
              );
              if (!captured && codes.isNotEmpty) {
                captured = true;
                Navigator.pop(context, codes.first.rawValue);
              }
            },
          ),
        ),
      ],
    ),
  );
}

class AdminPage extends StatelessWidget {
  final WarehouseStore store;
  const AdminPage({super.key, required this.store});
  Future<void> importFile(BuildContext context, int lot) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw WarehouseError('No se pudo leer el archivo seleccionado.');
      }
      final orders = parseWorkbook(bytes, lot);
      if (!context.mounted) return;
      final expected = orders.fold(0, (a, o) => a + o.expected);
      if (!await confirm(
        context,
        'Importar lote $lot',
        '${result.files.single.name}\n${orders.length} pedidos · $expected cajas.\nSe reemplazarán los datos de este lote solo si aún no tiene escaneos.',
      )) {
        return;
      }
      await store.change((w) => w.importLot(orders, lot), adminOnly: true);
      if (context.mounted) message(context, 'Lote $lot importado.');
    } catch (e) {
      if (context.mounted) message(context, e);
    }
  }

  Future<void> newReception(BuildContext context) async {
    String name = '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nueva campaña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'La campaña actual se archivará en este teléfono. Luego podrás importar los dos Excel.',
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => name = v.trim(),
              decoration: const InputDecoration(
                labelText: 'Nombre de la campaña',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    if (name.isEmpty) {
      if (context.mounted) {
        message(context, 'Escribe un nombre para la recepción.');
      }
      return;
    }
    try {
      final next = Warehouse.empty()..reception = name;
      await store.reset(next);
    } catch (e) {
      if (context.mounted) message(context, e);
    }
  }

  Future<void> demo(BuildContext context, bool received) async {
    if (!await confirm(
      context,
      'Cargar demostración',
      'Se archivará la campaña actual. Se cargarán 350 cajas en 100 pedidos y 10 vehículos: 210 del lote 19 y 140 del lote 22, ${received ? 'con recepción registrada' : 'sin cajas recibidas'}. Cada vehículo tiene un solo lote.',
    )) {
      return;
    }
    try {
      await store.reset(Warehouse.demo(received: received));
    } catch (e) {
      if (context.mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!store.admin) return const Empty('Acceso restringido.', Icons.lock);
    final w = store.data;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Notice(
          'Prototipo local. El PIN restringe las acciones administrativas en este dispositivo. La autenticación y sincronización de servidor se implementarán en otra etapa.',
        ),
        const SizedBox(height: 16),
        Text(
          w.reception,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final lot in [19, 22])
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file, color: teal),
              title: Text('Importar Excel · Lote $lot'),
              subtitle: Text(
                '${w.orders.where((o) => o.lot == lot).length} pedidos · ${w.total('expected', lot: lot)} esperadas',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => importFile(context, lot),
            ),
          ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: teal),
            title: const Text('Registrar cajas'),
            subtitle: const Text('Selecciona zona y escanea las etiquetas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ScanPage(store: store)),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.grid_view, color: teal),
            title: const Text('Zonas'),
            subtitle: const Text(
              'Generales compartidas, especiales y revisión',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ZonesPage(store: store)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => newReception(context),
          icon: const Icon(Icons.add),
          label: const Text('Nueva campaña'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Herramientas de demostración',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () => demo(context, false),
          child: const Text('Demo desde cero: probar recepción'),
        ),
        TextButton(
          onPressed: () => demo(context, true),
          child: const Text('Demo recibida: probar rutas y cuadre'),
        ),
        const Notice(
          'Formato de código de prueba: consejeraFguía. También puedes escribir una guía o consejera si identifica un único pedido. Validar la etiqueta real antes de uso operativo.',
        ),
      ],
    );
  }
}

class ZonesPage extends StatelessWidget {
  final WarehouseStore store;
  const ZonesPage({super.key, required this.store});
  Future<void> add(BuildContext context) async {
    String code = '', kind = 'normal';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Nueva zona'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Código, por ejemplo A-09',
                ),
                onChanged: (v) => code = v.trim().toUpperCase(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kind,
                items: const [
                  DropdownMenuItem(
                    value: 'normal',
                    child: Text('General · ambos lotes'),
                  ),
                  DropdownMenuItem(
                    value: 'special',
                    child: Text('Cajas especiales'),
                  ),
                ],
                onChanged: (v) => set(() => kind = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await store.change((w) {
          if (!RegExp(r'^[A-Z][A-Z0-9-]{1,19}$').hasMatch(code) ||
              w.zones.any((z) => z.code == code)) {
            throw WarehouseError(
              'Código inválido o repetido. Usa letras, números y guion.',
            );
          }
          w.zones.add(Zone(code, kind: kind));
        }, adminOnly: true);
      } catch (e) {
        if (context.mounted) message(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Zonas'),
        actions: [
          IconButton(
            onPressed: () => add(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Notice(
            'Las zonas generales admiten ambos lotes: máximo 15 cajas entre los dos. Especiales y revisión no tienen límite. El código de una zona se puede leer como texto o como Z:A-01.',
          ),
          const SizedBox(height: 12),
          for (final z in store.data.zones)
            Card(
              child: ListTile(
                leading: Icon(
                  z.kind == 'review'
                      ? Icons.warning_amber
                      : Icons.place_outlined,
                  color: teal,
                ),
                title: Text(z.code),
                subtitle: Text(
                  z.kind == 'normal'
                      ? 'General · lotes 19 y 22'
                      : z.kind == 'special'
                      ? 'Cajas especiales'
                      : 'Administración · en revisión',
                ),
                trailing: Text(
                  '${store.data.orders.fold(0, (a, o) => a + (o.locations[z.code] ?? 0))} cajas',
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(z.code),
                    content: SelectableText(
                      'Código para etiqueta:\nZ:${z.code}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
