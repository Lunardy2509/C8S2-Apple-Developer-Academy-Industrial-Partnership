import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    // MARK: - Private Properties
    private var locationManager = CLLocationManager()
    private var locationUpdateTimer: Timer?
    private var hasSetInitialRegion = false

    override init() {
        super.init()
        print("Initialize LocationManager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestAuthorization()
        locationManager.startUpdatingHeading()

        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
        
        if let timer = locationUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    // MARK: - Authorization Handling
    private func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("Meminta izin lokasi...")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("Lokasi diizinkan, memulai pembaruan lokasi")
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            print("Akses lokasi ditolak")
        @unknown default:
            print("Status otorisasi tidak diketahui")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestAuthorization()
    }

    func updateRegion(to coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.userLocation = coordinate
            self.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        let coordinate = currentLocation.coordinate

        // Update user location
        DispatchQueue.main.async {
            self.userLocation = coordinate
        }

        // Set initial region
        if !hasSetInitialRegion {
            updateRegion(to: coordinate)
            hasSetInitialRegion = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Gagal mendapatkan lokasi: \(error.localizedDescription)")
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        print("Pembaruan lokasi dihentikan")
    }
}
