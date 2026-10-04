//
//  ItemViewController.swift
//  alpha
//
//  Created by Christophe Vichery on 10/4/26.
//

import UIKit

final class ItemViewController: UIViewController {
    private var item: Item
    private let onUpdate: (Item) async -> Void

    private let titleLabel = UILabel()
    private let idLabel = UILabel()
    private let userLabel = UILabel()
    private let completedLabel = UILabel()
    private let completedSwitch = UISwitch()

    init(item: Item, onUpdate: @escaping (Item) async -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Item \(item.id)"
        view.backgroundColor = .systemBackground

        // Content
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0

        let mono = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        idLabel.text = "ID     : \(item.id)"
        idLabel.font = mono
        userLabel.text = "USERID : \(item.userId)"
        userLabel.font = mono
        completedLabel.text = "COMPLETED"
        completedLabel.font = mono

        completedSwitch.isOn = item.completed
        completedSwitch.addAction(UIAction { [weak self] _ in
            self?.completedChanged()
        }, for: .valueChanged)

        // Layout
        let switchRow = UIStackView(arrangedSubviews: [completedLabel, completedSwitch])
        switchRow.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleLabel, idLabel, userLabel, switchRow])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    private func completedChanged() {
        item.completed = completedSwitch.isOn
        let updated = item
        Task {
            await onUpdate(updated)
        }
    }
}
