import { movementLabels, type Movement } from '../types';

const dateFormat = new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' });

export default function MovementList({ movements }: { movements: Movement[] }) {
  if (movements.length === 0) {
    return <p className="empty">Nenhuma movimentação ainda.</p>;
  }

  return (
    <ul className="movements">
      {movements.map((m) => (
        <li key={m.id}>
          <span className={`badge badge-${m.type}`}>{movementLabels[m.type]}</span>
          <div className="movement-main">
            <strong>{m.productName}</strong>
            <span className="muted">
              {m.createdAt ? dateFormat.format(m.createdAt.toDate()) : '—'}
              {' · '}
              {m.source === 'app' ? 'App' : 'Site'}
              {m.userEmail && ` · ${m.userEmail}`}
            </span>
          </div>
          <span className={m.delta >= 0 ? 'delta positive' : 'delta negative'}>
            {m.delta > 0 ? `+${m.delta}` : m.delta}
          </span>
        </li>
      ))}
    </ul>
  );
}
