import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()

    var body: some View {
        VStack {
            HStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)

                Text(healthManager.status)
                    .multilineTextAlignment(.leading)

                if healthManager.canRequestAuthorization {
                    Button("Connect Health") {
                        healthManager.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

@MainActor
private final class HealthManager: ObservableObject {
    @Published var status: String
    @Published var canRequestAuthorization = false

    private let healthStore = HKHealthStore()

    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = "HealthKit is unavailable on this device."
            return
        }

        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            switch healthStore.authorizationStatus(for: heartRate) {
            case .sharingAuthorized:
                status = "Connected"
            case .sharingDenied:
                status = "Health Sharing is Denied. Enable it in Settings."
            case .notDetermined:
                status = "Ready to Connect"
                canRequestAuthorization = true
            @unknown default:
                status = "Status is Unknown."
            }
        } else {
            status = "Unavailable"
        }
    }

    func requestAuthorization() {
        guard let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            status = "Unavailable"
            return
        }

        Task {
            do {
                try await healthStore.requestAuthorization(
                    toShare: [heartRate],
                    read: [heartRate]
                )
                canRequestAuthorization = false
                status = "Connected"
            } catch {
                status = "Could not connect to HealthKit: \(error.localizedDescription)"
            }
        }
    }
}
