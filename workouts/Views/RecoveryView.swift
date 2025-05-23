import SwiftUI

struct RecoveryView: View {
    var body: some View {
        NavigationView {
            ContentUnavailableView(
                "Coming soon...",
                systemImage: "figure.mind.and.body",
                description: Text("Recovery is not implemented yet")
            )
            .navigationTitle("Recovery")
        }
    }
}
