import WidgetKit
import SwiftUI

@main
struct OmaweWidgetBundle: WidgetBundle {
    var body: some Widget {
        OmaweWidget()
        OmaweWidgetControl()
        OmaweWidgetLiveActivity()
    }
}
