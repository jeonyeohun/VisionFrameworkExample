//
//  ResultViewController.swift
//  VisionCardScanner
//
//  Created by USER on 2022/04/28.
//

import UIKit

class ResultViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var cvvLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    private var dataSource: CreditCardInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLabelContents()
    }

    func configureDataSource(creditCardInfo: CreditCardInfo) {
        self.dataSource = creditCardInfo
    }

    private func configureLabelContents() {
        guard let dataSource = dataSource else {
            return
        }
        nameLabel.text = dataSource.name
        numberLabel.text = dataSource.number
        dateLabel.text = dataSource.date
        cvvLabel.text = dataSource.cvv
    }

    @IBAction func retryButtonDidTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
