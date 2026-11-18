import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useData, useMovementsSince, useSales } from '../DataContext';
import {
  ColumnChart,
  LineChart,
  PairBars,
  RankBars,
  type BarDatum,
  type PairDatum,
  type RankDatum,
} from '../components/Charts';
import {
  formatMoney,
  isLowStock,
  paymentLabels,
  type Movement,
  type PaymentMethod,
  type Sale,
} from '../types';

const periods = [
  { days: 1, label: 'Hoje', compare: 'ontem até esta hora' },
  { days: 7, label: 'Últimos 7 dias', compare: 'os 7 dias anteriores' },
  { days: 30, label: 'Últimos 30 dias', compare: 'os 30 dias anteriores' },
];

const tabs = [
  { id: 'vendas', label: 'Vendas' },
  { id: 'estoque', label: 'Estoque' },
  { id: 'estoque-vendas', label: 'Estoque x Vendas' },
] as const;

type TabId = (typeof tabs)[number]['id'];

const DAY = 24 * 60 * 60 * 1000;
const weekday = new Intl.DateTimeFormat('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' });
const shortDate = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit' });

const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;
const units = (n: number) => plural(n, 'unidade', 'unidades');

function startOfDay(date: Date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

// Intervalos do gráfico de tempo: horas de hoje ou dias do período.
function buckets(days: number, currentStart: Date) {
  if (days === 1) {
    return Array.from({ length: 24 }, (_, h) => {
      const start = new Date(currentStart.getTime() + h * 60 * 60 * 1000);
      return { start, end: new Date(start.getTime() + 60 * 60 * 1000), label: `${h}h`, title: `${h}h às ${h + 1}h` };
    });
  }
  return Array.from({ length: days }, (_, i) => {
    const start = new Date(currentStart.getTime() + i * DAY);
    return { start, end: new Date(start.getTime() + DAY), label: shortDate.format(start), title: weekday.format(start) };
  });
}

function summarize(sales: Sale[]) {
  const revenue = sales.reduce((sum, s) => sum + s.total, 0);
  const items = sales.reduce((sum, s) => sum + s.items.reduce((n, i) => n + i.quantity, 0), 0);
  return { revenue, count: sales.length, ticket: sales.length ? revenue / sales.length : 0, items };
}

function Change({ now, before }: { now: number; before: number }) {
  if (before === 0) {
    return <span className="change neutral">{now > 0 ? 'Sem vendas no período anterior' : '—'}</span>;
  }
  const pct = Math.round(((now - before) / before) * 100);
  if (pct === 0) return <span className="change neutral">Igual ao período anterior</span>;
  return (
    <span className={pct > 0 ? 'change up' : 'change down'}>
      {pct > 0 ? '▲' : '▼'} {Math.abs(pct)}% vs. período anterior
    </span>
  );
}

export default function Relatorios() {
  const [params, setParams] = useSearchParams();
  const tab: TabId = tabs.find((t) => t.id === params.get('aba'))?.id ?? 'vendas';
  const [days, setDays] = useState(7);
  const period = periods.find((p) => p.days === days)!;
  const sales = useSales(days * 2); // período atual + o anterior, para comparar

  return (
    <>
      <div className="page-header">
        <h1 className="page-title">Relatórios</h1>
        <select
          className="period-select"
          value={days}
          onChange={(e) => setDays(Number(e.target.value))}
          aria-label="Período"
        >
          {periods.map((p) => (
            <option key={p.days} value={p.days}>
              {p.label}
            </option>
          ))}
        </select>
      </div>

      <div className="tabs" role="tablist">
        {tabs.map((t) => (
          <button
            key={t.id}
            role="tab"
            aria-selected={tab === t.id}
            onClick={() => setParams(t.id === 'vendas' ? {} : { aba: t.id }, { replace: true })}
          >
            {t.label}
          </button>
        ))}
      </div>

      {sales === null ? (
        <p className="muted">Carregando…</p>
      ) : tab === 'vendas' ? (
        <SalesReport sales={sales} days={days} compare={period.compare} />
      ) : tab === 'estoque' ? (
        <StockReport days={days} />
      ) : (
        <StockVsSalesReport sales={sales} days={days} />
      )}
    </>
  );
}

// Vendas do período atual (sem as canceladas).
function currentSales(sales: Sale[], days: number) {
  const currentStart = startOfDay(new Date(Date.now() - (days - 1) * DAY));
  return {
    currentStart,
    current: sales.filter((s) => s.status === 'done' && s.createdAt && s.createdAt.toDate() >= currentStart),
  };
}

// ------------------------------------------------------------------ Vendas

function SalesReport({ sales, days, compare }: { sales: Sale[]; days: number; compare: string }) {
  const { products, categoryById } = useData();
  const { currentStart, current } = currentSales(sales, days);

  // Período anterior = mesma duração, deslocada para trás (hoje 8h–14h → ontem 8h–14h).
  const previousStart = new Date(currentStart.getTime() - days * DAY);
  const previousEnd = new Date(Date.now() - days * DAY);
  const previous = sales.filter((s) => {
    if (s.status !== 'done' || !s.createdAt) return false;
    const t = s.createdAt.toDate();
    return t >= previousStart && t <= previousEnd;
  });
  const cur = summarize(current);
  const prev = summarize(previous);

  const timeline: BarDatum[] = buckets(days, currentStart).map((b) => {
    const inBucket = current.filter((s) => {
      const t = s.createdAt!.toDate();
      return t >= b.start && t < b.end;
    });
    return {
      label: b.label,
      title: b.title,
      value: inBucket.reduce((sum, s) => sum + s.total, 0),
      detail: plural(inBucket.length, 'venda', 'vendas'),
    };
  });

  const hourly: BarDatum[] = Array.from({ length: 24 }, (_, h) => {
    const inHour = current.filter((s) => s.createdAt!.toDate().getHours() === h);
    return {
      label: `${h}h`,
      title: `${h}h às ${h + 1}h`,
      value: inHour.length,
      detail: formatMoney(inHour.reduce((sum, s) => sum + s.total, 0)),
    };
  });

  const byProduct = new Map<string, { name: string; quantity: number; revenue: number }>();
  for (const sale of current) {
    for (const item of sale.items) {
      const entry = byProduct.get(item.productId) ?? { name: item.name, quantity: 0, revenue: 0 };
      entry.quantity += item.quantity;
      entry.revenue += item.quantity * item.price;
      byProduct.set(item.productId, entry);
    }
  }
  const topProducts: RankDatum[] = [...byProduct.entries()]
    .sort((a, b) => b[1].revenue - a[1].revenue)
    .slice(0, 8)
    .map(([id, p]) => ({ key: id, label: p.name, value: p.revenue, detail: `${p.quantity} un.` }));

  const productCategory = new Map(products.map((p) => [p.id, p.categoryId]));
  const byCategory = new Map<string, number>();
  for (const sale of current) {
    for (const item of sale.items) {
      const name = categoryById.get(productCategory.get(item.productId) ?? '')?.name ?? 'Outros';
      byCategory.set(name, (byCategory.get(name) ?? 0) + item.quantity * item.price);
    }
  }
  const categories: RankDatum[] = [...byCategory.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([name, value]) => ({
      key: name,
      label: name,
      value,
      detail: cur.revenue ? `${Math.round((value / cur.revenue) * 100)}%` : undefined,
    }));

  const payments: RankDatum[] = (Object.keys(paymentLabels) as PaymentMethod[])
    .map((method) => {
      const list = current.filter((s) => s.payment === method);
      return {
        key: method,
        label: paymentLabels[method],
        value: list.reduce((sum, s) => sum + s.total, 0),
        detail: plural(list.length, 'venda', 'vendas'),
      };
    })
    .filter((p) => p.value > 0)
    .sort((a, b) => b.value - a.value);

  return (
    <>
      <p className="muted page-subtitle">Comparando com {compare}. Vendas canceladas não entram na conta.</p>

      <section className="stats">
        <div className="stat stat-highlight">
          <span className="stat-value">{formatMoney(cur.revenue)}</span>
          <span className="stat-label">Faturamento</span>
          <Change now={cur.revenue} before={prev.revenue} />
        </div>
        <div className="stat">
          <span className="stat-value">{cur.count}</span>
          <span className="stat-label">Vendas</span>
          <Change now={cur.count} before={prev.count} />
        </div>
        <div className="stat">
          <span className="stat-value">{formatMoney(cur.ticket)}</span>
          <span className="stat-label">Ticket médio</span>
          <Change now={cur.ticket} before={prev.ticket} />
        </div>
        <div className="stat">
          <span className="stat-value">{cur.items}</span>
          <span className="stat-label">Itens vendidos</span>
          <Change now={cur.items} before={prev.items} />
        </div>
      </section>

      {cur.count === 0 ? (
        <section className="panel">
          <p className="empty">Nenhuma venda nesse período ainda.</p>
        </section>
      ) : (
        <>
          <section className="panel report-block">
            <h2>{days === 1 ? 'Faturamento por hora' : 'Faturamento por dia'}</h2>
            <ColumnChart
              data={timeline}
              format={formatMoney}
              caption={days === 1 ? 'Faturamento por hora' : 'Faturamento por dia'}
              labelEvery={days === 1 ? 3 : days > 7 ? 5 : 1}
            />
          </section>

          <div className="columns report-block">
            <section className="panel">
              <h2>Mais vendidos</h2>
              <RankBars data={topProducts} format={formatMoney} />
            </section>
            <section className="panel">
              <h2>Por categoria</h2>
              <RankBars data={categories} format={formatMoney} />
            </section>
          </div>

          <div className="columns report-block">
            <section className="panel">
              <h2>Formas de pagamento</h2>
              <RankBars data={payments} format={formatMoney} />
            </section>
            {days > 1 && (
              <section className="panel">
                <h2>Horários de pico</h2>
                <ColumnChart
                  data={hourly}
                  format={(n) => plural(n, 'venda', 'vendas')}
                  caption="Número de vendas por hora do dia"
                  labelEvery={3}
                />
              </section>
            )}
          </div>
        </>
      )}
    </>
  );
}

// ----------------------------------------------------------------- Estoque

function StockReport({ days }: { days: number }) {
  const { products, categoryById } = useData();
  const movements = useMovementsSince(days);

  const totalUnits = products.reduce((sum, p) => sum + p.quantity, 0);
  const totalValue = products.reduce((sum, p) => sum + p.quantity * p.price, 0);
  const low = products.filter((p) => p.quantity > 0 && isLowStock(p)).length;
  const empty = products.filter((p) => p.quantity === 0).length;

  // Evolução: parte do estoque de agora e desfaz as movimentações posteriores a cada ponto.
  const currentStart = startOfDay(new Date(Date.now() - (days - 1) * DAY));
  const now = Date.now();
  function stockTimeline(list: Movement[]): BarDatum[] {
    return buckets(days, currentStart)
      .filter((b) => b.start.getTime() <= now) // horas que ainda não chegaram ficam de fora
      .map((b) => {
        const end = Math.min(b.end.getTime(), now);
        const after = list.filter((m) => m.createdAt && m.createdAt.toMillis() > end);
        const inBucket = list.filter((m) => {
          const t = m.createdAt?.toMillis() ?? 0;
          return t >= b.start.getTime() && t < b.end.getTime();
        });
        return {
          label: b.label,
          title: days === 1 ? `Às ${b.end.getHours() || 24}h` : `Fim de ${b.title}`,
          value: totalUnits - after.reduce((sum, m) => sum + m.delta, 0),
          detail: plural(inBucket.length, 'movimentação', 'movimentações'),
        };
      });
  }

  const byCategory = new Map<string, { units: number; value: number }>();
  for (const p of products) {
    const name = categoryById.get(p.categoryId)?.name ?? 'Sem categoria';
    const entry = byCategory.get(name) ?? { units: 0, value: 0 };
    entry.units += p.quantity;
    entry.value += p.quantity * p.price;
    byCategory.set(name, entry);
  }
  const categoryValue: RankDatum[] = [...byCategory.entries()]
    .sort((a, b) => b[1].value - a[1].value)
    .map(([name, c]) => ({ key: name, label: name, value: c.value, detail: `${c.units} un.` }));

  const lowest: RankDatum[] = products
    .filter((p) => isLowStock(p))
    .sort((a, b) => a.quantity - b.quantity)
    .slice(0, 8)
    .map((p) => ({ key: p.id, label: p.name, value: p.quantity, detail: `mínimo ${p.minStock}` }));

  return (
    <>
      <p className="muted page-subtitle">Situação atual do estoque e como ele mudou no período.</p>

      <section className="stats">
        <div className="stat stat-highlight">
          <span className="stat-value">{formatMoney(totalValue)}</span>
          <span className="stat-label">Valor em estoque (preço de venda)</span>
        </div>
        <div className="stat">
          <span className="stat-value">{totalUnits}</span>
          <span className="stat-label">Unidades em estoque</span>
        </div>
        <div className={low ? 'stat stat-alert' : 'stat'}>
          <span className="stat-value">{low}</span>
          <span className="stat-label">Abaixo do mínimo</span>
        </div>
        <div className={empty ? 'stat stat-alert' : 'stat'}>
          <span className="stat-value">{empty}</span>
          <span className="stat-label">Sem estoque</span>
        </div>
      </section>

      <section className="panel report-block">
        <h2>{days === 1 ? 'Estoque ao longo do dia' : 'Estoque ao fim de cada dia'}</h2>
        {movements === null ? (
          <p className="muted">Carregando…</p>
        ) : (
          <LineChart
            data={stockTimeline(movements)}
            format={units}
            caption="Unidades em estoque ao longo do período"
            labelEvery={days === 1 ? 3 : days > 7 ? 5 : 1}
          />
        )}
      </section>

      <div className="columns report-block">
        <section className="panel">
          <h2>Valor em estoque por categoria</h2>
          <RankBars data={categoryValue} format={formatMoney} />
        </section>
        <section className="panel">
          <h2>Precisam repor</h2>
          {lowest.length === 0 ? (
            <p className="empty">Nenhum produto abaixo do mínimo.</p>
          ) : (
            <RankBars data={lowest} format={units} />
          )}
        </section>
      </div>
    </>
  );
}

// ------------------------------------------------------- Estoque x Vendas

type Coverage = { label: string; className: string };

function coverageOf(stock: number, perDay: number): Coverage {
  if (stock === 0) return { label: 'Sem estoque', className: 'badge-low' };
  if (perDay === 0) return { label: 'Parado', className: 'badge-sale_cancel' };
  const daysLeft = stock / perDay;
  if (daysLeft < 7) return { label: 'Repor logo', className: 'badge-low' };
  if (daysLeft > 60) return { label: 'Excesso', className: 'badge-adjust' };
  return { label: 'Equilibrado', className: 'badge-in' };
}

function StockVsSalesReport({ sales, days }: { sales: Sale[]; days: number }) {
  const { products } = useData();
  const { current } = currentSales(sales, days);

  const sold = new Map<string, number>();
  for (const sale of current) {
    for (const item of sale.items) sold.set(item.productId, (sold.get(item.productId) ?? 0) + item.quantity);
  }

  const rows = products.map((p) => {
    const unitsSold = sold.get(p.id) ?? 0;
    const perDay = unitsSold / days;
    return {
      product: p,
      sold: unitsSold,
      perDay,
      daysLeft: perDay > 0 ? p.quantity / perDay : null,
      coverage: coverageOf(p.quantity, perDay),
    };
  });

  const totalSold = rows.reduce((sum, r) => sum + r.sold, 0);
  const totalStock = products.reduce((sum, p) => sum + p.quantity, 0);
  const sellThrough = totalSold + totalStock > 0 ? Math.round((totalSold / (totalSold + totalStock)) * 100) : 0;
  const restockSoon = rows.filter((r) => r.coverage.label === 'Repor logo').length;
  const stalled = rows.filter((r) => r.coverage.label === 'Parado');

  const pairs: PairDatum[] = rows
    .filter((r) => r.sold > 0 || r.product.quantity > 0)
    .sort((a, b) => b.sold - a.sold || b.product.quantity - a.product.quantity)
    .slice(0, 10)
    .map((r) => ({ key: r.product.id, label: r.product.name, a: r.sold, b: r.product.quantity }));

  // Quem acaba primeiro aparece no topo.
  const coverageList = rows
    .filter((r) => r.sold > 0)
    .sort((a, b) => (a.daysLeft ?? 0) - (b.daysLeft ?? 0));

  return (
    <>
      <p className="muted page-subtitle">
        Compara o que vendeu no período com o que ainda tem em estoque, para saber o que repor e o que está
        encalhado.
      </p>

      <section className="stats">
        <div className="stat stat-highlight">
          <span className="stat-value">{sellThrough}%</span>
          <span className="stat-label">Do estoque disponível foi vendido</span>
        </div>
        <div className="stat">
          <span className="stat-value">{totalSold}</span>
          <span className="stat-label">Unidades vendidas</span>
        </div>
        <div className={restockSoon ? 'stat stat-alert' : 'stat'}>
          <span className="stat-value">{restockSoon}</span>
          <span className="stat-label">Acabam em menos de 7 dias</span>
        </div>
        <div className="stat">
          <span className="stat-value">{stalled.length}</span>
          <span className="stat-label">Parados (sem venda)</span>
        </div>
      </section>

      <section className="panel report-block">
        <h2>Vendido x em estoque</h2>
        {pairs.length === 0 ? (
          <p className="empty">Nenhum produto com estoque ou venda no período.</p>
        ) : (
          <PairBars
            data={pairs}
            labels={['Vendido no período', 'Em estoque agora']}
            format={(n) => `${n} un.`}
            caption="Unidades vendidas no período e unidades em estoque por produto"
          />
        )}
      </section>

      <div className="columns report-block">
        <section className="panel">
          <h2>Quanto tempo o estoque dura</h2>
          <p className="muted">No ritmo de vendas do período.</p>
          {coverageList.length === 0 ? (
            <p className="empty">Sem vendas no período para calcular.</p>
          ) : (
            <ul className="coverage">
              {coverageList.slice(0, 12).map((r) => (
                <li key={r.product.id}>
                  <div className="coverage-main">
                    <strong>{r.product.name}</strong>
                    <span className="muted">
                      {r.product.quantity} em estoque · vende {r.perDay.toFixed(1).replace('.', ',')}/dia
                    </span>
                  </div>
                  <span className="coverage-days">
                    {r.product.quantity === 0 ? '0 dias' : `${Math.round(r.daysLeft!)} dias`}
                  </span>
                  <span className={`badge ${r.coverage.className}`}>{r.coverage.label}</span>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="panel">
          <h2>Produtos parados</h2>
          <p className="muted">Têm estoque, mas não venderam nada no período.</p>
          {stalled.length === 0 ? (
            <p className="empty">Todos os produtos com estoque venderam.</p>
          ) : (
            <ul className="stalled stalled-single">
              {stalled.slice(0, 12).map((r) => (
                <li key={r.product.id}>
                  {r.product.code && <span className="code">{r.product.code}</span>}
                  {r.product.name}
                  <span className="muted"> · {r.product.quantity} em estoque</span>
                </li>
              ))}
              {stalled.length > 12 && <li className="muted">e mais {stalled.length - 12}…</li>}
            </ul>
          )}
        </section>
      </div>
    </>
  );
}
