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

    private let tickWidth: CGFloat = 3

    private var stepDistance: CGFloat {
        return bounds.width / (ticksCount-1).cgf
    }

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }

        var ticks = [CGRect]()

        for i in 0...ticksCount - 1 {
            var xPos = i.cgf * stepDistance
            if i == (ticksCount - 1) {
                xPos = xPos - tickWidth // make last tick visible
            }
            let tick = CGRect(x: xPos, y: 0, width: tickWidth, height: bounds.height)
            ticks.append(tick)
        }

        for (index, tickRect) in ticks.enumerated() {
            let path = UIBezierPath(rect: tickRect)
            ctx.addPath(path.cgPath)

            let tickValue: Float = Float((slider.maxValue.i/(ticksCount-1))*index)

            var color: CGColor

            //print("tickValue: \(tickValue), min: \(slider.selectedMinValue), max: \(slider.selectedMaxValue), index:\(index)")
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
