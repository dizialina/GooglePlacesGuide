//
//  MapPoint.m
//  GooglePlaces
//
//  Created by Admin on 12.05.16.
//  Copyright © 2016 Alina Egorova. All rights reserved.
//

#import "MapPoint.h"

@interface MapPoint()

@end

@implementation MapPoint

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate  {
    if ((self = [super init])) {
        _name = [name copy];
        _address = [address copy];
        _coordinate = coordinate;
        
    }
    return self;
}

- (NSString *)title {
    if ([_name isKindOfClass:[NSNull class]])
        return @"Unknown charge";
    else
        return _name;
}

- (NSString *)subtitle {
    return _address;
}

@end
