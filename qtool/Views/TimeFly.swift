//
//  TimeFly.swift
//  qtool
//
//  Created by Hoang Minh Thang on 10/8/26.
//

import SwiftUI
import UIKit

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

struct TimeFlyDisplayView: View {
    @State private var minutes: Int = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                Text("\(minutes)")
                    .font(.system(size: 160, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        }
        .ignoresSafeArea()
        .onAppear { minutes = Self.remainingMinutes() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            minutes = Self.remainingMinutes()
        }
    }

    private static func remainingMinutes() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return 0 }
        return max(0, Int(midnight.timeIntervalSince(now) / 60))
    }
}

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
