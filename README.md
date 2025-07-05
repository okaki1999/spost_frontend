# 🌍 Spost - 位置情報ベースのミニマルSNS

位置情報を活用したシンプルなソーシャルネットワーキングアプリです。近くの投稿を発見し、自分の場所から投稿を共有できます。

## 🚀 技術スタック

### フロントエンド
- **Flutter** - クロスプラットフォームモバイルアプリ
- **Firebase Auth** - ユーザー認証
- **Riverpod** - 状態管理
- **Geolocator** - 位置情報取得
- **Dio** - HTTP通信

### バックエンド
- **NestJS** - Node.jsフレームワーク
- **Prisma ORM** - データベースORM
- **PostgreSQL + PostGIS** - 地理空間データベース
- **Firebase Admin SDK** - トークン検証

### インフラ
- **Supabase** - PostgreSQLデータベース（PostGIS拡張）
- **Firebase** - 認証・ホスティング
- **Render** - バックエンドホスティング（開発）
- **Railway** - バックエンドホスティング（本番）

## 📱 機能

### ユーザー認証
- メール/パスワードでの登録・ログイン
- Firebase Authによる安全な認証
- セッション管理

### 投稿機能
- 位置情報付き投稿作成
- タイトル・内容の入力
- 自動位置情報取得
- 投稿一覧表示

### 位置情報
- 現在地の自動取得
- PostGISによる地理空間クエリ
- 近くの投稿表示（準備中）

## 🛠️ セットアップ

### 前提条件
- Node.js 18+
- Flutter 3.0+
- PostgreSQL（Supabase推奨）
- Firebase プロジェクト

### 1. リポジトリのクローン
```bash
git clone <repository-url>
cd Spost
```

### 2. バックエンドセットアップ

```bash
cd spost_backend

# 依存関係のインストール
npm install

# 環境変数の設定
cp .env.example .env
```

`.env`ファイルを編集：
```env
DATABASE_URL="postgresql://username:password@host:port/database"
FIREBASE_PROJECT_ID="your-firebase-project-id"
FIREBASE_PRIVATE_KEY="your-firebase-private-key"
FIREBASE_CLIENT_EMAIL="your-firebase-client-email"
```

```bash
# データベースマイグレーション
npx prisma migrate dev

# Prismaクライアント生成
npx prisma generate

# 開発サーバー起動
npm run start:dev
```

### 3. フロントエンドセットアップ

```bash
cd spost_frontend

# 依存関係のインストール
flutter pub get

# Firebase設定
# firebase_options.dartを生成するか、手動で設定
```

`lib/firebase_options.dart`を設定（Firebase CLIで生成推奨）

```bash
# アプリ起動
flutter run
```

### 4. データベース設定（Supabase）

1. Supabaseプロジェクトを作成
2. PostGIS拡張を有効化：
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```
3. 接続文字列を`.env`に設定

### 5. Firebase設定

1. Firebaseプロジェクトを作成
2. Authenticationでメール/パスワード認証を有効化
3. サービスアカウントキーをダウンロード
4. 設定を環境変数に追加

## 📁 プロジェクト構造

```
Spost/
├── spost_backend/          # NestJS バックエンド
│   ├── src/
│   │   ├── auth/          # 認証関連
│   │   ├── posts/         # 投稿API
│   │   ├── firebase/      # Firebase設定
│   │   └── prisma/        # Prisma設定
│   ├── prisma/
│   │   └── schema.prisma  # データベーススキーマ
│   └── package.json
├── spost_frontend/         # Flutter フロントエンド
│   ├── lib/
│   │   ├── providers/     # Riverpod状態管理
│   │   ├── screens/       # UI画面
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## 🔧 開発

### バックエンド開発
```bash
cd spost_backend
npm run start:dev    # 開発サーバー
npm run build        # ビルド
npm run start:prod   # 本番サーバー
```

### フロントエンド開発
```bash
cd spost_frontend
flutter run          # デバッグ実行
flutter build web    # Webビルド
flutter build apk    # Androidビルド
```

### データベース管理
```bash
cd spost_backend
npx prisma studio    # Prisma Studio起動
npx prisma migrate dev  # マイグレーション
npx prisma generate     # クライアント生成
```

## 🚀 デプロイ

### バックエンド（Render）
1. Renderで新しいWeb Serviceを作成
2. GitHubリポジトリを接続
3. 環境変数を設定
4. ビルドコマンド: `npm install && npm run build`
5. 起動コマンド: `npm run start:prod`

### フロントエンド（Firebase Hosting）
```bash
cd spost_frontend
flutter build web
firebase deploy
```

## 📊 API仕様

### 認証
- `POST /auth/verify` - Firebaseトークン検証

### 投稿
- `GET /posts` - 投稿一覧取得
- `POST /posts` - 新規投稿作成
- `GET /posts/nearby` - 近くの投稿取得（準備中）

## 🤝 コントリビューション

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 🆘 トラブルシューティング

### よくある問題

**Prismaマイグレーションエラー**
```bash
# PostGIS拡張が有効になっているか確認
npx prisma db push
```

**Firebase認証エラー**
- Firebase設定が正しいか確認
- サービスアカウントキーの形式を確認

**位置情報エラー**
- ブラウザの位置情報権限を確認
- HTTPS環境で実行しているか確認

## 📞 サポート

問題が発生した場合は、GitHubのIssuesで報告してください。
