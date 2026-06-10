import SwiftUI
import Combine
import RoomPlan
import ARKit

// MARK: - ScanState

enum ScanState: Equatable {
    case idle, scanning, processing, completed, error
}

// MARK: - ScanCoordinator

/// Steuert den gesamten LiDAR-Scan-Ablauf und hält den Zustand für die View
@MainActor
final class ScanCoordinator: NSObject, ObservableObject {

    // MARK: Veröffentlichter Zustand

    @Published var scanState: ScanState = .idle
    @Published var capturedRoom: Room?
    @Published var errorMessage: String?
    @Published var wallsDetected:    Int = 0
    @Published var doorsDetected:    Int = 0
    @Published var windowsDetected:  Int = 0
    @Published var lightingWarning:  Bool = false

    // MARK: Private Eigenschaften

    /// RoomCaptureView wird im init erstellt – sie besitzt die Session intern.
    /// Der Representable gibt diese View direkt zurück, statt eine neue zu erstellen.
    let roomCaptureView: RoomCaptureView

    /// Shortcut auf die View-eigene Session (read-only in RoomPlan API)
    private var captureSession: RoomCaptureSession { roomCaptureView.captureSession }

    /// Konvertiert CapturedRoomData → CapturedRoom (async)
    /// nonisolated(unsafe): Zugriff aus nonisolated Delegate-Callbacks,
    /// thread-sicher durch internen async/await-Mechanismus von RoomBuilder
    nonisolated(unsafe) private let roomBuilder: RoomBuilder

    /// Laufender Live-Update-Task (wird bei jedem didUpdate-Callback debounced)
    nonisolated(unsafe) private var updateTask: Task<Void, Never>?

    // MARK: Initialisierung

    override init() {
        roomCaptureView = RoomCaptureView(frame: .zero)
        roomBuilder     = RoomBuilder(options: [.beautifyObjects])
        super.init()
    }

    // MARK: - Öffentliche Methoden

    /// Startet den Scan – prüft zuerst die LiDAR-Verfügbarkeit
    func startScan() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) else {
            errorMessage = "Dieses Gerät unterstützt kein LiDAR-Scanning.\nBitte ein iPhone 12 Pro oder neuer verwenden."
            scanState = .error
            return
        }
        captureSession.delegate = self
        let configuration = RoomCaptureSession.Configuration()
        captureSession.run(configuration: configuration)
        scanState = .scanning
    }

    /// Beendet den Scan – Ergebnisse kommen über den Delegate
    func stopScan() {
        captureSession.stop()
        // scanState → .processing wird in captureSession(_:didEndWith:error:) gesetzt
    }

    /// Setzt alle Werte zurück für einen neuen Scan
    func resetScan() {
        capturedRoom     = nil
        errorMessage     = nil
        wallsDetected    = 0
        doorsDetected    = 0
        windowsDetected  = 0
        lightingWarning  = false
        scanState        = .idle
    }
}

// MARK: - RoomCaptureSessionDelegate

extension ScanCoordinator: RoomCaptureSessionDelegate {

    /// Live-Update während des Scans: Wände, Türen, Fenster zählen und Licht prüfen
    nonisolated func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoomData) {
        // Vorherigen Task abbrechen – nur das letzte Update auswerten (Debounce)
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            guard let self, !Task.isCancelled else { return }

            // Zwischenverarbeitung: CapturedRoomData → CapturedRoom für Live-Werte
            guard let processed = try? await roomBuilder.capturedRoom(from: room),
                  !Task.isCancelled else { return }

            let walls   = processed.walls.count
            let doors   = processed.doors.count
            let windows = processed.windows.count

            // Beleuchtungswarnung: Wände mit niedriger Erkennungs-Konfidenz
            let hasLowConfidence = processed.walls.contains { surface in
                switch surface.confidence {
                case .low: return true
                default:   return false
                }
            }

            await MainActor.run {
                self.wallsDetected   = walls
                self.doorsDetected   = doors
                self.windowsDetected = windows
                self.lightingWarning = hasLowConfidence
            }
        }
    }

    /// Scan abgeschlossen – finales CapturedRoom in eigenes Room-Model überführen
    nonisolated func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        if let error {
            Task { @MainActor in
                self.errorMessage = error.localizedDescription
                self.scanState    = .error
            }
            return
        }

        Task { @MainActor in self.scanState = .processing }

        Task { [weak self] in
            guard let self else { return }
            do {
                let processed = try await roomBuilder.capturedRoom(from: data)

                // CapturedRoom.Surface → eigene WallSurface / Opening Typen
                // dimensions.x = Breite, dimensions.y = Höhe (in Metern)
                let walls = processed.walls.map {
                    WallSurface(width: $0.dimensions.x, height: $0.dimensions.y)
                }
                let doors = processed.doors.map {
                    Opening(width: $0.dimensions.x, height: $0.dimensions.y)
                }
                let windows = processed.windows.map {
                    Opening(width: $0.dimensions.x, height: $0.dimensions.y)
                }

                let room = RoomCalculator.calculate(walls: walls, doors: doors, windows: windows)

                await MainActor.run {
                    self.capturedRoom = room
                    self.scanState    = .completed
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.scanState    = .error
                }
            }
        }
    }
}

// MARK: - RoomCaptureViewRepresentable

/// Bettet die Apple-RoomCaptureView (inkl. Coaching-UI) in SwiftUI ein
struct RoomCaptureViewRepresentable: UIViewRepresentable {
    let coordinator: ScanCoordinator

    func makeUIView(context: Context) -> RoomCaptureView {
        coordinator.roomCaptureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
}

// MARK: - ScanView

/// Haupt-Scan-Screen mit zustandsabhängiger Darstellung
struct ScanView: View {

    @StateObject private var coordinator = ScanCoordinator()
    @State private var showingQuote = false

    private let brandBlue = Color(red: 0.106, green: 0.227, blue: 0.361)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch coordinator.scanState {
            case .idle:       idleView
            case .scanning:   scanningView
            case .processing: processingView
            case .completed:  EmptyView() // Sheet öffnet sich via onChange
            case .error:      errorView
            }
        }
        .onChange(of: coordinator.scanState) { _, newState in
            if newState == .completed { showingQuote = true }
        }
        .sheet(isPresented: $showingQuote, onDismiss: {
            coordinator.resetScan()
        }) {
            if let room = coordinator.capturedRoom {
                NavigationStack {
                    QuoteView(room: room)
                        .navigationTitle("Angebot erstellen")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Idle-Ansicht: Bereit zum Scannen

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 60))
                .foregroundStyle(brandBlue)

            Text("Raum scannen")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Halte das iPhone hoch und bewege dich langsam durch den Raum")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                coordinator.startScan()
            } label: {
                Text("Scan starten")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(brandBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Scan-Ansicht: Kamera + Live-Overlay

    private var scanningView: some View {
        ZStack(alignment: .top) {
            // RoomCaptureView füllt den gesamten Bildschirm
            RoomCaptureViewRepresentable(coordinator: coordinator)
                .ignoresSafeArea()

            // Fortschritts-Panel oben mit abgerundeten Unterkanten
            VStack(spacing: 8) {
                Text("Wände: \(coordinator.wallsDetected)  |  Türen: \(coordinator.doorsDetected)  |  Fenster: \(coordinator.windowsDetected)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                if coordinator.lightingWarning {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Zu wenig Licht — bitte Beleuchtung verbessern")
                            .font(.system(size: 13))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 18)
            .background(Color.black.opacity(0.7))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16, topTrailingRadius: 0
                )
            )

            // Beenden-Button unten
            VStack {
                Spacer()
                Button {
                    coordinator.stopScan()
                } label: {
                    Text("Scan beenden")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Verarbeitungs-Ansicht: RoomBuilder rechnet

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("Raum wird berechnet...")
                .font(.system(size: 17))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Fehler-Ansicht

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("Fehler")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            if let message = coordinator.errorMessage {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                coordinator.resetScan()
            } label: {
                Text("Erneut versuchen")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(brandBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    ScanView()
}
