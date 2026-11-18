import { NavLink, Outlet } from 'react-router-dom';
import { signOut, type User } from 'firebase/auth';
import { auth } from '../firebase';
import { useData } from '../DataContext';

const links = [
  { to: '/', label: 'Início', end: true },
  { to: '/vendas', label: 'Vendas' },
  { to: '/relatorios', label: 'Relatórios' },
  { to: '/produtos', label: 'Produtos' },
  { to: '/categorias', label: 'Categorias' },
  { to: '/historico', label: 'Histórico' },
];

export default function Layout({ user }: { user: User }) {
  const { loading } = useData();

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          <img src="/logo.png" alt="" />
          <span>Organiza+</span>
        </div>
        <nav className="nav">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end}>
              {l.label}
            </NavLink>
          ))}
        </nav>
        <div className="user">
          <span className="muted user-email">{user.email}</span>
          <button className="btn btn-ghost" onClick={() => signOut(auth)}>
            Sair
          </button>
        </div>
      </header>
      <main className="content">{loading ? <p className="muted">Carregando estoque…</p> : <Outlet />}</main>
    </div>
  );
}
