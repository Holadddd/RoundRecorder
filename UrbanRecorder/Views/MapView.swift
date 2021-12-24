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
    
    @Binding var userCurrentRegion: MKCoordinateRegion?
    
    @Binding var isUpdatedUserRegion: Bool
    
    var showsUserLocation: Bool
    
    @Binding var removeAnnotationItem: HomeMapAnnotation?
    
    @Binding var addAnnotationItem: HomeMapAnnotation
    
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
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
        if !isUpdatedUserRegion, let userCurrentRegion = userCurrentRegion {
            uiView.region = userCurrentRegion
            isUpdatedUserRegion.toggle()
        }
        
        if let removeAnnotationItem = removeAnnotationItem {
            uiView.removeAnnotation(removeAnnotationItem)
        }
        
        
        uiView.addAnnotation(addAnnotationItem)
        
        if !removeRoutes.isEmpty {
            for route in removeRoutes {
                uiView.removeOverlay(route.polyline)
            }
            
            removeRoutes.removeAll()
        }
        
        for route in displayRoutes {
            uiView.addOverlay(route.polyline)
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
            let annotionView = MKAnnotationView(annotation: annotion, reuseIdentifier: nil)

            let image = UIImage(systemName: annotion.imageSystemName)?.withTintColor(.red)

            annotionView.image = image

            return annotionView
        }
    }
}
