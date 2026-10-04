//
//  DataService.swift
//  alpha
//
//  Created by Christophe Vichery on 10/3/26.
//

import os
import Foundation

final class DataService {
    private var isFirstLoad = true
    private let itemStore: ItemStoreProtocol
    private let dataSource: DataSourceProtocol
    private let logger = Logger(subsystem: "com.vichtechnologies.alpha", category: "DataService")
    
    init(dataSource: DataSourceProtocol, itemStore: ItemStoreProtocol) {
        self.itemStore = itemStore
        self.dataSource = dataSource
    }
    
    func updateItem(item: Item) async {
        do {
            try await itemStore.update(item: item)
        } catch {
            logger.error("itemStore update failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func fetchItems() async throws -> [Item] {
        if isFirstLoad {
            isFirstLoad = false
            
            do {
                let cached = try await itemStore.load()
                if !cached.isEmpty { return cached }
            } catch {
                logger.error("itemStore load failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        do {
            let items = try await dataSource.fetchItems()
            
            do {
                try await itemStore.save(items: items)
            } catch {
                logger.error("itemStore save failed: \(error.localizedDescription, privacy: .public)")
            }
            
            return items
        } catch {
            logger.error("fetchItems failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    // Grand Central Dispatch
    func fetchGCDPins(completion: @escaping ([Pin]) -> Void) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "fetchGCDPins")
        var allPins = [Pin]()
        
        for step in 0..<3 {
            group.enter()
            dataSource.fetchGCDPins(step: step) { [weak self] result in
                switch result {
                case .success(let pins):
                    queue.sync {
                        allPins.append(contentsOf: pins)
                    }
                case .failure(let error):
                    self?.logger.error("fetchGCDPins step \(step) failed: \(error.localizedDescription, privacy: .public)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allPins.sorted{ $0.id < $1.id })
        }
    }
    
    // Swift Concurrency
    func fetchAsyncPins() async -> [Pin] {
        await withTaskGroup(of: [Pin].self) { group in
            for step in 0..<3 {
                group.addTask { @MainActor in
                    do {
                        return try await self.dataSource.fetchAsyncPins(step: step)
                    } catch {
                        self.logger.error("fetchAsyncPins step \(step) failed: \(error.localizedDescription, privacy: .public)")
                        return []
                    }
                }
            }
            
            var allPins = [Pin]()
            for await pins in group {
                allPins.append(contentsOf: pins)
            }
            return allPins.sorted { $0.id < $1.id }
        }
    }
}
