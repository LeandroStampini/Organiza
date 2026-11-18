import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useData, useMovements, useSales } from '../DataContext';
import MovementList from '../components/MovementList';
import ProductPhoto from '../components/ProductPhoto';
import StockModal from '../components/StockModal';
import { formatMoney, isLowStock, type Product } from '../types';

export default function Inicio() {
  const { categories, products, categoryById } = useData();
  const movements = useMovements(8);
  const salesToday = useSales(1);
  const [restocking, setRestocking] = useState<Product | null>(null);

  const totalUnits = products.reduce((sum, p) => sum + p.quantity, 0);
  const lowStock = products.filter(isLowStock).sort((a, b) => a.quantity - b.quantity);
  const doneToday = (salesToday ?? []).filter((s) => s.status === 'done');
  const soldToday = doneToday.reduce((sum, s) => sum + s.total, 0);

  return (
    <>
      <div className="page-header">
        <h1 className="page-title">Início</h1>
        <Link to="/vendas" className="btn btn-primary">
          Nova venda
        </Link>
      </div>

      <section className="stats">
        <Link to="/vendas?aba=realizadas" className="stat stat-highlight">
          <span className="stat-value">{formatMoney(soldToday)}</span>
          <span className="stat-label">
            Vendido hoje · {doneToday.length} venda{doneToday.length === 1 ? '' : 's'}
          </span>
        </Link>
        <Link to="/produtos" className="stat">
          <span className="stat-value">{products.length}</span>
          <span className="stat-label">Produtos</span>
        </Link>
        <div className="stat">
          <span className="stat-value">{totalUnits}</span>
          <span className="stat-label">Unidades em estoque</span>
        </div>
        <Link to="/categorias" className="stat">
          <span className="stat-value">{categories.length}</span>
          <span className="stat-label">Categorias</span>
        </Link>
        <Link to="/produtos?repor=1" className={lowStock.length ? 'stat stat-alert' : 'stat'}>
          <span className="stat-value">{lowStock.length}</span>
          <span className="stat-label">Precisam repor</span>
        </Link>
      </section>

      <div className="columns">
        <section className="panel">
          <h2>Precisa repor</h2>
          {lowStock.length === 0 ? (
            <p className="empty">Tudo certo com o estoque.</p>
          ) : (
            <ul className="product-list compact">
              {lowStock.slice(0, 8).map((p) => (
                <li key={p.id}>
                  <ProductPhoto src={p.photo} size={44} />
                  <div className="product-main">
                    <strong>{p.name}</strong>
                    <span className="muted">{categoryById.get(p.categoryId)?.name ?? 'Sem categoria'}</span>
                  </div>
                  <span className="qty qty-low">{p.quantity}</span>
                  <button className="btn btn-ghost btn-sm" onClick={() => setRestocking(p)}>
                    Dar entrada
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="panel">
          <h2>Últimas movimentações</h2>
          {movements ? <MovementList movements={movements} /> : <p className="muted">Carregando…</p>}
          <Link to="/historico" className="panel-link">
            Ver histórico completo
          </Link>
        </section>
      </div>

      {restocking && <StockModal product={restocking} onClose={() => setRestocking(null)} />}
    </>
  );
}
