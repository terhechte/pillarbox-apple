//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AVFoundation

enum ItemQueueUpdate {
    case assets([any Assetable])
    case itemTransition(ItemTransition)
}

enum QueueAsset {
    case valid((any Assetable)?)
    case invalid
}

struct ItemQueue {
    static var initial: Self {
        .init(assets: [], itemTransition: .advance(to: nil))
    }

    let assets: [any Assetable]
    let itemTransition: ItemTransition

    init(assets: [any Assetable], itemTransition: ItemTransition) {
        self.assets = assets
        self.itemTransition = !assets.isEmpty ? itemTransition : .advance(to: nil)
    }

    func updated(with update: ItemQueueUpdate) -> Self {
        switch update {
        case let .assets(assets):
            return .init(assets: assets, itemTransition: itemTransition)
        case let .itemTransition(itemTransition):
            return .init(assets: assets, itemTransition: itemTransition)
        }
    }

    var currentIndex: ItemIndex {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                guard let index = assets.firstIndex(where: { $0.matches(item) }) else { return .invalid }
                return .valid(index)
            }
            else if !assets.isEmpty {
                return .valid(0)
            }
            else {
                return .valid(nil)
            }
        case let .stop(on: item):
            guard let index = assets.firstIndex(where: { $0.matches(item) }) else { return .invalid }
            return .valid(index)
        case .finish:
            return .valid(nil)
        }
    }

    var currentAsset: QueueAsset {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                guard let asset = assets.first(where: { $0.matches(item) }) else { return .invalid }
                return .valid(asset)
            }
            else {
                return .valid(assets.first)
            }
        case let .stop(on: asset):
            guard let item = assets.first(where: { $0.matches(asset) }) else { return .invalid }
            return .valid(item)
        case .finish:
            return .valid(nil)
        }
    }
}
