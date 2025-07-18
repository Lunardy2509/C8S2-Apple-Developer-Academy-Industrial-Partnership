//
//  PDRManager.swift
//  SIG-IPC
//
//  Created by Ferdinand Lunardy on 18/07/25.
//

import Foundation
import CoreMotion
import CoreLocation
import Combine

class PDRManager: ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D
    
    private let pedometer = CMPedometer()
    private let motionManager = CMMotionManager()
    private var previousStepCount: Int = 0
    
    private var stepLength: Double = 0.75
    private var heading: Double = 0.0
    private var cancelLabels = Set<AnyCancellable>()
    
    init(initialCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -6.301998041670829, longitude: 106.65247636617268)){
        self.currentLocation = initialCoordinate
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                guard let self = self,
                      let steps = data?.numberOfSteps.intValue else { return }
                let deltaSteps = steps - self.previousStepCount
                self.previousStepCount = steps
                
                if deltaSteps > 0 {
                    self.updatePosition(steps: deltaSteps)
                }
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let attitude = motion?.attitude else { return }
                self.heading = attitude.yaw * 180 / .pi
            }
        }
    }
    
    private func updatePosition(steps: Int) {
        let distance = Double(steps) * stepLength
        let earthRadius = 6378137.0
        
        let deltaLat = (distance * cos(heading * .pi / 180)) / earthRadius
        let deltaLon = (distance * sin(heading * .pi / 180)) / (earthRadius * cos(currentLocation.latitude * .pi / 180))
        
        let newLat = currentLocation.latitude + deltaLat * 180 / .pi
        let newLon = currentLocation.longitude + deltaLon * 180 / .pi
        
        let newCoord = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
        
        DispatchQueue.main.async {
            self.currentLocation = newCoord
        }
    }
}
