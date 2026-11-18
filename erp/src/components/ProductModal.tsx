import { useState, type FormEvent } from 'react';
import Modal from './Modal';
import ProductPhoto from './ProductPhoto';
import { useData } from '../DataContext';
import { createProduct, deleteProduct, updateProduct } from '../data';
import { resizeImage } from '../image';
import { nextCode, normalizeCode, parseMoney, type Product } from '../types';

interface Props {
  product?: Product;
  initialCategoryId?: string;
  onClose: () => void;
}

export default function ProductModal({ product, initialCategoryId, onClose }: Props) {
  const { categories, products } = useData();
  const [code, setCode] = useState(product?.code ?? '');
  // Produto novo (ou antigo sem código) começa com o código automático ligado.
  const [autoCode, setAutoCode] = useState(!product?.code);
  const [name, setName] = useState(product?.name ?? '');
  const [categoryId, setCategoryId] = useState(
    product?.categoryId ?? initialCategoryId ?? categories[0]?.id ?? '',
  );
  const [quantity, setQuantity] = useState(String(product?.quantity ?? 0));
  const [minStock, setMinStock] = useState(String(product?.minStock ?? 0));
  const [price, setPrice] = useState(product?.price ? product.price.toFixed(2).replace('.', ',') : '');
  const [photo, setPhoto] = useState(product?.photo ?? null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (categories.length === 0) {
    return (
      <Modal title="Novo produto" onClose={onClose}>
        <p>Crie uma categoria antes de cadastrar produtos.</p>
        <div className="modal-actions">
          <button className="btn btn-primary" onClick={onClose}>
            Entendi
          </button>
        </div>
      </Modal>
    );
  }

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setError(null);
    try {
      await action();
      onClose();
    } catch {
      setError('Não foi possível salvar. Verifique sua conexão e tente de novo.');
      setBusy(false);
    }
  }

  const autoCodePreview = nextCode(products.filter((p) => p.id !== product?.id).map((p) => p.code));

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const finalCode = autoCode ? autoCodePreview : normalizeCode(code);
    if (!finalCode) {
      setError('Digite o código do produto ou ligue a geração automática.');
      return;
    }
    const taken = products.find((p) => p.code === finalCode && p.id !== product?.id);
    if (taken) {
      setError(`O código ${finalCode} já é do produto "${taken.name}".`);
      return;
    }
    const finalPrice = parseMoney(price);
    if (finalPrice <= 0) {
      setError('Informe o preço de venda do produto.');
      return;
    }
    const input = {
      code: finalCode,
      name: name.trim(),
      categoryId,
      quantity: Math.max(0, Math.trunc(Number(quantity) || 0)),
      minStock: Math.max(0, Math.trunc(Number(minStock) || 0)),
      price: finalPrice,
      photo,
    };
    run(() => (product ? updateProduct(product, input) : createProduct(input)));
  }

  function handleDelete() {
    if (product && confirm(`Excluir "${product.name}"? Essa ação não pode ser desfeita.`)) {
      run(() => deleteProduct(product.id));
    }
  }

  async function handlePhoto(file: File | undefined) {
    if (!file) return;
    try {
      setPhoto(await resizeImage(file));
    } catch {
      setError('Não foi possível ler essa imagem.');
    }
  }

  return (
    <Modal title={product ? 'Editar produto' : 'Novo produto'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="form">
        <div className="photo-picker">
          <ProductPhoto src={photo} size={96} />
          <div className="photo-picker-actions">
            <label className="btn btn-ghost">
              {photo ? 'Trocar foto' : 'Adicionar foto'}
              <input
                type="file"
                accept="image/*"
                hidden
                onChange={(e) => handlePhoto(e.target.files?.[0])}
              />
            </label>
            {photo && (
              <button type="button" className="btn btn-link" onClick={() => setPhoto(null)}>
                Remover foto
              </button>
            )}
          </div>
        </div>

        <label className="field">
          <span>Nome</span>
          <input value={name} onChange={(e) => setName(e.target.value)} required autoFocus />
        </label>

        <div className="field">
          <span>Código</span>
          <label className="switch">
            <input
              type="checkbox"
              role="switch"
              checked={autoCode}
              onChange={(e) => setAutoCode(e.target.checked)}
            />
            <span className="switch-track" aria-hidden="true" />
            Gerar código automaticamente
          </label>
          {autoCode ? (
            <p className="muted switch-hint">
              {product?.code ? 'Novo código' : 'Este produto vai receber o código'}{' '}
              <span className="code">{autoCodePreview}</span>
            </p>
          ) : (
            <input
              value={code}
              onChange={(e) => setCode(e.target.value)}
              aria-label="Código do produto"
              autoCapitalize="characters"
              required
            />
          )}
        </div>
        <label className="field">
          <span>Categoria</span>
          <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Preço de venda (R$)</span>
          <input
            inputMode="decimal"
            placeholder="0,00"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            required
          />
        </label>
        <div className="field-row">
          <label className="field">
            <span>Quantidade</span>
            <input
              type="number"
              min={0}
              inputMode="numeric"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
            />
          </label>
          <label className="field">
            <span>Avisar quando chegar a</span>
            <input
              type="number"
              min={0}
              inputMode="numeric"
              value={minStock}
              onChange={(e) => setMinStock(e.target.value)}
            />
          </label>
        </div>

        {error && <p className="error">{error}</p>}

        <div className="modal-actions">
          {product && (
            <button type="button" className="btn btn-danger-link" onClick={handleDelete} disabled={busy}>
              Excluir
            </button>
          )}
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
