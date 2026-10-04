//
//  ListViewController.swift
//  alpha
//
//  Created by Christophe Vichery on 10/4/26.
//

import UIKit

final class ListViewController: UIViewController {
    private let viewModel: ContentViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)

    // Rows are identified by Item.ID (Int), not by the whole Item.
    private lazy var dataSource = UITableViewDiffableDataSource<Int, Item.ID>(tableView: tableView) { [weak self] tableView, indexPath, id in
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        guard let item = self?.viewModel.items.first(where: { $0.id == id }) else { return cell }

        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = "ID \(item.id) · User \(item.userId) · \(item.completed ? "Completed" : "Open")"
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Items"
        view.backgroundColor = .systemBackground

        // Fetch button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Fetch",
            image: UIImage(systemName: "arrow.down.circle"),
            primaryAction: UIAction { [weak self] _ in self?.fetch() }
        )

        // Table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in
            Task {
                await self?.viewModel.fetchItems()
                self?.tableView.refreshControl?.endRefreshing()
            }
        }, for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    // Called by UIKit, and called again whenever an observed property read here changes.
    override func updateProperties() {
        super.updateProperties()
        applySnapshot(ids: viewModel.items.map(\.id))
        updateState(viewModel.state)
    }

    private func applySnapshot(ids: [Item.ID]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(ids)
        snapshot.reconfigureItems(ids)   // refresh rows whose content changed, like completed
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateState(_ state: ViewState) {
        switch state {
        case .idle:
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "tray")
            config.text = "No Items"
            config.secondaryText = "Tap Fetch to load items."
            contentUnavailableConfiguration = config
        case .loading:
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        case .loaded:
            contentUnavailableConfiguration = nil
        case .failed(let message):
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "exclamationmark.triangle")
            config.text = "Error"
            config.secondaryText = message
            config.button = .filled()
            config.button.title = "Retry"
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in self?.fetch() }
            contentUnavailableConfiguration = config
        }
    }

    private func fetch() {
        Task { [weak self] in
            await self?.viewModel.fetchItems()
        }
    }
}

// MARK: - UITableViewDelegate

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let item = viewModel.items.first(where: { $0.id == id }) else { return }

        let detail = ItemViewController(item: item) { [weak self] updated in
            await self?.viewModel.updateItem(item: updated)
        }
        navigationController?.pushViewController(detail, animated: true)
    }
}
