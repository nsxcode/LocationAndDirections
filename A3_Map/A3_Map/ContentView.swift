//
//  ContentView.swift
//  A3_Map
//
//  Created by Natalie Sahadeo on 2021-11-09.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State var firstStop = ""
    @State var secondStop = ""
    @State var finalDestination = ""
    @State var locEnterdText: String = ""
    @State var direction = 0
    @State var location: CLLocationCoordinate2D?
    @State var toggleDirections = false
    
    struct Location : Identifiable{
        let id = UUID()
        let name : String
        let coordinate : CLLocationCoordinate2D
    }

    struct RouteSteps : Identifiable{
        let id = UUID()
        let step : String
    }

    @State var routeSteps : [RouteSteps] = [
        RouteSteps(step: "Directions")
    ]

    @State var annotations = [
        Location(name: "Empire State Building", coordinate: CLLocationCoordinate2D(latitude: 40.748440, longitude: -73.985664))
    ]

    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: CLLocationManager().location!.coordinate.latitude, longitude: CLLocationManager().location!.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    var body: some View {
        ZStack{
            Image("palepink")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            ScrollView{
            VStack{
                Section{
                    Text("Assignment 3").font(.headline)
                    Text("Please enter your first stop")
                    TextField("First Stop", text: $firstStop).background(Color.white) .textFieldStyle(.roundedBorder) .padding(.vertical, 10)
                            .padding(.horizontal, 99)
                    
                    Text("Please enter your second stop")
                    TextField("Second Stop", text: $secondStop).background(Color.white) .textFieldStyle(.roundedBorder) .padding(.vertical, 10)
                            .padding(.horizontal, 99)

                    Text("Please enter your final destination")
                    TextField("Final Destination", text: $finalDestination).background(Color.white) .textFieldStyle(.roundedBorder) .padding(.vertical, 10)
                            .padding(.horizontal, 99)
                    
                    //Show Map
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations){
                        item in MapPin(coordinate: item.coordinate)
                    }.ignoresSafeArea().accentColor(Color(.systemPink)).frame(width: 300, height: 300, alignment: .center).onAppear{viewModel.checkIfLocationServiceIsEnabled()}.padding(.vertical, 25)
                    
                    Section{
                        Text("Choose a direction: ")
                    Picker(selection: $direction, label: Text("Choose a direction: ")) {
                        Text("Start to Stop 1 to Stop 2 to Final Destination").tag(0).font(.subheadline)
                        Text("Start to Stop 1 ").tag(1).font(.subheadline)
                        Text("Stop 1 to Stop 2").tag(2).font(.subheadline)
                    }.pickerStyle(InlinePickerStyle()).border(Color.white).frame(width: 100, height: 100, alignment: .center).padding(.vertical, 25).accentColor(Color.pink)}
                        
                    Button(action: {
                        toggleDirections = true
                        //If picker is set to the first option
                        if(direction == 0){
                            routeSteps = []
                            //Source to first
                            let sourceLoc = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationManager().location!.coordinate.latitude, longitude: CLLocationManager().location!.coordinate.longitude))
                            findNewLocation(locEntered: firstStop, source: sourceLoc)

                            self.getLocation(from: firstStop) { coordinates in
                                self.location = coordinates
                                findNewLocation(locEntered: secondStop, source: MKPlacemark(coordinate: coordinates!))
                                //second to final
                                self.getLocation(from: secondStop){
                                    coordinate2 in
                                    self.location = coordinate2
                                    findNewLocation(locEntered: finalDestination, source: MKPlacemark(coordinate: coordinate2!))

                                }
                            }
                        }
                     
                        if(direction == 1){
                            routeSteps.removeAll()
                            //Start to Stop 1
                            let sourceLoc = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationManager().location!.coordinate.latitude, longitude: CLLocationManager().location!.coordinate.longitude))
                            findNewLocation(locEntered: firstStop, source: sourceLoc)
                        }
                      
                        if(direction == 2){
                            //Stop 1 to Stop 2
                            //Start to first
                            routeSteps.removeAll()
                            routeSteps = []
                            self.getLocation(from: firstStop) { coordinates in
                                self.location = coordinates // Assign to a local variable for further processing
                                findNewLocation(locEntered: secondStop, source: MKPlacemark(coordinate: coordinates!))
                            }}

                        
                    }){Text("Get Directions")}.sheet(isPresented: $toggleDirections, content: {
                        VStack(spacing: 0) {
                          Text("Directions")
                            .font(.largeTitle)
                            .bold()
                            .padding()

                          Divider().background(Color(UIColor.systemBlue))
                            List(routeSteps){r in Text(r.step)}
                          }
                        }

                   ).frame(width: 129, height: 54, alignment: .center)
                        .font(.headline)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.pink)).foregroundColor(Color.white)
                }
            }
    
            }
        }
}

  
    //Get the location coordinates
    func getLocation(from enteredLocation: String, completion: @escaping (_ location: CLLocationCoordinate2D?)-> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(enteredLocation) { (placemarks, error) in
            guard let placemarks = placemarks,
                  let location = placemarks.first?.location?.coordinate else {
                completion(nil)
                return
            }
            completion(location)
        }
    }

    func findNewLocation(locEntered:String, source:MKPlacemark){
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locEntered, completionHandler: {
            //placemarks is an array
            (placemarks, error) -> Void in
            if(error != nil){
                print("Error")
            }
            //going to take the first item from list
            if let placemark  = placemarks?[0]{
                let coordinates : CLLocationCoordinate2D =
                        placemark.location!.coordinate

                annotations.append(Location(name: placemark.name!, coordinate: placemark.location!.coordinate))
                print("Count: \(annotations.endIndex)")
                print(type(of: placemark))


                region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))


                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate.self))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
                request.requestsAlternateRoutes = false
                request.transportType = .automobile

                let directions = MKDirections(request: request)
                //still have to do a loop even though its gonna show one result since we set alternative routes to false
                directions.calculate(completionHandler: {response, error in
                    for route in (response?.routes)!{
                        for step in route.steps {
                            routeSteps.append(RouteSteps(step: step.instructions))
                        }
                    }
                }
                )
            }
        }
        )}
    
    
    //For accessing the location permissions
    final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
        var locationManager : CLLocationManager?
        func checkIfLocationServiceIsEnabled(){

            if CLLocationManager.locationServicesEnabled(){
                locationManager = CLLocationManager()
                locationManager!.delegate = self

            } else{
                print("Location is off")
            }
        }
        private func checkLocationAuthorization(){
            guard let locationManager = locationManager else {
                return
            }
            switch locationManager.authorizationStatus{

            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Location is restricted")
            case .denied:
                print("Location denied")
            case .authorizedAlways,.authorizedWhenInUse:
                break
            @unknown default:
                break
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            checkLocationAuthorization()
        }


    }



}
