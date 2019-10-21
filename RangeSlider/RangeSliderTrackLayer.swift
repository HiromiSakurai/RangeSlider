//
//  RangeSliderTrackLayer.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/21.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import UIKit

class RangeSliderTrackLayer: CALayer {
  weak var rangeSlider: RangeSlider?

  override func draw(in ctx: CGContext) {
    guard let slider = rangeSlider else {
      return
    }

    let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
    ctx.addPath(path.cgPath)

    ctx.setFillColor(slider.trackTintColor.cgColor)
    ctx.fillPath()

    ctx.setFillColor(slider.trackHighlightTintColor.cgColor)
    let lowerValuePosition = slider.positionForValue(slider.lowerValue)
    let upperValuePosition = slider.positionForValue(slider.upperValue)
    let rect = CGRect(x: lowerValuePosition, y: 0,
                      width: upperValuePosition - lowerValuePosition,
                      height: bounds.height)
    ctx.fill(rect)
  }
}

