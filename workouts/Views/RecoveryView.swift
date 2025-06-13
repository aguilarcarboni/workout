import SwiftUI

struct RecoveryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming soon...",
                systemImage: "figure.mind.and.body",
                description: Text("Recovery is not implemented yet")
            )
            .navigationTitle("Recovery")
        }
    }
}
