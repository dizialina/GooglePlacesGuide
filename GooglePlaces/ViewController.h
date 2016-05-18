//
//  ViewController.h
//  GooglePlaces
//
//  Created by Admin on 12.05.16.
//  Copyright © 2016 Alina Egorova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MapPoint.h"

@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)toolBarButtonPress:(id)sender;
- (IBAction)zoomWithSelectedPoint:(id)sender;
- (IBAction)showWayToSelectedPoint:(id)sender;
- (IBAction)showGoogleWidget:(id)sender;

@end

