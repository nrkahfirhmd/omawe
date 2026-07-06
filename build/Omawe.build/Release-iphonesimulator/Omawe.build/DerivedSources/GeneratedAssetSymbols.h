#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.exboyfriends.omawe";

/// The "Primary" asset catalog color resource.
static NSString * const ACColorNamePrimary AC_SWIFT_PRIVATE = @"Primary";

/// The "PrimarySoft" asset catalog color resource.
static NSString * const ACColorNamePrimarySoft AC_SWIFT_PRIVATE = @"PrimarySoft";

/// The "Frame 74" asset catalog image resource.
static NSString * const ACImageNameFrame74 AC_SWIFT_PRIVATE = @"Frame 74";

/// The "HomeBackground" asset catalog image resource.
static NSString * const ACImageNameHomeBackground AC_SWIFT_PRIVATE = @"HomeBackground";

/// The "HomeCircleSlide" asset catalog image resource.
static NSString * const ACImageNameHomeCircleSlide AC_SWIFT_PRIVATE = @"HomeCircleSlide";

/// The "SliderButton" asset catalog image resource.
static NSString * const ACImageNameSliderButton AC_SWIFT_PRIVATE = @"SliderButton";

/// The "Star" asset catalog image resource.
static NSString * const ACImageNameStar AC_SWIFT_PRIVATE = @"Star";

/// The "TapCircleSlide" asset catalog image resource.
static NSString * const ACImageNameTapCircleSlide AC_SWIFT_PRIVATE = @"TapCircleSlide";

/// The "TimeChip" asset catalog image resource.
static NSString * const ACImageNameTimeChip AC_SWIFT_PRIVATE = @"TimeChip";

/// The "Trip_Status_Bar" asset catalog image resource.
static NSString * const ACImageNameTripStatusBar AC_SWIFT_PRIVATE = @"Trip_Status_Bar";

/// The "avatar" asset catalog image resource.
static NSString * const ACImageNameAvatar AC_SWIFT_PRIVATE = @"avatar";

/// The "omaweCircle" asset catalog image resource.
static NSString * const ACImageNameOmaweCircle AC_SWIFT_PRIVATE = @"omaweCircle";

#undef AC_SWIFT_PRIVATE
