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
    @State private var activities: [Activity] = []
    @State private var selectedActivityID: UUID?
    @State private var hasLoaded = false
    private let agendaService = AgendaService(persistence: LocalAgendaDatabase())

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("Agenda")
                .font(.title2)
            Text("UI simple y reemplazable para tareas, estudio y otros.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if activities.isEmpty {
                Text("Sin actividades para hoy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(activities) { activity in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.title)
                                    .font(.headline)
                                Text(activity.topic)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(statusLabel(for: activity.status))
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(for: activity.status).opacity(0.2))
                                .foregroundStyle(statusColor(for: activity.status))
                                .clipShape(Capsule())
                            Button("Iniciar") {
                                Task {
                                    _ = try? await agendaService.startActivity(id: activity.id)
                                    selectedActivityID = activity.id
                                    await reloadActivities()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let active = selectedActivity {
                PomodoroTimerView(
                    title: "Pomodoro: \(active.title)",
                    secondsRemaining: 25 * 60,
                    onMarkCompleted: {
                        Task {
                            _ = await agendaService.completeActivity(id: active.id)
                            await reloadActivities()
                        }
                    },
                    onMarkPending: {
                        Task {
                            _ = await agendaService.markActivityPending(id: active.id)
                            await reloadActivities()
                        }
                    }
                )
            }
        }
        .padding()
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await seedInitialActivitiesIfNeeded()
            await reloadActivities()
        }
    }

    private var selectedActivity: Activity? {
        if let selectedActivityID {
            return activities.first(where: { $0.id == selectedActivityID })
        }
        return activities.first(where: { $0.status == .inProgress }) ?? activities.first
    }

    private func seedInitialActivitiesIfNeeded() async {
        let today = Date()
        let existing = await agendaService.listActivities(on: today)
        guard existing.isEmpty else {
            selectedActivityID = existing.first(where: { $0.status == .inProgress })?.id ?? existing.first?.id
            return
        }

        _ = await agendaService.createActivity(
            title: "Repaso de matemáticas",
            topic: "Derivadas",
            type: .study,
            scheduledAt: today
        )
        _ = await agendaService.createActivity(
            title: "Entregar tarea",
            topic: "Álgebra",
            type: .task,
            scheduledAt: today
        )
    }

    private func reloadActivities() async {
        let today = Date()
        let listed = await agendaService.listActivities(on: today)
        await MainActor.run {
            self.activities = listed
            if self.selectedActivityID == nil || !listed.contains(where: { $0.id == self.selectedActivityID }) {
                self.selectedActivityID = listed.first(where: { $0.status == .inProgress })?.id ?? listed.first?.id
            }
        }
    }

    private func statusLabel(for status: ActivityStatus) -> String {
        switch status {
        case .pending:
            "Pendiente"
        case .inProgress:
            "En progreso"
        case .completed:
            "Realizada"
        }
    }

    private func statusColor(for status: ActivityStatus) -> Color {
        switch status {
        case .pending:
            .orange
        case .inProgress:
            .blue
        case .completed:
            .green
        }
    }
}

public struct PomodoroTimerView: View {
    public let title: String
    public let secondsRemaining: Int
    public let onMarkCompleted: () -> Void
    public let onMarkPending: () -> Void

    public init(
        title: String,
        secondsRemaining: Int,
        onMarkCompleted: @escaping () -> Void,
        onMarkPending: @escaping () -> Void
    ) {
        self.title = title
        self.secondsRemaining = secondsRemaining
        self.onMarkCompleted = onMarkCompleted
        self.onMarkPending = onMarkPending
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            Text(formattedTime(secondsRemaining))
                .font(.title3.monospacedDigit())
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Marcar realizada", action: onMarkCompleted)
                    .buttonStyle(.borderedProminent)
                Button("Dejar pendiente", action: onMarkPending)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = max(totalSeconds, 0) / 60
        let seconds = max(totalSeconds, 0) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
