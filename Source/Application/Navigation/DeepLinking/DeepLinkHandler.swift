// 
// MIT License
//
// Copyright (c) 2018-2019 Open Zesame (https://github.com/OpenZesame)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit
import RxSwift
import RxCocoa

final class DeepLinkHandler {
    enum AnalyticsEvent: TrackableEvent {
        case handlingIncomingDeeplink
        case sourceOfDeepLink(sendingAppId: String)
        case failedToParseLink

        var eventName: String {
            switch self {
            case .handlingIncomingDeeplink: return "handlingIncomingDeeplink"
            case .sourceOfDeepLink(let sendingAppId): return "sourceOfDeepLink: \(sendingAppId)"
            case .failedToParseLink: return "failedToParseLink"
            }
        }
    }

    private let tracker: Tracker
    private let navigator: Navigator<DeepLink>

    /// This buffered link gets set when the app is locked with a PIN code
    private var bufferedLink: DeepLink?
    private var appIsLockedSoBufferLink = false

    init(tracker: Tracker = Tracker(), navigator: Navigator<DeepLink> = Navigator<DeepLink>()) {
        self.tracker = tracker
        self.navigator = navigator
    }

    func appIsLockedBufferDeeplinks() {
        appIsLockedSoBufferLink = true
    }
    func appIsUnlockedEmitBufferedDeeplinks() {
        defer { bufferedLink = nil }
        appIsLockedSoBufferLink = false
        guard let link = bufferedLink else { return }
        navigate(to: link)
    }
}

extension DeepLinkHandler {

    /// Read more: https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
    /// Handles incoming `url`, e.g. `Zhip://send?to=0x1a2b3c&amount=1337`
    ///
    /// return: `true` if the delegate successfully handled the request or `false` if the attempt to open the URL resource failed.
    func handle(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        track(event: .handlingIncomingDeeplink)

        if let sendingAppID = options[.sourceApplication] as? String {
            track(event: .sourceOfDeepLink(sendingAppId: sendingAppID))
        }

        guard let destination = DeepLink(url: url) else {
            track(event: .failedToParseLink)
            return false
        }

        navigate(to: destination)
        return true
    }

    var navigation: Driver<DeepLink> {
        return navigator.navigation.filter { [unowned self] _ in return !self.appIsLockedSoBufferLink }
    }

}

// MARK: Private
private extension DeepLinkHandler {
    func navigate(to destination: DeepLink) {
        if appIsLockedSoBufferLink {
            bufferedLink = destination
        } else {
            navigator.next(destination)
        }
    }

    func track(event: AnalyticsEvent) {
        tracker.track(event: event)
    }
}

