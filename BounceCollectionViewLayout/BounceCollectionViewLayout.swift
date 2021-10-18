//
//  BounceCollectionViewLayout.swift
//  BounceCollectionViewLayout
//
//  Created by Ben Deckys on 2021/10/18.
//

import UIKit

@IBDesignable
final class BounceCollectionViewLayout: UICollectionViewFlowLayout {

    private var dynamicAnimator: UIDynamicAnimator!
    private var visibleIndexPaths: Set<IndexPath> = []
    private var latestDelta: CGFloat = 0
    private var resistanceFactor: CGFloat = 1500

    // MARK: - Initialization
    override init() {
        super.init()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
    }

    // MARK: - Lifecycle
    deinit {
        dynamicAnimator.removeAllBehaviors()
        visibleIndexPaths.removeAll()
    }

    // MARK: - Private
    private var visibleRect: CGRect {
        guard let collectionView = collectionView else { return .zero }

        return CGRect(
            x: collectionView.bounds.origin.x, // equivalent to contentOffset.x
            y: collectionView.bounds.origin.y, // equivalent to contentOffset.y
            width: collectionView.frame.size.width,
            height: collectionView.frame.size.height
        ).insetBy(dx: 0, dy: -200)
    }

    /// A "disused" behaviour exists within the dynamicAnimator, but not the visible rect's layoutAttributes array.
    private func removeDisusedBehaviours(from layoutAttributes: [UICollectionViewLayoutAttributes]) {
        let indexPaths = layoutAttributes.map { $0.indexPath }

        dynamicAnimator.behaviors
            .compactMap { $0 as? UIAttachmentBehavior }
            .filter {
                guard let layoutAttributes = $0.items.first as? UICollectionViewLayoutAttributes else { return false }
                return !indexPaths.contains(layoutAttributes.indexPath)
            }
            .forEach { object in
                dynamicAnimator.removeBehavior(object)
                visibleIndexPaths.remove((object.items.first as! UICollectionViewLayoutAttributes).indexPath)
            }
    }

    /// A "new" behaviour is contained within the layoutAttributes array, but not in the visibleIndexPaths.
    private func addNewBehaviours(for layoutAttributes: [UICollectionViewLayoutAttributes]) {
        guard let collectionView = collectionView else { return }

        let touchLocation = collectionView.panGestureRecognizer.location(in: collectionView)

        layoutAttributes
            .filter {
                !visibleIndexPaths.contains($0.indexPath)
            }
            .forEach { item in
                let center = item.center
                let behaviour = UIAttachmentBehavior(item: item, attachedToAnchor: center)
                behaviour.length = 0
                behaviour.damping = 0.5
                behaviour.frequency = 0.8
                behaviour.frictionTorque = 0.0

                if !touchLocation.equalTo(.zero) {
                    guard let item = behaviour.items.first as? UICollectionViewLayoutAttributes else { return }
                    let scrollResistance = computeScrollResistance(from: touchLocation, anchorPoint: behaviour.anchorPoint)
                    var center = item.center
                    center.y += latestDelta < 0 ? max(latestDelta, latestDelta * scrollResistance) : min(latestDelta, latestDelta * scrollResistance)
                    item.center = center
                }

                dynamicAnimator.addBehavior(behaviour)
                visibleIndexPaths.insert(item.indexPath)
            }
    }

    override func prepare() {
        super.prepare()
        guard let elementsInVisibleRect = super.layoutAttributesForElements(in: visibleRect) else { return }

        removeDisusedBehaviours(from: elementsInVisibleRect)
        addNewBehaviours(for: elementsInVisibleRect)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        dynamicAnimator.items(in: rect) as? [UICollectionViewLayoutAttributes]
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        dynamicAnimator.layoutAttributesForCell(at: indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return true }

        let delta = newBounds.origin.y - collectionView.bounds.origin.y
        let touchLocation = collectionView.panGestureRecognizer.location(in: collectionView)
        latestDelta = delta

        dynamicAnimator.behaviors
            .compactMap { $0 as? UIAttachmentBehavior }
            .forEach {
                guard let item = $0.items.first else { return }

                let scrollResistance = computeScrollResistance(from: touchLocation, anchorPoint: $0.anchorPoint)
                var center = item.center

                center.y += delta > 0 ? min(delta, delta * scrollResistance) : max(delta, delta * scrollResistance)
                item.center = center

                dynamicAnimator.updateItem(usingCurrentState: item)
            }

        return false
    }

    private func computeScrollResistance(from touchLocation: CGPoint, anchorPoint: CGPoint) -> CGFloat {
        let distanceFromTouchY: CGFloat = abs(touchLocation.y - anchorPoint.y)
        let distanceFromTouchX: CGFloat = abs(touchLocation.x - anchorPoint.x)
        return (distanceFromTouchX + distanceFromTouchY) / resistanceFactor
    }

}
