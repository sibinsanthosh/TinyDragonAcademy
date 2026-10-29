//
//  PhotoBoothView.swift
//  Tiny Dragon Academy
//
//  Pose your dragon on a postcard, then save it to Photos or (with a
//  grown-up's OK) share it.
//

import SwiftUI
import Photos

struct PhotoBoothView: View {
    @EnvironmentObject var gameManager: GameManager

    @State private var frame: PostcardFrame = .classic
    @State private var pose: PostcardPose = .happy
    @State private var useIsland = false
    @State private var showParentGate = false
    @State private var shareImage: ShareableImage?
    @State private var message: String?

    private var dragon: DragonModel { gameManager.activeDragon }

    private var postcard: PostcardView {
        PostcardView(dragon: dragon, frame: frame, pose: pose,
                     islandBackground: useIsland ? gameManager.state.island.theme.backgroundGradient : nil)
    }

    var body: some View {
        ZStack {
            ClayBackdrop()

            VStack(spacing: 12) {
                ZStack {
                    Text("Photo booth")
                        .font(.clay(24, .heavy))
                        .foregroundColor(ClayColor.ink)
                    HStack {
                        ClayIconButton(systemName: "xmark", accessibilityLabel: "Close") {
                            gameManager.navigate(to: .mainMenu)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                GeometryReader { geo in
                    let scale = min(geo.size.width / PostcardView.size.width, geo.size.height / PostcardView.size.height)
                    postcard
                        .scaleEffect(scale)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .shadow(color: ClayColor.shadow, radius: 16, y: 8)
                }
                .padding(.horizontal, 24)

                ClaySegmented(options: PostcardFrame.allCases, selection: $frame) { $0.title }
                    .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    ForEach(PostcardPose.allCases) { option in
                        poseButton(option)
                    }
                    choiceButton("Island", icon: "leaf.fill", isOn: useIsland, color: ClayColor.mintShade) {
                        useIsland.toggle()
                    }
                    .accessibilityLabel("Island background")
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Button {
                        HapticsService.shared.medium()
                        showParentGate = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.clay(18, .heavy))
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 22))
                    KidButton(title: "Save", icon: "square.and.arrow.down", backgroundColor: ClayColor.accent,
                              minWidth: 0, minHeight: 54, fontSize: 18) {
                        saveToPhotos()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            if let message {
                Text(message)
                    .font(.clay(16, .heavy))
                    .foregroundColor(ClayColor.ink)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .claySurface(cornerRadius: 24, elevation: 1.3)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if showParentGate {
                ParentGateView(
                    onSuccess: {
                        showParentGate = false
                        if let image = render() { shareImage = ShareableImage(image: image) }
                    },
                    onCancel: { showParentGate = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: message)
        .sheet(item: $shareImage) { ActivityView(items: [$0.image]) }
    }

    private func poseButton(_ option: PostcardPose) -> some View {
        choiceButton(option.title, icon: option.iconName, isOn: option == pose, color: ClayColor.accent) {
            pose = option
        }
    }

    private func choiceButton(_ title: String, icon: String, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.light()
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                Text(title).font(.clay(11, .heavy))
            }
            .foregroundColor(isOn ? .white : ClayColor.ink)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isOn ? color : Color.white))
            .shadow(color: ClayColor.shadow, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// The postcard at 3× scale: 1080×1350 pixels.
    @MainActor
    private func render() -> UIImage? {
        let renderer = ImageRenderer(content: postcard.environmentObject(gameManager))
        renderer.scale = 3
        return renderer.uiImage
    }

    private func saveToPhotos() {
        guard let image = render() else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in show("Allow Photos in Settings to save postcards") }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                Task { @MainActor in show(success ? "Saved to Photos" : "Couldn't save. Try again.") }
            }
        }
    }

    private func show(_ text: String) {
        message = text
        HapticsService.shared.success()
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if message == text { message = nil }
        }
    }
}

struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// The system share sheet.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
