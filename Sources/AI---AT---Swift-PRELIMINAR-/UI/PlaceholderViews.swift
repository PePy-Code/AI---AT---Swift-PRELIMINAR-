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
    @State private var newTitle = ""
    @State private var newTopic = ""
    @State private var newTypeRawValue = ActivityType.study.rawValue
    private let agendaService = AgendaService(persistence: LocalAgendaDatabase())

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("Agenda")
                .font(.title2)
            Text("Agenda funcional para tareas, estudio y otros.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                TextField("Título", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("Tema", text: $newTopic)
                    .textFieldStyle(.roundedBorder)
                Picker("Tipo", selection: $newTypeRawValue) {
                    ForEach(ActivityType.allCases, id: \.rawValue) { type in
                        Text(typeLabel(for: type)).tag(type.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Button("Agregar actividad") {
                    Task {
                        await addActivity()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
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
                            Button("Eliminar", role: .destructive) {
                                Task {
                                    _ = await agendaService.deleteActivity(id: activity.id)
                                    await reloadActivities()
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedActivityID = activity.id
                        }
                    }
                }
            }

            if let active = selectedActivity {
                PomodoroTimerView(
                    title: "Pomodoro: \(active.title)",
                    initialSeconds: 25 * 60,
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
                    },
                    onTimerFinished: {
                        Task {
                            _ = await agendaService.completeActivity(id: active.id)
                            await reloadActivities()
                        }
                    }
                )
                .id(active.id)
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

    private func addActivity() async {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let topic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !topic.isEmpty else { return }
        let type = ActivityType(rawValue: newTypeRawValue) ?? .study
        _ = await agendaService.createActivity(title: title, topic: topic, type: type, scheduledAt: Date())
        await MainActor.run {
            newTitle = ""
            newTopic = ""
            newTypeRawValue = ActivityType.study.rawValue
        }
        await reloadActivities()
    }

    private func typeLabel(for type: ActivityType) -> String {
        switch type {
        case .task:
            "Tarea"
        case .study:
            "Estudio"
        case .other:
            "Otro"
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
    public let initialSeconds: Int
    public let onMarkCompleted: () -> Void
    public let onMarkPending: () -> Void
    public let onTimerFinished: (() -> Void)?
    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var didFinish = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        title: String,
        initialSeconds: Int,
        onMarkCompleted: @escaping () -> Void,
        onMarkPending: @escaping () -> Void,
        onTimerFinished: (() -> Void)? = nil
    ) {
        self.title = title
        self.initialSeconds = max(initialSeconds, 0)
        self.onMarkCompleted = onMarkCompleted
        self.onMarkPending = onMarkPending
        self.onTimerFinished = onTimerFinished
        _remainingSeconds = State(initialValue: max(initialSeconds, 0))
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            Text(formattedTime(remainingSeconds))
                .font(.title3.monospacedDigit())
                .foregroundStyle(.secondary)
            if didFinish {
                Text("Tiempo completado")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            HStack(spacing: 10) {
                Button(isRunning ? "Pausar" : "Iniciar") {
                    guard remainingSeconds > 0 else { return }
                    isRunning.toggle()
                }
                .buttonStyle(.bordered)
                Button("Reiniciar") {
                    resetTimer()
                }
                .buttonStyle(.bordered)
                Button("Marcar realizada", action: onMarkCompleted)
                    .buttonStyle(.borderedProminent)
                Button("Dejar pendiente", action: onMarkPending)
                    .buttonStyle(.bordered)
            }
        }
        .onReceive(ticker) { _ in
            guard isRunning, remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                isRunning = false
                didFinish = true
                onTimerFinished?()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resetTimer() {
        isRunning = false
        didFinish = false
        remainingSeconds = initialSeconds
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
