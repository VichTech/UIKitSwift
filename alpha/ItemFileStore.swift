//
//  ItemFileStore.swift
//  alpha
//
//  Created by Christophe Vichery on 10/3/26.
//

import Foundation

actor ItemFileStore: ItemStoreProtocol {
    private let fileURL: URL
    
    init(fileURL: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "items.json")) {
        self.fileURL = fileURL
    }

    func load() throws -> [Item] {
        let data = try Data(contentsOf: fileURL)
        let items = try JSONDecoder().decode([Item].self, from: data)
        return items
    }
    
    func update(item: Item) throws {
        var items = (try? load()) ?? []
        
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        
        try save(items: items)
    }
    
    func save(items: [Item]) throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
