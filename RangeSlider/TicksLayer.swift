//
//  TicksLayer.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/23.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import Foundation
import UIKit

class TicksLayer: CALayer {
    weak var rangeSlider: RangeSeekSlider?

    var ticksCount: Int!
    var selectedValue: (CGFloat, CGFloat)!

    var stepDistance: Int {
        return Int(bounds.width) / (ticksCount-1)
    }

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }

        var ticks = [CGRect]()

        for i in 0...ticksCount - 1 {
            let xPos = i == ticksCount ? i*stepDistance - 3 : i*stepDistance
            let tick = CGRect(x: xPos.cgflo, y: 0, width: 3, height: bounds.height)
            ticks.append(tick)
        }

        for (index, tickRect) in ticks.enumerated() {
            let path = UIBezierPath(rect: tickRect)
            ctx.addPath(path.cgPath)

            var color: CGColor

            let tickValue: Float = Float((100/(ticksCount-1))*index)

            //print("tickValue: \(tickValue), min: \(selectedValue.0), max: \(selectedValue.1), index:\(index)")
            if slider.selectedMinValue.f <= tickValue && tickValue <= slider.selectedMaxValue.f {
                color = UIColor.green.cgColor
            }  else {
                color = UIColor.blue.cgColor
            }

            ctx.setFillColor(color)
            ctx.fillPath()
        }

    }
}

extension Int {
    var cgflo: CGFloat {
        return CGFloat(self)
    }
}

extension CGFloat {
    var f: Float {
        return Float(self)
    }
}
