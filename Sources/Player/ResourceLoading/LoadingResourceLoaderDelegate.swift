//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AVFoundation

final class LoadingResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let id: UUID

    init(id: UUID) {
        self.id = id
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        PlayerItem.trigger.activate(for: id)
        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest
    ) -> Bool {
        true
    }
}
