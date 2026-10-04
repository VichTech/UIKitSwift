//
//  Protocols.swift
//  alpha
//
//  Created by Christophe Vichery on 10/2/26.
//

protocol DataSourceProtocol {
    func fetchItems() async throws -> [Item]
    func fetchAsyncPins(step: Int) async throws -> [Pin]
    func fetchGCDPins(step: Int, completion: @escaping (Result<[Pin], Error>) -> Void)
}

protocol ItemStoreProtocol: Sendable {
    func load() async throws -> [Item]
    func update(item: Item) async throws
    func save(items: [Item]) async throws
}
