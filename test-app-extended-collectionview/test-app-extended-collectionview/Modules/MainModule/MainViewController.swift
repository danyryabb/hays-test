import UIKit
import SnapKit

class MainViewController: UIViewController {
    enum Constants {
        static let rowsCount: Int = 5
        static let columnsCount: Int = 3
    }

    var ids: [[Int]] {
        var array: [[Int]] = (0..<Constants.rowsCount).map { _ in [Int](repeating: 0, count: Constants.columnsCount) }
        var num = 0
        for i in 0..<Constants.rowsCount {
            for j in 0..<Constants.columnsCount {
                array[i][j] = num
                num += 1
            }
        }
        return array
    }

    lazy var collectionView = with(UICollectionView(
        frame: .zero, collectionViewLayout: CustomLayout(size: CollectionViewSize(Constants.rowsCount, Constants.columnsCount)))
    ) {
        $0.bounces = false
        $0.register(cellClasses: ColoredCell.self)
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = UIColor.white
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.delegate = self
        $0.dataSource = self
        if let layout = $0.collectionViewLayout as? CustomLayout {
            layout.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension MainViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ids.flatMap { $0 }.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell: ColoredCell = collectionView.dequeueReusableCell(for: indexPath) {
            cell.delegate = collectionView.collectionViewLayout as? CustomLayout
            cell.cellPosition = (indexPath.item / Constants.columnsCount, indexPath.item % Constants.columnsCount)
            cell.id = indexPath.item
            cell.collectionViewSize = CollectionViewSize(Constants.rowsCount, Constants.columnsCount)
            return cell
        } else { return UICollectionViewCell() }
    }
}

extension MainViewController: UICollectionViewDelegate {}

extension MainViewController: CustomLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForCellAtIndexPath indexPath: IndexPath) -> CGFloat? {
        let cell = self.collectionView.cellForItem(at: indexPath)
        let height = cell?.frame.size.height
        return height
    }
}
