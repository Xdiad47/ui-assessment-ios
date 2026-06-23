import SwiftUI
import CoreLocation

struct PetrolLocationPermissionView: View {
    @StateObject private var viewModel = PetrolLocationPermissionViewModel()
    @State private var navigateToStations = false

    let onManualLocation: (() -> Void)?

    init(onManualLocation: (() -> Void)? = nil) {
        self.onManualLocation = onManualLocation
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                NavigationLink(destination: PetrolStationView(), isActive: $navigateToStations) {
                    EmptyView()
                }
                .hidden()

                mapBackground
                    .ignoresSafeArea()

                permissionSheet(bottomInset: proxy.safeAreaInsets.bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.isAuthorized { navigateToStations = true }
            }
            .onChange(of: viewModel.isAuthorized) { _, authorized in
                if authorized { navigateToStations = true }
            }
        }
    }

    // MARK: - Map background

    private var mapBackground: some View {
        ZStack {
            Color(hex: "#1A2235")

            PetrolMapRoadsLayer()

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
            .offset(x: 30, y: -90)

            PetrolMapPin(x: -110, y: -215, size: 40)
            PetrolMapPin(x:  130, y: -195, size: 40)
            PetrolMapPin(x:  -20, y:  -55, size: 40)
        }
    }

    // MARK: - Permission sheet

    private func permissionSheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
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

            Text("To find petrol stations near you,\nallow location access in your device\nsettings.")
                .font(Font.custom("Inter", size: 16))
                .foregroundColor(Color(hex: "#6B6B6B"))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, 14)
                .padding(.horizontal, 8)

            VStack(spacing: 14) {
                Button(action: handleAllowTap) {
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

    private func handleAllowTap() {
        if viewModel.isAuthorized {
            navigateToStations = true
        } else {
            viewModel.requestLocationAccess()
        }
    }
}

// MARK: - Map helpers (private to this file)

private struct PetrolMapRoadsLayer: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.00, y: h * 0.12),
                    p1: CGPoint(x: w * 0.28, y: h * 0.30),
                    p2: CGPoint(x: w * 0.60, y: h * 0.44),
                    p3: CGPoint(x: w * 1.00, y: h * 0.26)
                )
                .stroke(Color(hex: "#0D1830"), style: StrokeStyle(lineWidth: 20, lineCap: .round))

                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.00, y: h * 0.24),
                    p1: CGPoint(x: w * 0.24, y: h * 0.20),
                    p2: CGPoint(x: w * 0.46, y: h * 0.16),
                    p3: CGPoint(x: w * 0.72, y: h * 0.26)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.70, y: h * 0.00),
                    p1: CGPoint(x: w * 0.68, y: h * 0.24),
                    p2: CGPoint(x: w * 0.74, y: h * 0.48),
                    p3: CGPoint(x: w * 0.84, y: h * 0.72)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.42, y: h * 0.00),
                    p1: CGPoint(x: w * 0.44, y: h * 0.22),
                    p2: CGPoint(x: w * 0.40, y: h * 0.40),
                    p3: CGPoint(x: w * 0.26, y: h * 0.62)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.08, y: h * 0.56),
                    p1: CGPoint(x: w * 0.36, y: h * 0.54),
                    p2: CGPoint(x: w * 0.64, y: h * 0.62),
                    p3: CGPoint(x: w * 1.00, y: h * 0.70)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                PetrolCurvedPath(
                    p0: CGPoint(x: w * 0.78, y: h * 0.06),
                    p1: CGPoint(x: w * 1.00, y: h * 0.14),
                    p2: CGPoint(x: w * 1.00, y: h * 0.34),
                    p3: CGPoint(x: w * 0.86, y: h * 0.50)
                )
                .stroke(Color(hex: "#3F7C8C"), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                ForEach(blockPaths, id: \.0) { _, pts in
                    PetrolPolylinePath(points: pts.map { CGPoint(x: w * $0.x, y: h * $0.y) })
                        .stroke(Color(hex: "#4465A8"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: w, height: h)
        }
    }

    private var blockPaths: [(Int, [CGPoint])] {
        [
            (0,  [CGPoint(x: 0.02, y: 0.16), CGPoint(x: 0.20, y: 0.12), CGPoint(x: 0.36, y: 0.20)]),
            (1,  [CGPoint(x: 0.60, y: 0.08), CGPoint(x: 0.90, y: 0.16), CGPoint(x: 0.80, y: 0.34)]),
            (2,  [CGPoint(x: 0.56, y: 0.30), CGPoint(x: 0.84, y: 0.42), CGPoint(x: 0.92, y: 0.56)]),
            (3,  [CGPoint(x: 0.10, y: 0.42), CGPoint(x: 0.28, y: 0.34), CGPoint(x: 0.44, y: 0.46)]),
            (4,  [CGPoint(x: 0.08, y: 0.72), CGPoint(x: 0.30, y: 0.60), CGPoint(x: 0.48, y: 0.74)]),
            (5,  [CGPoint(x: 0.56, y: 0.58), CGPoint(x: 0.72, y: 0.52), CGPoint(x: 0.92, y: 0.62)]),
            (6,  [CGPoint(x: 0.24, y: 0.90), CGPoint(x: 0.46, y: 0.82), CGPoint(x: 0.68, y: 0.92)]),
            (7,  [CGPoint(x: 0.74, y: 0.78), CGPoint(x: 0.86, y: 0.88), CGPoint(x: 1.02, y: 0.82)]),
            (8,  [CGPoint(x: 0.00, y: 0.48), CGPoint(x: 0.16, y: 0.52), CGPoint(x: 0.28, y: 0.46)]),
            (9,  [CGPoint(x: 0.38, y: 0.68), CGPoint(x: 0.54, y: 0.74), CGPoint(x: 0.66, y: 0.64)]),
            (10, [CGPoint(x: 0.18, y: 0.30), CGPoint(x: 0.32, y: 0.24), CGPoint(x: 0.52, y: 0.32)]),
        ]
    }
}

private struct PetrolCurvedPath: Shape {
    let p0, p1, p2, p3: CGPoint
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: p0)
        p.addCurve(to: p3, control1: p1, control2: p2)
        return p
    }
}

private struct PetrolPolylinePath: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        points.dropFirst().forEach { p.addLine(to: $0) }
        return p
    }
}

private struct PetrolMapPin: View {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#CC0011"))
                .frame(width: size, height: size)
            Image(systemName: "fuelpump.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: x, y: y)
    }
}

// Routes directly to PetrolStationView if location is already authorized — no permission flash.
struct PetrolPumpRouter: View {
    @State private var skipPermission: Bool = {
        let s = CLLocationManager().authorizationStatus
        return s == .authorizedWhenInUse || s == .authorizedAlways
    }()

    var body: some View {
        if skipPermission {
            PetrolStationView()
        } else {
            PetrolLocationPermissionView()
        }
    }
}

#Preview {
    NavigationView { PetrolPumpRouter() }
}
