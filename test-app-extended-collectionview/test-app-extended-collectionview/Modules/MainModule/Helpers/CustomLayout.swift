import UIKit

protocol CustomLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForCellAtIndexPath indexPath: IndexPath) -> CGFloat?
}

final class CustomLayout: UICollectionViewFlowLayout {

    private enum CalculationDirection {
        case sameRow(CGFloat, ColoredCell, Int)
        case sameColumn(CGFloat, ColoredCell, Int)
        case underItem(CGFloat, CGFloat, ColoredCell, Int, Int)
        case aboveItem(CGFloat, CGFloat, ColoredCell, Int, Int)

        var itemSize: CGSize {
            switch self {
            case let .sameRow(contentWidth, zoomedCell, colsCount):
                return CGSize(
                    width: (contentWidth - zoomedCell.frame.width) / CGFloat(colsCount - 1),
                    height: zoomedCell.frame.height
                )
            case let .sameColumn(contentHeight, zoomedCell, rowsCount):
                return CGSize(
                    width: zoomedCell.frame.width,
                    height: (contentHeight - zoomedCell.frame.height) / CGFloat(rowsCount - 1)
                )
            case let .aboveItem(contentWidth, contentHeight, zoomedCell, colsCount, rowsCount):
                return CGSize(
                    width: (contentWidth - zoomedCell.frame.width) / CGFloat(colsCount - 1),
                    height: (contentHeight - zoomedCell.frame.height) / CGFloat(rowsCount - 1)
                )
            case let .underItem(contentWidth, contentHeight, zoomedCell, colsCount, rowsCount):
                return CGSize(
                    width: (contentWidth - zoomedCell.frame.width) / CGFloat(colsCount - 1),
                    height: (contentHeight - zoomedCell.frame.height) / CGFloat(rowsCount - 1)
                )
            }
        }
    }

    weak var delegate: CustomLayoutDelegate?
    private var collectionViewSize: CollectionViewSize
    private let cellPadding: CGFloat = 0

    private var cellWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width / CGFloat(collectionViewSize.columnsCount)
    }

    private var itemsCache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    init(size: CollectionViewSize) {
        self.collectionViewSize = size
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView, itemsCache.isEmpty else { return }

        let cellWidth = contentWidth / CGFloat(collectionViewSize.columnsCount)
        var xOffset: [CGFloat] = []
        for column in 0..<collectionViewSize.columnsCount {
            xOffset.append(CGFloat(column) * cellWidth)
        }
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: collectionViewSize.columnsCount)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            // Ask delegate about cell height or use cellWidth
            let cellHeight = delegate?.collectionView(collectionView, heightForCellAtIndexPath: indexPath) ?? cellWidth
            let height = cellPadding * 2 + cellHeight
            let frame = CGRect(
                x: xOffset[column],
                y: yOffset[column],
                width: cellWidth,
                height: height
            )
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            itemsCache.append(attributes)

            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height

            column = column < (collectionViewSize.columnsCount - 1) ? (column + 1) : 0
        }
    }

    override func layoutAttributesForElements(in rect: CGRect)-> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)

        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []

        for attributes in itemsCache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath)
        return itemsCache[indexPath.item]
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        contentHeight = 0.0
        return true
    }
}

extension CustomLayout: CellMotionDelegate {

    func update(_ zoomableCell: ColoredCell, scale: CGFloat) {

        // TODO: find a mistake (that's for myself in future)
        // somewhere here there is a mistake in calculation of view's origin point
        // have no time to find out this mistake

        guard let origin = recalculateOriginPoint(for: zoomableCell) else { return }
        zoomableCell.frame.origin = origin

        itemsCache = itemsCache.map { attributes in
            let itemId = attributes.indexPath.item
            let cellId = (itemId / collectionViewSize.columnsCount, itemId % collectionViewSize.columnsCount)

            if let selectedViewCellId = zoomableCell.cellPosition, cellId != selectedViewCellId {
                if cellId.0 == selectedViewCellId.0 {
                    // for items in row, (cell.1 - 1) --- column number - 1
                    attributes.frame = cellId.1 < selectedViewCellId.1 ? CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1),
                            y: zoomableCell.frame.origin.y
                        ),
                        size: CalculationDirection.sameRow(contentWidth, zoomableCell, collectionViewSize.columnsCount).itemSize
                    ) : CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1 - 1) + zoomableCell.frame.width,
                            y: zoomableCell.frame.origin.y
                        ),
                        size: CalculationDirection.sameRow(contentWidth, zoomableCell, collectionViewSize.columnsCount).itemSize
                    )
                } else if cellId.1 == selectedViewCellId.1 {
                    // for items in column
                    attributes.frame = cellId.0 < selectedViewCellId.0 ? CGRect(
                        origin: CGPoint(
                            x: zoomableCell.frame.origin.x,
                            y: (attributes.frame.height) * CGFloat(cellId.0)
                        ),
                        size: CalculationDirection.sameColumn(contentHeight, zoomableCell, collectionViewSize.rowsCount).itemSize
                    ) : CGRect(
                        origin:  CGPoint(
                            x: zoomableCell.frame.origin.x,
                            y: (attributes.frame.height) * CGFloat(cellId.0 - 1) + zoomableCell.frame.height
                        ),
                        size: CalculationDirection.sameColumn(contentHeight, zoomableCell, collectionViewSize.rowsCount).itemSize
                    )
                } else if cellId.0 < selectedViewCellId.0 {
                    // for items that are higher then zoomed one
                    attributes.frame = cellId.1 < selectedViewCellId.1 ? CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1),
                            y: (attributes.frame.height) * CGFloat(cellId.0)
                        ),
                        size: CalculationDirection.aboveItem(contentWidth, contentHeight, zoomableCell, collectionViewSize.columnsCount, collectionViewSize.rowsCount).itemSize
                    ) : CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1 - 1) + zoomableCell.frame.width,
                            y: (attributes.frame.height) * CGFloat(cellId.0)
                        ),
                        size: CalculationDirection.aboveItem(contentWidth, contentHeight, zoomableCell, collectionViewSize.columnsCount, collectionViewSize.rowsCount).itemSize
                    )
                } else if cellId.0 > selectedViewCellId.0 {
                    // for items that are under zoomed one
                    attributes.frame = cellId.1 < selectedViewCellId.1 ? CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1),
                            y: (attributes.frame.height) * CGFloat(cellId.0 - 1) + zoomableCell.frame.height
                        ),
                        size: CalculationDirection.underItem(contentWidth, contentHeight, zoomableCell, collectionViewSize.columnsCount, collectionViewSize.rowsCount).itemSize
                    ) : CGRect(
                        origin: CGPoint(
                            x: (attributes.frame.width) * CGFloat(cellId.1 - 1) + zoomableCell.frame.width,
                            y: (attributes.frame.height) * CGFloat(cellId.0 - 1) + zoomableCell.frame.height
                        ),
                        size: CalculationDirection.underItem(contentWidth, contentHeight, zoomableCell, collectionViewSize.columnsCount, collectionViewSize.rowsCount).itemSize
                    )
                }
            } else {
                // change zoomed cell attributes here
                attributes.frame = zoomableCell.frame

            }
            return attributes
        }
        contentHeight = 0
        itemsCache.forEach { attribute in
            contentHeight = max(contentHeight, attribute.frame.maxY)
        }
        invalidateLayout()
    }

    private func recalculateOriginPoint(for zoomableCell: ColoredCell) -> CGPoint? {
        guard let cellPosition = zoomableCell.cellPosition else { return nil }

        let attributes = itemsCache.filter { attribute in
            let itemId = attribute.indexPath.item
            let cellId = (itemId / collectionViewSize.columnsCount, itemId % collectionViewSize.columnsCount)
            return cellId == cellPosition
        }
        guard let attribute = attributes.first else { return nil }

        let oldFrame = attribute.frame
        let newSize = zoomableCell.frame.size
        let deltaX = oldFrame.size.width - newSize.width
        let deltaY = oldFrame.size.height - newSize.height

        // Standard origin after scale
        attribute.frame.origin.x = oldFrame.origin.x + floor(deltaX / CGFloat(collectionViewSize.columnsCount - 1))
        attribute.frame.origin.y = oldFrame.origin.y + floor(deltaY / CGFloat(collectionViewSize.rowsCount - 1))

        // For left column keep origin.x
        if cellPosition.1 == 0 {
            attribute.frame.origin.x = oldFrame.origin.x
        } else if cellPosition.1 == (collectionViewSize.columnsCount - 1) {
            // For right column recalculate origin.x
            attribute.frame.origin.x = oldFrame.origin.x + floor(deltaX / CGFloat(collectionViewSize.columnsCount - 1))
        }
        // For top element keep origin.y
        if cellPosition.0 == 0 {
            attribute.frame.origin.y = oldFrame.origin.y
        } else if cellPosition.0 == (collectionViewSize.rowsCount - 1) {
            // For bottom element recalculate origin.y
            attribute.frame.origin.y = oldFrame.origin.y + floor(deltaY / CGFloat(collectionViewSize.rowsCount - 1))
        }
        return attribute.frame.origin
    }
}
