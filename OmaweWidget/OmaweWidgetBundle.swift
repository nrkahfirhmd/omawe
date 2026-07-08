//
//  OmaweWidgetBundle.swift
//  OmaweWidget
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
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
