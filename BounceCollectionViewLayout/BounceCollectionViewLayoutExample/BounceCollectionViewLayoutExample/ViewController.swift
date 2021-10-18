//
//  ViewController.swift
//  BounceCollectionViewLayoutExample
//
//  Created by Ben Deckys on 2021/10/18.
//

import UIKit

final class ViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }

    private let fakeDataSource = (0...10000).map { $0 }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.reloadData()
    }

}

extension ViewController: UICollectionViewDelegate {}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fakeDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
}

