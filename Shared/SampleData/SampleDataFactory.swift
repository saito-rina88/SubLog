import Foundation
import SwiftData

#if DEBUG
enum SampleDataFactory {
    static func makeServices() -> [Service] {
        [
            makeGameService(
                name: "原神",
                gachaTemplates: [
                    ("空月の祝福", 610, 0),
                    ("創世結晶 980個", 1_840, 1),
                    ("創世結晶 6480個", 12_000, 2)
                ],
                monthlyPayments: [
                    [
                        payment(amount: 12_000, type: "ガチャ", day: 4, itemName: "限定祈願 80連"),
                        payment(amount: 1_840, type: "アイテム購入", day: 17, itemName: "創世結晶 980個"),
                        payment(amount: 610, type: "アイテム購入", day: 26, itemName: "空月の祝福")
                    ],
                    [
                        payment(amount: 1_840, type: "ガチャ", day: 8, itemName: "限定祈願 20連"),
                        payment(amount: 3_680, type: "ガチャ", day: 14, itemName: "武器祈願 40連")
                    ],
                    [
                        payment(amount: 12_000, type: "ガチャ", day: 6, itemName: "新キャラ祈願 80連"),
                        payment(amount: 610, type: "アイテム購入", day: 23, itemName: "空月の祝福"),
                        payment(amount: 1_840, type: "アイテム購入", day: 27, itemName: "創世結晶 980個")
                    ],
                    [
                        payment(amount: 1_220, type: "アイテム購入", day: 5, itemName: "紀行真珠"),
                        payment(amount: 12_000, type: "ガチャ", day: 19, itemName: "復刻祈願 80連")
                    ],
                    [
                        payment(amount: 610, type: "アイテム購入", day: 9, itemName: "空月の祝福"),
                        payment(amount: 3_680, type: "ガチャ", day: 18, itemName: "限定祈願 40連"),
                        payment(amount: 1_840, type: "アイテム購入", day: 28, itemName: "創世結晶 980個")
                    ],
                    [
                        payment(amount: 12_000, type: "ガチャ", day: 3, itemName: "今期ピックアップ 80連"),
                        payment(amount: 610, type: "アイテム購入", day: 11, itemName: "空月の祝福"),
                        payment(amount: 1_220, type: "アイテム購入", day: 22, itemName: "紀行真珠")
                    ]
                ]
            ),
            makeGameService(
                name: "プロセカ",
                gachaTemplates: [
                    ("プレミアムミッションパス", 1_500, 0),
                    ("クリスタル 3000個", 2_940, 1),
                    ("クリスタル 10000個", 10_000, 2)
                ],
                monthlyPayments: [
                    [
                        payment(amount: 2_940, type: "ガチャ", day: 7, itemName: "限定ガチャ 10連"),
                        payment(amount: 1_500, type: "アイテム購入", day: 20, itemName: "プレミアムミッションパス")
                    ],
                    [
                        payment(amount: 10_000, type: "ガチャ", day: 5, itemName: "カラフェス 40連"),
                        payment(amount: 2_940, type: "ガチャ", day: 21, itemName: "イベントガチャ 10連"),
                        payment(amount: 480, type: "アイテム購入", day: 27, itemName: "ライブボーナス回復")
                    ],
                    [
                        payment(amount: 1_500, type: "アイテム購入", day: 3, itemName: "プレミアムミッションパス"),
                        payment(amount: 2_940, type: "ガチャ", day: 16, itemName: "誕生日ガチャ 10連")
                    ],
                    [
                        payment(amount: 10_000, type: "ガチャ", day: 12, itemName: "限定ガチャ 40連"),
                        payment(amount: 1_500, type: "アイテム購入", day: 25, itemName: "プレミアムミッションパス")
                    ],
                    [
                        payment(amount: 2_940, type: "ガチャ", day: 8, itemName: "イベントガチャ 10連"),
                        payment(amount: 2_940, type: "ガチャ", day: 17, itemName: "復刻ガチャ 10連"),
                        payment(amount: 480, type: "アイテム購入", day: 24, itemName: "ライブボーナス回復")
                    ],
                    [
                        payment(amount: 10_000, type: "ガチャ", day: 4, itemName: "今月の限定ガチャ 40連"),
                        payment(amount: 1_500, type: "アイテム購入", day: 15, itemName: "プレミアムミッションパス"),
                        payment(amount: 2_940, type: "ガチャ", day: 26, itemName: "カラフェス追い課金 10連")
                    ]
                ]
            ),
            makeSubscriptionService(
                name: "Netflix",
                category: .video,
                billingType: .monthly,
                price: 1_590,
                paymentDay: 5,
                memo: "スタンダードプラン"
            ),
            makeSubscriptionService(
                name: "Spotify",
                category: .music,
                billingType: .monthly,
                price: 980,
                paymentDay: 12,
                memo: "Premium Individual"
            ),
            makeSubscriptionService(
                name: "ChatGPT Plus",
                category: .ai,
                billingType: .monthly,
                price: 3_000,
                paymentDay: 18,
                memo: "研究・執筆用"
            )
        ]
    }

    static func insertAll(into context: ModelContext) {
        makeServices().forEach(context.insert)
        insertDefaultPaymentCustomTypesIfNeeded(into: context)
        insertDefaultGachaTemplatesIfNeeded(into: context)
    }

    static func insertDefaultPaymentCustomTypesIfNeeded(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<PaymentCustomType>())) ?? []
        guard existing.isEmpty else { return }

        let defaults = ["ガチャ", "アイテム購入", "パス更新", PaymentContentCatalog.subscriptionRenewal, "その他"]
        for (index, name) in defaults.enumerated() {
            context.insert(PaymentCustomType(name: name, sortOrder: index))
        }
    }

    static func insertDefaultGachaTemplatesIfNeeded(into context: ModelContext) {
        let services = (try? context.fetch(FetchDescriptor<Service>())) ?? []
        let defaultTemplates: [(label: String, amount: Int?)] = [
            ("アイテム購入", nil),
            ("マンスリーパス", 610),
            ("シーズンパス", 1_220)
        ]

        for service in services where service.serviceType == .game && service.gachaTemplates.isEmpty {
            service.gachaTemplates = defaultTemplates.enumerated().map { index, template in
                let template = GachaTemplate(
                    label: template.label,
                    amount: template.amount,
                    service: service,
                    sortOrder: index
                )
                context.insert(template)
                return template
            }
        }
    }
}

private extension SampleDataFactory {
    struct PaymentSeed {
        let amount: Int
        let type: String
        let day: Int
        let itemName: String?
    }

    static func makeGameService(
        name: String,
        gachaTemplates: [(label: String, amount: Int?, sortOrder: Int)],
        monthlyPayments: [[PaymentSeed]]
    ) -> Service {
        let service = Service(
            name: name,
            category: .game,
            serviceType: .game,
            memo: "\(name)のサンプルデータ"
        )

        service.gachaTemplates = gachaTemplates.map { template in
            GachaTemplate(
                label: template.label,
                amount: template.amount,
                service: service,
                sortOrder: template.sortOrder
            )
        }

        service.payments = monthlyPayments.enumerated().flatMap { offset, seeds in
            seeds.map { seed in
                Payment(
                    date: paymentDate(monthsAgo: 5 - offset, day: seed.day),
                    amount: seed.amount,
                    type: seed.type,
                    service: service,
                    itemName: seed.itemName,
                    memo: "\(name)のサンプル課金"
                )
            }
        }

        return service
    }

    static func makeSubscriptionService(
        name: String,
        category: Category,
        billingType: BillingType,
        price: Int,
        paymentDay: Int,
        memo: String
    ) -> Service {
        let service = Service(
            name: name,
            category: category,
            serviceType: .subscription,
            memo: memo
        )

        let subscription = Subscription(
            label: "\(name) \(billingType.displayName)",
            billingType: billingType,
            price: price,
            startDate: paymentDate(monthsAgo: 5, day: paymentDay),
            service: service,
            memo: memo
        )

        service.subscriptions = [subscription]
        service.payments = (0..<6).map { offset in
            Payment(
                date: paymentDate(monthsAgo: 5 - offset, day: paymentDay),
                amount: price,
                type: PaymentContentCatalog.subscriptionRenewal,
                service: service,
                subscription: subscription,
                itemName: subscription.label,
                memo: "\(name)の定期更新"
            )
        }
        subscription.payments = service.payments

        return service
    }

    static func payment(
        amount: Int,
        type: String,
        day: Int,
        itemName: String? = nil
    ) -> PaymentSeed {
        PaymentSeed(amount: amount, type: type, day: day, itemName: itemName)
    }

    static func paymentDate(monthsAgo: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .month, value: -monthsAgo, to: .now) ?? .now
        let validDay = min(day, calendar.range(of: .day, in: .month, for: baseDate)?.count ?? day)

        return calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: calendar.date(bySetting: .day, value: validDay, of: baseDate) ?? baseDate
        ) ?? baseDate
    }
}
#endif
