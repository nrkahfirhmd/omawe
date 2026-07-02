import SwiftUI

struct CirclesLayoutView: View {
    let count: Int   // jumlah orang, auto-cap ke 6
    
    private struct CircleSpec {
        let size: CGFloat
        let xRatio: CGFloat
        let yRatio: CGFloat
        let label: String
    }
    
    // urutan reveal: index 0 = center (selalu muncul duluan),
    // lalu bawah kiri-kanan, lalu atas kiri-tengah-kanan
    private let specs: [CircleSpec] = [
        CircleSpec(size: 55, xRatio: 0.5,  yRatio: 0.35, label: "A"), // center
        CircleSpec(size: 40, xRatio: 0.3,  yRatio: 0.6,  label: "B"), // bawah kiri
        CircleSpec(size: 40, xRatio: 0.7,  yRatio: 0.6,  label: "C"), // bawah kanan
        CircleSpec(size: 25, xRatio: 0.25, yRatio: 0.23, label: "D"), // atas kiri
        CircleSpec(size: 30, xRatio: 0.5,  yRatio: 0.025, label: "E"), // atas tengah
        CircleSpec(size: 25, xRatio: 0.75, yRatio: 0.23, label: "F"), // atas kanan
    ]
    
    private var visibleCount: Int {
        min(max(count, 0), specs.count)
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            ZStack {
                ForEach(0..<visibleCount, id: \.self) { i in
                    let spec = specs[i]
                    Circle()
                        .fill(Color.white)
                        .frame(width: spec.size, height: spec.size)
                        .overlay(
                            Text(spec.label)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.black)
                        )
                        .position(x: width * spec.xRatio, y: height * spec.yRatio)
                }
            }
        }
    }
}

struct ArcCircleBackgroundView: View {
    var sizeRatio: CGFloat = 0.85   // persentase dari lebar screen
    var lineWidth: CGFloat = 3
    var topOpacity: Double = 0.9
    var bottomOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let circleSize = width * sizeRatio
            let maskHeight = circleSize / 2
            
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(topOpacity),
                            .white.opacity(bottomOpacity)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: circleSize, height: circleSize)
                .mask(
                    Rectangle()
                        .frame(height: maskHeight)
                        .offset(y: -maskHeight / 2)
                )
                .frame(width: width, alignment: .center)
        }
        .frame(height: 150)
    }
}

struct PeopleOrbit: View{
    var people: Int = 1
    var body: some View{
        ZStack{
            ArcCircleBackgroundView(lineWidth: 1.25)
            ArcCircleBackgroundView(sizeRatio: 0.5, lineWidth: 1.25)
                .offset(x: 0, y: 55)
            CirclesLayoutView(count: people)

            VStack{
                Spacer()
                VStack(spacing:4){
                    Text("\(people)")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                        .foregroundStyle(Theme.secondarySoft)
                    Text("People")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                }
                
            }
            
            
        }
        .frame(maxHeight: 162)
//                    .border(.red, width: 1)
        
        
    }
    
}
#Preview {
    ZStack{
        Color.black
            .ignoresSafeArea()
        PeopleOrbit(people: 9)
    }
    
}

#Preview {
    ZStack(alignment: .top) {
        Color.white
            .ignoresSafeArea()
        
        VStack {
            VStack {
                DynamicBox(
                    theme: Theme.themeSecondary,
                    title: "Ex-Boyfriends\nCelebration!",
                    subtitle: "by @Bintang • 27/06/2026 • 11:30",
                    helperText: "Swipe to see other trips",//curently this is missing symbol
                    footerTitle: "Trip is not starting yet"
                ) {
                    
                    ZStack{
                        ArcCircleBackgroundView(lineWidth: 1.25)
                        ArcCircleBackgroundView(sizeRatio: 0.5, lineWidth: 1.25)
                            .offset(x: 0, y: 55)
                        CirclesLayoutView(count: 1)

                        VStack{
                            Spacer()
                            VStack(spacing:4){
                                Text("12")
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .fontWidth(.expanded)
                                    .foregroundStyle(Theme.secondarySoft)
                                Text("People")
                                    .font(.caption)
                                    .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                            }
                            
                        }
                        
                        
                    }
                    .frame(maxHeight: 162)
//                    .border(.red, width: 1)
                    
                    
                }
                   
            }
        }
    }
//        .statusBarHidden(true)
    .ignoresSafeArea(edges: .top)

}
