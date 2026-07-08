//
//  GifHelper.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 07/07/26.
//

import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false

        return webView

    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif") else {
            return
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background: transparent;
                }

                img {
                    width: 100%;
                    height: 100%;
                    object-fit: contain; /* change to cover if you want it to fill */
                }
            </style>
        </head>
        <body>
            <img src="\(url.lastPathComponent)">
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }
}
