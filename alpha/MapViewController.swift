//
//  MapViewController.swift
//  alpha
//
//  Created by Christophe Vichery on 10/4/26.
//

import UIKit
import MapKit

final class MapViewController: UIViewController {
    private let viewModel: ContentViewModel
    private let mapView = MKMapView()
    private var fetchTask: Task<Void, Never>?

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"

        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTask = Task { [weak self] in
            //self?.viewModel.fetchGCDPins()
            await self?.viewModel.fetchAsyncPins()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchTask?.cancel()
        fetchTask = nil
    }

    // Called by UIKit, and called again whenever an observed property read here changes.
    override func updateProperties() {
        super.updateProperties()
        mapView.removeAnnotations(mapView.annotations)
        let annotations = viewModel.pins.map { pin in
            let annotation = MKPointAnnotation()
            annotation.title = pin.title
            annotation.coordinate = pin.coordinate
            return annotation
        }
        mapView.addAnnotations(annotations)
    }
}
