import Foundation

struct CollectionViewSize {
    let rowsCount: Int
    let columnsCount: Int

    init(_ rows: Int, _ cols: Int) {
        self.rowsCount = rows
        self.columnsCount = cols
    }
}
