//
//  MultitouchModule.m
//  TiMultitouch
//
//  Created by masuidrive on 10/08/05.
//  Copyright 2010 Big Canvas Inc. All rights reserved.
//

#import "MultitouchModule.h"

#define DOUBLE_TAP_DELAY		0.35
#define HORIZ_SWIPE_DRAG_MIN	12
#define VERT_SWIPE_DRAG_MAX		4


@implementation MultitouchModule

#pragma mark Lifecycle

-(void)startup
{
	[super startup];
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	[super dealloc];
}

@end

@interface TiUIView (exists)
- (void)handleSwipeRight;
- (void)handleSwipeLeft;
- (void)handleDoubleTap;
- (void)handleTwoFingerTap;
@end


@implementation TiUIView (multitouch)



// TODO: Take a very close look at event handling.  Make sure that parent controls get the right messages.
// It's kind of broken for tables right now, but there are a couple
// hacks to get around it.
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSLog(@"touchesBegan:%d",[touches count]);
	UITouch *touch = [touches anyObject];
	
	if (handlesSwipes)
	{
		touchLocation = [touch locationInView:nil];
	}
	
	if (handlesTaps)
	{
		// cancel any pending handleSingleTap messages 
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSingleTap) object:nil];
		
		int count = [[event touchesForView:self] count];
		
		// update our touch state
		if (count > 1)
		{
			multipleTouches = YES;
		}
		if (count > 2)
		{
			twoFingerTapIsPossible = NO;
		}
	}
	
	if (handlesTouches)
	{
		NSMutableDictionary *evt = [NSMutableDictionary dictionaryWithDictionary:[TiUtils pointToDictionary:[touch locationInView:self]]];
		[evt setValue:[TiUtils pointToDictionary:[touch locationInView:nil]] forKey:@"globalPoint"];
		NSMutableArray *ts = [NSMutableArray arrayWithCapacity:10];
		for (UITouch* t in touches) {
			[ts addObject:[TiUtils pointToDictionary:[t locationInView:nil]]];
		}
		[evt setValue:ts forKey:@"points"];
		
		if ([proxy _hasListeners:@"touchstart"])
		{
			[proxy fireEvent:@"touchstart" withObject:evt propagate:YES];
			[self handleControlEvents:UIControlEventTouchDown];
		}
        
        // Click handling is special; don't propagate if we have a delegate,
        // but DO invoke the touch delegate.
		// clicks should also be handled by any control the view is embedded in.
		if ([touch tapCount] == 1 && [proxy _hasListeners:@"click"])
		{
			if (touchDelegate == nil) {
				[proxy fireEvent:@"click" withObject:evt propagate:YES];
			}
			else {
				[touchDelegate touchesBegan:touches withEvent:event];
			}
		}
		else if ([touch tapCount] == 2 && [proxy _hasListeners:@"dblclick"])
		{
			[proxy fireEvent:@"dblclick" withObject:evt propagate:YES];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSLog(@"touchesMoved:%d",[touches count]);
	UITouch *touch = [touches anyObject];
	if (handlesTouches)
	{
		NSMutableDictionary *evt = [NSMutableDictionary dictionaryWithDictionary:[TiUtils pointToDictionary:[touch locationInView:self]]];
		[evt setValue:[TiUtils pointToDictionary:[touch locationInView:nil]] forKey:@"globalPoint"];
		NSMutableArray *ts = [NSMutableArray arrayWithCapacity:10];
		for (UITouch* t in touches) {
			[ts addObject:[TiUtils pointToDictionary:[t locationInView:nil]]];
		}
		[evt setValue:ts forKey:@"points"];
		if ([proxy _hasListeners:@"touchmove"])
		{
			[proxy fireEvent:@"touchmove" withObject:evt propagate:YES];
		}
	}
	if (handlesSwipes)
	{
		CGPoint point = [touch locationInView:nil];
		// To be a swipe, direction of touch must be horizontal and long enough.
		if (fabsf(touchLocation.x - point.x) >= HORIZ_SWIPE_DRAG_MIN &&
			fabsf(touchLocation.y - point.y) <= VERT_SWIPE_DRAG_MAX)
		{
			// It appears to be a swipe.
			if (touchLocation.x < point.x)
			{
				[self handleSwipeRight];
			}
			else 
			{
				[self handleSwipeLeft];
			}
		}
	}
	
	if (touchDelegate!=nil)
	{
		[touchDelegate touchesMoved:touches withEvent:event];
	}
}

@end
