//
//  OmaweWidgetBundle.swift
//  OmaweWidget
//
//  Created by Gleenryan on 29/06/26.
//

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
