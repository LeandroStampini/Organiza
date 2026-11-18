import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { auth } from './firebase';
import { DataProvider } from './DataContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Inicio from './pages/Inicio';
import Produtos from './pages/Produtos';
import Vendas from './pages/Vendas';
import Relatorios from './pages/Relatorios';
import Categorias from './pages/Categorias';
import Historico from './pages/Historico';

export default function App() {
  // undefined = ainda verificando a sessão
  const [user, setUser] = useState<User | null | undefined>(undefined);

  useEffect(() => onAuthStateChanged(auth, setUser), []);

  if (user === undefined) return <div className="splash">Carregando…</div>;
  if (!user) return <Login />;

  return (
    <DataProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout user={user} />}>
            <Route index element={<Inicio />} />
            <Route path="vendas" element={<Vendas />} />
            <Route path="relatorios" element={<Relatorios />} />
            <Route path="produtos" element={<Produtos />} />
            <Route path="categorias" element={<Categorias />} />
            <Route path="historico" element={<Historico />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </DataProvider>
  );
}
