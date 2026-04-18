#if canImport(SwiftUI)
import SwiftUI

public struct HomeView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                NavigationLink("Agenda") { AgendaView() }
                NavigationLink("Entrenador Mental") { MentalTrainerView() }
                Label("Racha actual", systemImage: "flame.fill")
            }
            .navigationTitle("Entrenador Académico")
        }
    }
}

public struct AgendaView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("Agenda")
                .font(.title2)
            Text("UI simple y reemplazable para tareas, estudio y otros.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

public struct MentalTrainerView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("Entrenador Mental")
                .font(.title2)
            Text("UI simple y reemplazable para trivia de 10 segundos por pregunta.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#endif
