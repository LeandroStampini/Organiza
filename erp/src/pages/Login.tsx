import { useState, type FormEvent } from 'react';
import { sendPasswordResetEmail, signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase';

function authError(code: string) {
  switch (code) {
    case 'auth/invalid-email':
      return 'E-mail inválido.';
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'E-mail ou senha incorretos.';
    case 'auth/too-many-requests':
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    case 'auth/network-request-failed':
      return 'Sem conexão com a internet.';
    default:
      return 'Não foi possível entrar. Tente novamente.';
  }
}

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState<{ text: string; ok?: boolean } | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMessage(null);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (err) {
      setMessage({ text: authError((err as { code?: string }).code ?? '') });
      setBusy(false);
    }
  }

  async function handleForgot() {
    if (!email.trim()) {
      setMessage({ text: 'Digite seu e-mail acima para receber o link.' });
      return;
    }
    try {
      await sendPasswordResetEmail(auth, email.trim());
      setMessage({ text: 'Enviamos um link para redefinir sua senha.', ok: true });
    } catch (err) {
      setMessage({ text: authError((err as { code?: string }).code ?? '') });
    }
  }

  return (
    <main className="login">
      <form className="login-card" onSubmit={handleSubmit}>
        <img src="/logo.png" alt="" className="login-logo" />
        <h1>Organiza+</h1>
        <p className="muted">Entre com a mesma conta do aplicativo</p>

        <label className="field">
          <span>E-mail</span>
          <input
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoFocus
          />
        </label>
        <label className="field">
          <span>Senha</span>
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </label>

        {message && <p className={message.ok ? 'notice' : 'error'}>{message.text}</p>}

        <button className="btn btn-primary btn-block" disabled={busy}>
          {busy ? 'Entrando…' : 'Entrar'}
        </button>
        <button type="button" className="btn btn-link" onClick={handleForgot}>
          Esqueci minha senha
        </button>
      </form>
    </main>
  );
}
