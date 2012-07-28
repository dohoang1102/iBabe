//
//  IBEventLocationMapViewController.m
//  iBabe
//
//  Created by David Liang on 28/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IBEventLocationMapViewController.h"
#import "IBEventDetailsViewController.h"

#define METERS_PER_MILE 1609.344



@interface IBEventLocationMapViewController ()

@end

@implementation IBEventLocationMapViewController
@synthesize mapEventLocation,location;





#pragma mark- UI Action Functions
-(void) initNavigationBar
{
    UIBarButtonItem* btnShowMe = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:100 target:self action:@selector(btnShowMyLocationPressed:)];
    
    
    UIBarButtonItem* btnShowTarget = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(btnShowTargetLocationPressed:)];
    
    NSMutableArray* rightBtns = [[NSMutableArray alloc]initWithCapacity:2];
    [rightBtns addObject:btnShowMe];
    [rightBtns addObject:btnShowTarget];
    
    [[self navigationItem] setRightBarButtonItems:rightBtns];
    
	
	[btnShowMe release];
	[btnShowTarget release];
	[rightBtns release];
}



- (IBAction)btnShowMyLocationPressed:(id)sender {
    
    [mapEventLocation setCenterCoordinate:mapEventLocation.userLocation.coordinate animated:YES];
}

- (IBAction)btnShowTargetLocationPressed:(id)sender {
    [mapEventLocation setCenterCoordinate:locationCoord animated:YES];
}



#pragma mark- MKMap Delegate


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([mapEventLocation showsUserLocation]) {  
        
    }
    
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    //MKPinAnnotationView *annView = nil;
    
    MKAnnotationView* annView = nil;
    static NSString* defaultPinID = @"com.sigmapps.iBabe.defPin";
    static NSString* userLocationPinID = @"com.sigmapps.iBabe.userLocPin";
    
    if (annotation!= mapEventLocation.userLocation)
    {
        
        
        annView = (MKPinAnnotationView*)[mapEventLocation dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        
        //annView = (MKAnnotationView*)[mapEventLocation dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        
        if (annView==nil)
        {
            annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        }
        
        
        //--- Add a right arrown icon on the title box for clicking. 
        annView.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoLight];
        annView.image = [UIImage imageNamed:@"pin-yellow.png"];
        
        
    }
    else {
        annView = (MKPinAnnotationView*)[mapEventLocation dequeueReusableAnnotationViewWithIdentifier:userLocationPinID];
        
        if (annView==nil)
        {
            annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:userLocationPinID];
        }
        
        
        //--- Add a right arrown icon on the title box for clicking. 
        annView.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoLight];
        annView.image = [UIImage imageNamed:@"pin-green.png"];
        [mapEventLocation.userLocation setTitle:@"Your're Here."];
    }
    
    annView.canShowCallout = YES;
    annView.draggable = NO;
    
    return annView;
    
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    //  NSLog(@"Call out tapped");
}





#pragma mark- View Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    mapEventLocation.delegate = self;
    
    [mapEventLocation.userLocation addObserver:self forKeyPath:@"location" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    
    mapEventLocation.showsUserLocation = YES;
    
    [self initNavigationBar];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if(![location isEqualToString:@""])
    {
        locationCoord = [SMMapUtil getLocationFromAddressString:location];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(locationCoord, METERS_PER_MILE, METERS_PER_MILE);
        
        // --- Set up the annotation.
        MKPointAnnotation* annotation = [[[MKPointAnnotation alloc]init]autorelease];
        annotation.coordinate = locationCoord;
        annotation.title = location;
        // annotation.subtitle = @"Get direction - Tab the 'i' icon.";
        
        [mapEventLocation addAnnotation:annotation];
        
        MKCoordinateRegion adjRegion = [mapEventLocation regionThatFits:region];
        [mapEventLocation setRegion:adjRegion animated:YES];
    }
}



- (void)viewDidUnload
{
    [self setMapEventLocation:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)dealloc {
    [mapEventLocation release];
    [super dealloc];
}
@end
