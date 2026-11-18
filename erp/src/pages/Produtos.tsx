import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useData } from '../DataContext';
import { generateMissingCodes } from '../data';
import ProductModal from '../components/ProductModal';
import ProductPhoto from '../components/ProductPhoto';
import StockModal from '../components/StockModal';
import { formatMoney, isLowStock, type Product } from '../types';

type Editing = { product?: Product } | null;
type Moving = { product: Product; type: 'in' | 'out' } | null;

export default function Produtos() {
  const { products, categories, categoryById } = useData();
  const [params, setParams] = useSearchParams();
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState<Editing>(null);
  const [moving, setMoving] = useState<Moving>(null);

  const categoryFilter = params.get('categoria') ?? '';
  const lowOnly = params.get('repor') === '1';

  function setFilter(key: string, value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    setParams(next, { replace: true });
  }

  const term = search.trim().toLowerCase();
  const withoutCode = products.filter((p) => !p.code);
  const visible = products.filter(
    (p) =>
      (!term || p.name.toLowerCase().includes(term) || p.code.toLowerCase().includes(term)) &&
      (!categoryFilter || p.categoryId === categoryFilter) &&
      (!lowOnly || isLowStock(p)),
  );

  return (
    <>
      <div className="page-header">
        <h1 className="page-title">Produtos</h1>
        <button className="btn btn-primary" onClick={() => setEditing({})}>
          + Novo produto
        </button>
      </div>

      {withoutCode.length > 0 && (
        <div className="banner">
          <span>
            {withoutCode.length} produto(s) ainda sem código. Os códigos são usados para vender pelo caixa.
          </span>
          <button
            className="btn btn-primary btn-sm"
            onClick={() =>
              generateMissingCodes(products).catch(() =>
                alert('Não foi possível gerar os códigos. Verifique sua conexão.'),
              )
            }
          >
            Gerar códigos
          </button>
        </div>
      )}

      <div className="filters">
        <input
          type="search"
          placeholder="Buscar por nome ou código…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Buscar produto"
        />
        <select
          value={categoryFilter}
          onChange={(e) => setFilter('categoria', e.target.value)}
          aria-label="Filtrar por categoria"
        >
          <option value="">Todas as categorias</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <label className="checkbox">
          <input type="checkbox" checked={lowOnly} onChange={(e) => setFilter('repor', e.target.checked ? '1' : '')} />
          Só os que precisam repor
        </label>
      </div>

      {visible.length === 0 ? (
        <p className="empty">
          {products.length === 0
            ? 'Nenhum produto cadastrado. Cadastre pelo app ou clique em "Novo produto".'
            : 'Nenhum produto encontrado com esses filtros.'}
        </p>
      ) : (
        <ul className="product-list">
          {visible.map((p) => {
            const category = categoryById.get(p.categoryId);
            const low = isLowStock(p);
            return (
              <li key={p.id}>
                <ProductPhoto src={p.photo} />
                <div className="product-main">
                  <strong>
                    {p.code && <span className="code">{p.code}</span>}
                    {p.name}
                  </strong>
                  <span className="category-tag">
                    <span className="dot" style={{ background: category?.color ?? '#999' }} />
                    {category?.name ?? 'Sem categoria'}
                  </span>
                  <span className="muted">{p.price > 0 ? formatMoney(p.price) : 'Sem preço'}</span>
                </div>
                <div className="qty-block">
                  <span className={low ? 'qty qty-low' : 'qty'}>{p.quantity}</span>
                  {low && <span className="badge badge-low">Repor</span>}
                </div>
                <div className="row-actions">
                  <button className="btn btn-in btn-sm" onClick={() => setMoving({ product: p, type: 'in' })}>
                    Entrada
                  </button>
                  <button
                    className="btn btn-out btn-sm"
                    onClick={() => setMoving({ product: p, type: 'out' })}
                    disabled={p.quantity === 0}
                  >
                    Saída
                  </button>
                  <button className="btn btn-ghost btn-sm" onClick={() => setEditing({ product: p })}>
                    Editar
                  </button>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {editing && (
        <ProductModal
          product={editing.product}
          initialCategoryId={categoryFilter || undefined}
          onClose={() => setEditing(null)}
        />
      )}
      {moving && (
        <StockModal product={moving.product} initialType={moving.type} onClose={() => setMoving(null)} />
      )}
    </>
  );
}
