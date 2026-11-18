import { useState, type FormEvent } from 'react';
import Modal from './Modal';
import { saveCategory } from '../data';
import type { Category } from '../types';

const presets = ['#2B4479', '#B8860B', '#2E7D32', '#C62828', '#6A1B9A', '#00838F', '#EF6C00', '#5D4037'];

interface Props {
  category?: Category;
  onClose: () => void;
}

export default function CategoryModal({ category, onClose }: Props) {
  const [name, setName] = useState(category?.name ?? '');
  const [color, setColor] = useState(category?.color ?? presets[0]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await saveCategory({ name: name.trim(), color: color.toUpperCase() }, category?.id);
      onClose();
    } catch {
      setError('Não foi possível salvar. Verifique sua conexão e tente de novo.');
      setBusy(false);
    }
  }

  return (
    <Modal title={category ? 'Editar categoria' : 'Nova categoria'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="form">
        <label className="field">
          <span>Nome</span>
          <input value={name} onChange={(e) => setName(e.target.value)} required autoFocus />
        </label>

        <div className="field">
          <span>Cor</span>
          <div className="swatches">
            {presets.map((c) => (
              <button
                key={c}
                type="button"
                className={c === color.toUpperCase() ? 'swatch selected' : 'swatch'}
                style={{ background: c }}
                onClick={() => setColor(c)}
                aria-label={`Cor ${c}`}
              />
            ))}
            <label className="swatch swatch-custom" title="Outra cor">
              <input type="color" value={color} onChange={(e) => setColor(e.target.value)} />
            </label>
          </div>
        </div>

        <div className="category-preview" style={{ background: color }}>
          {name.trim() || 'Prévia'}
        </div>

        {error && <p className="error">{error}</p>}

        <div className="modal-actions">
          <button type="button" className="btn btn-ghost" onClick={onClose}>
            Cancelar
          </button>
          <button className="btn btn-primary" disabled={busy || !name.trim()}>
            {busy ? 'Salvando…' : 'Salvar'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
