//
//  ReportToast.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 06/07/26.
//

import SwiftUI

struct ReportToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text("Your report has been recorded")
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.9))
        .clipShape(Capsule())
    }
}
