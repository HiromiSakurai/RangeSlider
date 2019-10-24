//
//  TicksLayer.swift
//  RangeSlider
//
//  Created by 櫻井寛海 on 2019/10/23.
//  Copyright © 2019 hiromi-sakurai. All rights reserved.
//

import UIKit

final class RangeSeekSlider: UIControl {

    // MARK: - initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    // MARK: - open stored properties

    var dataSource: [Int] = [] {
        didSet {
            maxValue = (20 * (dataSource.count - 1)).cgf
            selectedMaxValue = maxValue
            selectedIndex = (lower: 0, higher: dataSource.lastIndex)
        }
    }

    private(set) var selectedPrice: (lower: Int, higher: Int) = (0, 0)

    weak var delegate: RangeSeekSliderDelegate?

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

    /// Handle slider with custom color, you can set custom color for your handle
    var handleColor: UIColor?

    /// Set slider line tint color between handles
    var colorBetweenHandles: UIColor?

    /// The color of the entire slider when the handle is set to the minimum value and the maximum value. Default is nil.
    var initialColor: UIColor?

    /// If true the control will snap to point at each step between minValue and maxValue. Default is false.
    private var enableStep: Bool = true

    /// The step value, this control the value of each step. If not set the default is 0.0.
    /// (note: this is ignored if <= 0.0)
    var step: CGFloat = 20

    /// Handle slider with custom image, you can set custom image for your handle
    var handleImage: UIImage? {
        didSet {
            guard let image = handleImage else {
                return
            }
            
            var handleFrame = CGRect.zero
            handleFrame.size = image.size
            
            leftHandle.frame = handleFrame
            leftHandle.contents = image.cgImage

            rightHandle.frame = handleFrame
            rightHandle.contents = image.cgImage
        }
    }

    /// Handle diameter (default 16.0)
    var handleDiameter: CGFloat = 20.0 {
        didSet {
            leftHandle.cornerRadius = handleDiameter / 2.0
            rightHandle.cornerRadius = handleDiameter / 2.0
            leftHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
            rightHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        }
    }

    /// Set the slider line height (default 1.0)
    var lineHeight: CGFloat = 2.0 {
        didSet {
            updateLineHeight()
        }
    }

    /// Handle border width (default 0.0)
    var handleBorderWidth: CGFloat = 0.0 {
        didSet {
            leftHandle.borderWidth = handleBorderWidth
            rightHandle.borderWidth = handleBorderWidth
        }
    }

    // MARK: - private stored properties

    private enum HandleTracking { case none, left, right }
    private var handleTracking: HandleTracking = .none

    private let sliderLine: CALayer = CALayer()
    private let sliderLineBetweenHandles: CALayer = CALayer()

    private let ticksLayer: TicksLayer = TicksLayer()

    private let leftHandle: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1
        return layer
    }()
    private let rightHandle: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1
        return layer
    }()

    // UIFeedbackGenerator
    private var previousStepMinValue: CGFloat?
    private var previousStepMaxValue: CGFloat?

    private var selectedIndex: (lower: Int, higher: Int) = (0, 0) {
        didSet {
            guard !dataSource.isEmpty else { return }
            selectedPrice = (lower: dataSource[selectedIndex.lower],
                             higher: dataSource[selectedIndex.higher])
        }
    }

    // MARK: - UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        if handleTracking == .none {
            updateLineHeight()
            updateColors()
            updateHandlePositions()
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
        let isTouchingLeftHandle: Bool = leftHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightHandle: Bool = rightHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)

        guard isTouchingLeftHandle || isTouchingRightHandle else { return false }


        // the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.
        let distanceFromLeftHandle: CGFloat = touchLocation.distance(to: leftHandle.frame.center)
        let distanceFromRightHandle: CGFloat = touchLocation.distance(to: rightHandle.frame.center)

        if distanceFromLeftHandle < distanceFromRightHandle {//} && !disableRange {
            handleTracking = .left
        } else if selectedMaxValue == maxValue && leftHandle.frame.midX == rightHandle.frame.midX {
            handleTracking = .left
        } else {
            handleTracking = .right
        }

        delegate?.didStartTouches(in: self)

        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard handleTracking != .none else { return false }

        let location: CGPoint = touch.location(in: self)

        // find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
        let percentage: CGFloat = (location.x - sliderLine.frame.minX - handleDiameter / 2.0) / (sliderLine.frame.maxX - sliderLine.frame.minX)

        // multiply that percentage by self.maxValue to get the new selected minimum value
        let selectedValue: CGFloat = percentage * (maxValue - minValue) + minValue

        switch handleTracking {
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
        handleTracking = .none

        delegate?.didEndTouches(in: self)
    }

    // MARK: - private methods

    private func setup() {
        // draw the slider line
        layer.addSublayer(sliderLine)

        // draw the track distline
        layer.addSublayer(sliderLineBetweenHandles)

        // draw the ticks
        layer.addSublayer(ticksLayer)
        ticksLayer.rangeSlider = self

        // draw the minimum slider handle
        leftHandle.cornerRadius = handleDiameter / 2.0
        leftHandle.borderWidth = handleBorderWidth
        layer.addSublayer(leftHandle)

        // draw the maximum slider handle
        rightHandle.cornerRadius = handleDiameter / 2.0
        rightHandle.borderWidth = handleBorderWidth
        layer.addSublayer(rightHandle)

        let handleFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        leftHandle.frame = handleFrame
        rightHandle.frame = handleFrame

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
        let maxMinDif: CGFloat = sliderLine.frame.maxX - sliderLine.frame.minX

        // now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
        let offset: CGFloat = percentage * maxMinDif

        return sliderLine.frame.minX + offset
    }

    private func updateLineHeight() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle: CGFloat = (frame.height / 2.0) - (lineHeight / 2)
        let lineLeftSide: CGPoint = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide: CGPoint = CGPoint(x: frame.width - barSidePadding,
                                             y: yMiddle)
        sliderLine.frame = CGRect(x: lineLeftSide.x,
                                  y: lineLeftSide.y,
                                  width: lineRightSide.x - lineLeftSide.x,
                                  height: lineHeight)
        sliderLine.cornerRadius = lineHeight / 2.0
        sliderLineBetweenHandles.cornerRadius = sliderLine.cornerRadius
    }

    private func updateTicks() {
        ticksLayer.ticksCount = dataSource.count

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
        let isInitial: Bool = selectedMinValue == minValue && selectedMaxValue == maxValue
        if let initialColor = initialColor?.cgColor, isInitial {
            sliderLineBetweenHandles.backgroundColor = initialColor
            sliderLine.backgroundColor = initialColor
        } else {
            let tintCGColor: CGColor = tintColor.cgColor
            sliderLineBetweenHandles.backgroundColor = colorBetweenHandles?.cgColor ?? tintCGColor
            sliderLine.backgroundColor = tintCGColor
        }
    }

    private func updateHandlePositions() {
        leftHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMinValue),
                                      y: sliderLine.frame.midY)

        rightHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMaxValue),
                                       y: sliderLine.frame.midY)

        // positioning for the dist slider line
        sliderLineBetweenHandles.frame = CGRect(x: leftHandle.position.x,
                                                y: sliderLine.frame.minY,
                                                width: rightHandle.position.x - leftHandle.position.x,
                                                height: lineHeight)
    }
    
    // MARK: - refresh()
    private func refresh() {
        if enableStep && step > 0.0 {
            selectedMinValue = CGFloat(roundf(Float(selectedMinValue / step))) * step
            if let previousStepMinValue = previousStepMinValue, previousStepMinValue != selectedMinValue {
                TapticEngine.selection.feedback()
            }
            previousStepMinValue = selectedMinValue

            selectedMaxValue = CGFloat(roundf(Float(selectedMaxValue / step))) * step
            if let previousStepMaxValue = previousStepMaxValue, previousStepMaxValue != selectedMaxValue {
                TapticEngine.selection.feedback()
            }
            previousStepMaxValue = selectedMaxValue
        }

        let diff: CGFloat = selectedMaxValue - selectedMinValue

        if diff < minDistance {
            switch handleTracking {
            case .left:
                selectedMinValue = selectedMaxValue - minDistance
            case .right:
                selectedMaxValue = selectedMinValue + minDistance
            case .none:
                break
            }
        } else if diff > maxDistance {
            switch handleTracking {
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
        updateHandlePositions()
        updateTicks()
        CATransaction.commit()

        updateColors()

        // update the delegate
        if let delegate = delegate, handleTracking != .none {
            //delegate.rangeSeekSlider(self, didChange: selectedMinValue, maxValue: selectedMaxValue)
            sendActions(for: .valueChanged)
        }
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
