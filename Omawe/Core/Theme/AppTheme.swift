//
//  AppTheme.swift
//  Omawe
//
//  Created by Gleenryan on 01/07/26.
//


import SwiftUI

struct AppTheme {
    let gradient: LinearGradient
    let gradientSoft: LinearGradient
    let boxColor: Color
}

enum Theme {
    
    private static func make(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Raw Colors
    static let primaryBox   = Color(red: 0/255,  green: 107/255, blue: 124/255)
    static let secondaryBox = Color(red: 0/255,  green: 110/255, blue: 100/255)
    static let tertiaryBox  = Color(red: 25/255, green: 130/255, blue: 65/255)

    // MARK: - Raw Gradients
    static let primary      = make([Color(red: 3/255,  green: 185/255, blue: 214/255), Color(red: 122/255, green: 232/255, blue: 255/255)])
    static let primarySoft  = make([Color(red: 3/255,  green: 185/255, blue: 214/255), Color(red: 122/255, green: 232/255, blue: 255/255), Color(red: 3/255, green: 185/255, blue: 214/255)])
    static let secondary    = make([Color(red: 1/255,  green: 201/255, blue: 180/255), Color(red: 73/255,  green: 255/255, blue: 236/255)])
    static let secondarySoft = make([Color(red: 1/255, green: 201/255, blue: 180/255), Color(red: 73/255,  green: 255/255, blue: 236/255), Color(red: 1/255, green: 201/255, blue: 180/255)])
    static let tertiary = make([
        Color(red: 52/255, green: 218/255, blue: 113/255),
        Color(red: 119/255, green: 255/255, blue: 169/255)
    ])

    static let tertiarySoft = make([
        Color(red: 52/255, green: 218/255, blue: 113/255),
        Color(red: 119/255, green: 255/255, blue: 169/255),
        Color(red: 52/255, green: 218/255, blue: 113/255)
    ])
    
    static let graybackground = LinearGradient(
        colors: [
            Color(red: 28/255, green: 28/255, blue: 28/255),
            Color(red: 63/255, green: 63/255, blue: 63/255),
            Color(red: 28/255, green: 28/255, blue: 28/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    // MARK: - Bundled Themes
    static let themePrimary = AppTheme(
        gradient:     primary,
        gradientSoft: primarySoft,
        boxColor:     primaryBox
    )
    static let themeSecondary = AppTheme(
        gradient:     secondary,
        gradientSoft: secondarySoft,
        boxColor:     secondaryBox
    )
    static let themeTertiary = AppTheme(
        gradient:     tertiary,
        gradientSoft: tertiarySoft,
        boxColor:     tertiaryBox
    )
    static let GrayBackground = AppTheme(
        gradient:     graybackground,
        gradientSoft: tertiarySoft,
        boxColor:     tertiaryBox
    )
}

#Preview {
    VStack {
        Theme.primary
        Theme.primarySoft
//        Theme.secondary
//        Theme.secondarySoft
//        Theme.tertiary
//        Theme.tertiarySoft
        Theme.graybackground
    }
}
