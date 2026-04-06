# SubLog - SwiftUI 画面仕様書

**バージョン**：1.7  
**対象**：SubLog - サブスク管理アプリ  
**技術スタック**：SwiftUI / SwiftData / Swift Charts / StoreKit 2  
**最終更新**：2026-03-09

| バージョン | 変更内容 |
|-----------|---------|
| v1.0 | 初版作成 |
| v1.1 | タブバーアイコンを絵文字 → SF Symbols に変更 |
| v1.2 | カラーテーマをミントグリーンに刷新、テーマ選択機能（Section 9）を追加 |
| v1.3 | データモデルを `Service / Subscription / Payment / GachaTemplate` に再設計。全画面のデータ取得ロジックをモデルに合わせて書き直し |
| v1.4 | 画面構成と仕様書の整合確認・修正。設定画面のグループ順を調整 |
| v1.5 | ① `Payment.service` 非 Optional 化　② `Subscription.service` 非 Optional 化　③ `Subscription.payments` 逆参照追加　④ `nextRenewalDate` 差分計算方式（O(1)）に変更　⑤ `Service.icon` PNG Data 保存と明記　⑥ Service 削除時の二段階確認ダイアログ追加 |
| v1.7 | Section 5 SubscriptionDetailView に解約済み時の「節約額表示」を追加（計算ロジック `savedAmount` / 節約額カード UI / 表示条件） |

---

## 📌 ドキュメントの使い方

このドキュメントは **画面単位でAIエージェントに実装を依頼する際の仕様書** です。  
各画面セクションをそのままプロンプトとして渡すことを想定しています。

> 💡 **AIへの渡し方の推奨フロー**  
> 1. データモデル（Section 0）を先に実装する  
> 2. 各画面を1つずつ依頼する  
> 3. 「画面の目的 / 表示データ・取得ロジック / ユーザー操作」の3点セットで渡す

---

## Section 0：データモデル

> ⚠️ **必ずUIの実装前にこのモデルを確定・実装すること**

### モデル設計の考え方

```
Service（サービス定義。ゲーム・サブスクを問わず「サービス」として統一管理）
 ├── payments:        [Payment]        実際に発生した支払いイベント
 ├── subscriptions:   [Subscription]   定期課金契約（0件以上）
 └── gachaTemplates:  [GachaTemplate]  石テンプレート（ゲームのみ使用）
```

**責務の分離：**

| モデル | 責務 |
|--------|------|
| `Service` | サービス自体の情報（名前・カテゴリ・アイコン・メモ） |
| `Subscription` | 定期課金契約（金額・課金サイクル・開始日・解約状態） |
| `Payment` | 実際に発生した支払いイベント（ガチャ・月パス更新・サブスク更新など） |
| `GachaTemplate` | ゲームごとの石パック定義（素早いPayment記録に使用） |

**Service と Subscription の関係：**

```
Service（原神）
  serviceType = .game
  subscriptions:
    - Subscription（月間パス: ¥600/月）
    - Subscription（シーズンパス: ¥2,400/3ヶ月）
  payments:
    - Payment（ガチャ石×60個: ¥9,800）
    - Payment（月間パス更新: ¥600）  ← subscription に紐づく

Service（Netflix）
  serviceType = .subscription
  subscriptions:
    - Subscription（月額スタンダード: ¥1,490/月）
  payments:
    - Payment（月額更新: ¥1,490）  ← subscription に紐づく
```

---

### SwiftData モデル定義

> ⚠️ **設計方針（v1.5 変更点）**
> - `Payment.service` / `Subscription.service` は **非 Optional**（Payment・Subscription は必ず Service に属するため）
> - SwiftData の Optional リレーションはクラッシュ要因になることがあるため非 Optional を推奨
> - `Subscription.payments` の逆参照を追加（`subscription.payments` で直接取得可能に）
> - `Service.icon` は **UIImage → PNG Data** で保存（PNG 指定で色再現・アルファ対応）
> - `Service` 削除時は cascade により `Payment / Subscription / GachaTemplate` がすべて削除されるため、**削除確認ダイアログが必須**（Section 4・UI仕様参照）

```swift
import SwiftData
import Foundation

// MARK: - Service（サービス定義）

@Model
class Service {
    var id: UUID = UUID()
    var name: String                        // サービス名（例: "原神", "Netflix"）
    var category: Category                  // カテゴリ
    var serviceType: ServiceType            // .game / .subscription
    var icon: Data?                         // ⑤ UIImage → PNG Data で保存
                                            //   icon = image.pngData()
    var memo: String?                       // サービス全体のメモ
    var createdAt: Date = Date()

    // ⚠️ cascade: Service削除時に子レコードもすべて削除される
    @Relationship(deleteRule: .cascade, inverse: \Payment.service)
    var payments: [Payment] = []

    @Relationship(deleteRule: .cascade, inverse: \Subscription.service)
    var subscriptions: [Subscription] = []

    @Relationship(deleteRule: .cascade, inverse: \GachaTemplate.service)
    var gachaTemplates: [GachaTemplate] = []

    init(name: String, category: Category, serviceType: ServiceType) {
        self.name = name
        self.category = category
        self.serviceType = serviceType
    }
}


// MARK: - Subscription（定期課金契約）

@Model
class Subscription {
    var id: UUID = UUID()
    var label: String                       // 契約名（例: "月額スタンダード", "月パス", "シーズンパス"）
    var billingType: BillingType            // 課金サイクル
    var price: Int                          // 金額（円）
    var startDate: Date                     // 契約開始日
    var isActive: Bool = true               // true=継続中, false=解約済
    var canceledDate: Date?                 // 解約日
    var memo: String?

    // ② 非 Optional：Subscription は必ず Service に属する
    var service: Service

    // ③ 逆参照：この Subscription に紐づく Payment を直接取得できる
    @Relationship(inverse: \Payment.subscription)
    var payments: [Payment] = []

    init(label: String, billingType: BillingType, price: Int, startDate: Date, service: Service) {
        self.label = label
        self.billingType = billingType
        self.price = price
        self.startDate = startDate
        self.service = service
    }
}


// MARK: - Payment（支払いイベント）

@Model
class Payment {
    var id: UUID = UUID()
    var date: Date                          // 支払い日
    var amount: Int                         // 支払い金額（円）
    var type: PaymentType                   // 支払い種別
    var itemName: String?                   // 内容名（"ガチャ石×60個", "月額更新" など）
    var memo: String?
    var screenshotData: Data?               // スクショ（プレミアム限定）

    // ① 非 Optional：Payment は必ず Service に属する
    var service: Service

    // サブスク更新など特定Subscriptionに紐づく場合はセット、ガチャ等は nil
    var subscription: Subscription?

    init(date: Date, amount: Int, type: PaymentType, service: Service) {
        self.date = date
        self.amount = amount
        self.type = type
        self.service = service
    }
}


// MARK: - GachaTemplate（石テンプレート）

@Model
class GachaTemplate {
    var id: UUID = UUID()
    var label: String                       // 表示名（例: "💎 120石", "月間パス"）
    var amount: Int                         // 金額（円）
    var sortOrder: Int = 0                  // 表示順

    var service: Service                    // 非 Optional（GachaTemplate も必ず Service に属する）

    init(label: String, amount: Int, service: Service) {
        self.label = label
        self.amount = amount
        self.service = service
    }
}
```

#### ⑤ アイコン保存の実装パターン

```swift
// 保存時：UIImage → PNG Data
func saveIcon(_ image: UIImage, to service: Service) {
    service.icon = image.pngData()   // PNG 指定（JPEG より色再現・透過対応に優れる）
}

// 表示時：Data → UIImage
var iconImage: UIImage? {
    guard let data = service.icon else { return nil }
    return UIImage(data: data)
}
```

---

### Enum 定義

```swift
enum Category: String, CaseIterable, Codable {
    case game    = "ゲーム"
    case music   = "音楽"
    case video   = "動画"
    case book    = "書籍"
    case ai      = "AI"
    case other   = "その他"
}

enum ServiceType: String, Codable {
    case game         = "ゲーム課金"
    case subscription = "サブスク"
}

enum BillingType: String, CaseIterable, Codable {
    case weekly   = "ウィークリー"
    case monthly  = "マンスリー"
    case seasonal = "シーズンパス"   // 3ヶ月ごと
    case annual   = "年額"
    case oneTime  = "単発"
}

enum PaymentType: String, Codable {
    case gacha        = "ガチャ"
    case passRenewal  = "パス更新"       // 月パス・シーズンパス更新
    case subscription = "サブスク更新"   // Netflix等の月額・年額更新
    case other        = "その他"
}
```

---

### モデル間のリレーション図

```
Service
  │
  ├─[payments]──────────► Payment
  │                          ├ date / amount / type / itemName / memo
  │                          ├ service: Service          ← 非 Optional ①
  │                          └ subscription? ────────────────────────────┐
  │                                                                       │
  ├─[subscriptions]──────► Subscription ◄─────────────────────────────────┘
  │                          ├ label / billingType / price
  │                          ├ startDate / isActive / canceledDate
  │                          ├ service: Service          ← 非 Optional ②
  │                          └ payments: [Payment]       ← 逆参照追加 ③
  │
  └─[gachaTemplates]─────► GachaTemplate
                             ├ label / amount
                             └ service: Service          ← 非 Optional
```

**Payment と Subscription の紐づけルール：**

| Payment の種別 | `payment.subscription` |
|---------------|----------------------|
| ガチャ課金 | `nil`（特定Subscriptionと無関係） |
| 月パス更新 | `Subscription（月パス）` |
| Netflix月額更新 | `Subscription（月額スタンダード）` |
| その他 | 任意 |

---

### よく使うクエリパターン

```swift
// ① 今月の全支払い合計
let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())!
let total = services.flatMap { $0.payments }
    .filter { thisMonth.contains($0.date) }
    .reduce(0) { $0 + $1.amount }

// ② あるServiceの全Payment（日付降順）
let sorted = service.payments.sorted { $0.date > $1.date }

// ③ あるSubscriptionに紐づくPaymentを逆参照で取得（推奨）
let subPayments = subscription.payments
    .sorted { $0.date > $1.date }

// ④ アクティブなSubscription全件（更新日が近い順）
let active = services.flatMap { $0.subscriptions }.filter { $0.isActive }

// ⑤ 7日以内に更新があるSubscription
let upcoming = active.filter {
    guard let next = nextRenewalDate(for: $0) else { return false }
    return next.timeIntervalSinceNow <= 7 * 24 * 3600
}
```

---

## Section 1：タブバー構成

### タブ構成とSF Symbolsアイコン

| タブ | ラベル | SF Symbol（通常） | SF Symbol（選択時） |
|------|--------|------------------|-------------------|
| [0] | ホーム | `house` | `house.fill` |
| [1] | 履歴 | `rectangle.stack` | `rectangle.stack.fill` |
| [2] | 記録 | `plus`（円形ボタン） | `plus` |
| [3] | 分析 | `chart.bar` | `chart.bar.fill` |
| [4] | 設定 | `gearshape` | `gearshape.fill` |

### 中央「記録」ボタンの実装

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showRecordSheet = false
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("ホーム", systemImage: selectedTab == 0 ? "house.fill" : "house") }
                    .tag(0)
                HistoryView()
                    .tabItem { Label("履歴", systemImage: selectedTab == 1 ? "rectangle.stack.fill" : "rectangle.stack") }
                    .tag(1)
                Color.clear
                    .tabItem { Label("記録", systemImage: "plus") }
                    .tag(2)
                AnalyticsView()
                    .tabItem { Label("分析", systemImage: selectedTab == 3 ? "chart.bar.fill" : "chart.bar") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label("設定", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape") }
                    .tag(4)
            }
            .accentColor(theme.current.primary)

            Button { showRecordSheet = true } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#FF8FA3"), Color(hex: "#FF6B8A")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "#FF6B8A").opacity(0.4), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -16)
        }
        .sheet(isPresented: $showRecordSheet) { RecordView() }
    }
}
```

**デザイン要件：**
- 記録ボタンは円形・直径56pt・ピンクグラデーション（`#FF8FA3` → `#FF6B8A`）
- ピンクはテーマに関わらず固定（全テーマ共通アクセント）
- `offset(y: -16)` でタブバー上に浮かせる

---

### カラーパレット（アプリ共通）

> 🎨 **デフォルトテーマ：ミント**（テーマ選択機能で動的切り替え可 → Section 9）

| 変数名 | カラー（ミント） | 用途 |
|--------|----------------|------|
| `primaryColor` | `#3DBDA8` | メインアクセント、アクティブタブ、ボタン |
| `primaryDark` | `#2A9E8C` | グラデーション終端 |
| `primaryLight` | `#E6F7F5` | 選択状態の背景、金額表示エリア |
| `accentRed` | `#FF7C7C` | ゲーム課金金額表示 |
| `accentYellow` | `#FFB547` | ランキング2位バッジ |
| `bgColor` | `#F2F8F7` | 全画面背景 |
| `recordBtnFrom` | `#FF8FA3` | 記録ボタン（固定） |
| `recordBtnTo` | `#FF6B8A` | 記録ボタン（固定） |

---

## Section 2：ホーム画面（HomeView）

### 画面の目的

月次の課金サマリーをひと目で把握する。数字を「楽しく見える化」するのがコンセプト。

### 使用するモデル

```swift
@Query var services: [Service]
// payments・subscriptions は service のリレーション経由で参照
```

### 表示データとデータ取得ロジック

```swift
// ─── 集計用プロパティ ───────────────────────────────────────

var allPayments: [Payment] { services.flatMap { $0.payments } }

var thisMonthInterval: DateInterval {
    Calendar.current.dateInterval(of: .month, for: Date())!
}
var lastMonthInterval: DateInterval {
    let d = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    return Calendar.current.dateInterval(of: .month, for: d)!
}

// ① 今月の課金合計
var thisMonthTotal: Int {
    allPayments.filter { thisMonthInterval.contains($0.date) }
               .reduce(0) { $0 + $1.amount }
}

// ② 前月比
var lastMonthTotal: Int {
    allPayments.filter { lastMonthInterval.contains($0.date) }
               .reduce(0) { $0 + $1.amount }
}
var monthDiff: Int { thisMonthTotal - lastMonthTotal }

// ③ 月別棒グラフ（過去6ヶ月）
struct MonthlyTotal: Identifiable {
    let id = UUID(); let month: Date; let total: Int
}
var monthlyTotals: [MonthlyTotal] {
    (0..<6).reversed().map { offset in
        let d = Calendar.current.date(byAdding: .month, value: -offset, to: Date())!
        let interval = Calendar.current.dateInterval(of: .month, for: d)!
        let total = allPayments.filter { interval.contains($0.date) }
                               .reduce(0) { $0 + $1.amount }
        return MonthlyTotal(month: d, total: total)
    }
}

// ④ 今月の課金 Top3（Service単位で集計）
struct ServiceTotal: Identifiable {
    let id = UUID(); let service: Service; let total: Int
}
var thisMonthTop3: [ServiceTotal] {
    services.map { svc in
        let total = svc.payments.filter { thisMonthInterval.contains($0.date) }
                                .reduce(0) { $0 + $1.amount }
        return ServiceTotal(service: svc, total: total)
    }
    .filter { $0.total > 0 }
    .sorted { $0.total > $1.total }
    .prefix(3).map { $0 }
}

// ⑤ アクティブなSubscription（更新が近い順・最大5件）
var activeSubscriptions: [Subscription] {
    services.flatMap { $0.subscriptions }
        .filter { $0.isActive }
        .sorted {
            (nextRenewalDate(for: $0) ?? .distantFuture) <
            (nextRenewalDate(for: $1) ?? .distantFuture)
        }
        .prefix(5).map { $0 }
}
```

### UI構成

```
ScrollView（縦スクロール）
├── ヘッダー（グラデーション：primaryColor → primaryDark）
│     ├── あいさつ文 + アバター
│     └── thisMonthTotal（大きく）+ monthDiff（↑↓）
│
├── ポジティブメッセージカード
│     └── positiveMessage(for: thisMonthTotal)
│
├── 月別棒グラフ（Swift Charts）
│     └── monthlyTotals（過去6ヶ月、当月バーをprimaryColorでハイライト）
│
├── 今月の課金 Top3
│     └── thisMonthTop3（金・銀・銅バッジ + service.name + total）
│
└── アクティブなサブスク一覧（最大5件）
      ├── 各行：ServiceIconView / subscription.label / nextRenewalDate / subscription.price
      └── 残日数バッジ（7日以内→黄 / それ以上→緑）
```

### ポジティブメッセージ換算ロジック

```swift
func positiveMessage(for amount: Int) -> String {
    switch amount {
    case 0..<1000:    return "今月はしっかり節約！それでも楽しんでますね 👍"
    case 1000..<3000: return "カフェラテ約\(amount / 500)杯分。毎日の楽しみに投資しました！"
    case 3000..<10000: return "映画館\(amount / 1800)回分の体験価値。最高のエンタメ投資！"
    case 10000..<30000: return "旅行の交通費1回分。趣味にこれだけ本気になれる自分、すごい！"
    default: return "¥\(amount.formatted())は、あなたの熱量の証。推し活最高！🔥"
    }
}
```

### ユーザー操作

| 操作 | 遷移先 |
|------|--------|
| サブスク行タップ | `ServiceDetailView(service:)` |
| Top3行タップ | `ServiceDetailView(service:)` |
| 「すべて見る」タップ | `HistoryView`（履歴タブへ） |

---

## Section 3：履歴画面（HistoryView）

### 画面の目的

過去のすべての支払いを確認する。一覧表示とカレンダー表示を切り替えられる。

### 使用するモデル

```swift
@Query var services: [Service]
```

### 表示データとデータ取得ロジック

```swift
// サービス情報を保持した Payment ラッパー
struct PaymentWithService: Identifiable {
    let id = UUID()
    let payment: Payment
    let service: Service
}

// 全Payment（日付降順）
var allPaymentsWithService: [PaymentWithService] {
    services.flatMap { svc in
        svc.payments.map { PaymentWithService(payment: $0, service: svc) }
    }
    .sorted { $0.payment.date > $1.payment.date }
}

// 検索・フィルタ適用後
var filteredPayments: [PaymentWithService] {
    allPaymentsWithService.filter { item in
        // serviceType フィルタ（ゲーム / サブスク / すべて）
        if let type = selectedServiceType, item.service.serviceType != type { return false }
        // テキスト検索（service.name または payment.itemName）
        if !searchText.isEmpty {
            let nameHit = item.service.name.localizedCaseInsensitiveContains(searchText)
            let itemHit = item.payment.itemName?.localizedCaseInsensitiveContains(searchText) ?? false
            return nameHit || itemHit
        }
        return true
    }
}

// 月ごとにグループ化（一覧モード）
var groupedByMonth: [(key: Date, value: [PaymentWithService])] {
    Dictionary(grouping: filteredPayments) {
        Calendar.current.startOfMonth(for: $0.payment.date)
    }
    .sorted { $0.key > $1.key }
}

// 日付ごとのマップ（カレンダーモード）
var paymentsByDate: [Date: [PaymentWithService]] {
    Dictionary(grouping: filteredPayments) {
        Calendar.current.startOfDay(for: $0.payment.date)
    }
}
```

### UI構成

```
NavigationStack
├── タイトル「課金履歴」
├── Picker（セグメント）：一覧 | カレンダー
│
├── 【一覧モード】
│     ├── SearchBar（.searchable → searchText にバインド）
│     ├── フィルターチップ（横スクロール）
│     │     └── [すべて | ゲーム | サブスク]
│     └── List（月ごとのセクション）
│           ├── Section Header：「2026年3月」＋月計
│           └── 各行：日付ボックス / ServiceIconView / service.name + payment.itemName / 金額
│
└── 【カレンダーモード】
      ├── 月カレンダー（paymentsByDate にある日付にドット表示）
      ├── 日付タップ → 当日 PaymentWithService を下部に展開
      └── 各行タップ → serviceType に応じて遷移先が変わる
            ├── .game → GameChargeDetailView(service:)
            └── .subscription → SubscriptionDetailView(subscription:, service:)
```

### 各行デザイン

```
[ 日付ボックス ]  [ ServiceIconView ]  [ service.name        ]  [ ¥9,800 ]
[    10       ]                       [ payment.itemName     ]  ゲーム→accentRed
[    MAR      ]                       （例: "ガチャ石×60個"）   サブスク→primaryColor
```

### ユーザー操作

| 操作 | 遷移先 |
|------|--------|
| ゲーム課金の履歴行タップ | `GameChargeDetailView(service:)` |
| サブスクの履歴行タップ | `SubscriptionDetailView(subscription:, service:)` |
| カレンダー日付タップ | 当日リスト展開（インライン） |

---

## Section 4：ゲーム課金詳細画面（GameChargeDetailView）

### 画面の目的

ゲームサービスを主語とした課金詳細画面。石テンプレート・課金グラフ・メモ/スクショを確認できる。  
履歴画面でゲーム課金の行をタップしたときに表示される。

### 受け取るパラメータ

```swift
struct GameChargeDetailView: View {
    let service: Service   // serviceType == .game を想定
}
```

### 表示データとデータ取得ロジック

```swift
// ① 統計カード
var totalPaid: Int { service.payments.reduce(0) { $0 + $1.amount } }
var thisMonthPaid: Int {
    let interval = Calendar.current.dateInterval(of: .month, for: Date())!
    return service.payments.filter { interval.contains($0.date) }
                           .reduce(0) { $0 + $1.amount }
}
var paymentCount: Int { service.payments.count }

// ② 課金履歴（直近5件）
var recentPayments: [Payment] {
    service.payments.sorted { $0.date > $1.date }.prefix(5).map { $0 }
}

// ③ 月別グラフ（過去6ヶ月）
var monthlyTotals: [MonthlyTotal] {
    (0..<6).reversed().map { offset in
        let d = Calendar.current.date(byAdding: .month, value: -offset, to: Date())!
        let interval = Calendar.current.dateInterval(of: .month, for: d)!
        let total = service.payments.filter { interval.contains($0.date) }
                                    .reduce(0) { $0 + $1.amount }
        return MonthlyTotal(month: d, total: total)
    }
}
```

### UI構成

```
ScrollView
├── ヘッダー（GradientHeaderView: primaryDark → primaryDeep）
│     ├── ServiceIconView（56pt）+ service.name 🎮
│     └── 統計カード × 3（合計課金 / 今月 / 回数）
│
├── 課金履歴（recentPayments 直近5件）
│     ├── 各行: payment.date / payment.itemName / payment.amount
│     └── 「すべて見る」→ HistoryView（service でフィルタ済み）
│
├── 課金グラフ（Swift Charts・棒グラフ）
│     └── monthlyTotals（過去6ヶ月）
│
├── 石テンプレート
│     └── service.gachaTemplates をチップ表示
│           タップ → RecordView(preselectedService:, preselectedTemplate:) を開く
│
└── メモ / スクショ
      ├── service.memo テキスト表示（タップで編集シート）
      └── 直近Paymentのスクショサムネイル（プレミアム限定）
```

### ⑥ Service削除フロー

> ⚠️ Service を削除すると cascade により **Payment・Subscription・GachaTemplate がすべて消去**される。  
> 削除前に件数を提示した上で、二段階の確認ダイアログを表示すること。

```
ナビゲーションバー「…」メニュー → 「このサービスを削除」
  ↓
【1段目 Alert】
  タイトル:「'\(service.name)' を削除しますか？」
  本文:「課金履歴 \(paymentCount)件・石テンプレート \(templateCount)件も
        すべて削除されます。この操作は取り消せません。」
  ├── 「削除する」（破壊的アクション・赤文字）→ 2段目へ
  └── 「キャンセル」

  ↓ 「削除する」タップ

【2段目 Alert（最終確認）】
  タイトル:「本当に削除しますか？」
  本文:「すべてのデータが完全に消去されます。」
  ├── 「完全に削除する」（破壊的アクション・赤文字）
  │     → context.delete(service) → 画面を閉じる
  └── 「キャンセル」
```

```swift
// 削除実装パターン
func deleteService(_ service: Service, context: ModelContext, dismiss: DismissAction) {
    context.delete(service)   // cascade で子レコードも自動削除
    dismiss()
}
```

### ユーザー操作

| 操作 | アクション |
|------|-----------|
| テンプレートチップタップ | `RecordView` を開き金額・サービスを自動入力 |
| 「すべて見る」タップ | HistoryView（対象サービスでフィルタ済み）へ |
| メモタップ | メモ編集シート表示 |
| 「このサービスを削除」タップ | 二段階確認アラート → `context.delete(service)` |

---

## Section 5：サブスク詳細画面（SubscriptionDetailView）

### 画面の目的

個別の定期課金契約の詳細・支払い履歴・次回更新日を確認し、解約管理を行う。  
`ServiceDetailView` から `.navigationDestination` で遷移する子画面。

### 受け取るパラメータ

```swift
struct SubscriptionDetailView: View {
    let subscription: Subscription
    let service: Service          // アイコン・名前の表示用
}
```

### 表示データとデータ取得ロジック

```swift
// ① この Subscription に紐づく Payment を逆参照で取得（③ v1.5）
var subscriptionPayments: [Payment] {
    subscription.payments
        .sorted { $0.date > $1.date }
}

// ② 累計支払額
var totalPaid: Int { subscriptionPayments.reduce(0) { $0 + $1.amount } }

// ③ 契約期間（月数）
var contractMonths: Int {
    Calendar.current.dateComponents([.month],
        from: subscription.startDate, to: Date()).month ?? 0
}

// ④ 次回更新日・残日数
var nextRenewal: Date? {
    guard subscription.isActive else { return nil }
    return nextRenewalDate(from: subscription.startDate,
                           billingType: subscription.billingType)
}
var daysUntilRenewal: Int? {
    guard let next = nextRenewal else { return nil }
    return Calendar.current.dateComponents([.day], from: Date(), to: next).day
}

// ⑤ 解約で節約した金額（解約済みのみ）
// 解約日から現在までの経過期間に subscription.price × 更新回数 を掛けた推定節約額
var savedAmount: Int? {
    guard !subscription.isActive,
          let canceledDate = subscription.canceledDate else { return nil }
    let cal = Calendar.current
    let now = Date()
    switch subscription.billingType {
    case .weekly:
        let days = cal.dateComponents([.day], from: canceledDate, to: now).day ?? 0
        return (days / 7) * subscription.price
    case .monthly:
        let months = cal.dateComponents([.month], from: canceledDate, to: now).month ?? 0
        return months * subscription.price
    case .seasonal:
        let months = cal.dateComponents([.month], from: canceledDate, to: now).month ?? 0
        return (months / 3) * subscription.price
    case .annual:
        let years = cal.dateComponents([.year], from: canceledDate, to: now).year ?? 0
        return years * subscription.price
    case .oneTime:
        return nil   // 単発は節約額なし
    }
}
```

### 次回更新日の計算ロジック

> ④ **差分計算方式**（ループ方式からの変更）  
> 契約開始日から現在までの経過期間を一度で割り算し、次回更新日を O(1) で求める。  
> 長期利用ユーザーでも計算コストが増加しない。

```swift
func nextRenewalDate(from startDate: Date, billingType: BillingType) -> Date? {
    let cal = Calendar.current
    let now = Date()

    // 単発は更新なし
    guard billingType != .oneTime else { return nil }

    // BillingType → Calendar.Component と繰り返し単位に変換
    let (component, value): (Calendar.Component, Int) = {
        switch billingType {
        case .weekly:   return (.day,   7)
        case .monthly:  return (.month, 1)
        case .seasonal: return (.month, 3)
        case .annual:   return (.year,  1)
        case .oneTime:  fatalError("unreachable")
        }
    }()

    // startDate から now までの経過数を計算
    let elapsed = cal.dateComponents([component], from: startDate, to: now)
    let elapsedCount = max(0, (elapsed.value(for: component) ?? 0))

    // 次回 = startDate + (経過数 + 1) × 単位
    let nextCount = elapsedCount + 1
    guard let next = cal.date(byAdding: component, value: value * nextCount, to: startDate) else {
        return nil
    }

    // 念のため next > now を保証（月末ズレ等の安全弁）
    if next <= now {
        return cal.date(byAdding: component, value: value, to: next)
    }
    return next
}

// ラッパー（Subscription を直接渡すバージョン）
func nextRenewalDate(for subscription: Subscription) -> Date? {
    guard subscription.isActive else { return nil }
    return nextRenewalDate(from: subscription.startDate, billingType: subscription.billingType)
}
```

### UI構成

```
ScrollView
├── ヘッダー（primaryColor → primaryDark）
│     ├── ServiceIconView + service.name
│     └── 統計カード × 3（月額 / 累計支払 / 契約期間）
│
├── 次回更新カード（subscription.isActive == true のみ表示）
│     └── 🔄 nextRenewal（大きく）+ daysUntilRenewal + subscription.label
│
├── 節約額カード（subscription.isActive == false かつ savedAmount != nil のみ表示）
│     └── 💰「解約してから約¥\(savedAmount)節約しました！」
│           + 解約日からの経過期間
│
├── 契約情報
│     ├── 課金タイプ：subscription.billingType.rawValue
│     ├── 開始日：subscription.startDate
│     └── 解約日：subscription.canceledDate（解約済みのみ表示）
│
├── 支払い履歴（subscriptionPayments 直近3件）
│     └── 「すべて見る」→ HistoryView（subscriptionフィルタ済み）
│
├── メモ欄（subscription.memo）
│
└── 解約ボタン（subscription.isActive == true のときのみ表示）
      → Alert → subscription.isActive = false / canceledDate = Date()
```

### 解約フロー

```
解約ボタンタップ
  → Alert: 「'\(subscription.label)' を解約しますか？」
      ├── 「解約記録を残す」→ isActive = false, canceledDate = Date()
      └── 「キャンセル」
```

### ユーザー操作

| 操作 | アクション |
|------|-----------|
| 解約ボタンタップ | 確認アラート → `subscription.isActive = false` |
| メモタップ | 編集シート表示 |
| 「すべて見る」タップ | HistoryView（subscription フィルタ済み）へ |

---

## Section 6：課金登録画面（RecordView）

### 画面の目的

「支払いを記録すること」を中心とした統一画面。  
必要に応じて `Subscription` / `Service` の新規作成も行う。

### 受け取るパラメータ（オプション）

```swift
struct RecordView: View {
    var preselectedService: Service?      = nil
    var preselectedTemplate: GachaTemplate? = nil
}
```

### 使用するモデル

```swift
@Query var services: [Service]   // サービス検索・オートコンプリート用
```

### UXフロー

```
RecordView
│
├── 【ゲーム課金タブ】
│     ├── サービス選択（既存から検索 or 新規入力）
│     ├── 石テンプレート選択チップ（選択で amount・itemName を自動入力）
│     │     or カスタム金額を手入力
│     ├── 課金タイプ（.gacha / .passRenewal）
│     ├── 日付 / メモ / スクショ添付（プレミアム限定）
│     └── 「記録する」
│           → Payment(type:, service:, subscription: nil) を保存
│               ※ passRenewal の場合は subscription を選択してセット
│
└── 【サブスクタブ】
      │
      ├── サービス選択（既存から検索 or 新規入力）
      │
      ├── Subscription選択
      │     ├── 既存: service.subscriptions を Picker で一覧表示
      │     │     選択 → subscription.price を amount に自動入力
      │     └── 「＋ 新しいプランを追加」→ インラインフォームを展開
      │           ├── プラン名（subscription.label）
      │           ├── 課金タイプ（BillingType Picker）
      │           ├── 金額
      │           └── 開始日
      │
      ├── 日付 / メモ / スクショ添付（プレミアム限定）
      └── 「記録する」
            → ① 新規Service なら保存
            → ② 新規Subscription なら保存（service に紐づけ）
            → ③ Payment(type: .subscription, service:, subscription:) を保存
```

### 保存処理

```swift
func save(context: ModelContext) throws {
    // ① 新規 Service が必要なら作成
    if isNewService {
        let svc = Service(name: serviceName, category: selectedCategory,
                          serviceType: selectedType)
        context.insert(svc)
        selectedService = svc
    }
    guard let service = selectedService else { throw RecordError.noService }

    // ② 新規 Subscription が必要なら作成
    //    init に service を渡す（非 Optional のため）
    if isNewSubscription {
        let sub = Subscription(label: subLabel, billingType: selectedBillingType,
                               price: amount, startDate: subStartDate, service: service)
        context.insert(sub)
        selectedSubscription = sub
    }

    // ③ Payment を作成（必ず実行）
    //    init に service を渡す（非 Optional のため）
    let payment = Payment(date: paymentDate, amount: amount, type: paymentType, service: service)
    payment.subscription    = selectedSubscription   // ガチャなら nil
    payment.itemName        = itemName
    payment.memo            = memo
    payment.screenshotData  = screenshotData         // プレミアムのみ非nil
    context.insert(payment)
}
```

### バリデーション

```swift
var isValid: Bool {
    guard let _ = selectedService ?? (isNewService ? Optional(()) : nil) else { return false }
    guard amount > 0 else { return false }
    if selectedType == .subscription {
        return selectedSubscription != nil || isNewSubscription
    }
    return true
}
```

### ユーザー操作

| 操作 | アクション |
|------|-----------|
| 「キャンセル」タップ | シート dismiss（確認なし） |
| 「記録する」タップ | `save()` → dismiss → ホームを更新 |
| テンプレートチップタップ | amount・itemName を自動入力 |
| スクショ添付（非プレミアム） | プレミアム誘導シート表示 |

---

## Section 7：分析画面（AnalyticsView）

### 画面の目的

課金データを複数の切り口で可視化する。「課金人生グラフ（累積）」が目玉機能。

### 使用するモデル

```swift
@Query var services: [Service]
var allPayments: [Payment] { services.flatMap { $0.payments } }
```

### 表示データとデータ取得ロジック

```swift
enum AnalyticsPeriod: String, CaseIterable { case month = "月"; case year = "年"; case allTime = "全期間" }

// 期間フィルタ済みPayment
var filteredPayments: [Payment] {
    switch selectedPeriod {
    case .month:
        let i = Calendar.current.dateInterval(of: .month, for: Date())!
        return allPayments.filter { i.contains($0.date) }
    case .year:
        let i = Calendar.current.dateInterval(of: .year, for: Date())!
        return allPayments.filter { i.contains($0.date) }
    case .allTime:
        return allPayments
    }
}

var periodTotal: Int { filteredPayments.reduce(0) { $0 + $1.amount } }

// ② カテゴリ別集計（Donutチャート）
struct CategoryTotal: Identifiable {
    let id = UUID(); let category: Category; let total: Int; var ratio: Double
}
var categoryTotals: [CategoryTotal] {
    let grouped = Dictionary(grouping: filteredPayments) {
        $0.service.category   // ① Payment.service は非 Optional（v1.5）
    }
    return grouped.map { cat, payments in
        let sum = payments.reduce(0) { $0 + $1.amount }
        return CategoryTotal(category: cat, total: sum,
                             ratio: periodTotal > 0 ? Double(sum)/Double(periodTotal) : 0)
    }.sorted { $0.total > $1.total }
}

// ③ サービス別ランキング（上位5件）
struct ServiceRanking: Identifiable {
    let id = UUID(); let service: Service; let total: Int; var ratio: Double
}
var serviceRankings: [ServiceRanking] {
    services.map { svc in
        let sum = filteredPayments.filter { $0.service?.id == svc.id }
                                  .reduce(0) { $0 + $1.amount }
        return ServiceRanking(service: svc, total: sum,
                              ratio: periodTotal > 0 ? Double(sum)/Double(periodTotal) : 0)
    }
    .filter { $0.total > 0 }
    .sorted { $0.total > $1.total }
    .prefix(5).map { $0 }
}

// ④ 年間推移（12ヶ月棒グラフ）
var yearlyMonthlyTotals: [MonthlyTotal] {
    (0..<12).reversed().map { offset in
        let d = Calendar.current.date(byAdding: .month, value: -offset, to: Date())!
        let interval = Calendar.current.dateInterval(of: .month, for: d)!
        let total = allPayments.filter { interval.contains($0.date) }
                               .reduce(0) { $0 + $1.amount }
        return MonthlyTotal(month: d, total: total)
    }
}

// ⑤ 課金人生グラフ（累積・全期間）⚠️ プレミアム限定
struct CumulativePoint: Identifiable {
    let id = UUID(); let date: Date; let cumulative: Int
}
var cumulativeData: [CumulativePoint] {
    var running = 0
    return allPayments.sorted { $0.date < $1.date }.map { p in
        running += p.amount
        return CumulativePoint(date: p.date, cumulative: running)
    }
}
```

### UI構成

```
ScrollView
├── タイトル「分析」
├── 期間切替ピッカー（Segmented）：月 | 年 | 全期間
│
├── 合計金額カード（periodTotal + 前期間比）
│
├── カテゴリ別円グラフ（Swift Charts / SectorMark）⚠️ プレミアム限定
│     └── categoryTotals を Donut 形式で表示
│
├── サービス別ランキング（serviceRankings 上位5件）
│     └── 順位バッジ + service.name + total + 割合バー
│
├── 年間推移グラフ（Swift Charts / BarMark）
│     └── yearlyMonthlyTotals（12ヶ月）
│
└── 課金人生グラフ（Swift Charts / LineMark + AreaMark）⚠️ プレミアム限定
      ├── cumulativeData
      └── 🔒 非プレミアム：ぼかし + 誘導バナー
```

### Swift Charts 実装メモ

```swift
// カテゴリ別Donut
Chart(categoryTotals) { item in
    SectorMark(angle: .value("金額", item.total),
               innerRadius: .ratio(0.6), angularInset: 2)
        .foregroundStyle(by: .value("カテゴリ", item.category.rawValue))
}

// 年間推移棒グラフ
Chart(yearlyMonthlyTotals) { item in
    BarMark(x: .value("月", item.month, unit: .month),
            y: .value("金額", item.total))
        .foregroundStyle(
            Calendar.current.isDate(item.month, equalTo: Date(), toGranularity: .month)
                ? theme.current.primary : theme.current.primaryLight
        )
}

// 課金人生グラフ（累積）
Chart(cumulativeData) { item in
    LineMark(x: .value("日付", item.date), y: .value("累計", item.cumulative))
        .foregroundStyle(theme.current.primary)
    AreaMark(x: .value("日付", item.date), y: .value("累計", item.cumulative))
        .foregroundStyle(theme.current.primary.opacity(0.15))
}
```

---

## Section 8：設定画面（SettingsView）

### 画面の目的

アプリのカスタマイズ、データ管理、プレミアムプラン管理を行う。

### 使用するモデル

```swift
@Query var services: [Service]   // エクスポート・テンプレート管理で使用
```

### UI構成

```
NavigationStack
├── タイトル「設定」
│
├── プレミアムバナー（primaryColor → primaryDark）
│     └── 「管理する」→ SubscriptionManagementView
│
├── グループ「カスタマイズ」
│     ├── 🎮 ガチャ石テンプレート管理 → GachaTemplateSettingsView
│     ├── 🎨 カラーテーマ → ThemeSelectView（シート）
│     ├── 💬 ポジティブメッセージ設定 → MessageSettingsView
│     └── 🔔 更新日リマインダー（Toggle）※仕様書記載・画面構成外
│
├── グループ「データ」
│     ├── 📤 データエクスポート（CSV / JSON）→ ExportView
│     ├── ☁️ iCloud バックアップ（Toggle）※仕様書記載・画面構成外
│     └── 🗑️ データを削除 → 確認アラート
│
└── グループ「アプリについて」
      ├── ⭐ App Store でレビュー
      ├── 📋 利用規約・プライバシーポリシー
      └── バージョン表示
```

> 📝 **画面構成との対応：**  
> `プレミアムプラン管理` → プレミアムバナー  
> `ガチャ石テンプレート管理` → カスタマイズグループ先頭  
> `テーマ選択` → ThemeSelectView（シート）  
> `ポジティブメッセージ設定` → MessageSettingsView  
> `データエクスポート` → データグループ  
> `データ管理（バックアップ等）` → データグループ（iCloudバックアップ・削除）  
> `アプリについて` → アプリについてグループ

### ガチャ石テンプレート管理（GachaTemplateSettingsView）

```swift
var gameServices: [Service] {
    services.filter { $0.serviceType == .game }
}
```

```
List（サービス別セクション）
├── Section「原神」
│     ├── "💎 120石  ¥9,800"   （スワイプで削除）
│     ├── "💎 60個   ¥4,900"
│     └── "🌙 月間パス ¥600"
└── 「+ テンプレートを追加」
      → シートで label・amount を入力
      → GachaTemplate を作成し service に紐づけて保存
```

### エクスポート仕様（CSV）

```swift
// ヘッダー行 + Payment1件1行
// date, serviceName, serviceType, subscriptionLabel, itemName, amount, memo
// 2026/03/10, 原神, ゲーム課金, , ガチャ石×60個, 9800,
// 2026/03/08, Netflix, サブスク, 月額スタンダード, 月額更新, 1490,

func exportCSV(services: [Service]) -> String {
    var rows = ["date,serviceName,serviceType,subscriptionLabel,itemName,amount,memo"]
    for svc in services {
        for p in svc.payments.sorted(by: { $0.date < $1.date }) {
            rows.append([
                p.date.formatted(date: .numeric, time: .omitted),
                svc.name, svc.serviceType.rawValue,
                p.subscription?.label ?? "",
                p.itemName ?? "", "\(p.amount)", p.memo ?? ""
            ].joined(separator: ","))
        }
    }
    return rows.joined(separator: "\n")
}
```

### プレミアムプラン管理（SubscriptionManagementView）

```swift
let monthlyProductID = "jp.yourapp.sublog.premium.monthly"
let annualProductID  = "jp.yourapp.sublog.premium.annual"
```

| プラン | 価格 | Apple価格ティア |
|--------|------|----------------|
| 月額 | ¥250〜¥380 | Tier 1〜2 |
| 年額 | ¥1,800〜¥2,400 | Tier 6〜8 |

---

## Section 9：テーマ選択画面（ThemeSelectView）

### 画面の目的

アプリ全体のメインカラーをユーザーが自由に変更できる。設定画面の「カラーテーマ」行タップで `.sheet` 表示。

### テーマ定義

```swift
struct AppTheme: Identifiable {
    let id: String; let name: String
    let primary: Color       // メインカラー
    let primaryDark: Color   // グラデーション終端・強調
    let primaryDeep: Color   // ヘッダー最深色
    let primaryMid: Color    // バー・ボーダー
    let primaryLight: Color  // カード背景・選択行
    let primaryXLight: Color // 画面背景色
}

extension AppTheme {
    static let all: [AppTheme] = [
        AppTheme(id:"mint",   name:"ミント",
            primary:Color(hex:"#3DBDA8"), primaryDark:Color(hex:"#1A9E8A"),
            primaryDeep:Color(hex:"#107060"), primaryMid:Color(hex:"#87D9CF"),
            primaryLight:Color(hex:"#D8F4F0"), primaryXLight:Color(hex:"#EFF9F7")),
        AppTheme(id:"green",  name:"グリーン",
            primary:Color(hex:"#52C97D"), primaryDark:Color(hex:"#2EA055"),
            primaryDeep:Color(hex:"#1A6B35"), primaryMid:Color(hex:"#8FDBA8"),
            primaryLight:Color(hex:"#D4F5E0"), primaryXLight:Color(hex:"#EDFAF3")),
        AppTheme(id:"pink",   name:"ピンク",
            primary:Color(hex:"#F07099"), primaryDark:Color(hex:"#C83A6A"),
            primaryDeep:Color(hex:"#8C1A42"), primaryMid:Color(hex:"#F5A0BC"),
            primaryLight:Color(hex:"#FCD8E8"), primaryXLight:Color(hex:"#FFF0F5")),
        AppTheme(id:"blue",   name:"ブルー",
            primary:Color(hex:"#5B9EEF"), primaryDark:Color(hex:"#2E68D4"),
            primaryDeep:Color(hex:"#1040A0"), primaryMid:Color(hex:"#90C0F5"),
            primaryLight:Color(hex:"#D0E8FB"), primaryXLight:Color(hex:"#EBF4FF")),
        AppTheme(id:"purple", name:"パープル",
            primary:Color(hex:"#9B72CF"), primaryDark:Color(hex:"#6A3EAF"),
            primaryDeep:Color(hex:"#401880"), primaryMid:Color(hex:"#BFA0E0"),
            primaryLight:Color(hex:"#E0D0F5"), primaryXLight:Color(hex:"#F3EEFF")),
        AppTheme(id:"orange", name:"オレンジ",
            primary:Color(hex:"#F5914A"), primaryDark:Color(hex:"#CC6018"),
            primaryDeep:Color(hex:"#8C3A08"), primaryMid:Color(hex:"#F8B880"),
            primaryLight:Color(hex:"#FCE0C8"), primaryXLight:Color(hex:"#FFF2EA")),
    ]
    static let `default` = AppTheme.all[0]
}

class ThemeManager: ObservableObject {
    @Published var current: AppTheme = AppTheme.default {
        didSet { UserDefaults.standard.set(current.id, forKey: "selectedThemeID") }
    }
    init() {
        if let id = UserDefaults.standard.string(forKey: "selectedThemeID"),
           let t = AppTheme.all.first(where: { $0.id == id }) { current = t }
    }
    func apply(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) { current = theme }
    }
}
```

### ThemeRow の実装

```swift
struct ThemeRow: View {
    let theme: AppTheme; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [theme.primary, theme.primaryDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name).font(.system(size: 15, weight: .bold))
                    Text("タップして適用").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.primary).font(.system(size: 22))
                } else {
                    Circle().strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(14)
            .background(isSelected ? theme.primaryLight : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? theme.primary : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
```

---

## Section 10：フリー / プレミアム制限一覧

| 機能 | フリー | プレミアム |
|------|--------|-----------|
| Service登録 | 上限10件 | 無制限 |
| Payment記録 | 無制限 | 無制限 |
| 月別グラフ | ✅ | ✅ |
| カテゴリ別円グラフ | ❌ | ✅ |
| 課金人生グラフ | ❌ | ✅ |
| スクショ添付 | ❌ | ✅ |
| 更新リマインダー通知 | ❌ | ✅ |
| GachaTemplate | 全Service合計3件まで | 無制限 |
| データエクスポート | ❌ | ✅ |

```swift
class EntitlementManager: ObservableObject {
    @Published var isPremium: Bool = false

    func canAddService(currentCount: Int) -> Bool { isPremium || currentCount < 10 }
    func canAddGachaTemplate(totalCount: Int) -> Bool { isPremium || totalCount < 3 }
    func canAttachScreenshot() -> Bool { isPremium }
    func canViewAdvancedAnalytics() -> Bool { isPremium }
    func canExportData() -> Bool { isPremium }
}
```

---

## Section 11：共通コンポーネント

### ServiceIconView

```swift
struct ServiceIconView: View {
    let service: Service; let size: CGFloat
    var body: some View {
        Group {
            if let data = service.icon, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: service.category.sfSymbol)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(service.category.tintColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(service.category.tintColor.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }
}

extension Category {
    var sfSymbol: String {
        switch self {
        case .game:  return "gamecontroller.fill"
        case .music: return "music.note"
        case .video: return "play.tv.fill"
        case .book:  return "book.fill"
        case .ai:    return "sparkles"
        case .other: return "square.grid.2x2.fill"
        }
    }
    var tintColor: Color {
        switch self {
        case .game:  return .orange
        case .music: return .green
        case .video: return .red
        case .book:  return .blue
        case .ai:    return .purple
        case .other: return .gray
        }
    }
}
```

### RenewalBadgeView

```swift
struct RenewalBadgeView: View {
    let daysUntilRenewal: Int
    var body: some View {
        Text(daysUntilRenewal <= 0 ? "今日更新" : "あと\(daysUntilRenewal)日")
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(daysUntilRenewal <= 7 ? Color.yellow.opacity(0.2) : Color.green.opacity(0.15))
            .foregroundStyle(daysUntilRenewal <= 7 ? .orange : .green)
            .clipShape(Capsule())
    }
}
```

### GradientHeaderView

```swift
struct GradientHeaderView<Content: View>: View {
    let colors: [Color]
    @ViewBuilder let content: () -> Content
    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.08)).frame(width: 200).offset(x: 80, y: -60)
            content()
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
    }
}
```

### Calendar ヘルパー

```swift
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let c = dateComponents([.year, .month], from: date)
        return self.date(from: c)!
    }
}
```

---

## Appendix：AIへの依頼テンプレート

```
以下の仕様に従って、SwiftUI + SwiftData で [画面名] を実装してください。

【データモデル】
// Section 0 の Service / Subscription / Payment / GachaTemplate をコピー

【画面の目的】
// Section X の「画面の目的」をコピー

【使用するモデルとデータ取得ロジック】
// Section X の「使用するモデル」「表示データとデータ取得ロジック」をコピー

【UI構成】
// Section X の「UI構成」をコピー

【ユーザー操作】
// Section X の「ユーザー操作」をコピー

【技術要件】
- SwiftUI（iOS 17以上）、SwiftData でデータ永続化
- グラフは Swift Charts を使用
- カラーは ThemeManager（@EnvironmentObject）の theme.current.primary 等を使用
  - デフォルト: primaryColor = #3DBDA8 / bg = #F2F8F7
- フォント: システムフォント（SF Pro）
- アイコン: SF Symbols のみ使用（絵文字禁止）
  - タブバー: house / rectangle.stack / plus / chart.bar / gearshape
  - 選択時は .fill サフィックスを付ける
  - 中央「記録」ボタン: 円形ピンクグラデーション（#FF8FA3 → #FF6B8A）

【その他】
- プレビュー用 SampleData を含めてください
- accessibilityLabel を最低限付与してください
```

---

*このドキュメントは開発進行に合わせて随時更新してください。*  
*バージョン管理は Git で行い、画面単位でブランチを切ることを推奨します。*
