#if canImport(SwiftUI)
import SwiftUI

public struct HomeView: View {
    @State private var todayActivities: [Activity] = []
    @State private var streakState = StreakState()
    @State private var hasLoaded = false
    private let agendaService = AgendaService(persistence: LocalAgendaDatabase())
    private let streakEngine = StreakEngine()
    private let planner = NotificationPlanner()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Resumen de hoy") {
                    HStack {
                        Label("Racha actual", systemImage: "flame.fill")
                        Spacer()
                        Text("\(streakState.days) días")
                            .fontWeight(.semibold)
                    }
                    Text(planner.reminderForDay(activities: todayActivities).body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Módulos") {
                    NavigationLink("Agenda") { AgendaView() }
                    NavigationLink("Entrenador Mental") { MentalTrainerView() }
                }
            }
            .navigationTitle("Entrenador Académico")
            .task {
                guard !hasLoaded else { return }
                hasLoaded = true
                await refreshSummary()
            }
            .refreshable {
                await refreshSummary()
            }
        }
    }

    private func refreshSummary() async {
        let activities = await agendaService.listActivities(on: Date())
        let updated = streakEngine.evaluate(
            current: streakState,
            input: DailyEvaluationInput(day: Date(), scheduledActivities: activities, validMentalTrainingCompletions: 0)
        )
        await MainActor.run {
            self.todayActivities = activities
            self.streakState = updated
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
    @State private var supportMaterialByActivityID: [UUID: [String]] = [:]
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
                                    if let session = try? await agendaService.startActivity(id: activity.id) {
                                        await MainActor.run {
                                            supportMaterialByActivityID[activity.id] = session.supportMaterial
                                        }
                                    }
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
                if let support = supportMaterialByActivityID[active.id], !support.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Material IA para \(active.topic)")
                            .font(.headline)
                        ForEach(support, id: \.self) { line in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text(line)
                                    .font(.footnote)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasStarted = false
    @State private var currentQuestion: TriviaQuestion?
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    @State private var currentQuestionIndex = 0
    @State private var totalQuestions = 0
    @State private var questionDeadline: Date?
    @State private var feedbackMessage: String?
    @State private var feedbackColor: Color = .secondary
    @State private var isGameOver = false
    @State private var sessionCompleted = false
    @State private var questionAnswered = false
    @State private var answeredOptionIndex: Int?
    @State private var correctOptionIndex: Int?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let mentalService = MentalTrainerService()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entrenador Mental")
                .font(.title2.weight(.semibold))

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if !hasStarted {
                Text("Responde trivia con 10 segundos por pregunta. Si fallas después de 5 aciertos, termina la partida.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(isLoading ? "Cargando..." : "Iniciar entrenamiento") {
                    Task { await startSession() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            } else {
                HStack {
                    Label("Correctas: \(correctAnswers)", systemImage: "checkmark.seal.fill")
                    Spacer()
                    Label("Fallos: \(incorrectAnswers)", systemImage: "xmark.seal.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let currentQuestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pregunta \(currentQuestionIndex + 1) de \(max(totalQuestions, 1))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currentQuestion.prompt)
                            .font(.headline)

                        if let deadline = questionDeadline {
                            Text("Tiempo restante: \(remainingSeconds(until: deadline))s")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(remainingSeconds(until: deadline) <= 3 ? .red : .secondary)
                        }

                        ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                            Button {
                                Task { await answer(optionIndex: index) }
                            } label: {
                                HStack {
                                    Text(option)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if questionAnswered {
                                        if index == correctOptionIndex {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        } else if index == answeredOptionIndex {
                                            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(questionAnswered || sessionCompleted || isLoading)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let feedbackMessage {
                    Text(feedbackMessage)
                        .font(.footnote)
                        .foregroundStyle(feedbackColor)
                }

                HStack(spacing: 10) {
                    Button("Nueva sesión") {
                        Task { await startSession() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    if sessionCompleted || isGameOver {
                        Text(isGameOver ? "Game Over" : "Sesión finalizada")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isGameOver ? .red : .green)
                    }
                }
            }
        }
        .padding()
        .onReceive(ticker) { _ in
            guard hasStarted, !questionAnswered, !sessionCompleted, !isGameOver,
                  let deadline = questionDeadline else { return }
            if Date() >= deadline {
                Task { await answer(optionIndex: -1, answerDate: Date()) }
            }
        }
    }

    private func startSession() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            feedbackMessage = nil
            isGameOver = false
            sessionCompleted = false
            questionAnswered = false
            answeredOptionIndex = nil
            correctOptionIndex = nil
        }

        do {
            let session = try await mentalService.startSession(questionCount: 10)
            let question = await mentalService.currentQuestion()
            await MainActor.run {
                hasStarted = true
                isLoading = false
                currentQuestion = question
                totalQuestions = session.questions.count
                currentQuestionIndex = session.currentIndex
                questionDeadline = session.deadline
                correctAnswers = session.attempt.correctAnswers
                incorrectAnswers = session.attempt.incorrectAnswers
            }
        } catch {
            await MainActor.run {
                isLoading = false
                hasStarted = false
                errorMessage = "No se pudo iniciar la sesión: \(error.localizedDescription)"
            }
        }
    }

    private func answer(optionIndex: Int, answerDate: Date = Date()) async {
        guard !questionAnswered, !sessionCompleted, !isGameOver else { return }
        await MainActor.run {
            questionAnswered = true
            answeredOptionIndex = optionIndex >= 0 ? optionIndex : nil
            isLoading = true
        }

        guard let feedback = await mentalService.submitAnswer(optionIndex: optionIndex, answeredAt: answerDate) else {
            await MainActor.run {
                isLoading = false
                questionAnswered = false
            }
            return
        }

        let nextQuestion = await mentalService.currentQuestion()
        let session = await mentalService.activeSession

        await MainActor.run {
            correctOptionIndex = feedback.correctOptionIndex
            correctAnswers = session?.attempt.correctAnswers ?? correctAnswers + (feedback.isCorrect ? 1 : 0)
            incorrectAnswers = session?.attempt.incorrectAnswers ?? incorrectAnswers + (feedback.isCorrect ? 0 : 1)
            currentQuestionIndex = session?.currentIndex ?? currentQuestionIndex + 1
            questionDeadline = session?.deadline

            if feedback.isCorrect {
                feedbackMessage = "¡Correcto!"
                feedbackColor = .green
            } else if feedback.shouldShowRetry {
                feedbackMessage = "Incorrecto. Sigue intentando."
                feedbackColor = .orange
            } else if feedback.isGameOver {
                feedbackMessage = "Perdiste después de 5 aciertos. Game Over."
                feedbackColor = .red
            } else {
                feedbackMessage = "Respuesta incorrecta."
                feedbackColor = .red
            }

            if feedback.isGameOver {
                isGameOver = true
                sessionCompleted = true
                isLoading = false
                return
            }

            if let nextQuestion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.currentQuestion = nextQuestion
                    self.answeredOptionIndex = nil
                    self.correctOptionIndex = nil
                    self.questionAnswered = false
                    self.isLoading = false
                }
            } else {
                currentQuestion = nil
                sessionCompleted = true
                isLoading = false
                if feedbackMessage == nil {
                    feedbackMessage = "Sesión finalizada."
                    feedbackColor = .green
                }
            }
        }
    }

    private func remainingSeconds(until deadline: Date) -> Int {
        max(Int(deadline.timeIntervalSinceNow.rounded(.down)), 0)
    }
}
#endif
