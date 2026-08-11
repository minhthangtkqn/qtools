//
//  TimeFly.swift
//  qtool
//
//  Created by Hoang Minh Thang on 10/8/26.
//

import SwiftUI
import UIKit

// MARK: - Mode

enum TimeFlyMode: String {
    case allDay
    case sixHourShift
}

// MARK: - Launch

func launchTimeFly() {
    let vc = TimeFlyLandscapeHostingController(rootView: TimeFlyDisplayView())
    vc.modalPresentationStyle = .fullScreen

    AppDelegate.orientationLock = .landscapeRight

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))

    scene.keyWindow?
        .rootViewController?
        .present(vc, animated: true)
}

// MARK: - Display view

struct TimeFlyDisplayView: View {
    @AppStorage("timeFlyMode") private var mode: TimeFlyMode = .allDay
    @State private var minutes: Int = 0
    @State private var showConfig = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Countdown
            Text("\(minutes)")
                .font(.system(size: 160, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.horizontal, 24)

            // Top chrome: back (left) + config (right)
            VStack {
                HStack {
                    Button(action: {
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.keyWindow?
                            .rootViewController?
                            .dismiss(animated: false)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(16)
                    }

                    Spacer()

                    Button(action: { showConfig = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(16)
                    }
                    .opacity(0.5)
                }
                Spacer()
            }

            // Config popup
            if showConfig {
                configOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear {
            minutes = Self.remainingMinutes(for: mode)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            minutes = Self.remainingMinutes(for: mode)
        }
    }

    // MARK: Config overlay

    private var configOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { showConfig = false }

            VStack(alignment: .leading, spacing: 12) {
                Text("Display Mode")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)

                modeRow(.allDay,
                        label: "All Day",
                        subtitle: "Remaining minutes until midnight")

                modeRow(.sixHourShift,
                        label: "6-hours Shift",
                        subtitle: "Remaining minutes until next 0, 6, 12, or 18")
            }
            .padding(24)
            .background(Color(white: 0.15))
            .cornerRadius(16)
            .frame(maxWidth: 380)
            .padding(48)
        }
    }

    private func modeRow(_ m: TimeFlyMode, label: String, subtitle: String) -> some View {
        Button(action: {
            mode = m
            minutes = Self.remainingMinutes(for: m)
            showConfig = false
        }) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(mode == m ? Color.white.opacity(0.12) : Color.clear)
            .cornerRadius(10)
        }
    }

    // MARK: Time calculation

    private static func remainingMinutes(for mode: TimeFlyMode) -> Int {
        let calendar = Calendar.current
        let now = Date()

        switch mode {
        case .allDay:
            guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return 0 }
            return max(0, Int(midnight.timeIntervalSince(now) / 60))

        case .sixHourShift:
            let shiftHours = [0, 6, 12, 18]
            let currentHour = calendar.component(.hour, from: now)
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.minute = 0
            comps.second = 0
            if let nextHour = shiftHours.first(where: { $0 > currentHour }) {
                comps.hour = nextHour
                guard let target = calendar.date(from: comps) else { return 0 }
                return max(0, Int(target.timeIntervalSince(now) / 60))
            } else {
                // Past 18:xx — next shift is 0:00 tomorrow
                comps.hour = 0
                guard let base = calendar.date(from: comps),
                      let target = calendar.date(byAdding: .day, value: 1, to: base) else { return 0 }
                return max(0, Int(target.timeIntervalSince(now) / 60))
            }
        }
    }
}

// MARK: - Landscape host

private class TimeFlyLandscapeHostingController: UIHostingController<TimeFlyDisplayView> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscapeRight }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
    override var shouldAutorotate: Bool { true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let scene = view.window?.windowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let window = view.window else { return }

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .black
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(overlay)

        AppDelegate.orientationLock = .portrait
        if let scene = window.windowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        presentingViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
}

#Preview {
    TimeFlyDisplayView()
}
