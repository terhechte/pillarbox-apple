//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AVFoundation
import Combine

extension Player {
    struct AssetUpdate {
        static var empty: Self {
            .init(assets: [], currentItem: nil)
        }

        let assets: [any Assetable]
        let currentItem: AVPlayerItem?
    }
}

extension Player {
    func assetUpdatePublisher() -> AnyPublisher<AssetUpdate, Never> {
        itemUpdatePublisher
            .map { update in
                Publishers.AccumulateLatestMany(update.items.map { item in
                    item.$asset
                })
                .map { AssetUpdate(assets: $0, currentItem: update.currentItem) }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
