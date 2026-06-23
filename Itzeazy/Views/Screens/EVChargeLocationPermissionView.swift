import SwiftUI
import CoreLocation

struct EVChargeLocationPermissionView: View {
    @StateObject private var viewModel = EVChargeLocationPermissionViewModel()
    @State private var navigateToCharge = false

    let onManualLocation: (() -> Void)?

    init(onManualLocation: (() -> Void)? = nil) {
        self.onManualLocation = onManualLocation
    }

    // Kept for binary compatibility with cached build artifacts
    init(onPermissionGranted: (() -> Void)?, onManualLocation: (() -> Void)?) {
        self.onManualLocation = onManualLocation
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Hidden NavigationLink fires as soon as permission is granted
                NavigationLink(destination: EVChargeView(), isActive: $navigateToCharge) {
                    EmptyView()
                }
                .hidden()

                mapBackground
                    .ignoresSafeArea()

                permissionSheet(bottomInset: proxy.safeAreaInsets.bottom)
            }
            .navigationBarHidden(true)
            // Auto-skip if already authorized when this view appears
            .onAppear {
                if viewModel.isAuthorized {
                    navigateToCharge = true
                }
            }
            // Navigate when permission is freshly granted
            .onChange(of: viewModel.isAuthorized) { _, isAuthorized in
                if isAuthorized { navigateToCharge = true }
            }
        }
    }

    // MARK: - Map background

    private var mapBackground: some View {
        ZStack {
            Color(hex: "#1A2235")

            EVMapRoadsLayer()

            // User location pulse
            ZStack {
                Circle()
                    .fill(Color(hex: "#BB0011").opacity(0.12))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Color(hex: "#BB0011").opacity(0.22))
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(Color(hex: "#BB0011"))
                    .frame(width: 13, height: 13)
            }
            .offset(x: -42, y: -108)

            EVMapPin(x: -130, y: -210, size: 40)
            EVMapPin(x:  118, y: -202, size: 40)
            EVMapPin(x:   52, y:  -62, size: 40)
        }
    }

    // MARK: - Permission sheet

    private func permissionSheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "#FCDEDE"))
                    .frame(width: 88, height: 88)

                Image("location_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .padding(.top, 36)

            Text("Allow location access")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 26))
                .foregroundColor(Color(hex: "#191C1D"))
                .multilineTextAlignment(.center)
                .padding(.top, 22)

            Text("To find EV charging stations near you,\nallow location access in your device\nsettings.")
                .font(Font.custom("Inter", size: 16))
                .foregroundColor(Color(hex: "#6B6B6B"))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, 14)
                .padding(.horizontal, 8)

            VStack(spacing: 14) {
                Button(action: handleAllowLocationTap) {
                    Text("Allow Location")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color(hex: "#E61A20"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: { onManualLocation?() }) {
                    Text("Enter Location Manually")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                        .foregroundColor(Color(hex: "#191C1D"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color(hex: "#E5E5E5"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 32)
            .padding(.bottom, 34 + bottomInset)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private func handleAllowLocationTap() {
        if viewModel.isAuthorized {
            navigateToCharge = true
        } else {
            viewModel.requestLocationAccess()
        }
    }
}

// MARK: - Map road layer

private struct EVMapRoadsLayer: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Main diagonal highway (dark) ─────────────────────────────
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.00, y: h * 0.10),
                    p1: CGPoint(x: w * 0.30, y: h * 0.32),
                    p2: CGPoint(x: w * 0.62, y: h * 0.48),
                    p3: CGPoint(x: w * 1.00, y: h * 0.28)
                )
                .stroke(Color(hex: "#0D1830"), style: StrokeStyle(lineWidth: 20, lineCap: .round))

                // ── Secondary teal roads ──────────────────────────────────────
                // Top-left horizontal
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.00, y: h * 0.22),
                    p1: CGPoint(x: w * 0.22, y: h * 0.18),
                    p2: CGPoint(x: w * 0.44, y: h * 0.14),
                    p3: CGPoint(x: w * 0.70, y: h * 0.24)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Right-side vertical descend
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.72, y: h * 0.00),
                    p1: CGPoint(x: w * 0.70, y: h * 0.22),
                    p2: CGPoint(x: w * 0.76, y: h * 0.46),
                    p3: CGPoint(x: w * 0.86, y: h * 0.70)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Mid diagonal (upper)
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.44, y: h * 0.00),
                    p1: CGPoint(x: w * 0.46, y: h * 0.20),
                    p2: CGPoint(x: w * 0.42, y: h * 0.38),
                    p3: CGPoint(x: w * 0.28, y: h * 0.60)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Lower horizontal sweep
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.06, y: h * 0.58),
                    p1: CGPoint(x: w * 0.34, y: h * 0.56),
                    p2: CGPoint(x: w * 0.62, y: h * 0.64),
                    p3: CGPoint(x: w * 1.00, y: h * 0.72)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Far-right upper curve
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.80, y: h * 0.08),
                    p1: CGPoint(x: w * 1.00, y: h * 0.16),
                    p2: CGPoint(x: w * 1.00, y: h * 0.36),
                    p3: CGPoint(x: w * 0.88, y: h * 0.52)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                // Top connector
                EVCurvedPath(
                    p0: CGPoint(x: w * 0.00, y: h * 0.06),
                    p1: CGPoint(x: w * 0.20, y: h * 0.04),
                    p2: CGPoint(x: w * 0.40, y: h * 0.08),
                    p3: CGPoint(x: w * 0.60, y: h * 0.04)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 7, lineCap: .round))

                // ── Finer city-block grid lines ───────────────────────────────
                ForEach(cityBlockPaths, id: \.0) { _, pts in
                    EVPolylinePath(points: pts.map { CGPoint(x: w * $0.x, y: h * $0.y) })
                        .stroke(Color(hex: "#4465A8"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: w, height: h)
        }
    }

    private var cityBlockPaths: [(Int, [CGPoint])] {
        [
            (0,  [CGPoint(x: 0.02, y: 0.14), CGPoint(x: 0.18, y: 0.10), CGPoint(x: 0.34, y: 0.18)]),
            (1,  [CGPoint(x: 0.58, y: 0.06), CGPoint(x: 0.88, y: 0.14), CGPoint(x: 0.78, y: 0.32)]),
            (2,  [CGPoint(x: 0.54, y: 0.28), CGPoint(x: 0.82, y: 0.40), CGPoint(x: 0.90, y: 0.54)]),
            (3,  [CGPoint(x: 0.08, y: 0.40), CGPoint(x: 0.26, y: 0.32), CGPoint(x: 0.42, y: 0.44)]),
            (4,  [CGPoint(x: 0.06, y: 0.70), CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.46, y: 0.72)]),
            (5,  [CGPoint(x: 0.54, y: 0.56), CGPoint(x: 0.70, y: 0.50), CGPoint(x: 0.92, y: 0.60)]),
            (6,  [CGPoint(x: 0.22, y: 0.88), CGPoint(x: 0.44, y: 0.80), CGPoint(x: 0.66, y: 0.90)]),
            (7,  [CGPoint(x: 0.72, y: 0.76), CGPoint(x: 0.84, y: 0.86), CGPoint(x: 1.00, y: 0.80)]),
            (8,  [CGPoint(x: 0.00, y: 0.46), CGPoint(x: 0.14, y: 0.50), CGPoint(x: 0.26, y: 0.44)]),
            (9,  [CGPoint(x: 0.36, y: 0.66), CGPoint(x: 0.52, y: 0.72), CGPoint(x: 0.64, y: 0.62)]),
            (10, [CGPoint(x: 0.16, y: 0.28), CGPoint(x: 0.30, y: 0.22), CGPoint(x: 0.50, y: 0.30)]),
        ]
    }
}

// MARK: - Cubic-bezier path shape

private struct EVCurvedPath: Shape {
    let p0, p1, p2, p3: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: p0)
        p.addCurve(to: p3, control1: p1, control2: p2)
        return p
    }
}

// MARK: - Polyline shape (replaces EVMapPath)

private struct EVPolylinePath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        points.dropFirst().forEach { p.addLine(to: $0) }
        return p
    }
}

// MARK: - EV charging pin

private struct EVMapPin: View {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#CC0011"))
                .frame(width: size, height: size)
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: x, y: y)
    }
}

// Routes directly to EVChargeView if location is already authorized — no permission flash.
struct EVChargeRouter: View {
    @State private var skipPermission: Bool = {
        let s = CLLocationManager().authorizationStatus
        return s == .authorizedWhenInUse || s == .authorizedAlways
    }()

    var body: some View {
        if skipPermission {
            EVChargeView()
        } else {
            EVChargeLocationPermissionView()
        }
    }
}

#Preview {
    NavigationView {
        EVChargeRouter()
    }
}
