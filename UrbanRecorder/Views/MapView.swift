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
    
    static let firstSetupCoordinateDistance: CLLocationDistance = 1000
    #warning("Calculate the real needed distance")
    static let fileRouteDisplayCoordinateDistance: CLLocationDistance = 1000
    
    @Binding var isSetupCurrentLocation: Bool
    
    @Binding var userCurrentMapCamera: MKMapCamera?
    
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
        mapView.showsCompass = true
        mapView.showsTraffic = false
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // MARK: Setup camera vision
        if !isSetupCurrentLocation, let userCurrentLocation = uiView.userLocation.location?.toCLLocationCoordinate2D {
            // first user vision
            isSetupCurrentLocation.toggle()
            uiView.camera.centerCoordinate = userCurrentLocation
            uiView.camera.centerCoordinateDistance = MapView.firstSetupCoordinateDistance
        } else if updateByMapItem , let userCurrentMapCamera = userCurrentMapCamera {
            // Udpate by item (ex: routes, annotation...)
            updateByMapItem.toggle()
            uiView.camera = userCurrentMapCamera
            uiView.camera.centerCoordinateDistance = MapView.fileRouteDisplayCoordinateDistance
        } else if isLocationLocked, let userCurrentLocation = uiView.userLocation.location?.toCLLocationCoordinate2D {
            // Lock user vision with current location
            uiView.camera.centerCoordinate = userCurrentLocation
            uiView.camera.heading = headingDirection
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

                let image = UIImage(systemName: annotion.imageSystemName)
                
                annotionView.image = image
                // TODO:  Fix the tint color on annotation
                annotionView.image?.withTintColor(.red, renderingMode: .alwaysTemplate)
                
                return annotionView
            default:
                return nil
            }
            
        }
        
    }
}
