//
//  MapView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/20.
//

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    
    typealias UIViewType = MKMapView
    
    static let userArrowColor: UIColor = UIColor("#66b2ff")
    
    @Binding var userCurrentRegion: MKCoordinateRegion?
    
    @Binding var isLocationLocked: Bool
    
    var headingDirection: CLLocationDirection
    
    @Binding var updateByMapItem: Bool
    
    var showsUserLocation: Bool
    
    @Binding var removeAnnotationItems: [HomeMapAnnotation]
    
    var userAnootionItem: HomeMapAnnotation
    
    var addAnnotationItem: HomeMapAnnotation
    
    @Binding var displayRoutes: [MKRoute]
    
    @Binding var removeRoutes: [MKRoute]
    
    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.showsTraffic = false
        if let userCurrentRegion = userCurrentRegion {
            mapView.region = userCurrentRegion
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
        if (isLocationLocked || updateByMapItem), let userCurrentRegion = userCurrentRegion {
            updateByMapItem = false
            
            uiView.region.center = userCurrentRegion.center
            // Also update compass direction
            if isLocationLocked {
                uiView.camera.heading = headingDirection
            }
            // TODO: ShowsUserLocation with arrow
            
        }
        
        // UserAnnotionItem
        uiView.addAnnotation(userAnootionItem)
        // ReceiverAnnotionItem
        uiView.addAnnotation(addAnnotationItem)
        
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
        
        for route in displayRoutes {
            uiView.addOverlay(route.polyline, level: .aboveLabels)
        }
    }
    
    class MapViewCoordinator: NSObject, MKMapViewDelegate {
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
                let annotionView = MKAnnotationView(annotation: annotion, reuseIdentifier: nil)

                let rotateDegrees = ((annotion.userHeadingDegrees ?? 0) / 180) * .pi
                let annotionColor = MapView.userArrowColor
                let image = UIImage(systemName: annotion.imageSystemName)?.withTintColor(annotionColor).rotate(radians: rotateDegrees)
                
                annotionView.image = image

                return annotionView
            case .receiver:
                let annotionView = MKAnnotationView(annotation: annotion, reuseIdentifier: nil)

                let image = UIImage(systemName: annotion.imageSystemName)?.withTintColor(.orange)

                annotionView.image = image

                return annotionView
            default:
                return nil
            }
            
        }
        
    }
}
