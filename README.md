# Organiza+

Controle de estoque simples para pequenas empresas.

- **App (Flutter, pasta `app/`)**: usado no dia a dia para fotografar produtos e contar o estoque.
- **Gestão (React, pasta `erp/`)**: site para acompanhar e gerenciar tudo pelo computador.

Os dois usam o mesmo projeto Firebase (`oragnizamais`) e o mesmo login. O que é feito em um aparece na hora no outro.

```
Organiza/
├── app/                  # App Flutter (celular)
├── erp/                  # Site de gestão (React + Vite + TypeScript)
├── firebase/
│   ├── firestore.rules   # Regras de acesso ao banco (valem para app e site)
│   └── firestore.indexes.json
├── firebase.json         # Configuração do Firebase CLI (regras + hospedagem do site)
└── .firebaserc           # Projeto Firebase padrão
```

Os comandos `firebase ...` são rodados na raiz. Os do Flutter, dentro de `app/`, e os do site, dentro de `erp/`.

## Dados no Firestore

| Coleção      | Campos                                                                 |
|--------------|------------------------------------------------------------------------|
| `categories` | `name`, `color` (`#RRGGBB`)                                            |
| `products`   | `code`, `name`, `categoryId`, `quantity`, `minStock`, `price`, `photo`, `updatedAt` |
| `sales`      | `items` (`productId`, `code`, `name`, `quantity`, `price`), `total`, `payment` (`dinheiro`/`pix`/`cartao`), `status` (`done`/`cancelled`), `userEmail`, `createdAt` |
| `movements`  | `productId`, `productName`, `type` (`in`/`out`/`adjust`/`sale`/`sale_cancel`), `delta`, `source` (`app`/`erp`), `userEmail`, `createdAt`, `saleId` |

- Toda alteração de quantidade, no app ou no site, gera um registro em `movements` (histórico).
- A foto do produto é salva comprimida (até 600 px) dentro do próprio documento. Assim não é preciso usar o Firebase Storage, que exige o plano pago.
- `minStock` define quando o produto aparece como "precisa repor". É configurado pelo site.
- `code` é único. Se ficar em branco no cadastro, é gerado automaticamente (0001, 0002…). No caixa do site, o vendedor digita o código (ou usa um leitor de código de barras USB) e o produto entra na venda.
- As vendas são feitas pelo caixa do site e dão baixa no estoque na hora. O app mostra o acompanhamento das vendas.

## Configuração do Firebase (uma vez)

No [Console do Firebase](https://console.firebase.google.com/project/oragnizamais):

1. **Authentication → Sign-in method**: ative **E-mail/senha**.
2. **Firestore Database → Criar banco de dados**: modo produção, região `southamerica-east1` (São Paulo).
3. Publique as regras de acesso:
   ```bash
   firebase login
   firebase deploy --only firestore:rules
   ```

## Rodando o app

```bash
cd app
flutter pub get
flutter run
```

A chave do Gemini (assistente de IA) fica em `app/lib/config/secrets.dart`, que não vai para o git:

```dart
const String geminiApiKey = 'SUA_CHAVE';
```

> No Windows, o build Android falha se o caminho da pasta tiver acentos ou caracteres como `º`.
> Clone o projeto em um caminho simples, por exemplo `C:\dev\Organiza`.

## Rodando o site de gestão

```bash
cd erp
npm install
npm run dev        # abre em http://localhost:5173
```

Para publicar no Firebase Hosting (gratuito):

```bash
cd erp && npm run build && cd ..
firebase deploy --only hosting
```
