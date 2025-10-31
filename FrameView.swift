//
//  FrameView.swift
//  VideoManipulator
//
//  Created by Ya Wen Tang on 10/30/25.
//
import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("Video feed")

    var body: some View {
        if let image = image {
            GeometryReader { geo in
                Image(image, scale: 1.0, orientation: .upMirrored, label: label)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        } else {
            Color.black.ignoresSafeArea()
        }
    }
}

