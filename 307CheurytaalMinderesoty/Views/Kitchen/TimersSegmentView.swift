import SwiftUI

struct TimersSegmentView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAdd = false
    @State private var lastTick: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            if store.activeTimers.isEmpty {
                EmptyStateView(
                    symbol: "timer",
                    title: "No Active Timers",
                    message: "Start a cook timer for any dish and track progress live.",
                    actionTitle: "New Timer",
                    action: { showAdd = true },
                    artImage: "img_accent"
                )
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(store.activeTimers) { timer in
                                timerCard(timer)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: context.date) { newDate in
                        guard scenePhase == .active else { return }
                        let elapsed = max(0, Int(newDate.timeIntervalSince(lastTick)))
                        if elapsed >= 1 {
                            store.tickTimers(by: elapsed)
                            lastTick = newDate
                        }
                    }
                }
            }

            Button {
                HapticService.light()
                showAdd = true
            } label: {
                Label("New Timer", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(16)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.syncTimersOnForeground()
                lastTick = .now
            } else {
                store.pauseAllTimersForBackground()
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTimerSheet()
                .environmentObject(store)
        }
    }

    private func timerCard(_ timer: CookTimer) -> some View {
        SoftCard {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: timer.progress, lineWidth: 9)
                        .frame(width: 78, height: 78)
                    VStack(spacing: 2) {
                        Text(timer.displayTime)
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if timer.isFinished {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(timer.dishName)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(timer.isFinished ? "Done" : (timer.isRunning ? "Cooking…" : "Paused"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(timer.isFinished ? Color("AppPrimary") : Color("AppTextSecondary"))

                    HStack(spacing: 10) {
                        Button {
                            store.toggleTimerPause(timer.id)
                        } label: {
                            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                                .frame(width: 36, height: 36)
                                .background(Color("AppPrimary").opacity(0.25))
                                .clipShape(Circle())
                                .foregroundStyle(Color("AppAccent"))
                        }
                        .buttonStyle(.plain)
                        .disabled(timer.isFinished)

                        Button {
                            store.resetTimer(timer.id)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 36, height: 36)
                                .background(Color("AppSurface"))
                                .clipShape(Circle())
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.deleteTimer(timer.id)
                        } label: {
                            Image(systemName: "trash")
                                .frame(width: 36, height: 36)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct AddTimerSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var dishName = ""
    @State private var minutes = 10
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Dish") {
                    TextField("Dish name", text: $dishName)
                        .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                }
                Section("Duration") {
                    Stepper(value: $minutes, in: 1...180) {
                        Text("\(minutes) min")
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color("AppBackground"))
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        KeyboardDismiss.hide()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        KeyboardDismiss.hide()
                        if store.addTimer(dishName: dishName, minutes: minutes) != nil {
                            dismiss()
                        } else {
                            HapticService.warning()
                            withAnimation(.default) { shake += 1 }
                        }
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium])
        .dismissKeyboardOnTap()
    }
}
