import SwiftUI

struct PeopleOrbitPerson: Identifiable, Hashable {
    let id: String
    var displayName: String?

    var initials: String {
        let trimmedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedName.isEmpty {
            let initials = trimmedName
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }
                .map(String.init)
                .joined()

            if !initials.isEmpty {
                return initials.uppercased()
            }
        }

        return String(id.prefix(1)).uppercased()
    }
}

struct CirclesLayoutView: View {
    let people: [PeopleOrbitPerson]
    
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
    
    init(count: Int) {
        self.people = (0..<max(count, 0)).map {
            PeopleOrbitPerson(id: "person-\($0)", displayName: nil)
        }
    }

    init(people: [PeopleOrbitPerson]) {
        self.people = people
    }

    private var visiblePeople: [PeopleOrbitPerson] {
        Array(people.prefix(specs.count))
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            ZStack {
                ForEach(Array(visiblePeople.enumerated()), id: \.element.id) { i, person in
                    let spec = specs[i]
                    Circle()
                        .fill(Color.white)
                        .frame(width: spec.size, height: spec.size)
                        .overlay(
                            Text(person.initials.isEmpty ? spec.label : person.initials)
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
    private var people: [PeopleOrbitPerson]

    init(people: Int = 1) {
        self.people = (0..<max(people, 0)).map {
            PeopleOrbitPerson(id: "person-\($0)", displayName: nil)
        }
    }

    init(people: [PeopleOrbitPerson]) {
        self.people = people
    }

    var body: some View{
        ZStack{
            ArcCircleBackgroundView(lineWidth: 1.25)
            ArcCircleBackgroundView(sizeRatio: 0.5, lineWidth: 1.25)
                .offset(x: 0, y: 55)
            CirclesLayoutView(people: people)

            VStack{
                Spacer()
                VStack(spacing:4){
                    Text("\(people.count)")
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
