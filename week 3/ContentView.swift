import SwiftUI

struct Cell {
    enum Kind: CaseIterable { case slash, backslash, circle, diamond }
    let kind: Kind
    let color: Color
    let lineWidth: CGFloat
}

struct ContentView: View {
    private let cols = 24
    private let rows = 36
    private let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .blue, .purple, .pink, .black]
    private let widths: [CGFloat] = [3, 4, 5, 6, 7, 8]

    @State private var cells: [Cell] = []

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                    let w = size.width  / CGFloat(cols)
                    let h = size.height / CGFloat(rows)

                    for r in 0..<rows {
                        for c in 0..<cols {
                            let idx = r * cols + c
                            guard idx < cells.count else { continue }
                            let cell = cells[idx]

                            let origin = CGPoint(x: CGFloat(c) * w, y: CGFloat(r) * h)
                            let rect = CGRect(x: origin.x, y: origin.y, width: w, height: h)

                            var path = Path()
                            switch cell.kind {
                            case .slash:
                                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                                context.stroke(path, with: .color(cell.color),
                                               style: StrokeStyle(lineWidth: cell.lineWidth, lineCap: .round))
                            case .backslash:
                                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                                context.stroke(path, with: .color(cell.color),
                                               style: StrokeStyle(lineWidth: cell.lineWidth, lineCap: .round))
                            case .circle:
                                let inset = min(w, h) * 0.18
                                let circleRect = rect.insetBy(dx: inset, dy: inset)
                                path.addEllipse(in: circleRect)
                                context.stroke(path, with: .color(cell.color.opacity(0.9)),
                                               style: StrokeStyle(lineWidth: cell.lineWidth))
                            case .diamond:
                                let cx = rect.midX, cy = rect.midY
                                let rx = w * 0.42, ry = h * 0.42
                                path.move(to: CGPoint(x: cx,      y: cy - ry))
                                path.addLine(to: CGPoint(x: cx + rx, y: cy))
                                path.addLine(to: CGPoint(x: cx,      y: cy + ry))
                                path.addLine(to: CGPoint(x: cx - rx, y: cy))
                                path.closeSubpath()
                                context.stroke(path, with: .color(cell.color.opacity(0.9)),
                                               style: StrokeStyle(lineWidth: cell.lineWidth, lineJoin: .round))
                            }
                        }
                    }
                }
                .onAppear { if cells.isEmpty { regenerate() } }

                VStack {
                    Spacer()
                    Button("Regenerate") { regenerate() }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 24)
                }
            }
            .background(.white)
            .ignoresSafeArea()
        }
    }

    private func regenerate() {
        let total = rows * cols
        let kinds = Cell.Kind.allCases
        cells = (0..<total).map { _ in
            Cell(kind: kinds.randomElement()!,
                 color: colors.randomElement()!,
                 lineWidth: widths.randomElement()!)
        }
    }
}

#Preview { ContentView() }
