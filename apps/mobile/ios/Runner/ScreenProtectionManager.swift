import UIKit
import Flutter

final class ScreenProtectionManager {
    
    static let shared = ScreenProtectionManager()
    
    private var overlayWindow: UIWindow?
    private var screenshotTimer: Timer?
    private var isRecording = false
    
    private let screenshotHideDuration: TimeInterval = 1.0
    private let animationDuration: TimeInterval = 0.2
    
    private init() {}
    
    func enableProtection() {
        setupOverlayWindow()
        setupNotifications()
        checkScreenRecording()
    }
    
    func disableProtection() {
        removeNotifications()
        removeOverlayWindow()
        cancelScreenshotTimer()
    }
    
    private func setupOverlayWindow() {
        guard overlayWindow == nil else { return }
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.frame = windowScene.screen.bounds
        window.isUserInteractionEnabled = false
        window.backgroundColor = .clear
        
        let overlayVC = OverlayViewController()
        window.rootViewController = overlayVC
        
        window.makeKeyAndVisible()
        overlayWindow = window
    }
    
    private func removeOverlayWindow() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func checkScreenRecording() {
        if UIScreen.main.isCaptured {
            showRecordingOverlay()
        } else {
            hideRecordingOverlay()
        }
    }
    
    @objc private func screenCaptureDidChange() {
        DispatchQueue.main.async { [weak self] in
            if UIScreen.main.isCaptured {
                self?.showRecordingOverlay()
            } else {
                self?.hideRecordingOverlay()
            }
        }
    }
    
    private func showRecordingOverlay() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        overlayVC.showRecordingOverlay()
        isRecording = true
    }
    
    private func hideRecordingOverlay() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        overlayVC.hideOverlay()
        isRecording = false
    }
    
    @objc private func userDidTakeScreenshot() {
        guard !isRecording else { return }
        
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        
        overlayVC.showScreenshotOverlay()
        
        cancelScreenshotTimer()
        screenshotTimer = Timer.scheduledTimer(withTimeInterval: screenshotHideDuration, repeats: false) { [weak self] _ in
            self?.hideScreenshotOverlay()
        }
    }
    
    private func hideScreenshotOverlay() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        overlayVC.hideOverlay()
    }
    
    private func cancelScreenshotTimer() {
        screenshotTimer?.invalidate()
        screenshotTimer = nil
    }
    
    @objc private func appWillResignActive() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        overlayVC.showBackgroundOverlay()
    }
    
    @objc private func appDidBecomeActive() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        
        if isRecording {
            overlayVC.showRecordingOverlay()
        } else {
            overlayVC.hideOverlay()
        }
    }
    
    @objc private func appDidEnterBackground() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        overlayVC.showBackgroundOverlay()
    }
    
    @objc private func appWillEnterForeground() {
        guard let overlayVC = overlayWindow?.rootViewController as? OverlayViewController else { return }
        
        if isRecording {
            overlayVC.showRecordingOverlay()
        } else {
            overlayVC.hideOverlay()
        }
    }
    
    deinit {
        disableProtection()
    }
}

private class OverlayViewController: UIViewController {
    
    private let overlayView = UIView()
    private let messageLabel = UILabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupOverlayView()
    }
    
    private func setupOverlayView() {
        overlayView.frame = view.bounds
        overlayView.backgroundColor = .black
        overlayView.alpha = 0
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        
        blurView.frame = view.bounds
        blurView.alpha = 0
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.alpha = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func showRecordingOverlay() {
        messageLabel.text = "Screen recording is not allowed"
        
        UIView.animate(withDuration: 0.2) {
            self.overlayView.alpha = 1
            self.blurView.alpha = 0
            self.messageLabel.alpha = 1
        }
    }
    
    func showScreenshotOverlay() {
        UIView.animate(withDuration: 0.05) {
            self.overlayView.alpha = 1
            self.blurView.alpha = 0
            self.messageLabel.alpha = 0
        }
    }
    
    func showBackgroundOverlay() {
        UIView.animate(withDuration: 0.2) {
            self.overlayView.alpha = 0
            self.blurView.alpha = 1
            self.messageLabel.alpha = 0
        }
    }
    
    func hideOverlay() {
        UIView.animate(withDuration: 0.2) {
            self.overlayView.alpha = 0
            self.blurView.alpha = 0
            self.messageLabel.alpha = 0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlayView.frame = view.bounds
        blurView.frame = view.bounds
    }
}
