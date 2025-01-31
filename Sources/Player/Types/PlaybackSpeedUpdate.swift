//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum PlaybackSpeedUpdate: Equatable {
    case value(Float)
    case range(ClosedRange<Float>?)
}
