//
//  SubLogApp.swift
//  SubLog
//
//  Created by 齋藤莉菜 on 2026/03/10.
//

import SwiftUI
import SwiftData

@main
struct SubLogApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var entitlementManager = EntitlementManager()
    @StateObject private var notificationManager = NotificationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Service.self,
            Subscription.self,
            Payment.self,
            GachaTemplate.self,
            PaymentCustomType.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            #if DEBUG
            let context = container.mainContext
            let existing = try? context.fetch(FetchDescriptor<Service>())
            if existing?.isEmpty == true {
                SampleDataFactory.insertAll(into: context)
            } else {
                SampleDataFactory.insertDefaultPaymentCustomTypesIfNeeded(into: context)
                SampleDataFactory.insertDefaultGachaTemplatesIfNeeded(into: context)
            }
            #endif

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(themeManager)
                .environmentObject(entitlementManager)
                .environmentObject(notificationManager)
                .task {
                    await entitlementManager.updatePurchasedProducts()
                    _ = await notificationManager.requestAuthorization()
                    let services = (try? sharedModelContainer.mainContext.fetch(FetchDescriptor<Service>())) ?? []
                    await notificationManager.rescheduleAllReminders(services: services)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
