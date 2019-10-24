//
//  RangeSlider.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/24.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import Foundation
import UIKit

final class RangeSlider: UIControl {

    // MARK: - initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    // MARK: - open properties

    /// Set data source as Int array e.g) [0, 500, 1000, 2000, 3000, 4000]
    var dataSource: [Int] = [] {
        didSet {
            maxValue = (step.i * (dataSource.count - 1)).cgf
            selectedMaxValue = maxValue
            selectedIndex = (lower: 0, higher: dataSource.lastIndex)
        }
    }

    /// Set track tint color between thumbs. Default is red.
    var colorBetweenThumbs: UIColor = .red

    /// Set track tint color. Default is dark gray.
    var trackColor: UIColor = .darkGray

    /// You can get selected Prices from this tuple.
    private(set) var selectedPrice: (lower: Int, higher: Int) = (0, 0)

    // MARK: - properties for TicsLayer, dont set any value to these

    /// The minimum possible value to select in the range
    var minValue: CGFloat = 0.0 {
        didSet {
            refresh()
        }
    }

    /// The maximum possible value to select in the range
    var maxValue: CGFloat = 100.0 {
        didSet {
            refresh()
        }
    }

    /// The preselected minumum value
    /// (note: This should be less than the selectedMaxValue)
    var selectedMinValue: CGFloat = 0.0 {
        didSet {
            if selectedMinValue < minValue {
                selectedMinValue = minValue
            }
            let minSelectedIndex = (selectedMinValue.i / 20)
            guard minSelectedIndex >= 0 else { return }
            selectedIndex.lower = minSelectedIndex
        }
    }

    /// The preselected maximum value
    /// (note: This should be greater than the selectedMinValue)
    var selectedMaxValue: CGFloat = 100.0 {
        didSet {
            if selectedMaxValue > maxValue {
                selectedMaxValue = maxValue
            }
            let maxSelectedIndex = (selectedMaxValue.i / 20)
            guard maxSelectedIndex <= dataSource.lastIndex else { return }
            selectedIndex.higher = maxSelectedIndex
        }
    }

    // MARK: - private properties

    private enum ThumbTracking { case none, left, right }
    private var thumbTracking: ThumbTracking = .none

    private var step: CGFloat = 20 // This control the value of each step. This value is always fixed to 20.0
    private var thumbDiameter: CGFloat = 25.0

    private let track: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.darkGray.cgColor
        return layer
    }()

    private let trackBetweenThumbs: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.red.cgColor
        return layer
    }()

    private let ticksLayer: TicksLayer = {
        let layer = TicksLayer()
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()

    private let leftThumb: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
        layer.borderWidth = 0.1
        return layer
    }()
    private let rightThumb: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
        layer.borderWidth = 0.1
        return layer
    }()

    // UIFeedbackGenerator
    private var previousStepMinValue: CGFloat?
    private var previousStepMaxValue: CGFloat?

    private let feedbackGenerator: UISelectionFeedbackGenerator = {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        return generator
    }()


    // other
    private var selectedIndex: (lower: Int, higher: Int) = (0, 0) {
        didSet {
            guard !dataSource.isEmpty else { return }
            selectedPrice = (lower: dataSource[selectedIndex.lower],
                             higher: dataSource[selectedIndex.higher])
        }
    }

    /// The minimum distance the two selected slider values must be apart. Default is 0.
    private var minDistance: CGFloat = 0.0 {
        didSet {
            if minDistance < 0.0 {
                minDistance = 0.0
            }
        }
    }

    /// The maximum distance the two selected slider values must be apart. Default is CGFloat.greatestFiniteMagnitude.
    private var maxDistance: CGFloat = .greatestFiniteMagnitude {
        didSet {
            if maxDistance < 0.0 {
                maxDistance = .greatestFiniteMagnitude
            }
        }
    }

    /// Set the track height (default 1.0)
    private var lineHeight: CGFloat = 2.0 {
        didSet {
            updateLineHeight()
        }
    }

    // MARK: - UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        if thumbTracking == .none {
            updateLineHeight()
            updateColors()
            updateThumbPositions()
            updateTicks()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 65.0)
    }


    // MARK: - UIControl

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation: CGPoint = touch.location(in: self)
        let insetExpansion: CGFloat = -30.0
        let isTouchingLeftThumb: Bool = leftThumb.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightThumb: Bool = rightThumb.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)

        guard isTouchingLeftThumb || isTouchingRightThumb else { return false }


        // the touch was inside one of the thumbs so we're definitely going to start movign one of them. But the thumbs might be quite close to each other, so now we need to find out which thumb the touch was closest too, and activate that one.
        let distanceFromLeftThumb: CGFloat = touchLocation.distance(to: leftThumb.frame.center)
        let distanceFromRightThumb: CGFloat = touchLocation.distance(to: rightThumb.frame.center)

        if distanceFromLeftThumb < distanceFromRightThumb {
            thumbTracking = .left
        } else if selectedMaxValue == maxValue && leftThumb.frame.midX == rightThumb.frame.midX {
            thumbTracking = .left
        } else {
            thumbTracking = .right
        }

        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard thumbTracking != .none else { return false }

        let location: CGPoint = touch.location(in: self)

        // find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the thumb, not the left hand side)
        let percentage: CGFloat = (location.x - track.frame.minX - thumbDiameter / 2.0) / (track.frame.maxX - track.frame.minX)

        // multiply that percentage by self.maxValue to get the new selected minimum value
        let selectedValue: CGFloat = percentage * (maxValue - minValue) + minValue

        switch thumbTracking {
        case .left:
            selectedMinValue = min(selectedValue, selectedMaxValue)
        case .right:
            // don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            if selectedValue >= minValue {
                selectedMaxValue = selectedValue
            } else {
                selectedMaxValue = max(selectedValue, selectedMinValue)
            }
        case .none:
            // no need to refresh the view because it is done as a side-effect of setting the property
            break
        }

        refresh()

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        thumbTracking = .none
    }

    // MARK: - private methods

    private func setup() {
        // draw the track
        layer.addSublayer(track)

        // draw the track distline
        layer.addSublayer(trackBetweenThumbs)

        // draw the ticks
        layer.addSublayer(ticksLayer)
        ticksLayer.rangeSlider = self

        // draw the minimum thumb
        leftThumb.cornerRadius = thumbDiameter / 2.0
        layer.addSublayer(leftThumb)

        // draw the maximum thumb
        rightThumb.cornerRadius = thumbDiameter / 2.0
        layer.addSublayer(rightThumb)

        let thumbFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: thumbDiameter, height: thumbDiameter)
        leftThumb.frame = thumbFrame
        rightThumb.frame = thumbFrame

        refresh()
    }

    private func percentageAlongLine(for value: CGFloat) -> CGFloat {
        // stops divide by zero errors where maxMinDif would be zero. If the min and max are the same the percentage has no point.
        guard minValue < maxValue else { return 0.0 }

        // get the difference between the maximum and minimum values (e.g if max was 100, and min was 50, difference is 50)
        let maxMinDif: CGFloat = maxValue - minValue

        // now subtract value from the minValue (e.g if value is 75, then 75-50 = 25)
        let valueSubtracted: CGFloat = value - minValue

        // now divide valueSubtracted by maxMinDif to get the percentage (e.g 25/50 = 0.5)
        return valueSubtracted / maxMinDif
    }

    private func xPositionAlongLine(for value: CGFloat) -> CGFloat {
        // first get the percentage along the line for the value
        let percentage: CGFloat = percentageAlongLine(for: value)

        // get the difference between the maximum and minimum coordinate position x values (e.g if max was x = 310, and min was x=10, difference is 300)
        let maxMinDif: CGFloat = track.frame.maxX - track.frame.minX

        // now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
        let offset: CGFloat = percentage * maxMinDif

        return track.frame.minX + offset
    }

    private func updateLineHeight() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle: CGFloat = (frame.height / 2.0) - (lineHeight / 2)
        let lineLeftSide: CGPoint = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide: CGPoint = CGPoint(x: frame.width - barSidePadding,
                                             y: yMiddle)
        track.frame = CGRect(x: lineLeftSide.x,
                                  y: lineLeftSide.y,
                                  width: lineRightSide.x - lineLeftSide.x,
                                  height: lineHeight)
        track.cornerRadius = lineHeight / 2.0
        trackBetweenThumbs.cornerRadius = track.cornerRadius
    }

    private func updateTicks() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle: CGFloat = (frame.height / 2.0) - (lineHeight / 2)
        let lineLeftSide: CGPoint = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide: CGPoint = CGPoint(x: frame.width - barSidePadding,
                                             y: yMiddle)
        ticksLayer.frame = CGRect(x: lineLeftSide.x,
                            y: bounds.maxY / 3,
                            width: lineRightSide.x - lineLeftSide.x,
                            height: bounds.height / 3)
        ticksLayer.setNeedsDisplay()

    }

    private func updateColors() {
        track.backgroundColor = trackColor.cgColor
        trackBetweenThumbs.backgroundColor = colorBetweenThumbs.cgColor
    }

    private func updateThumbPositions() {
        leftThumb.position = CGPoint(x: xPositionAlongLine(for: selectedMinValue),
                                      y: track.frame.midY)

        rightThumb.position = CGPoint(x: xPositionAlongLine(for: selectedMaxValue),
                                       y: track.frame.midY)

        // positioning for the dist track
        trackBetweenThumbs.frame = CGRect(x: leftThumb.position.x,
                                                y: track.frame.minY,
                                                width: rightThumb.position.x - leftThumb.position.x,
                                                height: lineHeight)
    }

    private func refresh() {
        // thumb's step(jump) feature ------------------>
        selectedMinValue = CGFloat(roundf(Float(selectedMinValue / step))) * step
        if let previousStepMinValue = previousStepMinValue, previousStepMinValue != selectedMinValue {
            hapticFeedback()
        }
        previousStepMinValue = selectedMinValue

        selectedMaxValue = CGFloat(roundf(Float(selectedMaxValue / step))) * step
        if let previousStepMaxValue = previousStepMaxValue, previousStepMaxValue != selectedMaxValue {
            hapticFeedback()
        }
        previousStepMaxValue = selectedMaxValue
        // <------------------

        let diff: CGFloat = selectedMaxValue - selectedMinValue

        if diff < minDistance {
            switch thumbTracking {
            case .left:
                selectedMinValue = selectedMaxValue - minDistance
            case .right:
                selectedMaxValue = selectedMinValue + minDistance
            case .none:
                break
            }
        } else if diff > maxDistance {
            switch thumbTracking {
            case .left:
                selectedMinValue = selectedMaxValue - maxDistance
            case .right:
                selectedMaxValue = selectedMinValue + maxDistance
            case .none:
                break
            }
        }

        // ensure the minimum and maximum selected values are within range. Access the values directly so we don't cause this refresh method to be called again (otherwise changing the properties causes a refresh)
        if selectedMinValue < minValue {
            selectedMinValue = minValue
        }
        if selectedMaxValue > maxValue {
            selectedMaxValue = maxValue
        }

        // update the frames in a transaction so that the tracking doesn't continue until the frame has moved.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateThumbPositions()
        updateTicks()
        CATransaction.commit()

        updateColors()

        // send the event notification
        guard thumbTracking != .none else { return }
        sendActions(for: .valueChanged)
    }

    private func hapticFeedback() {
        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
    }
}


// MARK: - Extensions

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        let distX: CGFloat = to.x - x
        let distY: CGFloat = to.y - y
        return sqrt(distX * distX + distY * distY)
    }
}

extension Array where Element == Int {
    var lastIndex: Int {
        return self.count - 1
    }
}

extension Int {
    var cgf: CGFloat {
        return CGFloat(self)
    }
}

extension CGFloat {
    var f: Float {
        return Float(self)
    }

    var i: Int {
        return Int(self)
    }
}
