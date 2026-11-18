import type { Timestamp } from 'firebase/firestore';

// Estrutura compartilhada com o app Flutter (lib/screens/models.dart).

export interface Category {
  id: string;
  name: string;
  color: string; // "#RRGGBB"
}

export interface Product {
  id: string;
  code: string; // código do produto (digitado ou lido por leitor de código de barras)
  name: string;
  categoryId: string;
  quantity: number;
  minStock: number;
  price: number; // preço de venda em reais
  photo: string | null; // data URL JPEG comprimida
}

export type MovementType = 'in' | 'out' | 'adjust' | 'sale' | 'sale_cancel';

export interface Movement {
  id: string;
  productId: string;
  productName: string;
  type: MovementType;
  delta: number;
  source: 'app' | 'erp';
  userEmail: string | null;
  createdAt: Timestamp | null;
}

export const movementLabels: Record<MovementType, string> = {
  in: 'Entrada',
  out: 'Saída',
  adjust: 'Ajuste',
  sale: 'Venda',
  sale_cancel: 'Venda cancelada',
};

export type PaymentMethod = 'dinheiro' | 'pix' | 'cartao';

export const paymentLabels: Record<PaymentMethod, string> = {
  dinheiro: 'Dinheiro',
  pix: 'Pix',
  cartao: 'Cartão',
};

export interface SaleItem {
  productId: string;
  code: string;
  name: string;
  quantity: number;
  price: number;
}

export interface Sale {
  id: string;
  items: SaleItem[];
  total: number;
  payment: PaymentMethod;
  status: 'done' | 'cancelled';
  userEmail: string | null;
  createdAt: Timestamp | null;
}

export function isLowStock(p: Product) {
  return p.quantity <= p.minStock;
}

export function normalizeCode(code: string) {
  return code.trim().toUpperCase();
}

// Códigos automáticos são sequenciais (0001, 0002…). Códigos de barras longos não entram na conta.
export function nextCode(codes: string[]) {
  const max = codes
    .filter((c) => /^\d{1,6}$/.test(c))
    .reduce((m, c) => Math.max(m, Number(c)), 0);
  return String(max + 1).padStart(4, '0');
}

// Acha pelo código exato; se for só número, "12" também encontra "0012".
export function findByCode(products: Product[], typed: string) {
  const code = normalizeCode(typed);
  if (!code) return undefined;
  const exact = products.find((p) => p.code === code);
  if (exact || !/^\d+$/.test(code)) return exact;
  return products.find((p) => /^\d+$/.test(p.code) && Number(p.code) === Number(code));
}

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

export function formatMoney(value: number) {
  return money.format(value);
}

// Aceita "12,50", "12.50" ou "R$ 12,50".
export function parseMoney(text: string) {
  const value = Number(text.replace(/[^\d,.-]/g, '').replace(/\.(?=\d{3}(\D|$))/g, '').replace(',', '.'));
  return Number.isFinite(value) && value > 0 ? Math.round(value * 100) / 100 : 0;
}
