//
//  IBFirstViewController.h
//  iBabe
//
//  Created by David on 3/06/12.
//  Copyright (c) 2012 Sigmapps Application Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import "IBAppDelegate.h"
#import "IBEditEventViewController.h"
#import "SMImageUtl.h"


@interface IBDashBoardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>
{
    NSMutableArray *currentEvents;
	UIView* sharePopView;
}

@property (retain, nonatomic) IBOutlet UITableView *eventsList;
@property (retain, nonatomic) IBOutlet UIButton *btnShare;

// ---- For the count down days view
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxTopLeft;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxBottomLeft;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxTopRight;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxBottomRight;
@property (retain, nonatomic) IBOutlet UIImageView  *dayIdxTop;
@property (retain, nonatomic) IBOutlet UIImageView  *dayIdxBottom;
- (IBAction)didTapShareBtn:(id)sender;

// ---- For the post pregnant days view
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxTopLeftPregnant;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxBottomLeftPregnant;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxTopRightPregnant;
@property (retain, nonatomic) IBOutlet UIImageView  *weekIdxBottomRightPregnant;
@property (retain, nonatomic) IBOutlet UIImageView  *dayIdxTopPregnant;
@property (retain, nonatomic) IBOutlet UIImageView  *dayIdxBottomPregnant;

@property (retain, nonatomic) IBOutlet UIView   *dueDateCountDownSubView;
@property (retain, nonatomic) IBOutlet UIView   *pregnantDaysSubView;

@property (retain, nonatomic) IBOutlet UIPageControl *topViewPageControl;

@property (retain, nonatomic) IBOutlet UIScrollView *topScrollView;

- (IBAction)onTopViewChanged:(id)sender;

@end