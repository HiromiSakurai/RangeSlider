//
//  TicksLayer.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/23.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import Foundation
import UIKit

final class TicksLayer: CALayer {
    weak var rangeSlider: RangeSlider?

    private let tickWidth: CGFloat = 3

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }

        let ticksCount: Int = slider.dataSource.count
        let stepCount: Int = ticksCount - 1
        let stepDistance: CGFloat = bounds.width / stepCount.cgf

        var ticks = [CGRect]()

        // Create data where tick is drawn
        for i in 0...stepCount {
            var xPos = i.cgf * stepDistance
            if i == stepCount {
                xPos = xPos - tickWidth // make last tick visible
            }
            let tick = CGRect(x: xPos, y: 0, width: tickWidth, height: bounds.height)
            ticks.append(tick)
        }

        // Draw ticks
        for (index, tickRect) in ticks.enumerated() {
            let path = UIBezierPath(rect: tickRect)
            ctx.addPath(path.cgPath)

            let tickValue: Float = Float((slider.maxValue.i / stepCount) * index)

            let color: CGColor

            if slider.selectedMinValue.f <= tickValue && tickValue <= slider.selectedMaxValue.f {
                color = slider.colorBetweenHandles.cgColor
            }  else {
                color = slider.sliderColor.cgColor
            }

            ctx.setFillColor(color)
            ctx.fillPath()
        }
    }
}
