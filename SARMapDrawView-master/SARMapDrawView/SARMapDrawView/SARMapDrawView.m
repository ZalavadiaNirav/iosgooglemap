//
//  SARMapDrawView.m
//  SARMapDrawView
//
//  Created by Saravanan on 03/05/15.
//  Copyright (c) 2015 Saravanan. All rights reserved.
//

#import "SARMapDrawView.h"


@interface SARMapDrawView (){
    NSArray *_polys;
    NSMutableArray *polys;
    CGPoint lowestPoint;
    CGPoint leftMostPoint;
    CGPoint rightMostPoint;
    BOOL isInitiallyLoaded;//Used to draw polygons from database at its initial launch
    
    //    Zone
    NSInteger zoneId;
    NSString *zoneName;
    int selectedRegions;
    int unSelectedRegions;
}

@property(nonatomic,strong)SARMapDrawView *mapDrawView;

@end

@implementation SARMapDrawView
@synthesize mapView = mapView;
@synthesize polygons = polygons,removeDetailVw;

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self initialize];
}

-(void)initialize{
    isInitiallyLoaded = YES;
    self.coordinates = [NSMutableArray array];
    polygons = [NSArray array];
    _polys = [NSArray array];
    polys = [NSMutableArray array];

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:23.0281
                                                            longitude:72.5578
                                                                 zoom:18];//Hardcoding to some Location in Ahmedabad
    
    if (!mapView)
        mapView = [GMSMapView mapWithFrame:self.bounds camera:camera];
    mapView.camera = camera;
    mapView.delegate = self;
    mapView.mapType = kGMSTypeNormal;
    
    //to enable or disable my location button
    mapView.myLocationEnabled = YES;
    
    mapView.settings.myLocationButton = NO;

    
    //to hide google icon use to do padding
    mapView.padding = UIEdgeInsetsMake(0.0,0.0,0.0, 500.0);
    GMSUISettings * settings = mapView.settings;
    [settings setConsumesGesturesInView:NO];
//    mark=[[GMSMarker alloc] init];
    
}

#pragma mark - Other Methods
-(void)enableDrawing{
    self.isDrawingPolygon = YES;
    self.disableInteraction = YES;
    self.coordinates = [NSMutableArray array];

}

-(void)disableDrawing{
    self.isDrawingPolygon = NO;
    self.disableInteraction = NO;
    self.coordinates = nil;
}

-(void)changeUserInteraction{
    if (self.disableInteraction) {
        self.mapView.userInteractionEnabled = NO;
    }
    else{
        self.mapView.userInteractionEnabled = YES;
    }
}

#pragma mark - Polygon Methods
-(void)removeSelectedPolygon{
    NSMutableArray *polygonsArray = [NSMutableArray arrayWithArray:self.polygons];
    for (GMSPolygon *polygon in self.polygons){
        if (polygon == self.polygon) {
            [polygonsArray removeObject:polygon];
            break;
        }
    }
    self.polygons = polygonsArray;
}

-(void)handleCoordinate:(CLLocationCoordinate2D)coordinate{
    GMSPolyline *polyLine = [self.mapView addCoordinate:coordinate replaceLastObject:NO inCoordinates:self.coordinates];
    if (polyLine) {
        self.polyLine = polyLine;
        [polys addObject:polyLine];
        _polys = polys;
    }
    
}

-(void)drawPolygon{
    //    return;
    NSInteger numberOfPoints = [self.coordinates count];
    
    //        Removing the last drawn polygon
    //    self.polygon.map = nil;
    
    
    
    for (GMSPolyline *poly in _polys) {
        poly.map = nil;
    }
    
    
    GMSPolygon *polygon = [[GMSPolygon alloc] init];
    GMSMutablePath *path = [GMSMutablePath path];

    CLLocationCoordinate2D points[numberOfPoints];
    for (NSInteger i = 0; i < numberOfPoints; i++)
    {
        SARCoordinate *coordinateObject = self.coordinates[i];
        points[i] = coordinateObject.coordinate;
        
        [path addCoordinate:coordinateObject.coordinate];

        
    //All points lat-long here
        NSLog(@"lat %f  - long %f",points[i].latitude,points[i].longitude);
        
    }
    
    
    polygon.path = path;
            polygon.title = @"New York";
    
    //change selected region color here
    
    polygon.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:0.2f];
    polygon.strokeColor = [UIColor redColor];
    polygon.strokeWidth = 4;
    polygon.tappable = YES;
    
    polygon.map = mapView;
    
    self.polygon = polygon;
    
    NSMutableArray *polygonsArray = [NSMutableArray arrayWithArray:polygons];
    [polygonsArray addObject:polygon];
    polygons = polygonsArray;
    
    NSLog(@"numberOfPoints: %lu ", numberOfPoints);
    
//    //mapview preserve Location
    _mapframe=mapView.frame;

    //add Pin or GMSMarker
    for (int i=0; i<numberOfPoints; i++)
    {
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(points[i].latitude,points[i].longitude);
        GMSMarker *mark = [GMSMarker markerWithPosition:position];
        mark.groundAnchor = CGPointMake(0.5, 0.5);
        mark.title=[NSString stringWithFormat:@"Pin %d",i];
        mark.snippet = @"Detail of Marker here";

        mark.map = mapView;
        NSLog(@"polygons.count: %lu", polygons.count);
        
        
    }
    
    
    // and if we had a previous polyline, let's remove it
    
    if (self.polyLine)
        self.polyLine.map = nil;
    
    if (self.polygonDrawnBlock) {
        self.polygonDrawnBlock(self.polygon);
    }
    
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    //setting map frame to orignal map position
    self.mapView.frame=_mapframe;
    self.mapView.selectedMarker=marker;
    return YES;
}


- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    //Open detail view with animation
    NSLog(@"DID tap");
    
    //Marker DetailView
        [UIView animateWithDuration:1.0 animations:^{
       _markerDetailVw=[[UIView alloc] initWithFrame:CGRectMake(0, 540, 320, 320)];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_markerDetailVw cache:NO];
        [UIView beginAnimations:@"animate" context:nil];
        _markerDetailVw.frame=CGRectMake(0, 318, 320, 250);
        _markerDetailVw.tag=100;
        _markerDetailVw.backgroundColor=[UIColor blackColor];
        [self.mapView addSubview:_markerDetailVw];
            [UIView commitAnimations];
        }];
    
    //To Dismiss Marker DetailView
    
        removeDetailVw = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [removeDetailVw setFrame:CGRectMake(0, 0, 320, 318)];
        [removeDetailVw setBackgroundColor: [UIColor clearColor]];
        [removeDetailVw addTarget:self action:@selector(removeMarkerDetailView:)
        forControlEvents:UIControlEventTouchUpInside];
        [self.mapView addSubview:removeDetailVw];
   
}

-(void)removeMarkerDetailView:(id)sender
{
    [_markerDetailVw removeFromSuperview];
    [removeDetailVw removeFromSuperview];

}

#pragma mark - Calculation Methods
-(void)resetPoints
{
    lowestPoint = CGPointMake(0, 0);
    leftMostPoint = CGPointMake(2000, 2000);//Keeping it to the Max on the Right. 2000, since no iOS device crossed this (In Points)
    rightMostPoint = CGPointMake(0, 0);
}

-(NSArray*)coordinatesForCurrentPolygon{
    return self.polygon.coordinates;
}

-(void)calculatePoints:(BOOL)moveCamera{
    CGPoint lowestPoint_local = CGPointMake(0, 0);
    CGPoint leftMostPoint_local = CGPointMake(2000, 2000);
    CGPoint rightMostPoint_local = CGPointMake(0, 0);
    
    NSArray *coordinates = [self coordinatesForCurrentPolygon];
    if (coordinates.count > 0) {
        for (SARCoordinate *Coordinate_local in coordinates){
            CGPoint pointForCoordinate = [mapView.projection pointForCoordinate:Coordinate_local.coordinate];
            if (pointForCoordinate.y > lowestPoint_local.y) {
                lowestPoint_local = pointForCoordinate;
            }
            if (pointForCoordinate.x < leftMostPoint_local.x) {
                leftMostPoint_local = pointForCoordinate;
            }
            if (pointForCoordinate.x > rightMostPoint_local.x) {
                rightMostPoint_local = pointForCoordinate;
            }
        }
        
        lowestPoint = lowestPoint_local;
        leftMostPoint = leftMostPoint_local;
        rightMostPoint = rightMostPoint_local;
    }
    
    
//    if (moveCamera) {
////        [self moveCamera];
//    }
    
}

#pragma mark - Animation Methods
-(void)scrollMapUpToValue:(CGFloat)yValue{
    
    [mapView animateWithCameraUpdate:[GMSCameraUpdate scrollByX:0 Y:yValue]];
}

-(void)scrollMapDownToValue:(CGFloat)yValue{
    [mapView animateWithCameraUpdate:[GMSCameraUpdate scrollByX:0 Y:-yValue]];
}

#pragma mark - GMSMapView Delegates
- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position{
    [self calculatePoints:NO];
    
    if (self.MapViewIdleAtCameraPositionBlock) {
        self.MapViewIdleAtCameraPositionBlock(position);
    }

}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay
{
    NSLog(@"DID tap overlay");
    for (GMSPolygon *polygon in self.polygons)
    {
        if (polygon == overlay)
        {
            self.polygon = polygon;//Assigning the selected polygon here
            if (self.MapViewDidTapOverlayBlock)
            {
                self.MapViewDidTapOverlayBlock(polygon);
            }
            break;
        }
    }
    
}



#pragma mark - UITouches Delegates
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    NSLog(@"Touch began");
//    [_markerDetailVw removeFromSuperview];
    [self resetPoints];
    
    
    if (self.disableInteraction){
        self.disableInteraction = !self.disableInteraction;
        return;
    }
    
    if (!self.isDrawingPolygon)
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView.projection coordinateForPoint:location];
    
    [self handleCoordinate:coordinate];
    
    lowestPoint = location;
    leftMostPoint = location;
    rightMostPoint = location;
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.isDrawingPolygon) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView.projection coordinateForPoint:location];
    
    [self handleCoordinate:coordinate];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    //    NSLog(@"touchesEnded");
    if (!self.isDrawingPolygon)
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView.projection coordinateForPoint:location];
    
    [self handleCoordinate:coordinate];
    
    NSInteger numberOfPoints = [self.coordinates count];
    NSLog(@"touchesEnded: numberOfPoints: %lu", numberOfPoints);
        
    if (self.isDrawingPolygon) {
        
        //my code 2l
        
        [self resetPoints];
        [self removeSelectedPolygon];
        
        NSLog(@"my count polygon %lu -------------- %@",(unsigned long)polygons.count,[polygons description]);
        
        
        [self drawPolygon];
        [self calculatePoints:NO];
    }

}

#pragma mark - Setters
-(void)setDisableInteraction:(BOOL)disableInteraction{
    _disableInteraction = disableInteraction;
    [self changeUserInteraction];
    if (disableInteraction == NO) {
        if (self.ViewEnabledBlock) {
            self.ViewEnabledBlock();
        }
    }
}

@end
