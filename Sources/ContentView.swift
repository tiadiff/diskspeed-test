import SwiftUI

struct ContentView: View {
    @StateObject private var tester = DiskSpeedTester()
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 28/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Button(action: { tester.refreshVolumes() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 12)
                }
                .frame(height: 38)
                
                // Scrollable List of Disks
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(tester.volumeStates) { state in
                            DiskRowView(state: state, runTest: {
                                tester.runTest(for: state)
                            })
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(width: 550, height: 350)
    }
}

struct DiskRowView: View {
    @ObservedObject var state: VolumeTestState
    var runTest: () -> Void
    
    private var statusColor: Color {
        switch state.status {
        case .idle: return .yellow
        case .testing: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if !state.isInternal {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text(state.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    StatusTag(text: (state.errorText ?? state.status.rawValue).uppercased(), color: statusColor)
                    
                    if state.status == .testing || state.status == .success {
                        Text("\(Int(state.progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(statusColor)
                            .frame(width: geo.size.width * CGFloat(state.progress), height: 3)
                            .animation(.linear, value: state.progress)
                    }
                }
                .frame(height: 3)
                .padding(.top, 4)
                
                HStack(spacing: 20) {
                    SpeedMetric(label: "WRITE", value: state.writeSpeed)
                    SpeedMetric(label: "READ", value: state.readSpeed)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Interaction & Circle
            VStack(spacing: 10) {
                Button(action: runTest) {
                    ZStack {
                        Circle()
                            .stroke(state.status == .testing ? statusColor : Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        if state.status == .testing {
                            Circle()
                                .trim(from: 0, to: CGFloat(state.progress))
                                .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            
                            Image(systemName: "timer")
                                .font(.system(size: 14))
                                .foregroundColor(statusColor)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(state.status == .testing)
                
                if state.status == .success {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatusTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
            .lineLimit(1)
    }
}

struct SpeedMetric: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
            Text("\(Int(value)) MB/s")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
