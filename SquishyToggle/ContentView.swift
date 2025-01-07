import SwiftUI
import PureSwiftUI

private let frameLayoutConfig = LayoutGuideConfig.grid(columns: [0.25, 0.4, 0.6, 0.75], rows: 2)

private let buttonDiameterRatio: CGFloat = 0.9
private let duration: Double = 0.6
private let rotationIfOff = -(2 / buttonDiameterRatio).radians

private let stateIconConfig: LayoutGuideConfig = {
    let controlPointOffsetRatio: CGFloat = 0.552
    let controlPointOffsetInUnitSquare = controlPointOffsetRatio * 0.5
    let columnsAndRows = [
        0,
        0.5 - controlPointOffsetInUnitSquare,
        0.5,
        0.5 + controlPointOffsetInUnitSquare,
        1
    ]
    return LayoutGuideConfig.grid(columns: columnsAndRows, rows: columnsAndRows)
}()

struct SquishyToggle: View {
    @State private var isOn = true
    var body: some View {
        let debug = false
        GeometryReader { (geo: GeometryProxy) in
            let size = calculateSize(from: geo)
            let shadowRadius = size.widthScaled(0.015)
            let shadowOffset = CGPoint(size.widthScaled(0.01))
            let toggleColor: Color = isOn ? .green : .red
            let textSize = size.widthScaled(0.15)
            ZStack {
                ToggleFrame(isOn, debug: debug)
                    .styling(background: toggleColor, shadowRadius: shadowRadius, shadowOffset: shadowOffset)
                    .layoutGuide(frameLayoutConfig, color: .green, lineWidth: 2)
                    .animation(.linear(duration: duration))
                
                Group {
                    CustomText("ON", textSize, .white(0.4), .medium)
                        .opacityIfNot(isOn, 0)
                        .xOffset(-size.halfHeight)
                        .scaleIfNot(isOn, 0)
                    CustomText("OFF", textSize, .white(0.4), .medium)
                        .opacityIf(isOn, 0)
                        .xOffset(size.halfHeight)
                        .scaleIf(isOn, 0)
                }
                .blendMode(.multiply)
                .animation(.easeInOut(duration: duration))
                
                Group {
                    ToggleButton()
                        .frame(size.heightScaled(buttonDiameterRatio))
                        .shadowColor(.white(0.1), shadowRadius, offset: shadowOffset)

                    ToggleStateIcon(isOn, debug: debug)
                        .styling(lineWidth: size.width * 0.04, background: toggleColor, shadowRadius: shadowRadius, shadowOffset: shadowOffset)
                        .frame(size.halfHeight)
                        .layoutGuide(stateIconConfig, color: .red, lineWidth: 1, opacity: 1)
                }
                .xOffsetIfNot(debug, isOn ? size.halfHeight : -size.halfHeight)
                .animation(.easeInOut(duration: duration))

            }
            .frame(size)
            .borderIf(debug, Color.gray.opacity(0.2))
            .contentShape(Capsule())
            .onTapGesture {
                isOn.toggle()
            }
            .greedyFrame()
        }
        .showLayoutGuides(debug)
    }
    
    private func calculateSize(from geo: GeometryProxy) -> CGSize {
        let doubleHeight = geo.heightScaled(2)
        if geo.width < doubleHeight {
            return CGSize(geo.width, geo.halfWidth)
        } else {
            return CGSize(doubleHeight, geo.height)
        }
    }
}

private struct ToggleFrame: Shape {
    
    var animatableData: CGFloat
    private let debug: Bool
    
    init(_ isOn: Bool, debug: Bool = false) {
        animatableData = isOn ? 1 : 0
        self.debug = debug
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let maxCurveYOffset = rect.heightScaled(0.18)

        let offsetLayoutGuide = LayoutGuide.polar(.rect(.square(maxCurveYOffset)), rings: 1, segments: 1)
            .rotated(360.degrees, factor: animatableData)

        let curveYOffset = offsetLayoutGuide.bottom.y

        let g = frameLayoutConfig.layout(in: rect)

        let arcRadius = rect.halfHeight

        path.move(g[0, 0])

        path.curve(rect.top.yOffset(curveYOffset),
                   cp1: g[1, 0],
                   cp2: g[1, 0].yOffset(curveYOffset),
                   showControlPoints: debug)

        path.curve(g[3, 0],
                   cp1: g[2, 0].yOffset(curveYOffset),
                   cp2: g[2, 0],
                   showControlPoints: debug)

        path.arc(g[3, 1], radius: arcRadius, startAngle: .top, endAngle: .bottom)

        path.curve(rect.bottom.yOffset(-curveYOffset),
                   cp1: g[2, 2],
                   cp2: g[2, 2].yOffset(-curveYOffset),
                   showControlPoints: debug)

        path.curve(g[0, 2],
                   cp1: g[1, 2].yOffset(-curveYOffset),
                   cp2: g[1, 2],
                   showControlPoints: debug)

        path.arc(g[0, 1], radius: arcRadius, startAngle: .bottom, endAngle: .top)
        
        path.closeSubpath()
        
        return path
    }
    
    @ViewBuilder func styling(background: Color, shadowRadius: CGFloat, shadowOffset: CGPoint) -> some View {
        if debug {
            debugStyling()
        } else {
            innerShadow(background, radius: shadowRadius, offset: shadowOffset)
        }
    }
}

private let outerGradient = LinearGradient([.white(0.45), .white(0.95)], to: .topLeading)

private struct ToggleButton: View {
    
    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            let innerGradient = RadialGradient([.white(0.9), .white(0.3)],
                                               center: .bottomTrailing,
                                               from: geo.widthScaled(0.2),
                                               to: geo.widthScaled(1.5))
            ZStack {
                Circle()
                    .fill(outerGradient)
                Circle()
                    .inset(geo.widthScaled(0.1))
                    .fill(innerGradient)
            }
            .drawingGroup()
        }
    }
}

private struct ToggleStateIcon: Shape {
    
    var animatableData: CGFloat
    private let debug: Bool
    
    init(_ isOn: Bool, debug: Bool = false) {
        animatableData = isOn ? 1 : 0
        self.debug = debug
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let g = stateIconConfig.layout(in: rect)
            .rotated(rotationIfOff, factor: 1 - animatableData)
        
        path.move(g.leading.to(g.center, animatableData))
        
        path.curve(g.top,
                   cp1: g[0, 1].to(g[2, 1], animatableData),
                   cp2: g[1, 0].to(g.top.yOffset(1), animatableData),
                   showControlPoints: debug)
        
        path.curve(g.trailing.to(g.center, animatableData),
                   cp1:  g[3, 0].to(g.top.yOffset(1), animatableData),
                   cp2:  g[4, 1].to(g[2, 1], animatableData),
                   showControlPoints: debug)
        
        path.curve(g.bottom,
                   cp1: g[4, 3].to(g[2, 3], animatableData),
                   cp2: g[3, 4].to(g.bottom.yOffset(-1), animatableData),
                   showControlPoints: debug)

        path.curve(g.leading.to(g.center, animatableData),
                   cp1: g[1, 4].to(g.bottom.yOffset(-1), animatableData),
                   cp2: g[0, 3].to(g[2, 3], animatableData),
                   showControlPoints: debug)
        
        path.closeSubpath()
        
        return path
    }
    
    @ViewBuilder func styling(lineWidth: CGFloat, background: Color, shadowRadius: CGFloat, shadowOffset: CGPoint) -> some View {
        if debug {
            debugStyling()
        } else {
            stroke(style: .init(lineWidth: lineWidth, lineJoin: .round))
                .innerShadow(background.scale(1.5), radius: shadowRadius, offset: shadowOffset)
        }
    }
}

private extension Shape {
    func debugStyling() -> some View {
        strokeColor(.black, lineWidth: 2)
    }
    
    func innerShadow<V: View>(_ background: V, radius: CGFloat = 5, opacity: Double = 0.7, offset: CGPoint = .zero) -> some View {
        self.fill(Color.clear).innerShadow(background, self, radius: radius, opacity: opacity, offset: offset)
    }
}

private extension View {
    
    func innerShadow<V: View, S: Shape>(_ background: V, _ shape: S, radius: CGFloat = 5, opacity: Double = 0.7, offset: CGPoint = .zero) -> some View {
        self
            .background(background)
            .blendMode(.multiply)
            .background(
                ZStack {
                    shape.fill(Color(white: 1 - opacity))
                    shape.fill(Color.white).blur(radius).offset(offset)
                }
            )
            .mask(self.overlay(shape))
    }
}

struct SquishyToggle_Previews: PreviewProvider {
    struct SquishyToggle_Harness: View {
        
        var body: some View {
            SquishyToggle()
                .frame(400)
                .greedyFrame()
                .background(LinearGradient([.white(0.9), .white(0.3)], to: .bottomTrailing).ignoresSafeArea())
        }
    }
    
    static var previews: some View {
        SquishyToggle_Harness()
            .previewDevice(.iPhone_12_Pro_Max)
    }
}
