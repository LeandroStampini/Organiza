import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { limit, onSnapshot, orderBy, query, Timestamp, where } from 'firebase/firestore';
import { categoriesCol, movementsCol, productsCol, salesCol } from './data';
import type { Category, Movement, Product, Sale } from './types';

interface DataState {
  categories: Category[];
  products: Product[];
  loading: boolean;
  categoryById: Map<string, Category>;
}

const DataContext = createContext<DataState | null>(null);

// Categorias e produtos ficam sincronizados em tempo real com o app.
export function DataProvider({ children }: { children: ReactNode }) {
  const [categories, setCategories] = useState<Category[] | null>(null);
  const [products, setProducts] = useState<Product[] | null>(null);

  useEffect(() => {
    const unsubCategories = onSnapshot(query(categoriesCol, orderBy('name')), (snap) =>
      setCategories(
        snap.docs.map((d) => ({
          id: d.id,
          name: d.get('name') ?? '',
          color: d.get('color') ?? '#2B4479',
        })),
      ),
    );
    const unsubProducts = onSnapshot(query(productsCol, orderBy('name')), (snap) =>
      setProducts(
        snap.docs.map((d) => ({
          id: d.id,
          code: d.get('code') ?? '',
          name: d.get('name') ?? '',
          categoryId: d.get('categoryId') ?? '',
          quantity: d.get('quantity') ?? 0,
          minStock: d.get('minStock') ?? 0,
          price: d.get('price') ?? 0,
          photo: d.get('photo') ?? null,
        })),
      ),
    );
    return () => {
      unsubCategories();
      unsubProducts();
    };
  }, []);

  const value = useMemo<DataState>(
    () => ({
      categories: categories ?? [],
      products: products ?? [],
      loading: categories === null || products === null,
      categoryById: new Map((categories ?? []).map((c) => [c.id, c])),
    }),
    [categories, products],
  );

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}

export function useData() {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useData precisa estar dentro de DataProvider');
  return ctx;
}

export function useMovements(max: number) {
  const [movements, setMovements] = useState<Movement[] | null>(null);

  useEffect(
    () =>
      onSnapshot(query(movementsCol, orderBy('createdAt', 'desc'), limit(max)), (snap) =>
        setMovements(
          snap.docs.map(
            (d) => ({ id: d.id, ...d.data({ serverTimestamps: 'estimate' }) }) as Movement,
          ),
        ),
      ),
    [max],
  );

  return movements;
}

// Movimentações dos últimos `days` dias (1 = só hoje), da mais recente para a mais antiga.
export function useMovementsSince(days: number) {
  const [movements, setMovements] = useState<Movement[] | null>(null);

  useEffect(() => {
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    since.setDate(since.getDate() - (days - 1));
    setMovements(null);
    return onSnapshot(
      query(movementsCol, where('createdAt', '>=', Timestamp.fromDate(since)), orderBy('createdAt', 'desc')),
      (snap) =>
        setMovements(
          snap.docs.map(
            (d) => ({ id: d.id, ...d.data({ serverTimestamps: 'estimate' }) }) as Movement,
          ),
        ),
    );
  }, [days]);

  return movements;
}

// Vendas dos últimos `days` dias (1 = só hoje), da mais recente para a mais antiga.
export function useSales(days: number) {
  const [sales, setSales] = useState<Sale[] | null>(null);

  useEffect(() => {
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    since.setDate(since.getDate() - (days - 1));
    setSales(null);
    return onSnapshot(
      query(salesCol, where('createdAt', '>=', Timestamp.fromDate(since)), orderBy('createdAt', 'desc')),
      (snap) =>
        setSales(
          snap.docs.map((d) => ({ id: d.id, ...d.data({ serverTimestamps: 'estimate' }) }) as Sale),
        ),
    );
  }, [days]);

  return sales;
}
