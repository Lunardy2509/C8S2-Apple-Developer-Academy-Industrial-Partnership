import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    @Binding var shouldRecenter: Bool
    @Binding var selectedBrand: [Entity]
    @Binding var displayMode: DisplayModeEnum
    @Binding var popupCoordinate: CLLocationCoordinate2D?
    @Binding var popupScreenPosition: CGPoint
    @Binding var popupData: CustomPopupData?
    @Binding var mapViewRef: MKMapView?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isRotateEnabled = true

        let zoomRange = MKMapView.CameraZoomRange(
            maxCenterCoordinateDistance: 500
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        if let location = userLocation {
            let circle = MKCircle(center: location, radius: 100)
            mapView.addOverlay(circle)
        }
                
        DispatchQueue.main.async {
            self.mapViewRef = mapView
        }
        
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.2
        
        longPress.delegate = context.coordinator
        mapView.addGestureRecognizer(longPress)
        
        GeoJSONDecoderManager.shared.loadGeoJSON(on: mapView)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if self.shouldRecenter, let userLocation = self.userLocation {
            uiView.setUserTrackingMode(.followWithHeading, animated: true)
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.shouldRecenter = false
            }
            
        }


        if context.coordinator.lastDisplayMode != displayMode {
               context.coordinator.lastDisplayMode = displayMode
               
               let allAnnotations = uiView.annotations
               uiView.removeAnnotations(allAnnotations.filter { !($0 is MKUserLocation) })
               
               for overlay in uiView.overlays {
                   guard let polygon = overlay as? MKPolygon,
                         let title = polygon.title?.lowercased()
                   else { continue }
                   
                   let brand = EntityData.entities.first(where: { $0.properties.name.lowercased() == title })
                   let hall = HallData.halls.first(where: { $0.name.lowercased() == title })
                   
                   if let brand, ["tunnel", "booth", "stage"].contains(brand.properties.objectType) {
                       var annotationTitle: String?
                       switch displayMode {
                           case .brand: annotationTitle = brand.properties.name
                           case .activity: annotationTitle = brand.properties.activity
                       }
                       
                       if let title = annotationTitle {
                           let annotation = MKPointAnnotation()
                           annotation.coordinate = polygon.coordinate
                           annotation.title = title
                           uiView.addAnnotation(annotation)
                       }
                   } else if let hall {
                       let annotation = MKPointAnnotation()
                       annotation.coordinate = polygon.coordinate
                       annotation.title = hall.name
                       uiView.addAnnotation(annotation)
                   }
               }
           }

        context.coordinator.adjustAnnotationVisibility(for: uiView)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        var lastDisplayMode: DisplayModeEnum
        
        private let zoomLevelShowOnlyHalls = 0.0007
        private let zoomLevelShowFocusedBooths = 0.0005

        init(_ parent: MapView) {
            self.parent = parent
            self.lastDisplayMode = parent.displayMode
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circle)
                circleRenderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
                circleRenderer.strokeColor = UIColor.systemBlue
                circleRenderer.lineWidth = 1
                return circleRenderer
            }
            
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                let title = polygon.title?.lowercased() ?? ""
                let selectedBrands = parent.selectedBrand.map {
                    $0.properties.name.lowercased()
                }
                
                if selectedBrands.contains(title) {
                    renderer.fillColor = UIColor(Color(red: 218 / 255, green: 53 / 255, blue: 88 / 255))
                } else {
                    if HallData.halls.contains(where: { $0.name.lowercased() == title }) {
                        renderer.fillColor = UIColor.white
                        renderer.strokeColor = UIColor(Color(red: 221 / 255, green: 170 / 255, blue: 167 / 255))
                        renderer.lineWidth = 1.5
                        return renderer
                    }
                    
                    if EntityData.entities.contains(where: { $0.properties.name.lowercased() == title && $0.properties.objectType == "wall" }) {
                        renderer.fillColor = UIColor.black.withAlphaComponent(0.6)
                    } else if EntityData.entities.contains(where: { $0.properties.name.lowercased() == title && $0.properties.objectType == "tunnel" }) {
                        renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                    } else if EntityData.entities.contains(where: { $0.properties.name.lowercased() == title && $0.properties.objectType == "stage" }) {
                        renderer.fillColor = UIColor.red.withAlphaComponent(0.8)
                    } else {
                        // Booth
                        renderer.fillColor = selectedBrands.isEmpty ? UIColor(Color(red: 220 / 255, green: 62 / 255, blue: 136 / 255)) : UIColor(Color(red: 241 / 255, green: 178 / 255, blue: 207 / 255))
                    }
                    renderer.strokeColor = UIColor.clear
                }

                renderer.lineWidth = 1
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            mapView.overlays
                .filter { $0 is MKCircle }
                .forEach { mapView.removeOverlay($0) }

            let circle = MKCircle(center: userLocation.coordinate, radius: 2)
            mapView.addOverlay(circle)

            DispatchQueue.main.async {
                self.parent.userLocation = userLocation.coordinate
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Hindari pin untuk user location
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "LabelAnnotationView"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? LabelAnnotationView

            if view == nil {
                view = LabelAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            
            view?.onLongPress = { [weak self] in
                guard let self = self else { return }
                let coordinate = annotation.coordinate
                let title = annotation.title ?? ""

                if let booth = EntityData.entities.first(where: { $0.properties.name == title }) {
                    let data = CustomPopupData(
                        title: booth.properties.name,
                        subtitle: booth.properties.hall ?? "",
                        onClose: {
                            DispatchQueue.main.async {
                                self.parent.popupCoordinate = nil
                                self.parent.popupData = nil
                                self.adjustAnnotationVisibility(for: mapView)
                            }
                        },
                        onClick: {
                            // Optional redirect
                        }
                    )
                    DispatchQueue.main.async {
                        self.parent.popupCoordinate = coordinate
                        self.parent.popupData = data
                        self.adjustAnnotationVisibility(for: mapView)
                    }
                }
            }
            
            return view
        }
        
        @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            guard gestureRecognizer.state == .began,
                  let mapView = gestureRecognizer.view as? MKMapView else { return }
            
            if gestureRecognizer.state == .began {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            let booths = EntityData.entities.filter{ $0.properties.objectType == "booth"}
            for booth in booths {
                let coordinates = booth.geometry.coordinates.map { $0.coordinate }
                if contains(coordinate, in: coordinates) {
                    let data = CustomPopupData(
                        title: booth.properties.name,
                        subtitle: booth.properties.hall ?? "",
                       onClose: {
                           DispatchQueue.main.async {
                               self.parent.popupCoordinate = nil
                               self.parent.popupData = nil
                           }
                       },
                        onClick: {
                            // TODO: Redirect to brand profile page
                            return
                       })
                    
                    DispatchQueue.main.async {
                        self.parent.popupData = data
                    }
                    let centerCoord = calculateCentroid(of: coordinates)
                    showPopup(at: centerCoord, on: mapView)
                    
                    adjustAnnotationVisibility(for: mapView)
                    break
                    
                }
            }
        }
        
        func calculateCentroid(of coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
            guard !coordinates.isEmpty else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }

            var totalLat: CLLocationDegrees = 0
            var totalLon: CLLocationDegrees = 0

            for coord in coordinates {
                totalLat += coord.latitude
                totalLon += coord.longitude
            }

            let count = CLLocationDegrees(coordinates.count)
            return CLLocationCoordinate2D(latitude: totalLat / count, longitude: totalLon / count)
        }
        
        func contains(_ coordinate: CLLocationCoordinate2D, in polygon: [CLLocationCoordinate2D]) -> Bool {
            let mapPoint = MKMapPoint(coordinate)
            let cgPoints = polygon.map { MKMapPoint($0) }
            let renderer = MKPolygonRenderer(polygon: MKPolygon(coordinates: polygon, count: polygon.count))
            let point = renderer.point(for: mapPoint)
            
            let path = CGMutablePath()
            if let first = cgPoints.first {
                path.move(to: renderer.point(for: first))
                for p in cgPoints.dropFirst() {
                    path.addLine(to: renderer.point(for: p))
                }
                path.closeSubpath()
            }

            return path.contains(point)
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            if let coordinate = parent.popupCoordinate {
                let point = mapView.convert(coordinate, toPointTo: mapView)
                DispatchQueue.main.async {
                    self.parent.popupScreenPosition = point
                }
            }
            
            adjustAnnotationVisibility(for: mapView)
        }
        
        func adjustAnnotationVisibility(for mapView: MKMapView) {
            let latitudeDelta = mapView.region.span.latitudeDelta
            let isPopupActive = self.parent.popupData != nil

            for annotationView in mapView.annotations.compactMap({ mapView.view(for: $0) as? LabelAnnotationView }) {
                guard let title = annotationView.annotation?.title ?? nil else { continue }
                let entity: Entity?

                switch parent.displayMode {
                    case .brand:
                        entity = EntityData.entities.first(where: { $0.properties.name == title })
                    default:
                        entity = EntityData.entities.first(where: { $0.properties.activity == title })
                }
                                
                if let entity = entity {
                    switch latitudeDelta {
                        case ..<zoomLevelShowFocusedBooths:
                            // Very close zoom
                        annotationView.setLabelHidden(entity.properties.objectType != "booth" && entity.properties.objectType != "stage")
                        case ..<zoomLevelShowOnlyHalls:
                            // Medium zoom
                            annotationView.setLabelHidden(!(entity.properties.objectType == "booth" && entity.properties.isFocused == true) && entity.properties.objectType != "stage")
                        default:
                            // Far zoom
                            annotationView.setLabelHidden(entity.properties.objectType != "hall")
                    }
                } else if let _ = HallData.halls.first(where: { $0.name == title }) {
                    let isZoomedInEnough = latitudeDelta <= zoomLevelShowOnlyHalls
                    annotationView.setLabelHidden(isZoomedInEnough || isPopupActive)
                } else {
                    annotationView.setLabelHidden(true)
                }
            }
        }
        
        func showPopup(at coordinate: CLLocationCoordinate2D, on mapView: MKMapView) {
            parent.popupCoordinate = coordinate

            mapView.setCenter(coordinate, animated: true)
        }
        
        func polygonScreenFrame(for polygon: MKPolygon, in mapView: MKMapView) -> CGRect {
            let renderer = MKPolygonRenderer(polygon: polygon)
            let points = polygon.points()
            let count = polygon.pointCount
            
            guard count > 0 else { return .zero }
            
            var minX: CGFloat = .greatestFiniteMagnitude
            var minY: CGFloat = .greatestFiniteMagnitude
            var maxX: CGFloat = .leastNormalMagnitude
            var maxY: CGFloat = .leastNormalMagnitude

            for i in 0..<count {
                let mapPoint = points[i]
                let cgPoint = renderer.point(for: mapPoint)
                minX = min(minX, cgPoint.x)
                maxX = max(maxX, cgPoint.x)
                minY = min(minY, cgPoint.y)
                maxY = max(maxY, cgPoint.y)
            }

            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    
    class LabelAnnotationView: MKAnnotationView {
        private let label = UILabel()
        var onLongPress: (() -> Void)?
        
        override var annotation: MKAnnotation? {
            willSet {
                guard let title = newValue?.title ?? nil else { return }
                setupLabel(with: title)
            }
        }

        private func setupLabel(with title: String) {
            label.text = title
            label.font = UIFont.systemFont(ofSize: 8, weight: .bold)
            label.textColor = .black
            label.sizeToFit()
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            label.textAlignment = .center

            addSubview(label)
            frame = label.bounds
                        
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            self.addGestureRecognizer(longPress)
            self.isUserInteractionEnabled = true
        }
        
        @objc private func handleLongPress() {
            print("Long press triggered")

            if onLongPress == nil {
                print("No onLongPress")
            }
            onLongPress?()
        
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            label.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        }
        
        func setLabelHidden(_ hidden: Bool) {
            label.isHidden = hidden
        }
    }
}
