import UIKit
import SnapKit

protocol CellMotionDelegate: AnyObject {
    func update(_ zoomableCell: ColoredCell, scale: CGFloat)
}

final class ColoredCell: UICollectionViewCell {

    private lazy var backgroundColorView = with(UIView()) {
        $0.clipsToBounds = true
        $0.isUserInteractionEnabled = true
        $0.backgroundColor = UIColor.randomColor()
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var contentLabel = with(UILabel()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .black
        $0.text = "We’ve accomplished a basic layout of our cells, but if you’ve worked with collection views before, you might know that your data source is also capable of vending reusable supplementary views to create things like headers, accessory views, and the like. So how do those fit into compositional layouts?"
        $0.font = UIFont(name: "HelveticaNeue", size: 18)
        $0.numberOfLines = 0
        $0.lineBreakMode = .byTruncatingTail
        $0.isUserInteractionEnabled = true
    }

    var collectionViewSize: CollectionViewSize?
    var cellPosition: (Int, Int)?
    var id: Int?
    weak var delegate: CellMotionDelegate?
    private var startWidth: CGFloat = 0
    private var startHeight: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        setViewsAndConstraints()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        backgroundColorView.addGestureRecognizer(pinchGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    @objc func handlePinch(sender: UIPinchGestureRecognizer) -> CGRect {
        switch sender.state {
        case .began, .ended:
            startWidth = self.frame.width
            startHeight = self.frame.height
            delegate?.update(self, scale: sender.scale)
            return self.frame
        case .changed:
            if sender.scale > 0.5,
               sender.scale < 2.0 {
                let newWidth = startWidth * sender.scale
                let newHeight = startHeight * sender.scale
                self.frame = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
                delegate?.update(self, scale: sender.scale)
            }
            return self.frame
        default:
            return self.frame
        }
    }

    private func setViewsAndConstraints() {
        self.contentView.addSubview(backgroundColorView)
        backgroundColorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        backgroundColorView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
