//
//  GlassStarShape.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

struct GlassStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 48
        let scaleY = rect.height / 47

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scaleX, y: y * scaleY)
        }

        var path = Path()

        path.move(to: point(20.7591, 1.17368))

        path.addCurve(
            to: point(27.1979, 1.17368),
            control1: point(22.6201, -0.391228),
            control2: point(25.3369, -0.391231)
        )

        path.addLine(to: point(31.9113, 5.13722))

        path.addCurve(
            to: point(34.1447, 6.21277),
            control1: point(32.5538, 5.67745),
            control2: point(33.3218, 6.04732)
        )

        path.addLine(to: point(40.1823, 7.42665))

        path.addCurve(
            to: point(44.1968, 12.4607),
            control1: point(42.5661, 7.90593),
            control2: point(44.26, 10.03)
        )

        path.addLine(to: point(44.0368, 18.617))

        path.addCurve(
            to: point(44.5884, 21.0338),
            control1: point(44.015, 19.4561),
            control2: point(44.2047, 20.2872)
        )

        path.addLine(to: point(47.4037, 26.511))

        path.addCurve(
            to: point(45.971, 32.7883),
            control1: point(48.5153, 28.6735),
            control2: point(47.9107, 31.3222)
        )

        path.addLine(to: point(41.058, 36.5016))

        path.addCurve(
            to: point(39.5124, 38.4397),
            control1: point(40.3883, 37.0077),
            control2: point(39.8568, 37.6742)
        )

        path.addLine(to: point(36.9854, 44.0558))

        path.addCurve(
            to: point(31.1843, 46.8494),
            control1: point(35.9877, 46.2732),
            control2: point(33.54, 47.4519)
        )

        path.addLine(to: point(25.218, 45.3235))

        path.addCurve(
            to: point(22.7391, 45.3235),
            control1: point(24.4048, 45.1155),
            control2: point(23.5523, 45.1155)
        )

        path.addLine(to: point(16.7727, 46.8494))

        path.addCurve(
            to: point(10.9716, 44.0558),
            control1: point(14.417, 47.4519),
            control2: point(11.9693, 46.2732)
        )

        path.addLine(to: point(8.44464, 38.4397))

        path.addCurve(
            to: point(6.89908, 36.5016),
            control1: point(8.10022, 37.6742),
            control2: point(7.56871, 37.0077)
        )

        path.addLine(to: point(1.98608, 32.7883))

        path.addCurve(
            to: point(0.553319, 26.511),
            control1: point(0.0462923, 31.3222),
            control2: point(-0.558249, 28.6735)
        )

        path.addLine(to: point(3.36865, 21.0338))

        path.addCurve(
            to: point(3.92025, 18.617),
            control1: point(3.75237, 20.2872),
            control2: point(3.94206, 19.4561)
        )

        path.addLine(to: point(3.76021, 12.4607))

        path.addCurve(
            to: point(7.77471, 7.42665),
            control1: point(3.69702, 10.03),
            control2: point(5.3909, 7.90593)
        )

        path.addLine(to: point(13.8123, 6.21277))

        path.addCurve(
            to: point(16.0457, 5.13722),
            control1: point(14.6352, 6.04732),
            control2: point(15.4033, 5.67745)
        )

        path.addLine(to: point(20.7591, 1.17368))
        path.closeSubpath()

        return path
    }
}
