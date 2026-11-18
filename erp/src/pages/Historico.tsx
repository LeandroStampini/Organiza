import { useState } from 'react';
import { useMovements } from '../DataContext';
import MovementList from '../components/MovementList';
import { movementLabels, type MovementType } from '../types';

export default function Historico() {
  const movements = useMovements(300);
  const [search, setSearch] = useState('');
  const [type, setType] = useState<MovementType | ''>('');

  const term = search.trim().toLowerCase();
  const visible = (movements ?? []).filter(
    (m) => (!term || m.productName.toLowerCase().includes(term)) && (!type || m.type === type),
  );

  return (
    <>
      <h1 className="page-title">Histórico</h1>
      <p className="muted page-subtitle">Todas as entradas, saídas e ajustes feitos pelo app ou pelo site.</p>

      <div className="filters">
        <input
          type="search"
          placeholder="Buscar produto…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Buscar produto"
        />
        <select
          value={type}
          onChange={(e) => setType(e.target.value as MovementType | '')}
          aria-label="Filtrar por tipo"
        >
          <option value="">Todos os tipos</option>
          {Object.entries(movementLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>

      <section className="panel">
        {movements ? <MovementList movements={visible} /> : <p className="muted">Carregando…</p>}
      </section>
    </>
  );
}
