import {
  collection,
  doc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  where,
  writeBatch,
  type WriteBatch,
} from 'firebase/firestore';
import { auth, db } from './firebase';
import { nextCode, type MovementType, type PaymentMethod, type Product, type Sale, type SaleItem } from './types';

export const categoriesCol = collection(db, 'categories');
export const productsCol = collection(db, 'products');
export const movementsCol = collection(db, 'movements');
export const salesCol = collection(db, 'sales');

export interface CategoryInput {
  name: string;
  color: string;
}

export interface ProductInput {
  code: string;
  name: string;
  categoryId: string;
  quantity: number;
  minStock: number;
  price: number;
  photo: string | null;
}

// Toda mudança de quantidade gera um registro no histórico.
function addMovement(
  batch: WriteBatch,
  product: { id: string; name: string },
  type: MovementType,
  delta: number,
  saleId?: string,
) {
  batch.set(doc(movementsCol), {
    productId: product.id,
    productName: product.name,
    type,
    delta,
    source: 'erp',
    userEmail: auth.currentUser?.email ?? null,
    createdAt: serverTimestamp(),
    ...(saleId && { saleId }),
  });
}

// Registra a venda e dá baixa no estoque de cada item, tudo de uma vez.
export async function createSale(items: SaleItem[], payment: PaymentMethod) {
  const batch = writeBatch(db);
  const ref = doc(salesCol);
  const total = items.reduce((sum, i) => sum + i.quantity * i.price, 0);
  batch.set(ref, {
    items,
    total: Math.round(total * 100) / 100,
    payment,
    status: 'done',
    userEmail: auth.currentUser?.email ?? null,
    createdAt: serverTimestamp(),
  });
  for (const item of items) {
    batch.update(doc(productsCol, item.productId), {
      quantity: increment(-item.quantity),
      updatedAt: serverTimestamp(),
    });
    addMovement(batch, { id: item.productId, name: item.name }, 'sale', -item.quantity, ref.id);
  }
  await batch.commit();
  return total;
}

// Cancela a venda e devolve os itens ao estoque (produtos excluídos são ignorados).
export async function cancelSale(sale: Sale, existingProductIds: Set<string>) {
  const batch = writeBatch(db);
  batch.update(doc(salesCol, sale.id), {
    status: 'cancelled',
    cancelledAt: serverTimestamp(),
    cancelledBy: auth.currentUser?.email ?? null,
  });
  for (const item of sale.items) {
    if (!existingProductIds.has(item.productId)) continue;
    batch.update(doc(productsCol, item.productId), {
      quantity: increment(item.quantity),
      updatedAt: serverTimestamp(),
    });
    addMovement(batch, { id: item.productId, name: item.name }, 'sale_cancel', item.quantity, sale.id);
  }
  await batch.commit();
}

export async function saveCategory(input: CategoryInput, id?: string) {
  const batch = writeBatch(db);
  batch.set(id ? doc(categoriesCol, id) : doc(categoriesCol), input, { merge: true });
  await batch.commit();
}

// Exclui a categoria junto com seus produtos (mesmo comportamento do app).
export async function deleteCategory(id: string) {
  const products = await getDocs(query(productsCol, where('categoryId', '==', id)));
  const batch = writeBatch(db);
  products.forEach((p) => batch.delete(p.ref));
  batch.delete(doc(categoriesCol, id));
  await batch.commit();
}

export async function createProduct(input: ProductInput) {
  const batch = writeBatch(db);
  const ref = doc(productsCol);
  batch.set(ref, { ...input, updatedAt: serverTimestamp() });
  if (input.quantity > 0) {
    addMovement(batch, { id: ref.id, name: input.name }, 'in', input.quantity);
  }
  await batch.commit();
}

export async function updateProduct(product: Product, input: ProductInput) {
  const { quantity, ...fields } = input;
  const delta = quantity - product.quantity;
  const batch = writeBatch(db);
  batch.update(doc(productsCol, product.id), {
    ...fields,
    ...(delta !== 0 && { quantity: increment(delta) }),
    updatedAt: serverTimestamp(),
  });
  if (delta !== 0) {
    addMovement(batch, { id: product.id, name: input.name }, 'adjust', delta);
  }
  await batch.commit();
}

export async function moveStock(product: Product, type: 'in' | 'out', amount: number) {
  const delta = type === 'in' ? amount : -amount;
  const batch = writeBatch(db);
  batch.update(doc(productsCol, product.id), {
    quantity: increment(delta),
    updatedAt: serverTimestamp(),
  });
  addMovement(batch, product, type, delta);
  await batch.commit();
}

// Dá um código sequencial para cada produto cadastrado antes de existir o campo.
export async function generateMissingCodes(products: Product[]) {
  const codes = products.map((p) => p.code).filter(Boolean);
  const batch = writeBatch(db);
  for (const p of products.filter((p) => !p.code)) {
    const code = nextCode(codes);
    codes.push(code);
    batch.update(doc(productsCol, p.id), { code });
  }
  await batch.commit();
}

export async function deleteProduct(id: string) {
  const batch = writeBatch(db);
  batch.delete(doc(productsCol, id));
  await batch.commit();
}
