//
//  MapView.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/20.
//

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    
    typealias UIViewType = MKMapView
    
    static let userArrowColor: UIColor = UIColor("#66b2ff")
    
    static let firstSetupCoordinateDistance: CLLocationDistance = 1000
    #warning("Calculate the real needed distance")
    static let fileRouteDisplayCoordinateDistance: CLLocationDistance = 3000
    
    @Binding var isSetupCurrentLocation: Bool
    
    @Binding var isLocationLocked: Bool
    
    var headingDirection: CLLocationDirection
    
    @Binding var updateByMapItem: Bool
    
    var showsUserLocation: Bool
    
    @Binding var removeAnnotationItems: [HomeMapAnnotation]
    
    @Binding var userAnootion: HomeMapAnnotation
    
    @Binding var setNeedUpdateUserAnootionOnMap: Bool
    
    @Binding var sourceAnnotation: HomeMapAnnotation?
    
    @Binding var setNeedUpdateSourceAnnotationOnMap: Bool
    
    @Binding var displayPathWithRoutes: [MKRoute]
    
    @Binding var setNeedUpdateNewPathAnnotationsOnMap: Bool
    
    @Binding var displayPathWithAnnotations: [HomeMapAnnotation]
    
    @Binding var removeRoutes: [MKRoute]
    
    @Binding var cameraCenterLocation: CLLocationCoordinate2D?
    
    @Binding var cameraCenterDistance: CLLocationDistance
    
    var didUpdateUserLocation: ((RRLocationCoordinate3D)->Void)
    
    var didUpdateCenterCoordinateDistance: ((CLLocationDistance)->Void)
    
    let coordinator = MapViewCoordinator()
    
    func makeCoordinator() -> MapViewCoordinator {
        
        coordinator.didUpdateCenterCoordinateDistance = didUpdateCenterCoordinateDistance
        
        coordinator.didUpdateUserLocation = didUpdateUserLocation
        print("Get coordinator")
        return coordinator
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.showsCompass = true
        mapView.showsTraffic = false
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // MARK: Setup camera vision
        if let cameraCenterLocation = cameraCenterLocation, updateByMapItem {
            // Udpate by item (ex: routes, annotation...)
            updateByMapItem.toggle()
            uiView.camera.centerCoordinate = cameraCenterLocation
        } else if let cameraCenterLocation = cameraCenterLocation, isLocationLocked {
            // Lock user vision with current location
            uiView.camera.heading = headingDirection
            uiView.camera.centerCoordinate = cameraCenterLocation
        }
        
        uiView.camera.centerCoordinateDistance = cameraCenterDistance
        // Path
        if !removeAnnotationItems.isEmpty {
            uiView.removeAnnotations(removeAnnotationItems)
            removeAnnotationItems.removeAll()
        }
        
        if !removeRoutes.isEmpty {
            for route in removeRoutes {
                uiView.removeOverlay(route.polyline)
            }
            
            removeRoutes.removeAll()
        }
        
        if HomeMapViewModel.displayPathByRoutes {
            for route in displayPathWithRoutes {
                uiView.addOverlay(route.polyline, level: .aboveLabels)
            }
        } else if setNeedUpdateNewPathAnnotationsOnMap && (displayPathWithAnnotations.count > 1) {
            setNeedUpdateNewPathAnnotationsOnMap.toggle()
            uiView.addAnnotations(displayPathWithAnnotations)
        }
        // UserAnnotionItem
        if setNeedUpdateUserAnootionOnMap {
            setNeedUpdateUserAnootionOnMap.toggle()
            uiView.addAnnotation(userAnootion)
        }
        // SourceAnnotionItem
        if setNeedUpdateSourceAnnotationOnMap, let sourceAnnotation = sourceAnnotation {
            setNeedUpdateSourceAnnotationOnMap.toggle()
            uiView.addAnnotation(sourceAnnotation)
        }
    }
    
    func filtPathAnnotationsWithCameraCenterDistance(annotations: [HomeMapAnnotation], distance: CLLocationDistance) -> [HomeMapAnnotation] {
        // The Annotations is set as 1 meters in each location
        let idealDistance: Int = Int(distance / 20)
        var newAnnotations: [HomeMapAnnotation] = []
        
        guard let origin = annotations.first, let last = annotations.last else { return newAnnotations}
        
        newAnnotations.append(origin)
        
        for (index, annotation)in annotations.enumerated() {
            guard index > 0 && index % idealDistance == 0 else { continue}
            newAnnotations.append(annotation)
        }
        newAnnotations.append(last)
        
        return newAnnotations
    }
    
    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var didUpdateCenterCoordinateDistance: ((CLLocationDistance)->Void)?
        
        var didUpdateUserLocation: ((RRLocationCoordinate3D)->Void)?
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            didUpdateUserLocation?(RRLocationCoordinate3D(latitude: userLocation.coordinate.latitude,
                                                          longitude: userLocation.coordinate.longitude,
                                                          altitude: userLocation.location?.altitude ?? 0))
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

            guard let annotion = annotation as? HomeMapAnnotation else { return nil }
            // TODO: Image Tint Color
            switch annotion.type{
            case .user:
                let annotationView = MKAnnotationView(annotation: annotion, reuseIdentifier: nil)

                let rotateDegrees = ((annotion.userHeadingDegrees ?? 0) / 180) * .pi
                let annotationColor = MapView.userArrowColor
                let image = UIImage(systemName: annotion.imageSystemName)?.withTintColor(annotationColor).rotate(radians: rotateDegrees)
                
                annotationView.image = image

                return annotationView
            case .receiver:
                let image = UIImage(systemName: annotion.imageSystemName)
                
                let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
                
                marker.animatesWhenAdded = true
                
                marker.displayPriority = MKFeatureDisplayPriority(2)
                
                marker.glyphImage = image
                
                marker.markerTintColor = annotion.color
                
                return marker
            case .pathWithDot:
                let image = UIImage(systemName: annotion.imageSystemName)
                
                let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
                
                marker.displayPriority = MKFeatureDisplayPriority(0)
                
                marker.glyphImage = image
                
                marker.markerTintColor = annotion.color
                
                return marker
            default:
                return nil
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            didUpdateCenterCoordinateDistance?(mapView.camera.centerCoordinateDistance)
        }
    }
}
