/*
 * Copyright (c) 2010 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "EventKitDataSource.h"
#import <EventKit/EventKit.h>

static NSString* URL_ID = @"http://iBabe.sigmapps.com.au";
static BOOL IsDateBetweenInclusive(NSDate *date, NSDate *begin, NSDate *end)
{
	return [date compare:begin] != NSOrderedAscending && [date compare:end] != NSOrderedDescending;
}

@interface EventKitDataSource ()
- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate;
- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate;
@end

@implementation EventKitDataSource

+ (EventKitDataSource *)dataSource
{
	return [[[[self class] alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		eventStore = [[EKEventStore alloc] init];
		events = [[NSMutableArray alloc] init];
		items = [[NSMutableArray alloc] init];
		eventStoreQueue = dispatch_queue_create("com.sigmapps.iBabe", NULL);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventStoreChanged:) name:EKEventStoreChangedNotification object:nil];
	}
	return self;
}

- (void)eventStoreChanged:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:KalDataSourceChangedNotification object:nil];
}

- (EKEvent *)eventAtIndexPath:(NSIndexPath *)indexPath
{
	return [items objectAtIndex:indexPath.row];
}

#pragma mark UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"MyCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
	
	EKEvent *event = [self eventAtIndexPath:indexPath];
	cell.textLabel.text = event.title;
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [items count];
}

#pragma mark KalDataSource protocol conformance

+(NSMutableArray *)getCurrentEventsWithTopEventNumber:(NSInteger)numberOfEvents
{
    
    // --- The maximun months that the logic will go through get the events. 
    // --- This is to avoid the logic keep looping through the whole calendar unlimitly.
    // --- TODO: this should be able to setup from the config page.
    NSInteger maxLoopCount = 11;
    
    
	NSMutableArray *currentEvents = [[NSMutableArray alloc]init]; 
	EKEventStore *currentEventStore = [[EKEventStore alloc]init];
	
    NSInteger daysInSecond = 24 * 60 * 60;    
    NSDate* fromDate = [NSDate date];
	NSDate* toDate = [fromDate dateByAddingTimeInterval:daysInSecond*30 ];
    
	
    NSInteger eventCount = 0;
    NSPredicate *predicate;
    NSArray *matchedEvents;
    BOOL enoughEvent = NO;
    NSURL* stdUrl = [[NSURL alloc]initWithString: URL_ID];
    
    
    for (int currentLoop=0; !enoughEvent&&currentLoop<maxLoopCount; currentLoop++) {
        
        predicate = [currentEventStore predicateForEventsWithStartDate:fromDate endDate:toDate calendars:nil];
        matchedEvents = [currentEventStore eventsMatchingPredicate:predicate];
        
        
        for (EKEvent *anEvent in matchedEvents) {
            if(eventCount==numberOfEvents)
            {
                enoughEvent=YES;
                break;
            }
            
            
            if ([anEvent.URL isEqual: stdUrl])
            {
                [currentEvents addObject:anEvent];
                eventCount++;
            }
        }    
        
        fromDate = toDate;
        toDate = [toDate dateByAddingTimeInterval:daysInSecond*30 ];
    }
    
	[stdUrl release];
	
	return currentEvents;
}


+ (BOOL)createIBabeCalendar
{
	EKEventStore* eventStore = [[EKEventStore alloc]init];
	EKSource* locSource;
	
	// ---- Check if there is a local event source.
	for (EKSource* aSource in eventStore.sources) {
		if(aSource.sourceType == EKSourceTypeLocal)
		{
			locSource = aSource;
			break;
		}
	}
	
	// --- If local source not available then return nil.
	if(locSource==Nil)
		return NO;
	
	// --- Check if the iBabe Calendar exist or not.
	BOOL ibbCalExist = NO;
	
	NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
	
	NSString* calID = [userDefault objectForKey:USER_DEFAULT_CALENDAR_NAME];
	
	
	if (calID!=Nil)
	{
		for (EKCalendar* aCal in eventStore.calendars) {

			if ([aCal.title isEqualToString:CALENDAR_NAME])
			{
				ibbCalExist = YES;
				break;
			}
			
			if ([aCal.calendarIdentifier isEqualToString:calID])
			{
				ibbCalExist = YES;
				break;
			}
		}
	}
	
	
	if(!ibbCalExist)
	{
		EKCalendar* ibbCal = [EKCalendar calendarWithEventStore:eventStore];
		ibbCal.title = CALENDAR_NAME;
		ibbCal.source = locSource;
		calID = ibbCal.calendarIdentifier;
		
		NSError *err = Nil;
		BOOL calAdded = [eventStore saveCalendar:ibbCal commit:YES error:&err];
		
		if(calAdded)
		{
			// -- Add the calender identifier to the user defaults.
			[userDefault setObject:calID forKey:USER_DEFAULT_CALENDAR_NAME];
			return YES;
		}
		else {
			return NO;
		}
	}
	
	[eventStore release];
	
	return YES;
}



- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	// asynchronous callback on the main thread
	[events removeAllObjects];
	NSLog(@"Fetching events from EventKit between %@ and %@ on a GCD-managed background thread...", fromDate, toDate);
	dispatch_async(eventStoreQueue, ^{
		NSDate *fetchProfilerStart = [NSDate date];
		NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:fromDate endDate:toDate calendars:nil];
		NSArray *matchedEvents = [eventStore eventsMatchingPredicate:predicate];
		NSMutableArray *myEvents = [[NSMutableArray alloc]init]; 
		
		for (EKEvent *anEvent in matchedEvents) {
			if ([anEvent.title isEqualToString:@"book中医"])
			{
				[myEvents addObject:anEvent];
			}
		}
		
		
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"Fetched %d events in %f seconds", [myEvents count], -1.f * [fetchProfilerStart timeIntervalSinceNow]);
			[events addObjectsFromArray:myEvents];
			[delegate loadedDataSource:self];
		});
	});
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	// synchronous callback on the main thread
	return [[self eventsFrom:fromDate to:toDate] valueForKeyPath:@"startDate"];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	// synchronous callback on the main thread
	[items addObjectsFromArray:[self eventsFrom:fromDate to:toDate]];
}

- (void)removeAllItems
{
	// synchronous callback on the main thread
	[items removeAllObjects];
}

#pragma mark -

- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSMutableArray *matches = [NSMutableArray array];
	for (EKEvent *event in events)
		if (IsDateBetweenInclusive(event.startDate, fromDate, toDate))
			[matches addObject:event];
	
	return matches;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EKEventStoreChangedNotification object:nil];
	[items release];
	[events release];

	dispatch_sync(eventStoreQueue, ^{
		[eventStore release];
	});
	dispatch_release(eventStoreQueue);
	[super dealloc];
}

@end
