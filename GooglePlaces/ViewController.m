//
//  ViewController.m
//  GooglePlaces
//
//  Created by Admin on 12.05.16.
//  Copyright © 2016 Alina Egorova. All rights reserved.
//

#import "ViewController.h"
#import <GoogleMaps/GoogleMaps.h>

#define kGOOGLE_API_KEY @"AIzaSyBs0VqrJaA1Ikj8P_VA5Zzcrpg4sbmS0ek"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface ViewController () {
    
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    CLLocationCoordinate2D currentCentre;
    CLLocationCoordinate2D selectedPoint;
    int currenDist;
    NSString *selectedPlaceID;
    NSArray *results;
    MKDirections *directions;
    
    GMSPlacesClient *placesClient;
    GMSPlacePicker *placePicker;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    [self.mapView setShowsUserLocation:YES];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
    
    NSLog(@"%@", locationManager.location);
    
    placesClient = [[GMSPlacesClient alloc] init];
    
    [self getCurrentPlace];
    
    selectedPoint = kCLLocationCoordinate2DInvalid;
    
    
}

- (void)getCurrentPlace {
    
    [placesClient currentPlaceWithCallback:^(GMSPlaceLikelihoodList *placeLikelihoodList, NSError *error){
        if (error != nil) {
            NSLog(@"Pick Place error %@", [error localizedDescription]);
            return;
        }
        
        //self.nameLabel.text = @"No current place";
        //self.addressLabel.text = @"";
        
        if (placeLikelihoodList != nil) {
            GMSPlace *place = [[[placeLikelihoodList likelihoods] firstObject] place];
            if (place != nil) {
                //self.nameLabel.text = place.name;
                //self.addressLabel.text = [[place.formattedAddress componentsSeparatedByString:@", "] componentsJoinedByString:@"\n"];
                NSLog(@"%@", place.name);
                NSLog(@"%@", [[place.formattedAddress componentsSeparatedByString:@", "] componentsJoinedByString:@"\n"]);
            }
        }
    }];
}

- (void)pickPlace {
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(37.78583400, -122.40641700);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(center.latitude + 0.001,
                                                                  center.longitude + 0.001);
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(center.latitude - 0.001,
                                                                  center.longitude - 0.001);
    GMSCoordinateBounds *viewport = [[GMSCoordinateBounds alloc] initWithCoordinate:northEast
                                                                         coordinate:southWest];
    GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:viewport];
    placePicker = [[GMSPlacePicker alloc] initWithConfig:config];
    
    [placePicker pickPlaceWithCallback:^(GMSPlace *place, NSError *error) {
        if (error != nil) {
            NSLog(@"Pick Place error %@", [error localizedDescription]);
            return;
        }
        
        if (place != nil) {
            //self.nameLabel.text = place.name;
            //self.addressLabel.text = [[place.formattedAddress componentsSeparatedByString:@", "] componentsJoinedByString:@"\n"];
            NSLog(@"%@", place.name);
            NSLog(@"%@", [[place.formattedAddress componentsSeparatedByString:@", "] componentsJoinedByString:@"\n"]);
            NSLog(@"Place attributions %@", place.attributions.string);
            NSLog(@"Place ID: %@", place.placeID);
            
            selectedPlaceID = place.placeID;
            MapPoint *point = [[MapPoint alloc] initWithName:place.name address:place.formattedAddress coordinate:place.coordinate];
            [self.mapView addAnnotation:point];

        } else {
            //self.nameLabel.text = @"No place selected";
            //self.addressLabel.text = @"";
        }
    }];
}

- (void)receiveInformationByPlaceID:(NSString*)placeID {
    
    [placesClient lookUpPlaceID:placeID callback:^(GMSPlace *place, NSError *error) {
        if (error != nil) {
            NSLog(@"Place Details error %@", [error localizedDescription]);
            return;
        }
        
        if (place != nil) {
            NSLog(@"Place name %@", place.name);
            NSLog(@"Place address %@", place.formattedAddress);
            NSLog(@"Place placeID %@", place.placeID);
            NSLog(@"Place attributions %@", place.attributions);
        } else {
            NSLog(@"No place details for %@", placeID);
        }
    }];
    
}

- (void)receivePointsBySearchStringExample {
    
    // https://maps.googleapis.com/maps/api/place/textsearch/output?parameters
    // https://maps.googleapis.com/maps/api/place/textsearch/xml?query=restaurants+in+Sydney&key=YOUR_API_KEY
    
    //parameters: location, radius, minprice и maxprice, opennow, types (or many types type1|type2|и т.д.)
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)queryGooglePlaces:(NSString *)googleType {
    
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=%@&types=%@&sensor=true&key=%@", currentCentre.latitude, currentCentre.longitude, [NSString stringWithFormat:@"%i", currenDist], googleType, kGOOGLE_API_KEY];
    
    NSLog(@"%@", url);
    
    NSURL *googleRequestURL = [NSURL URLWithString:url];
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                          options:kNilOptions
                          error:&error];
    
    results = [json objectForKey:@"results"];
    
    //NSLog(@"Google Data: %@", places);
    
    [self plotPositions:results];
}

-(void)plotPositions:(NSArray *)data {
    
    // Remove any existing custom annotations but not the user location blue dot.
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MapPoint class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    // Loop through the array of places returned from the Google API.
    for (int i = 0; i < [data count]; i++) {
        
        NSDictionary* place = [data objectAtIndex:i];
        
        NSDictionary *geo = [place objectForKey:@"geometry"];
        NSDictionary *loc = [geo objectForKey:@"location"];
        
        NSString *name = [place objectForKey:@"name"];
        NSString *vicinity = [place objectForKey:@"vicinity"];

        CLLocationCoordinate2D placeCoord;

        placeCoord.latitude = [[loc objectForKey:@"lat"] doubleValue];
        placeCoord.longitude = [[loc objectForKey:@"lng"] doubleValue];
        
        //Create a new annotation.
        MapPoint *placeObject = [[MapPoint alloc] initWithName:name address:vicinity coordinate:placeCoord];
        [self.mapView addAnnotation:placeObject];
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
    
    currenDist = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);
    
    currentCentre = self.mapView.centerCoordinate;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    /*
    MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
    point.coordinate = userLocation.coordinate;
    point.title = @"Hello world!";
    point.subtitle = @"Hello again";
    [self.mapView addAnnotation:point];
    */
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    /*
    if (annotation == mapView.userLocation) {
        
        MKPinAnnotationView *annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        annView.pinTintColor = [UIColor blueColor];
        annView.animatesDrop = YES;
        annView.canShowCallout = YES;
        annView.calloutOffset = CGPointMake(-5, 5);
        return annView;
    }
    
    return nil;
    */
    
    static NSString *identifier = @"MapPoint";
    
    if ([annotation isKindOfClass:[MapPoint class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [infoButton addTarget:self action:@selector(showDetailInfo:) forControlEvents:UIControlEventTouchUpInside];
        annotationView.rightCalloutAccessoryView = infoButton;
        
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKPinAnnotationView *)view  {
    
    view.highlighted = YES;
    view.pinTintColor = UIColor.blueColor;

    MapPoint *selectedView = (MapPoint *)view.annotation;
    selectedPoint.latitude = selectedView.coordinate.latitude;
    selectedPoint.longitude = selectedView.coordinate.longitude;
    NSLog(@"Annotation was clicked. Coordinate: \n latitude: %f, \n longtitude: %f", selectedView.coordinate.latitude, selectedView.coordinate.longitude);
    
    for (NSDictionary *place in results) {
        NSString *name = [place objectForKey:@"name"];
        if ([name isEqualToString:selectedView.title]) {
            selectedPlaceID = [place objectForKey:@"place_id"];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKPinAnnotationView *)view {
    view.pinTintColor = UIColor.redColor;
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        renderer.lineWidth = 2.f;
        renderer.strokeColor = UIColor.redColor;
        return renderer;
    }
    return nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    currentLocation = [locations lastObject];
    //NSLog(@"%@", currentLocation);
}

#pragma mark - Actions

- (IBAction)toolBarButtonPress:(id)sender {
    
    [self.mapView removeOverlays:[self.mapView overlays]];
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    NSString *buttonTitle = [button.title lowercaseString];
    [self queryGooglePlaces:buttonTitle];
    
}

- (IBAction)zoomWithSelectedPoint:(id)sender {
    
    if (CLLocationCoordinate2DIsValid(selectedPoint)) {
        
        MKMapRect zoomRect = MKMapRectNull;
        MKMapPoint center = MKMapPointForCoordinate(currentLocation.coordinate);
        MKMapPoint selected = MKMapPointForCoordinate(selectedPoint);
        static double delta = 200;
        MKMapRect userLocationRect = MKMapRectMake(center.x - delta, center.y - delta, delta * 2, delta * 2);
        MKMapRect selectedPointRect = MKMapRectMake(selected.x - delta, selected.y - delta, delta * 2, delta * 2);
        zoomRect = [self.mapView mapRectThatFits:MKMapRectUnion(userLocationRect, selectedPointRect)];
        [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(20, 20, 20, 20) animated:YES];
    
        CLLocationDistance distance = MKMetersBetweenMapPoints(center, selected);
        NSLog(@"Distance between two points: %f", distance);
    }
    
    
}

- (IBAction)showWayToSelectedPoint:(id)sender {
    
    if (CLLocationCoordinate2DIsValid(selectedPoint)) {
        
        MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
        MKPlacemark *fromPoint = [[MKPlacemark alloc] initWithCoordinate:currentLocation.coordinate addressDictionary:nil];
        request.source = [[MKMapItem alloc] initWithPlacemark:fromPoint];
        MKPlacemark *toPoint = [[MKPlacemark alloc] initWithCoordinate:selectedPoint addressDictionary:nil];
        request.destination = [[MKMapItem alloc] initWithPlacemark:toPoint];
    
        request.transportType = MKDirectionsTransportTypeAutomobile;
        request.requestsAlternateRoutes = YES;
    
        if ([directions isCalculating]) {
            [directions cancel];
        }
        
        directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
            
        
            if (error) {
                NSLog(@"Error calculating directions: %@", [error localizedDescription]);
            } else if ([response.routes count] == 0) {
                NSLog(@"No routes found");
            } else {
                [self.mapView removeOverlays:[self.mapView overlays]];
                NSMutableArray *routes = [[NSMutableArray alloc] init];
                for (MKRoute *route in response.routes) {
                    [routes addObject:route.polyline];
                }
                [self.mapView addOverlays:routes level:MKOverlayLevelAboveRoads];
            }
        }];
        
    }    
    
}

- (IBAction)showGoogleWidget:(id)sender {
    [self pickPlace];
}

- (void)showDetailInfo:(UIButton *)sender {
    NSLog(@"%@", selectedPlaceID);
    
    [placesClient lookUpPlaceID:selectedPlaceID callback:^(GMSPlace *place, NSError *error) {
        if (error != nil) {
            NSLog(@"Place Details error %@", [error localizedDescription]);
            return;
        }
        
        if (place != nil) {
            
            NSMutableString *info = [[NSMutableString alloc] init];
            [info appendString:[NSString stringWithFormat:@"Place address: %@\n", place.formattedAddress]];
            [info appendString:@"Is open now: "];
            switch (place.openNowStatus) {
                case kGMSPlacesOpenNowStatusYes: {
                    [info appendString:@"Yes\n"];
                }
                case kGMSPlacesOpenNowStatusNo: {
                    [info appendString:@"No\n"];
                }
                case kGMSPlacesOpenNowStatusUnknown: {
                    [info appendString:@"No info\n"];
                }
            }
            [info appendString:[NSString stringWithFormat:@"Phone number: %@\n", place.phoneNumber]];
            [info appendString:[NSString stringWithFormat:@"Rating (1-5): %0.2f\n", place.rating]];
            [info appendString:[NSString stringWithFormat:@"Website: %@\n", place.website]];
            
            UIAlertController *vc = [UIAlertController alertControllerWithTitle:place.name message:info preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
            [vc addAction:okAction];
            [self presentViewController:vc animated:YES completion:nil];
            
        } else {
            NSLog(@"No place details for %@", selectedPlaceID);
        }
    }];

}

- (void)dealloc {
    if ([directions isCalculating]) {
        [directions cancel];
    }
}

@end


