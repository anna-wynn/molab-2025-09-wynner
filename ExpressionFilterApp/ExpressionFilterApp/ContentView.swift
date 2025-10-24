import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    // AR expression signal coming from AR view (0...1)
    @State private var expressionIntensity: CGFloat = 0.0
    @State private var expressionLabel: String = "Neutral"

    // Photo mode
    @State private var selectedItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var processedImage: UIImage?

    // Filter selection
    @State private var currentFilter: CIFilter = CIFilter.pixellate()
    private let context = CIContext()

    // UI state
    @State private var showFilterPicker = false
    @State private var showShareSheet = false
    @State private var shareItem: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Header with current expression
                HStack {
                    Text("Expression: \(expressionLabel)")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "Intensity: %.2f", expressionIntensity))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Live AR view (FaceMesh-style)
                ARFaceMeshView(intensity: $expressionIntensity, label: $expressionLabel)
                    .frame(minHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .bottomTrailing) {
                        CaptureButton {
                            Task {
                                if let arImage = await ARFaceMeshView.snapshot() {
                                    let filtered = applyFilter(to: arImage, intensity: expressionIntensity)
                                    UIImageWriteToSavedPhotosAlbum(filtered, nil, nil, nil)
                                    shareItem = filtered
                                    showShareSheet = true
                                }
                            }
                        }
                        .padding(12)
                    }

                Divider().padding(.vertical, 4)

                // Photo mode (Instafilter-style)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.secondary)

                        if let img = processedImage ?? photoImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(6)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                Text("Tap to import a photo")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(24)
                        }
                    }
                    .frame(minHeight: 180)
                }
                .onChange(of: selectedItem) { _, _ in
                    Task { await loadPhoto() }
                }

                // Filter controls
                HStack {
                    Button("Change Filter") { showFilterPicker = true }
                    Spacer()
                    Button("Apply Using My Expression") {
                        guard let img = photoImage else { return }
                        processedImage = applyFilter(to: img, intensity: expressionIntensity)
                    }
                    .disabled(photoImage == nil)
                }

                // Save & Share for photo
                HStack {
                    Button("Save Photo") {
                        guard let out = processedImage ?? photoImage else { return }
                        UIImageWriteToSavedPhotosAlbum(out, nil, nil, nil)
                    }
                    .disabled((processedImage ?? photoImage) == nil)

                    Spacer()

                    Button("Share Photo") {
                        shareItem = processedImage ?? photoImage
                        showShareSheet = (shareItem != nil)
                    }
                    .disabled((processedImage ?? photoImage) == nil)
                }
            }
            .padding()
            .navigationTitle("ExpressionFilter")
            .confirmationDialog("Select a filter", isPresented: $showFilterPicker) {
                Button("Pixellate")      { setFilter(CIFilter.pixellate()) }
                Button("Gaussian Blur")  { setFilter(CIFilter.gaussianBlur()) }
                Button("Crystallize")    { setFilter(CIFilter.crystallize()) }
                Button("Sepia Tone")     { setFilter(CIFilter.sepiaTone()) }
                Button("Vignette")       { setFilter(CIFilter.vignette()) }
                Button("Edges")          { setFilter(CIFilter.edges()) }
                Button("Unsharp Mask")   { setFilter(CIFilter.unsharpMask()) }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareItem {
                    ActivityView(activityItems: [shareItem])
                }
            }
        }
    }

    // MARK: - Helpers

    private func setFilter(_ f: CIFilter) {
        currentFilter = f
        if let img = photoImage {
            processedImage = applyFilter(to: img, intensity: expressionIntensity)
        }
    }

    private func loadPhoto() async {
        guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }
        photoImage = ui
        processedImage = nil
    }

    private func applyFilter(to image: UIImage, intensity: CGFloat) -> UIImage {
        guard let ciIn = CIImage(image: image) else { return image }

        currentFilter.setValue(ciIn, forKey: kCIInputImageKey)

        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(intensity, forKey: kCIInputIntensityKey) // 0...1
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(intensity * 25.0 + 2.0, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(intensity * 40.0 + 4.0, forKey: kCIInputScaleKey)
        }

        if let vignette = currentFilter as? CIVignette {
            vignette.intensity = Float(intensity * 2.0)
            vignette.radius = Float(10.0 + intensity * 60.0)
        }

        guard let out = currentFilter.outputImage,
              let cg = context.createCGImage(out, from: out.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - UI Helpers

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) { }
}

struct CaptureButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 48))
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capture AR snapshot")
    }
}
