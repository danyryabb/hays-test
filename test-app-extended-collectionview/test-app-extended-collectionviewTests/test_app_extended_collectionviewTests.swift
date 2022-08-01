import XCTest
@testable import test_app_extended_collectionview

final class MockMainViewController: MainViewController {
    // need to add init with ids, collectionView size for main view controller

    func getIds() -> [[Int]] {
        return self.ids
    }

    func getCollectionView() -> UICollectionView {
        return self.collectionView
    }
}

class test_app_extended_collectionviewTests: XCTestCase {
    var mockMainViewController: MockMainViewController!

    override func setUpWithError() throws {
        self.mockMainViewController = MockMainViewController()
    }

    override func tearDownWithError() throws {
        self.mockMainViewController = MockMainViewController()
    }

    func testGetIds_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        // act
        if let ids = sut?.getIds().flatMap({ $0 }) {
            // assert
            XCTAssertEqual(ids[1], 1)
        } else {
            // assert
            XCTFail("cant get ids")
        }
    }

    func collectionViewInit_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        // act
        if let collection = sut?.getCollectionView() {
            // assert
            XCTAssertEqual(collection.bounces, false)
            XCTAssertEqual(collection.frame, .zero)
        } else {
            // assert
            XCTFail("cant get collection")
        }
    }

    func getNumberOfSections_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        // act
        if let collection = sut?.getCollectionView(),
           let sectionsCount = sut?.numberOfSections(in: collection) {
            // assert
            XCTAssertEqual(sectionsCount, 1)
        } else {
            // assert
            XCTFail("cant get collection & number of sections")
        }
    }

    func getNumberOfItemsInSections_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        let ids = sut?.getIds().flatMap({ $0 }) ?? []
        // act
        if let collection = sut?.getCollectionView(),
           let itemsCount = sut?.collectionView(collection, numberOfItemsInSection: 0) {
            // assert
            XCTAssertEqual(ids.count, itemsCount)
        } else {
            // assert
            XCTFail("cant get collection & items count")
        }
    }

    func cellRegister_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        // act
        if let collection = sut?.getCollectionView(),
           let cell = sut?.collectionView(collection, cellForItemAt: IndexPath(item: 0, section: 0)) as? ColoredCell {
            // assert
            XCTAssertEqual(cell.collectionViewSize?.columnsCount, 3)
            XCTAssertEqual(cell.id, 0)
        } else {
            // assert
            XCTFail("cant get collection & cell")
        }
    }

    func cellPinch_testFunc() {
        // arrange
        let sut = self.mockMainViewController
        if let collection = sut?.getCollectionView(),
           let cell = sut?.collectionView(collection, cellForItemAt: IndexPath(item: 0, section: 0)) as? ColoredCell {
            let cellRect = cell.frame
            let sender = UIPinchGestureRecognizer()
            sender.scale = 1.5
            sender.state = .changed
            // act
            let newRect = cell.handlePinch(sender: sender)
            // assert
            XCTAssertEqual(newRect.origin.x, 0)
            XCTAssertEqual(newRect.origin.y, 0)
            XCTAssertEqual(newRect.width, cellRect.width * sender.scale)
            XCTAssertEqual(newRect.height, cellRect.height * sender.scale)
        } else {
            // assert
            XCTFail("cant get collection & cell")
        }
    }
}
