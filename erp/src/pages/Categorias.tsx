import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useData } from '../DataContext';
import CategoryModal from '../components/CategoryModal';
import { deleteCategory } from '../data';
import type { Category } from '../types';

export default function Categorias() {
  const { categories, products } = useData();
  const [editing, setEditing] = useState<{ category?: Category } | null>(null);

  async function handleDelete(category: Category, productCount: number) {
    const warning =
      productCount > 0
        ? `A categoria "${category.name}" tem ${productCount} produto(s). Excluir a categoria e todos esses produtos?`
        : `Excluir a categoria "${category.name}"?`;
    if (!confirm(warning)) return;
    try {
      await deleteCategory(category.id);
    } catch {
      alert('Não foi possível excluir. Verifique sua conexão e tente de novo.');
    }
  }

  return (
    <>
      <div className="page-header">
        <h1 className="page-title">Categorias</h1>
        <button className="btn btn-primary" onClick={() => setEditing({})}>
          + Nova categoria
        </button>
      </div>

      {categories.length === 0 ? (
        <p className="empty">Nenhuma categoria ainda. Crie pelo app ou clique em "Nova categoria".</p>
      ) : (
        <ul className="category-grid">
          {categories.map((c) => {
            const items = products.filter((p) => p.categoryId === c.id);
            const units = items.reduce((sum, p) => sum + p.quantity, 0);
            return (
              <li key={c.id} className="category-card">
                <Link to={`/produtos?categoria=${c.id}`} className="category-head" style={{ background: c.color }}>
                  {c.name}
                </Link>
                <div className="category-body">
                  <span className="muted">
                    {items.length} produto(s) · {units} unidade(s)
                  </span>
                  <div className="row-actions">
                    <button className="btn btn-ghost btn-sm" onClick={() => setEditing({ category: c })}>
                      Editar
                    </button>
                    <button className="btn btn-danger-link btn-sm" onClick={() => handleDelete(c, items.length)}>
                      Excluir
                    </button>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {editing && <CategoryModal category={editing.category} onClose={() => setEditing(null)} />}
    </>
  );
}
