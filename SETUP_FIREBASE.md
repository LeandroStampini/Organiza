# Setup Firebase — Organiza+

Guia completo para configurar o Firebase AI Logic e App Check no projeto.  
Siga esta ordem exata na **primeira vez** que configurar o ambiente.

---

## Pré-requisitos

| Ferramenta | Instalação |
|---|---|
| Flutter SDK | https://docs.flutter.dev/get-started/install |
| Firebase CLI | `npm install -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| Conta Google com acesso ao Firebase Console | https://console.firebase.google.com |

---

## Parte 1 — Console Firebase (faça uma vez)

### 1.1 Criar o projeto Firebase

1. Acesse https://console.firebase.google.com
2. Clique em **"Adicionar projeto"**
3. Nome: `organiza-plus` (ou qualquer nome)
4. Desative o Google Analytics (opcional)
5. Clique em **"Criar projeto"**

---

### 1.2 Registrar o app Android

1. Na página do projeto, clique no ícone **Android** (`</>`  → Android)
2. **Nome do pacote Android:** `com.example.projeto`
   - ⚠️ Deve ser igual ao `applicationId` em `android/app/build.gradle.kts`
   - Se você mudar o application ID no futuro, recrie o app no Firebase
3. **Apelido do app:** `Organiza Android` (opcional)
4. Clique em **"Registrar app"**
5. **Baixe o `google-services.json`**
6. Coloque o arquivo em: `android/app/google-services.json`
   - ⚠️ Este arquivo está no `.gitignore` — NÃO o commite em repos públicos

---

### 1.3 Registrar o app iOS (se for distribuir para iOS)

1. Na página do projeto, clique no ícone **Apple**
2. **Bundle ID:** encontre em `ios/Runner.xcodeproj/project.pbxproj` → busque `PRODUCT_BUNDLE_IDENTIFIER`
   - Valor padrão do template Flutter: `com.example.projeto`
3. **Apelido do app:** `Organiza iOS` (opcional)
4. Clique em **"Registrar app"**
5. **Baixe o `GoogleService-Info.plist`**
6. Abra o Xcode → arraste o arquivo para `ios/Runner/` (dentro do Xcode, não apenas pelo Finder)
   - ⚠️ Este arquivo está no `.gitignore` — NÃO o commite em repos públicos

---

### 1.4 Habilitar Firebase AI Logic (Gemini)

1. No menu lateral esquerdo, clique em **"AI"** → **"Firebase AI Logic"**
   - Se não aparecer, procure em "Compilação" → "AI Logic"
2. Clique em **"Começar"** / **"Get started"**
3. Selecione **"Gemini Developer API"** (gratuita, sem cartão de crédito)
   - Alternativa paga: Vertex AI (para escala enterprise)
4. Aceite os termos e clique em **"Continuar"**
5. O Firebase habilitará o acesso ao Gemini usando autenticação do Firebase (sem expor key)

---

### 1.5 Ativar Firebase App Check

O App Check impede que bots e apps não autorizados usem seus recursos Firebase.

1. No menu lateral, clique em **"App Check"** (em "Compilação")
2. Clique na aba **"Apps"**

#### Para o app Android:
3. Clique no app Android → **"Registrar"**
4. Selecione o provider: **"Play Integrity"**
   - ⚠️ Play Integrity funciona apenas com apps publicados na Play Store  
   - Para testes locais, use **Debug tokens** (veja Parte 3 abaixo)
5. Clique em **"Salvar"**

#### Para o app iOS:
6. Clique no app iOS → **"Registrar"**
7. Selecione o provider: **"App Attest"**
   - ⚠️ App Attest funciona apenas com apps publicados na App Store  
   - Para testes locais, use **Debug tokens** (veja Parte 3 abaixo)
8. Clique em **"Salvar"**

#### Habilitar enforcement (proteção ativa):
9. Vá em **"APIs"** → selecione **"Firebase AI Logic"**
10. Clique em **"Aplicar"** (Enforce)
    - ⚠️ Antes de aplicar enforcement, certifique-se de que os debug tokens estão configurados (Parte 3), senão o app vai falhar em desenvolvimento

---

## Parte 2 — Terminal (depois de configurar o console)

### 2.1 Login no Firebase CLI

```bash
firebase login
```

### 2.2 Gerar o firebase_options.dart

Na raiz do projeto, execute:

```bash
flutterfire configure
```

O comando vai:
- Perguntar qual projeto Firebase usar → selecione o criado na Parte 1
- Perguntar quais plataformas → selecione `android`, `ios` (e `web` se quiser)
- Criar/atualizar `lib/firebase_options.dart` com as configurações do projeto
- Atualizar `android/app/build.gradle.kts` e `android/build.gradle.kts` com o plugin google-services
- Adicionar o `google-services.json` ao Android (ou pedir que você adicione manualmente)

### 2.3 Instalar dependências

```bash
flutter pub get
```

### 2.4 Rodar o app (modo debug)

```bash
# Android
flutter run

# iOS (macOS necessário)
flutter run -d ios
```

---

## Parte 3 — App Check em modo debug (desenvolvimento local)

Sem esta configuração, o App Check vai bloquear todas as chamadas em desenvolvimento.

### 3.1 Obter o debug token

1. Execute o app no modo debug: `flutter run`
2. Observe o console (terminal ou Logcat no Android Studio)
3. Procure por uma linha como:
   ```'
   D/FirebaseAppCheck: Debug App Check token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
4. Copie esse token UUID

### 3.2 Cadastrar o token no Firebase Console

1. Acesse Firebase Console → **App Check** → aba **"Apps"**
2. Clique no app (Android ou iOS) → **"Tokens de debug"** (ou "Manage debug tokens")
3. Clique em **"Adicionar token de debug"**
4. Cole o UUID copiado no passo 3.1
5. Dê um nome (ex: "Notebook de Dev - João")
6. Clique em **"Salvar"**

Agora o app em modo debug consegue passar pelo App Check.

> **Dica:** Cada desenvolvedor gera seu próprio debug token. Nunca commite tokens de debug no repositório.

---

## Parte 4 — Web (opcional)

Se você quiser suporte Web com App Check:

1. Acesse https://www.google.com/recaptcha/admin
2. Registre seu domínio com **reCAPTCHA v3**
3. Copie a **Site Key** gerada
4. Em `lib/main.dart`, substitua:
   ```dart
   webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_V3_SITE_KEY'),
   ```
   pelo valor real da sua Site Key.

---

## Limpeza do histórico Git (URGENTE se o repo é público)

Duas API keys antigas do Gemini foram commitadas no histórico:
- `AIzaSyAk8yttC4weatQe6tPd49ZcIYsyGk2t7bc` (commit 675706c)
- `AIzaSyDdyL9rwq8bohkpLzLxQGyt6WBbzmGzMZA` (commit 03f726b)

Ambas já foram revogadas pelo Google, mas aparecem no `git log`. Para limpar:

### Instalar git-filter-repo

```bash
pip install git-filter-repo
```

### Remover as keys do histórico

```bash
git filter-repo --replace-text <(echo "AIzaSyAk8yttC4weatQe6tPd49ZcIYsyGk2t7bc==>REDACTED_KEY_1") --force
git filter-repo --replace-text <(echo "AIzaSyDdyL9rwq8bohkpLzLxQGyt6WBbzmGzMZA==>REDACTED_KEY_2") --force
```

### Forçar push para o GitHub

```bash
git push origin --force --all
git push origin --force --tags
```

> ⚠️ `--force` reescreve o histórico remoto. Avise os colaboradores — eles precisarão fazer `git clone` novamente.

---

## Estrutura final esperada

```
lib/
├── firebase_options.dart     ← gerado por flutterfire configure (não edite)
├── main.dart                 ← inicializa Firebase + App Check
├── services/
│   └── ai_service.dart       ← chama Gemini via Firebase AI Logic (sem API key)
└── screens/
    └── ai_chat_screen.dart   ← UI do chatbot (inalterada)

android/
└── app/
    └── google-services.json  ← NO .gitignore — não commite

ios/
└── Runner/
    └── GoogleService-Info.plist  ← NO .gitignore — não commite
```

---

## Checklist final

- [ ] Projeto Firebase criado
- [ ] App Android registrado + `google-services.json` em `android/app/`
- [ ] App iOS registrado + `GoogleService-Info.plist` em `ios/Runner/` (via Xcode)
- [ ] Firebase AI Logic habilitado (Gemini Developer API)
- [ ] App Check ativado para Android (Play Integrity) e iOS (App Attest)
- [ ] `flutterfire configure` executado → `firebase_options.dart` gerado
- [ ] `flutter pub get` executado
- [ ] Debug token cadastrado no Console para desenvolvimento local
- [ ] App rodando sem erros: `flutter run`
- [ ] Histórico Git limpo com `git filter-repo`
