import { useState, type FormEvent } from 'react';
import Modal from './Modal';
import ProductPhoto from './ProductPhoto';
import { moveStock } from '../data';
import type { Product } from '../types';

interface Props {
  product: Product;
  initialType?: 'in' | 'out';
  onClose: () => void;
}

export default function StockModal({ product, initialType = 'in', onClose }: Props) {
  const [type, setType] = useState(initialType);
  const [amount, setAmount] = useState('1');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const value = Math.trunc(Number(amount) || 0);
  const result = type === 'in' ? product.quantity + value : product.quantity - value;
  const invalid = value <= 0 || result < 0;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (invalid) return;
    setBusy(true);
    try {
      await moveStock(product, type, value);
      onClose();
    } catch {
      setError('Não foi possível salvar. Verifique sua conexão e tente de novo.');
      setBusy(false);
    }
  }

  return (
    <Modal title="Movimentar estoque" onClose={onClose}>
      <form onSubmit={handleSubmit} className="form">
        <div className="stock-product">
          <ProductPhoto src={product.photo} />
          <div>
            <strong>{product.name}</strong>
            <div className="muted">Em estoque: {product.quantity}</div>
          </div>
        </div>

        <div className="segmented" role="radiogroup" aria-label="Tipo de movimentação">
          <button
            type="button"
            role="radio"
            aria-checked={type === 'in'}
            className={type === 'in' ? 'active in' : ''}
            onClick={() => setType('in')}
          >
            Entrada
          </button>
          <button
            type="button"
            role="radio"
            aria-checked={type === 'out'}
            className={type === 'out' ? 'active out' : ''}
            onClick={() => setType('out')}
          >
            Saída
          </button>
        </div>

        <label className="field">
          <span>Quantidade</span>
          <input
            type="number"
            min={1}
            inputMode="numeric"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            autoFocus
            onFocus={(e) => e.target.select()}
          />
        </label>

        <p className={result < 0 ? 'error' : 'muted'}>
          {result < 0
            ? `Só há ${product.quantity} em estoque.`
            : `Estoque ficará com ${result}.`}
        </p>

        {error && <p className="error">{error}</p>}

        <div className="modal-actions">
          <button type="button" className="btn btn-ghost" onClick={onClose}>
            Cancelar
          </button>
          <button className="btn btn-primary" disabled={busy || invalid}>
            {busy ? 'Salvando…' : 'Confirmar'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
