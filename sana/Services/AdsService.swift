//
//  AdsService.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import SwiftUI
import GoogleMobileAds

enum TestAdIDs {
    static let app =
        "ca-app-pub-3940256099942544~1458002511"

    static let banner =
        "ca-app-pub-3940256099942544/2435281174"

    static let interstitial =
        "ca-app-pub-3940256099942544/4411468910"
}

struct TestBanner: UIViewRepresentable {

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: AdSizeBanner)
        view.adUnitID = TestAdIDs.banner

        view.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first?.rootViewController

        view.load(Request())

        return view
    }

    func updateUIView(
        _ uiView: BannerView,
        context: Context
    ) {}
}

@MainActor
final class InterstitialService:
    NSObject, ObservableObject, FullScreenContentDelegate {

    private var ad: InterstitialAd?

    @Published var ready = false

    func load() async {
        do {
            let loaded = try await InterstitialAd.load(
                with: TestAdIDs.interstitial,
                request: Request()
            )

            loaded.fullScreenContentDelegate = self
            ad = loaded
            ready = true

        } catch {
            ready = false
        }
    }

    func show() {
        guard let ad else { return }

        guard let controller = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            return
        }

        ad.present(from: controller)

        ready = false
        self.ad = nil
    }

    nonisolated func adDidDismissFullScreenContent(
        _ ad: FullScreenPresentingAd
    ) {
        Task { @MainActor in
            await self.load()
        }
    }
}
