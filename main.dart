import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const iceBlue = Color(0xFF5EC8FF);
const deepBlue = Color(0xFF5B35C9);
const iceBlack = Color(0xFF07070A);
const bg = Color(0xFFF6F7FB);

const productCatalog = [
  'Granizado S',
  'Granizado M',
  'Granizado L',
  'Soda Italiana',
  'Soda Sencilla',
  'Cerveza Michelada',
  'Agua',
  'Corona',
  'Coronita',
  'Costeña',
  'Póker',
  'Promoción 2X1',
  'Gomas Enchiladas',
  'Botella Aguardiente',
  'Botella Ron',
  'Tequila',
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IcebangApp());
}

class Sale {
  final String id, description, payment;
  final DateTime date;
  final double amount;

  Sale({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.payment,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(),
    'description': description, 'amount': amount, 'payment': payment,
  };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'],
    date: DateTime.parse(j['date']),
    description: j['description'] ?? '',
    amount: (j['amount'] as num).toDouble(),
    payment: j['payment'] ?? 'Efectivo',
  );
}

class IcebangApp extends StatelessWidget {
  const IcebangApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Icebang',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: iceBlue),
      fontFamily: 'sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: iceBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: deepBlue, width: 2),
        ),
      ),
    ),
    home: const HomePage(),
  );
}

String money(double v) => NumberFormat.currency(
  locale: 'es_CO', symbol: r'$', decimalDigits: 0,
).format(v);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Sale> sales = [];
  bool loading = true;

  @override
  void initState() { super.initState(); loadSales(); }

  Future<void> loadSales() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('sales') ?? '[]';
    final data = (jsonDecode(raw) as List)
        .map((e) => Sale.fromJson(Map<String, dynamic>.from(e))).toList();
    data.sort((a,b) => b.date.compareTo(a.date));
    if (mounted) setState(() { sales = data; loading = false; });
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
  }

  Future<Set<String>> closedDays() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('closed_days') ?? []).toSet();
  }

  String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> closeToday() async {
    final closed = await closedDays();
    if (closed.contains(dayKey(DateTime.now()))) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El día de hoy ya está cerrado.')),
      );
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClosingPage(sales: today)),
    );
    if (ok == true) {
      final p = await SharedPreferences.getInstance();
      closed.add(dayKey(DateTime.now()));
      await p.setStringList('closed_days', closed.toList());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Día cerrado correctamente.')),
        );
      }
    }
  }

  List<Sale> get today => sales.where((s) => sameDay(s.date, DateTime.now())).toList();
  double total(Iterable<Sale> x) => x.fold(0, (a,s) => a + s.amount);
  double paymentTotal(String p) => total(today.where((s) => s.payment == p));

  Future<void> newSale() async {
    final s = await Navigator.push<Sale>(
      context, MaterialPageRoute(builder: (_) => const NewSalePage()),
    );
    if (s != null) { setState(() => sales.insert(0,s)); await persist(); }
  }

  Future<void> deleteSale(Sale s) async {
    setState(() => sales.removeWhere((x) => x.id == s.id));
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    final t = total(today);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          _Logo(size: 36), const SizedBox(width: 10),
          const Text('ICEBANG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: 1.1)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => HistoryPage(sales: sales))),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: loadSales,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text('¡Hola!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800, color: const Color(0xFF102A43))),
            const SizedBox(height: 2),
            Text('Aquí está el resumen de hoy',
              style: TextStyle(color: Colors.blueGrey.shade600)),
            const SizedBox(height: 16),
            _DatePill(date: DateTime.now()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [iceBlack, deepBlue, iceBlue]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                  color: iceBlue.withOpacity(.20), blurRadius: 18, offset: const Offset(0,8),
                )],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total vendido hoy', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Icon(Icons.trending_up_rounded, color: Colors.white.withOpacity(.9)),
                ]),
                const SizedBox(height: 6),
                Text(money(t), style: const TextStyle(
                  color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${today.length} ${today.length == 1 ? 'venta' : 'ventas'}',
                  style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PayCard('Efectivo', Icons.payments_outlined, paymentTotal('Efectivo'), const Color(0xFF13B981))),
              const SizedBox(width: 10),
              Expanded(child: _PayCard('Transferencia', Icons.swap_horiz_rounded, paymentTotal('Transferencia'), const Color(0xFF1479FF))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _PayCard('Tarjeta', Icons.credit_card_rounded, paymentTotal('Tarjeta'), const Color(0xFF7C3AED))),
              const SizedBox(width: 10),
              Expanded(child: _PayCard('Promedio', Icons.analytics_outlined,
                today.isEmpty ? 0 : t/today.length, const Color(0xFFF59E0B))),
            ]),
            const SizedBox(height: 16),
            SizedBox(height: 54, child: FilledButton.icon(
              onPressed: newSale,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar venta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: iceBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )),
            const SizedBox(height: 10),
            SizedBox(height: 50, child: OutlinedButton.icon(
              onPressed: closeToday,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Cierre del día', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: deepBlue,
                side: const BorderSide(color: iceBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Ventas de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${today.length}', style: TextStyle(color: Colors.blueGrey.shade600)),
            ]),
            const SizedBox(height: 8),
            if (today.isEmpty) _EmptyState()
            else ...today.map((s) => _SaleTile(
              sale: s, onDelete: () => deleteSale(s),
            )),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .24),
    child: Container(
      width: size,
      height: size,
      color: iceBlack,
      padding: EdgeInsets.all(size * .04),
      child: Image.asset(
        'assets/icebang_logo.jpg',
        fit: BoxFit.cover,
      ),
    ),
  );
}

class _DatePill extends StatelessWidget {
  final DateTime date;
  const _DatePill({required this.date});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.calendar_today_outlined, size: 18, color: iceBlue),
      const SizedBox(width: 10),
      Text(DateFormat("EEEE, d 'de' MMMM 'de' y", 'es_CO').format(date),
        style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}

class _PayCard extends StatelessWidget {
  final String title; final IconData icon; final double value; final Color accent;
  const _PayCard(this.title, this.icon, this.value, this.accent);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3EAF2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: accent.withOpacity(.11), shape: BoxShape.circle),
        child: Icon(icon, color: accent, size: 19),
      ),
      const SizedBox(height: 9),
      Text(title, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
      const SizedBox(height: 2),
      FittedBox(child: Text(money(value),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
    ]),
  );
}

class _SaleTile extends StatelessWidget {
  final Sale sale; final VoidCallback onDelete;
  const _SaleTile({required this.sale, required this.onDelete});
  Color get color => sale.payment == 'Efectivo'
      ? const Color(0xFF13B981) : sale.payment == 'Transferencia'
      ? iceBlue : const Color(0xFF7C3AED);

  @override Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: color.withOpacity(.10), shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_outlined, color: color),
      ),
      title: Text(sale.description.isEmpty ? 'Venta' : sale.description,
        style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${DateFormat('HH:mm').format(sale.date)} · ${sale.payment}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(money(sale.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20)),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: const Column(children: [
      Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF9FB3C8)),
      SizedBox(height: 8),
      Text('Aún no hay ventas', style: TextStyle(fontWeight: FontWeight.w700)),
      SizedBox(height: 4),
      Text('Registra tu primera venta del día.', textAlign: TextAlign.center,
        style: TextStyle(color: Colors.blueGrey)),
    ]),
  );
}

class NewSalePage extends StatefulWidget {
  const NewSalePage({super.key});
  @override State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  final amount = TextEditingController();
  String? selectedProduct;
  String payment = 'Efectivo';

  @override void dispose() { amount.dispose(); super.dispose(); }

  void save() {
    final value = double.tryParse(amount.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un valor de venta válido.')),
      );
      return;
    }
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto.')),
      );
      return;
    }
    Navigator.pop(context, Sale(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(), description: selectedProduct!,
      amount: value, payment: payment,
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nueva venta', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Registrar venta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('Selecciona un producto, ingresa el valor y guarda la venta.',
        style: TextStyle(color: Colors.blueGrey.shade600)),
      const SizedBox(height: 22),
      TextField(controller: amount, autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Valor de la venta *', prefixText: r'$ ',
          prefixIcon: Icon(Icons.attach_money_rounded))),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: selectedProduct,
        decoration: const InputDecoration(
          labelText: 'Producto *',
          prefixIcon: Icon(Icons.local_drink_outlined),
        ),
        items: productCatalog.map((p) => DropdownMenuItem(
          value: p,
          child: Text(p),
        )).toList(),
        onChanged: (v) => setState(() => selectedProduct = v),
      ),
      const SizedBox(height: 18),
      const Text('Forma de pago', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ...['Efectivo', 'Transferencia', 'Tarjeta'].map((p) => Card(
        elevation: 0, margin: const EdgeInsets.only(bottom: 7),
        color: Colors.white,
        child: RadioListTile<String>(
          value: p, groupValue: payment, onChanged: (v) => setState(() => payment = v!),
          title: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
          secondary: Icon(p == 'Efectivo' ? Icons.payments_outlined :
            p == 'Transferencia' ? Icons.swap_horiz_rounded : Icons.credit_card_rounded),
        ),
      )),
      const SizedBox(height: 14),
      SizedBox(height: 54, child: FilledButton.icon(
        onPressed: save, icon: const Icon(Icons.save_outlined),
        label: const Text('Guardar venta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: iceBlack,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      )),
    ]),
  );
}


class ClosingPage extends StatelessWidget {
  final List<Sale> sales;
  const ClosingPage({super.key, required this.sales});

  double total(String payment) =>
      sales.where((s) => s.payment == payment).fold(0, (a, s) => a + s.amount);

  @override
  Widget build(BuildContext context) {
    final totalDay = sales.fold(0.0, (a, s) => a + s.amount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre del día',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [iceBlack, deepBlue, iceBlue]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 58),
                const SizedBox(height: 12),
                const Text('¿Cerrar el día?',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text(
                  'Se guardará el resumen de ventas de hoy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(children: [
                    const Text('TOTAL DEL DÍA',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(money(totalDay),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${sales.length} ventas',
                        style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Resumen por forma de pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _CloseRow('Efectivo', total('Efectivo'), Icons.payments_outlined),
          _CloseRow('Transferencia', total('Transferencia'), Icons.swap_horiz_rounded),
          _CloseRow('Tarjeta', total('Tarjeta'), Icons.credit_card_rounded),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Cerrar día',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: iceBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseRow extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  const _CloseRow(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const Icon(Icons.circle, size: 10, color: iceBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Text(money(value),
          style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class HistoryPage extends StatelessWidget {
  final List<Sale> sales;
  const HistoryPage({super.key, required this.sales});

  @override Widget build(BuildContext context) {
    final groups = <String, List<Sale>>{};
    for (final s in sales) groups.putIfAbsent(DateFormat('yyyy-MM-dd').format(s.date), () => []).add(s);
    final keys = groups.keys.toList()..sort((a,b) => b.compareTo(a));
    return Scaffold(
      appBar: AppBar(title: const Text('Historial', style: TextStyle(fontWeight: FontWeight.w800))),
      body: keys.isEmpty ? const Center(child: Text('No hay ventas registradas.')) :
      ListView.builder(
        padding: const EdgeInsets.all(14), itemCount: keys.length,
        itemBuilder: (_, i) {
          final list = groups[keys[i]]!;
          final date = DateTime.parse(keys[i]);
          return Card(
            elevation: 0, margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text(DateFormat("d 'de' MMMM 'de' y", 'es_CO').format(date),
                style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${list.length} ventas'),
              trailing: Text(money(list.fold(0, (x,s) => x+s.amount)),
                style: const TextStyle(fontWeight: FontWeight.w900)),
              children: list.map((s) => ListTile(
                title: Text(s.description.isEmpty ? 'Venta' : s.description),
                subtitle: Text('${DateFormat('HH:mm').format(s.date)} · ${s.payment}'),
                trailing: Text(money(s.amount)),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}
