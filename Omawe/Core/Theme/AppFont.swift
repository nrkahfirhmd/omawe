import SwiftUI

enum AppFont {
    // MARK: - Display
    static let largeTitle = Font.system(size: 34, weight: .semibold)
    static let title1 = Font.system(size: 28, weight: .semibold)
    static let title2 = Font.system(size: 22, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Text
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subhead = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Action
    static let button = Font.system(size: 15, weight: .semibold)
}

extension Font {
    // MARK: - Display
    static func largeTitle() -> Font { AppFont.largeTitle }
    static func title1() -> Font { AppFont.title1 }
    static func title2() -> Font { AppFont.title2 }
    static func title3() -> Font { AppFont.title3 }

    // MARK: - Text
    static func headline() -> Font { AppFont.headline }
    static func bodyText() -> Font { AppFont.body }
    static func callout() -> Font { AppFont.callout }
    static func subhead() -> Font { AppFont.subhead }
    static func footnote() -> Font { AppFont.footnote }
    static func caption1() -> Font { AppFont.caption1 }
    static func caption2() -> Font { AppFont.caption2 }

    // MARK: - Action
    static func button() -> Font { AppFont.button }
}
