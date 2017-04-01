//
//  FeedCoordinator.swift
//  FLYR
//
//  Created by Garric G. Nahapetian on 3/26/17.
//  Copyright © 2017 Garric Nahapetian. All rights reserved.
//

//import UIKit
import MapKit
import CloudKit
import GGNLocationPicker

class FeedCoordinator: Coordinator {
    
    enum Mode {
        case userLocation
        case preferredLocation(CLLocation)
        case losAngeles(CLLocation)
    }
    
    weak var delegate: CoordinatorDelegate?
    
    let rootViewController: UIViewController = UINavigationController(rootViewController: LoadingVC())
    
    private let mode: Mode
    private let fetcher: FlyrFetchable
    private let locationManager: LocationManageable
    private let loadingVC = LoadingVC()

    private var navigationController: UINavigationController {
        if let viewController = rootViewController as? UINavigationController {
            return viewController
        } else {
            fatalError("Expects and UINavigationController!")
        }
    }
    
    private var preferredLocation: MKAnnotation? {
        guard let dictionary = UserDefaults.standard.dictionary(forKey: "PreferredLocation")
            , let title = dictionary["title"] as? String
            , let subtitle = dictionary["subtitle"] as? String
            , let coordinate = dictionary["coordinate"] as? [String: Any]
            , let latitude = coordinate["latitude"] as? Double
            , let longitude = coordinate["longitude"] as? Double
            else { return nil }
        
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = coord
        return annotation
    }
    
    init(mode: FeedCoordinator.Mode,
         fetcher: FlyrFetchable, locationManager: LocationManageable) {
        self.mode = mode
        self.fetcher = fetcher
        self.locationManager = locationManager
    }
    
    func start() {
        switch mode {
        case .userLocation: startUserLocationMode()
        case .preferredLocation(let location): startFeed(with: location)
        case .losAngeles(let location): startFeed(with: location)
        }
        
        fetcher.output.onNext { [weak self] flyrs in
            guard let weakSelf = self else { return }

            let viewController = weakSelf.resolvedFeedVC(with: flyrs)
            let viewControllers = [viewController]
            
            DispatchQueue.main.async {
                weakSelf.navigationController.setViewControllers(viewControllers, animated: false)
                weakSelf.delegate?.coordinatorIsReady(coordinator: weakSelf)
            }
        }
    }
    
    private func resolvedFeedVC(with flyrs: Flyrs) -> FlyrTableVC {
        let leftBarButtonItem = UIBarButtonItem(
            title: "◉",
            style: .plain,
            target: self,
            action: #selector(locationButtonTapped))
        let gestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onLongPress))
        
        let viewModel = FeedVM(model: flyrs)
        let viewController = FlyrTableVC(viewModel: viewModel)
        viewController.navigationItem.leftBarButtonItem = leftBarButtonItem
        viewController.tableView.addGestureRecognizer(gestureRecognizer)
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.register(FlyrCell.self, forCellReuseIdentifier: FlyrCell.identifier)
        viewController.refreshControl?.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        return viewController
    }
    
    private func startFeed(with location: CLLocation) {
        
    }
    
    // MARK: - User Location Mode

    private func startUserLocationMode() {
        locationManager.requestLocation { [weak self] response in
            self?.completion(with: response)
        }
    }
    
    private func completion(with response: LocationResponse) {
        switch response {
        case .didUpdateLocations(let locations):
            fetch(with: locations.last!)
        case .didFail(let error):
            assertionFailure("Handle error: \(error)")
        case .didFailAuthorization(let authorization):
            assertionFailure("Handle did fail authorization: \(authorization)")
        }
    }
    
    private func fetch(with location: CLLocation) {
        let query = makeQuery(from: location)
        fetcher.fetch(with: query)
    }
    
    private func makeQuery(from location: CLLocation) -> CKQuery {
        let radius: CGFloat = 100000000.0
        let format = "(distanceToLocation:fromLocation:(location, %@) < %f)"
        let predicate = NSPredicate(
            format: format,
            location,
            radius
        )
        return CKQuery(recordType: "Flyr", predicate: predicate)
    }
    
    // MARK: - Private Functions
    
    @objc private func locationButtonTapped() {
        let locationPicker = LocationPickerVC(with: preferredLocation)
        locationPicker.navigationItem.title = "Set Search Area"
        locationPicker.navigationItem.rightBarButtonItem = makeCancelButton(for: locationPicker)
        locationPicker.didPick = {
            self.save(preferredLocation: $0)
            locationPicker.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
        let vc = UINavigationController(rootViewController: locationPicker)
        rootViewController.present(vc, animated: true, completion: nil)
    }
    
    @objc private func addButtonTapped() {
    }
    
    @objc private func onPullToRefresh() {}
    
    @objc private func onLongPress() {}
    
    private func save(preferredLocation annotation: MKAnnotation) {
        let preferredLocation: [String: Any] = [
            "title": (annotation.title!)!,
            "subtitle": (annotation.subtitle!)!,
            "coordinate": [
                "latitude": annotation.coordinate.latitude,
                "longitude": annotation.coordinate.longitude
            ]
        ]
    
        UserDefaults.standard.set(preferredLocation, forKey: "PreferredLocation")
        UserDefaults.standard.synchronize()
    }
}


extension MKAnnotation {
    var location: CLLocation {
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}





//
//private func pointAnnotation(from annotation: MKAnnotation) -> MKPointAnnotation {
//    let pointAnnotation = MKPointAnnotation()
//    pointAnnotation.coordinate = annotation.coordinate
//    pointAnnotation.title = annotation.title!
//    pointAnnotation.subtitle = annotation.subtitle!
//    return pointAnnotation
//}
