//
//  ViewController.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/21.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RangeSeekSliderDelegate {
    let seekSlider = RangeSeekSlider(frame: .zero)


    override func viewDidLoad() {
        super.viewDidLoad()
        seekSlider.delegate = self

        view.addSubview(seekSlider)
    }

    override func viewDidLayoutSubviews() {
        let margin: CGFloat = 20
        let width = view.bounds.width - 2 * margin
        let height: CGFloat = 30

        seekSlider.frame = CGRect(x: 0, y: 0, width: width, height: height)
        seekSlider.center = view.center
        seekSlider.backgroundColor = .yellow
        seekSlider.colorBetweenHandles = .green
        seekSlider.enableStep = true
        seekSlider.step = 20.0
    }

    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let values = "(\(rangeSlider.lowerValue) \(rangeSlider.upperValue))"
        print("Range slider value changed: \(values)")
    }

    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {
        //print("min: \(minValue), max: \(maxValue)")
    }
}

