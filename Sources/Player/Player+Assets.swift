//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

extension Player {
    func assetsPublisher() -> AnyPublisher<[any Assetable], Never> {
        playerItemQueuePublisher
            .slice(at: \.items)
            .map { items in
                Publishers.AccumulateLatestMany(items.map { item in
                    item.$asset
                })
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
