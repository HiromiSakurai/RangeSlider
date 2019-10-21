import Foundation
import UIKit

@objc public protocol TGPControlsTicksProtocol
{
    func tgpTicksDistanceChanged(ticksDistance:CGFloat, sender:AnyObject)
    func tgpValueChanged(value:UInt)
}
