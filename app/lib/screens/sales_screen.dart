import 'package:flutter/material.dart';
import 'models.dart';
import '../services/inventory_service.dart';

const _navy = Color(0xFF2B4479);
const _gold = Color(0xFFB8860B);

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Acompanhamento das vendas feitas pelo caixa do site.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _days = 1;
  late Stream<List<Sale>> _stream = _watch();

  // Busca o período atual + o anterior, para comparar.
  Stream<List<Sale>> _watch() => InventoryService.watchSales(
    _startOfDay(DateTime.now()).subtract(Duration(days: _days * 2 - 1)),
  );

  void _setDays(int days) {
    setState(() {
      _days = days;
      _stream = _watch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Vendas"),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 1,
      ),
      body: StreamBuilder<List<Sale>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Não foi possível carregar as vendas.\nVerifique sua conexão.",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildReport(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildReport(List<Sale> sales) {
    final now = DateTime.now();
    final currentStart = _startOfDay(now).subtract(Duration(days: _days - 1));
    final previousStart = currentStart.subtract(Duration(days: _days));
    final previousEnd = now.subtract(Duration(days: _days));

    final done = sales.where((s) => !s.cancelled && s.createdAt != null);
    final current = done
        .where((s) => !s.createdAt!.isBefore(currentStart))
        .toList();
    final previous = done
        .where(
          (s) =>
              !s.createdAt!.isBefore(previousStart) &&
              !s.createdAt!.isAfter(previousEnd),
        )
        .toList();

    double revenueOf(Iterable<Sale> list) =>
        list.fold(0.0, (total, s) => total + s.total);
    final revenue = revenueOf(current);
    final previousRevenue = revenueOf(previous);
    final items = current.fold(0, (n, s) => n + s.itemCount);
    final ticket = current.isEmpty ? 0.0 : revenue / current.length;

    final compareLabel = _days == 1
        ? "ontem até esta hora"
        : "período anterior";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text("Hoje")),
            ButtonSegment(value: 7, label: Text("7 dias")),
            ButtonSegment(value: 30, label: Text("30 dias")),
          ],
          selected: {_days},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _setDays(s.first),
        ),
        const SizedBox(height: 16),

        // ----- Resumo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Faturamento",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(revenue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _changeText(revenue, previousRevenue, compareLabel),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _heroStat("Vendas", current.length.toString()),
                  _heroStat("Ticket médio", formatMoney(ticket)),
                  _heroStat("Itens", items.toString()),
                ],
              ),
            ],
          ),
        ),

        if (current.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              "Nenhuma venda nesse período ainda.\nAs vendas são registradas pelo caixa do site.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        else ...[
          _section(
            _days == 1 ? "Por hora" : "Por dia",
            _BarChart(bars: _timeline(current, currentStart)),
          ),
          _section("Mais vendidos", _ranking(_topProducts(current))),
          _section("Formas de pagamento", _ranking(_payments(current))),
          _section("Últimas vendas", _recentSales(sales)),
        ],
      ],
    );
  }

  String _changeText(double now, double before, String label) {
    if (before == 0) {
      return now > 0 ? "Sem vendas em $label" : "—";
    }
    final pct = ((now - before) / before * 100).round();
    if (pct == 0) return "Igual a $label";
    return "${pct > 0 ? '▲' : '▼'} ${pct.abs()}% vs. $label";
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  List<_Bar> _timeline(List<Sale> current, DateTime currentStart) {
    if (_days == 1) {
      return List.generate(24, (h) {
        final inHour = current.where((s) => s.createdAt!.hour == h);
        return _Bar(
          label: h % 3 == 0 ? "${h}h" : "",
          tooltip:
              "${h}h às ${h + 1}h\n${formatMoney(inHour.fold(0.0, (t, s) => t + s.total))} · ${_plural(inHour.length, 'venda', 'vendas')}",
          value: inHour.fold(0.0, (t, s) => t + s.total),
        );
      });
    }
    final every = _days > 7 ? 5 : 1;
    return List.generate(_days, (i) {
      final day = currentStart.add(Duration(days: i));
      final inDay = current.where((s) => _startOfDay(s.createdAt!) == day);
      final value = inDay.fold(0.0, (t, s) => t + s.total);
      return _Bar(
        label: i % every == 0 ? "${_two(day.day)}/${_two(day.month)}" : "",
        tooltip:
            "${_two(day.day)}/${_two(day.month)}\n${formatMoney(value)} · ${_plural(inDay.length, 'venda', 'vendas')}",
        value: value,
      );
    });
  }

  List<_Rank> _topProducts(List<Sale> current) {
    final byProduct = <String, _Rank>{};
    for (final sale in current) {
      for (final item in sale.items) {
        final entry = byProduct.putIfAbsent(
          item.productId,
          () => _Rank(label: item.name),
        );
        entry.value += item.subtotal;
        entry.count += item.quantity;
      }
    }
    final list = byProduct.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final r in list) {
      r.detail = "${r.count} un.";
    }
    return list.take(5).toList();
  }

  List<_Rank> _payments(List<Sale> current) {
    final list =
        Sale.paymentLabels.entries
            .map((e) {
              final ofMethod = current.where((s) => s.payment == e.key);
              return _Rank(label: e.value)
                ..value = ofMethod.fold(0.0, (t, s) => t + s.total)
                ..detail = _plural(ofMethod.length, 'venda', 'vendas');
            })
            .where((r) => r.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _ranking(List<_Rank> rows) {
    final max = rows.fold(0.0, (m, r) => r.value > m ? r.value : m);
    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        formatMoney(r.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "  ${r.detail}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max > 0 ? r.value / max : 0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0F2F6),
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _recentSales(List<Sale> sales) {
    final current = sales.where((s) => s.createdAt != null).take(15);
    return Column(
      children: current.map((s) {
        final t = s.createdAt!;
        final when = _days == 1
            ? "${_two(t.hour)}:${_two(t.minute)}"
            : "${_two(t.day)}/${_two(t.month)} ${_two(t.hour)}:${_two(t.minute)}";
        final style = TextStyle(
          decoration: s.cancelled ? TextDecoration.lineThrough : null,
          color: s.cancelled ? Colors.grey : null,
        );
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            s.items.map((i) => "${i.quantity}× ${i.name}").join(", "),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
          subtitle: Text(
            s.cancelled
                ? "$when · ${s.paymentLabel} · Cancelada"
                : "$when · ${s.paymentLabel}",
          ),
          trailing: Text(
            formatMoney(s.total),
            style: style.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}

class _Bar {
  final String label;
  final String tooltip;
  final double value;

  _Bar({required this.label, required this.tooltip, required this.value});
}

class _Rank {
  final String label;
  double value = 0;
  int count = 0;
  String detail = "";

  _Rank({required this.label});
}

/// Colunas simples de uma série; toque numa coluna para ver o valor.
class _BarChart extends StatelessWidget {
  final List<_Bar> bars;

  const _BarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final max = bars.fold(0.0, (m, b) => b.value > m ? b.value : m);
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars
                .map(
                  (b) => Expanded(
                    child: Tooltip(
                      message: b.tooltip,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Container(
                        // área de toque maior que a barra
                        color: Colors.transparent,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FractionallySizedBox(
                          heightFactor: max > 0 ? b.value / max : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: b.value == max && max > 0 ? _gold : _navy,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 4),
        Row(
          children: bars
              .map(
                (b) => Expanded(
                  child: Text(
                    b.label,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        const Text(
          "Toque numa coluna para ver o valor. Em dourado, o melhor resultado.",
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
