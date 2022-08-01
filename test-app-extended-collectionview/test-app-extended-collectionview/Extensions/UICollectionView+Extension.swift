import UIKit

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T? {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.description(), for: indexPath) as? T else {
            assertionFailure("unable to dequeue cell with identifier \(T.description())")
            return nil
        }

        return cell
    }

    func register(cellClasses: UICollectionViewCell.Type...) {
        cellClasses.forEach({
            register($0.self, forCellWithReuseIdentifier: $0.description())
        })
    }
}
