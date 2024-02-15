//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CoreCollector
import AVFoundationCollector
import PillarboxPlayer

class BitmovinTracker: PlayerItemTracker {
    private let analyticsCollector: AVPlayerCollectorApi

    required init(configuration: Void) {
        analyticsCollector = AVPlayerCollectorFactory.create(config: .init(licenseKey: "my-license"))
    }
    
    func enable(for player: Player) {
        analyticsCollector.attach(to: player.systemPlayer)
    }
    
    func updateMetadata(with metadata: Void) {}
    
    func updateProperties(with properties: PlayerProperties) {}
    
    func disable() {
        analyticsCollector.detach()
    }
}
