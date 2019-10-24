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

    let priceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(rangeSlider)

        view.addSubview(priceLabel)
        priceLabel.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor, constant: 100).isActive = true
        priceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let margin: CGFloat = 20
        let width = view.bounds.width - 2 * margin
        let height: CGFloat = 30

        rangeSlider.frame = CGRect(x: 0, y: 0, width: width, height: height)
        rangeSlider.center = view.center
        //seekSlider.backgroundColor = .blue
        rangeSlider.colorBetweenThumbs = .cyan
        rangeSlider.sliderColor = .brown
        rangeSlider.dataSource = [0, 500, 1000, 2000, 4000, 6000, 8000, 10000]
    }

    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        //print("value changed --- min:\(rangeSlider.selectedMinValue) max:\(rangeSlider.selectedMaxValue)")
        priceLabel.text = "\(rangeSlider.selectedPrice.lower)$ ~ \(rangeSlider.selectedPrice.higher)$"
    }
}

