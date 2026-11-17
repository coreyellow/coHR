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
                status = "HealthKit is connected."
            case .sharingDenied:
                status = "HealthKit access is denied. Enable it in Settings."
            case .notDetermined:
                status = "HealthKit is ready to connect."
                canRequestAuthorization = true
            @unknown default:
                status = "HealthKit authorization status is unknown."
            }
        } else {
            status = "The heart rate type is unavailable."
        }
    }

    func requestAuthorization() {
        guard let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            status = "The heart rate type is unavailable."
            return
        }

        Task {
            do {
                try await healthStore.requestAuthorization(
                    toShare: [heartRate],
                    read: [heartRate]
                )
                canRequestAuthorization = false
                status = "HealthKit connection request complete."
            } catch {
                status = "Could not connect to HealthKit: \(error.localizedDescription)"
            }
        }
    }
}
