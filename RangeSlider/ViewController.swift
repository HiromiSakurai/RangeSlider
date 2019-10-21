//
//  ViewController.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/21.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let rangeSlider = RangeSlider(frame: .zero)
    let slider = UISlider()


    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(slider)
        view.addSubview(rangeSlider)
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)),
                              for: .valueChanged)
//        let time = DispatchTime.now() + 1
//        DispatchQueue.main.asyncAfter(deadline: time) {
//            self.rangeSlider.trackHighlightTintColor = .red
//            self.rangeSlider.thumbImage = #imageLiteral(resourceName: "RectThumb")
//            self.rangeSlider.highlightedThumbImage = #imageLiteral(resourceName: "HighlightedRect")
//        }
    }

    override func viewDidLayoutSubviews() {
        let margin: CGFloat = 20
        let width = view.bounds.width - 2 * margin
        let height: CGFloat = 30

        rangeSlider.frame = CGRect(x: 0, y: 0, width: width, height: height)
        rangeSlider.center = view.center

        slider.frame = CGRect(x: 0, y: 0, width: width, height: height)
        slider.center = CGPoint(x: rangeSlider.center.x, y: rangeSlider.center.y + 100)
    }

    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let values = "(\(rangeSlider.lowerValue) \(rangeSlider.upperValue))"
        print("Range slider value changed: \(values)")
    }
}

