import { useEffect, useState, type FormEvent } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useData, useSales } from '../DataContext';
import ProductPhoto from '../components/ProductPhoto';
import { cancelSale, createSale } from '../data';
import {
  findByCode,
  formatMoney,
  parseMoney,
  paymentLabels,
  type PaymentMethod,
  type Product,
  type Sale,
} from '../types';

export default function Vendas() {
  const [params, setParams] = useSearchParams();
  const tab = params.get('aba') === 'realizadas' ? 'realizadas' : 'nova';

  return (
    <>
      <h1 className="page-title">Vendas</h1>
      <div className="tabs" role="tablist">
        <button role="tab" aria-selected={tab === 'nova'} onClick={() => setParams({}, { replace: true })}>
          Nova venda
        </button>
        <button
          role="tab"
          aria-selected={tab === 'realizadas'}
          onClick={() => setParams({ aba: 'realizadas' }, { replace: true })}
        >
          Vendas realizadas
        </button>
      </div>
      {tab === 'nova' ? <NovaVenda /> : <VendasRealizadas />}
    </>
  );
}

// ---------------------------------------------------------------- Nova venda

interface CartLine {
  productId: string;
  quantity: number;
  priceText: string; // editável, para permitir desconto na hora
}

function priceToText(price: number) {
  return price > 0 ? price.toFixed(2).replace('.', ',') : '';
}

function NovaVenda() {
  const { products } = useData();
  const [search, setSearch] = useState('');
  const [codeInput, setCodeInput] = useState('');
  const [codeFeedback, setCodeFeedback] = useState<{ text: string; ok: boolean } | null>(null);
  const [cart, setCart] = useState<CartLine[]>([]);
  const [payment, setPayment] = useState<PaymentMethod>('pix');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<string | null>(null);

  useEffect(() => {
    if (!done) return;
    const timer = setTimeout(() => setDone(null), 4000);
    return () => clearTimeout(timer);
  }, [done]);

  const productById = new Map(products.map((p) => [p.id, p]));
  const inCart = (id: string) => cart.find((l) => l.productId === id)?.quantity ?? 0;

  const term = search.trim().toLowerCase();
  const visible = products.filter(
    (p) => !term || p.name.toLowerCase().includes(term) || p.code.toLowerCase().includes(term),
  );

  // Funciona digitando ou com leitor de código de barras (que digita e aperta Enter sozinho).
  function handleCode(e: FormEvent) {
    e.preventDefault();
    const typed = codeInput.trim();
    if (!typed) return;
    const product = findByCode(products, typed);
    if (!product) {
      setCodeFeedback({ text: `Nenhum produto com o código ${typed}.`, ok: false });
    } else if (product.quantity - inCart(product.id) <= 0) {
      setCodeFeedback({ text: `${product.name} está sem estoque.`, ok: false });
    } else {
      add(product);
      setCodeFeedback({ text: `${product.name} adicionado.`, ok: true });
    }
    setCodeInput('');
  }

  const lines = cart.map((line) => {
    const product = productById.get(line.productId);
    const price = parseMoney(line.priceText);
    return {
      ...line,
      product,
      price,
      subtotal: price * line.quantity,
      problem: !product
        ? 'Produto excluído'
        : line.quantity > product.quantity
          ? `Só há ${product.quantity} em estoque`
          : null,
    };
  });
  const total = lines.reduce((sum, l) => sum + l.subtotal, 0);
  const hasProblem = lines.some((l) => l.problem);

  function add(product: Product) {
    setDone(null);
    setCart((current) =>
      current.some((l) => l.productId === product.id)
        ? current.map((l) => (l.productId === product.id ? { ...l, quantity: l.quantity + 1 } : l))
        : [...current, { productId: product.id, quantity: 1, priceText: priceToText(product.price) }],
    );
  }

  function update(productId: string, changes: Partial<CartLine>) {
    setCart((current) => current.map((l) => (l.productId === productId ? { ...l, ...changes } : l)));
  }

  function remove(productId: string) {
    setCart((current) => current.filter((l) => l.productId !== productId));
  }

  async function finish() {
    if (cart.length === 0 || hasProblem) return;
    setBusy(true);
    setError(null);
    try {
      const saleTotal = await createSale(
        lines.map((l) => ({
          productId: l.productId,
          code: l.product!.code,
          name: l.product!.name,
          quantity: l.quantity,
          price: l.price,
        })),
        payment,
      );
      setCart([]);
      setSearch('');
      setCodeFeedback(null);
      setDone(`Venda de ${formatMoney(saleTotal)} registrada. Estoque atualizado.`);
    } catch {
      setError('Não foi possível registrar a venda. Verifique sua conexão e tente de novo.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="pos">
      <section className="pos-products">
        <form className="panel code-entry" onSubmit={handleCode}>
          <label className="field">
            <span>Código do produto</span>
            <div className="code-entry-row">
              <input
                value={codeInput}
                onChange={(e) => setCodeInput(e.target.value)}
                placeholder="Digite o código e aperte Enter"
                autoComplete="off"
                autoFocus
              />
              <button className="btn btn-primary">Adicionar</button>
            </div>
          </label>
          {codeFeedback && (
            <p className={codeFeedback.ok ? 'notice' : 'error'} role="status">
              {codeFeedback.text}
            </p>
          )}
        </form>

        <input
          type="search"
          placeholder="Ou procure pelo nome…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Buscar produto"
        />
        {visible.length === 0 ? (
          <p className="empty">Nenhum produto encontrado.</p>
        ) : (
          <ul className="pos-grid">
            {visible.map((p) => {
              const available = p.quantity - inCart(p.id);
              return (
                <li key={p.id}>
                  <button className="pos-item" onClick={() => add(p)} disabled={available <= 0}>
                    <ProductPhoto src={p.photo} size={64} />
                    {p.code && <span className="code">{p.code}</span>}
                    <strong>{p.name}</strong>
                    <span>{p.price > 0 ? formatMoney(p.price) : 'Sem preço'}</span>
                    <span className="muted">
                      {p.quantity === 0 ? 'Sem estoque' : `${available} disponível(is)`}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <aside className="panel cart">
        <h2>Carrinho</h2>
        {done && <p className="notice cart-done">{done}</p>}
        {cart.length === 0 ? (
          <p className="empty">Toque nos produtos para adicionar.</p>
        ) : (
          <ul className="cart-lines">
            {lines.map((l) => (
              <li key={l.productId}>
                <div className="cart-line-head">
                  <strong>{l.product?.name ?? 'Produto excluído'}</strong>
                  <button className="icon-btn" onClick={() => remove(l.productId)} aria-label="Remover">
                    ×
                  </button>
                </div>
                <div className="cart-line-body">
                  <div className="stepper">
                    <button
                      onClick={() =>
                        l.quantity > 1 ? update(l.productId, { quantity: l.quantity - 1 }) : remove(l.productId)
                      }
                      aria-label="Diminuir"
                    >
                      −
                    </button>
                    <span>{l.quantity}</span>
                    <button
                      onClick={() => update(l.productId, { quantity: l.quantity + 1 })}
                      disabled={!l.product || l.quantity >= l.product.quantity}
                      aria-label="Aumentar"
                    >
                      +
                    </button>
                  </div>
                  <label className="cart-price">
                    <span className="muted">R$</span>
                    <input
                      inputMode="decimal"
                      placeholder="0,00"
                      value={l.priceText}
                      onChange={(e) => update(l.productId, { priceText: e.target.value })}
                      aria-label="Preço unitário"
                    />
                  </label>
                  <strong className="cart-subtotal">{formatMoney(l.subtotal)}</strong>
                </div>
                {l.problem && <p className="error">{l.problem}</p>}
              </li>
            ))}
          </ul>
        )}

        <div className="segmented segmented-3" role="radiogroup" aria-label="Forma de pagamento">
          {(Object.keys(paymentLabels) as PaymentMethod[]).map((method) => (
            <button
              key={method}
              type="button"
              role="radio"
              aria-checked={payment === method}
              className={payment === method ? 'active pay' : ''}
              onClick={() => setPayment(method)}
            >
              {paymentLabels[method]}
            </button>
          ))}
        </div>

        <div className="cart-total">
          <span>Total</span>
          <strong>{formatMoney(total)}</strong>
        </div>

        {error && <p className="error">{error}</p>}

        <button
          className="btn btn-primary btn-block btn-lg"
          onClick={finish}
          disabled={busy || cart.length === 0 || hasProblem}
        >
          {busy ? 'Registrando…' : 'Finalizar venda'}
        </button>
      </aside>
    </div>
  );
}

// ---------------------------------------------------------- Vendas realizadas

const periods = [
  { days: 1, label: 'Hoje' },
  { days: 7, label: 'Últimos 7 dias' },
  { days: 30, label: 'Últimos 30 dias' },
];

const timeFormat = new Intl.DateTimeFormat('pt-BR', { timeStyle: 'short' });
const dateTimeFormat = new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' });

function VendasRealizadas() {
  const { products } = useData();
  const [days, setDays] = useState(1);
  const sales = useSales(days);

  const valid = (sales ?? []).filter((s) => s.status === 'done');
  const total = valid.reduce((sum, s) => sum + s.total, 0);
  const byPayment = (Object.keys(paymentLabels) as PaymentMethod[])
    .map((method) => ({
      method,
      total: valid.filter((s) => s.payment === method).reduce((sum, s) => sum + s.total, 0),
    }))
    .filter((p) => p.total > 0);

  async function handleCancel(sale: Sale) {
    if (!confirm(`Cancelar a venda de ${formatMoney(sale.total)}? Os itens voltam para o estoque.`)) return;
    try {
      await cancelSale(sale, new Set(products.map((p) => p.id)));
    } catch {
      alert('Não foi possível cancelar. Verifique sua conexão e tente de novo.');
    }
  }

  return (
    <>
      <div className="filters">
        <select value={days} onChange={(e) => setDays(Number(e.target.value))} aria-label="Período">
          {periods.map((p) => (
            <option key={p.days} value={p.days}>
              {p.label}
            </option>
          ))}
        </select>
      </div>

      <section className="stats">
        <div className="stat">
          <span className="stat-value">{formatMoney(total)}</span>
          <span className="stat-label">Total vendido</span>
        </div>
        <div className="stat">
          <span className="stat-value">{valid.length}</span>
          <span className="stat-label">Vendas</span>
        </div>
        <div className="stat">
          <span className="stat-value">{formatMoney(valid.length ? total / valid.length : 0)}</span>
          <span className="stat-label">Ticket médio</span>
        </div>
        <div className="stat">
          {byPayment.length === 0 ? (
            <span className="stat-label">Nenhum pagamento</span>
          ) : (
            byPayment.map((p) => (
              <span key={p.method} className="stat-line">
                {paymentLabels[p.method]} <strong>{formatMoney(p.total)}</strong>
              </span>
            ))
          )}
        </div>
      </section>

      <section className="panel">
        {sales === null ? (
          <p className="muted">Carregando…</p>
        ) : sales.length === 0 ? (
          <p className="empty">Nenhuma venda nesse período.</p>
        ) : (
          <ul className="sales">
            {sales.map((s) => (
              <li key={s.id} className={s.status === 'cancelled' ? 'cancelled' : ''}>
                <div className="sale-main">
                  <strong>
                    {s.items.map((i) => `${i.quantity}× ${i.name}`).join(', ')}
                  </strong>
                  <span className="muted">
                    {s.createdAt ? (days === 1 ? timeFormat : dateTimeFormat).format(s.createdAt.toDate()) : '—'}
                    {' · '}
                    {paymentLabels[s.payment]}
                    {s.userEmail && ` · ${s.userEmail}`}
                  </span>
                </div>
                <span className="sale-total">{formatMoney(s.total)}</span>
                {s.status === 'cancelled' ? (
                  <span className="badge badge-sale_cancel">Cancelada</span>
                ) : (
                  <button className="btn btn-danger-link btn-sm" onClick={() => handleCancel(s)}>
                    Cancelar
                  </button>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
