import SwiftUI

struct CookModeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe

    @State private var stepIndex = 0
    @State private var timerMinutes = 5
    @State private var appear = false
    @State private var lastStartedTimerID: UUID?
    @State private var justStarted = false

    private var progress: Double {
        guard !recipe.steps.isEmpty else { return 0 }
        return Double(stepIndex + 1) / Double(recipe.steps.count)
    }

    private var activeStepTimer: CookTimer? {
        guard let id = lastStartedTimerID else { return nil }
        return store.activeTimers.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(recipe.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        ProgressView(value: progress)
                            .tint(Color("AppPrimary"))
                        Text("Step \(stepIndex + 1) of \(recipe.steps.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }

                SoftCard {
                    Text(recipe.steps[stepIndex])
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxHeight: .infinity)

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Step Timer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if let timer = activeStepTimer {
                            runningTimerBlock(timer)
                        } else {
                            Stepper(value: $timerMinutes, in: 1...120) {
                                Text("\(timerMinutes) min")
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Button {
                                startStepTimer()
                            } label: {
                                Label("Start Timer", systemImage: "timer")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }

                        if justStarted {
                            Text("Timer running · also in Kitchen → Timers")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        HapticService.light()
                        stepIndex = max(0, stepIndex - 1)
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .opacity(stepIndex == 0 ? 0.45 : 1)
                    .disabled(stepIndex == 0)

                    Button {
                        HapticService.light()
                        if stepIndex < recipe.steps.count - 1 {
                            stepIndex += 1
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label(
                            stepIndex < recipe.steps.count - 1 ? "Next" : "Done",
                            systemImage: stepIndex < recipe.steps.count - 1 ? "chevron.right" : "checkmark"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(16)
            .opacity(appear ? 1 : 0)
            .navigationTitle("Cook Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticService.light()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .screenBackground()
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                store.markCookModeStarted()
                withAnimation(.easeOut(duration: 0.35)) { appear = true }
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    @ViewBuilder
    private func runningTimerBlock(_ timer: CookTimer) -> some View {
        HStack(spacing: 14) {
            ProgressRing(progress: timer.progress, lineWidth: 8)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(timer.displayTime)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(timer.isFinished ? "Done" : "Cooking…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(timer.isFinished ? Color("AppPrimary") : Color("AppTextSecondary"))
            }
            Spacer(minLength: 0)
        }

        HStack(spacing: 10) {
            if !timer.isFinished {
                Button {
                    store.toggleTimerPause(timer.id)
                } label: {
                    Label(
                        timer.isRunning ? "Pause" : "Resume",
                        systemImage: timer.isRunning ? "pause.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            Button {
                lastStartedTimerID = nil
                justStarted = false
            } label: {
                Label("New", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .opacity(0.85)
        }
    }

    private func startStepTimer() {
        guard let timer = store.addTimer(
            dishName: "\(recipe.name) · Step \(stepIndex + 1)",
            minutes: timerMinutes
        ) else {
            HapticService.warning()
            return
        }
        lastStartedTimerID = timer.id
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            justStarted = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                justStarted = false
            }
        }
    }
}
