import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Primary" asset catalog color resource.
    static let primary = DeveloperToolsSupport.ColorResource(name: "Primary", bundle: resourceBundle)

    /// The "PrimarySoft" asset catalog color resource.
    static let primarySoft = DeveloperToolsSupport.ColorResource(name: "PrimarySoft", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Frame 74" asset catalog image resource.
    static let frame74 = DeveloperToolsSupport.ImageResource(name: "Frame 74", bundle: resourceBundle)

    /// The "HomeBackground" asset catalog image resource.
    static let homeBackground = DeveloperToolsSupport.ImageResource(name: "HomeBackground", bundle: resourceBundle)

    /// The "HomeCircleSlide" asset catalog image resource.
    static let homeCircleSlide = DeveloperToolsSupport.ImageResource(name: "HomeCircleSlide", bundle: resourceBundle)

    /// The "SliderButton" asset catalog image resource.
    static let sliderButton = DeveloperToolsSupport.ImageResource(name: "SliderButton", bundle: resourceBundle)

    /// The "Star" asset catalog image resource.
    static let star = DeveloperToolsSupport.ImageResource(name: "Star", bundle: resourceBundle)

    /// The "TapCircleSlide" asset catalog image resource.
    static let tapCircleSlide = DeveloperToolsSupport.ImageResource(name: "TapCircleSlide", bundle: resourceBundle)

    /// The "TimeChip" asset catalog image resource.
    static let timeChip = DeveloperToolsSupport.ImageResource(name: "TimeChip", bundle: resourceBundle)

    /// The "Trip_Status_Bar" asset catalog image resource.
    static let tripStatusBar = DeveloperToolsSupport.ImageResource(name: "Trip_Status_Bar", bundle: resourceBundle)

    /// The "avatar" asset catalog image resource.
    static let avatar = DeveloperToolsSupport.ImageResource(name: "avatar", bundle: resourceBundle)

    /// The "omaweCircle" asset catalog image resource.
    static let omaweCircle = DeveloperToolsSupport.ImageResource(name: "omaweCircle", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "Primary" asset catalog color.
    static var primary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primary)
#else
        .init()
#endif
    }

    /// The "PrimarySoft" asset catalog color.
    static var primarySoft: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primarySoft)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "Primary" asset catalog color.
    static var primary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primary)
#else
        .init()
#endif
    }

    /// The "PrimarySoft" asset catalog color.
    static var primarySoft: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primarySoft)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    #warning("The \"Primary\" color asset name resolves to a conflicting Color symbol \"primary\". Try renaming the asset.")

    /// The "PrimarySoft" asset catalog color.
    static var primarySoft: SwiftUI.Color { .init(.primarySoft) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "PrimarySoft" asset catalog color.
    static var primarySoft: SwiftUI.Color { .init(.primarySoft) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Frame 74" asset catalog image.
    static var frame74: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .frame74)
#else
        .init()
#endif
    }

    /// The "HomeBackground" asset catalog image.
    static var homeBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .homeBackground)
#else
        .init()
#endif
    }

    /// The "HomeCircleSlide" asset catalog image.
    static var homeCircleSlide: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .homeCircleSlide)
#else
        .init()
#endif
    }

    /// The "SliderButton" asset catalog image.
    static var sliderButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sliderButton)
#else
        .init()
#endif
    }

    /// The "Star" asset catalog image.
    static var star: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .star)
#else
        .init()
#endif
    }

    /// The "TapCircleSlide" asset catalog image.
    static var tapCircleSlide: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tapCircleSlide)
#else
        .init()
#endif
    }

    /// The "TimeChip" asset catalog image.
    static var timeChip: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .timeChip)
#else
        .init()
#endif
    }

    /// The "Trip_Status_Bar" asset catalog image.
    static var tripStatusBar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tripStatusBar)
#else
        .init()
#endif
    }

    /// The "avatar" asset catalog image.
    static var avatar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatar)
#else
        .init()
#endif
    }

    /// The "omaweCircle" asset catalog image.
    static var omaweCircle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .omaweCircle)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Frame 74" asset catalog image.
    static var frame74: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .frame74)
#else
        .init()
#endif
    }

    /// The "HomeBackground" asset catalog image.
    static var homeBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .homeBackground)
#else
        .init()
#endif
    }

    /// The "HomeCircleSlide" asset catalog image.
    static var homeCircleSlide: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .homeCircleSlide)
#else
        .init()
#endif
    }

    /// The "SliderButton" asset catalog image.
    static var sliderButton: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sliderButton)
#else
        .init()
#endif
    }

    /// The "Star" asset catalog image.
    static var star: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .star)
#else
        .init()
#endif
    }

    /// The "TapCircleSlide" asset catalog image.
    static var tapCircleSlide: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tapCircleSlide)
#else
        .init()
#endif
    }

    /// The "TimeChip" asset catalog image.
    static var timeChip: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .timeChip)
#else
        .init()
#endif
    }

    /// The "Trip_Status_Bar" asset catalog image.
    static var tripStatusBar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tripStatusBar)
#else
        .init()
#endif
    }

    /// The "avatar" asset catalog image.
    static var avatar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .avatar)
#else
        .init()
#endif
    }

    /// The "omaweCircle" asset catalog image.
    static var omaweCircle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .omaweCircle)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

