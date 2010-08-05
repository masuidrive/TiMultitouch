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
		NSMutableDictionary *ts = [NSMutableDictionary dictionary];
		for (UITouch* t in touches) {
			[ts setObject:[TiUtils pointToDictionary:[t locationInView:nil]] forKey:[NSString stringWithFormat:@"%p",t]];
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
		NSMutableDictionary *ts = [NSMutableDictionary dictionary];
		for (UITouch* t in touches) {
			[ts setObject:[TiUtils pointToDictionary:[t locationInView:nil]] forKey:[NSString stringWithFormat:@"%p",t]];
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


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (handlesTaps)
	{
		BOOL allTouchesEnded = ([touches count] == [[event touchesForView:self] count]);
		
		// first check for plain single/double tap, which is only possible if we haven't seen multiple touches
		if (!multipleTouches) 
		{
			UITouch *touch = [touches anyObject];
			tapLocation = [touch locationInView:self];
			
			if ([touch tapCount] == 1) 
			{
				[self performSelector:@selector(handleSingleTap) withObject:nil afterDelay:DOUBLE_TAP_DELAY];
			} 
			else if([touch tapCount] == 2) 
			{
				[self handleDoubleTap];
			}
		}    
		
		// check for 2-finger tap if we've seen multiple touches and haven't yet ruled out that possibility
		else if (multipleTouches && twoFingerTapIsPossible) 
		{ 
			
			// case 1: this is the end of both touches at once 
			if ([touches count] == 2 && allTouchesEnded) 
			{
				int i = 0; 
				int tapCounts[2] = {0,0}; 
				CGPoint tapLocations[2];
				for (UITouch *touch in touches) {
					tapCounts[i]    = [touch tapCount];
					tapLocations[i] = [touch locationInView:self];
					i++;
				}
				if (tapCounts[0] == 1 && tapCounts[1] == 1) 
				{ 
					// it's a two-finger tap if they're both single taps
					tapLocation = midpointBetweenPoints(tapLocations[0], tapLocations[1]);
					[self handleTwoFingerTap];
				}
			}
			
			// case 2: this is the end of one touch, and the other hasn't ended yet
			else if ([touches count] == 1 && !allTouchesEnded) 
			{
				UITouch *touch = [touches anyObject];
				if ([touch tapCount] == 1) 
				{
					// if touch is a single tap, store its location so we can average it with the second touch location
					tapLocation = [touch locationInView:self];
				} 
				else 
				{
					twoFingerTapIsPossible = NO;
				}
			}
			
			// case 3: this is the end of the second of the two touches
			else if ([touches count] == 1 && allTouchesEnded) 
			{
				UITouch *touch = [touches anyObject];
				if ([touch tapCount] == 1) 
				{
					// if the last touch up is a single tap, this was a 2-finger tap
					tapLocation = midpointBetweenPoints(tapLocation, [touch locationInView:self]);
					//[self handleTwoFingerTap];
				}
			}
		}
        
		// if all touches are up, reset touch monitoring state
		if (allTouchesEnded) 
		{
			twoFingerTapIsPossible = YES;
			multipleTouches = NO;
		}
	}
	
	if (handlesTouches)
	{
		UITouch *touch = [touches anyObject];
		NSMutableDictionary *evt = [NSMutableDictionary dictionaryWithDictionary:[TiUtils pointToDictionary:[touch locationInView:self]]];
		[evt setValue:[TiUtils pointToDictionary:[touch locationInView:nil]] forKey:@"globalPoint"];
		NSMutableDictionary *ts = [NSMutableDictionary dictionary];
		for (UITouch* t in touches) {
			[ts setObject:[TiUtils pointToDictionary:[t locationInView:nil]] forKey:[NSString stringWithFormat:@"%p",t]];
		}
		[evt setValue:ts forKey:@"points"];
		if ([proxy _hasListeners:@"touchend"])
		{
			[proxy fireEvent:@"touchend" withObject:evt propagate:YES];
			[self handleControlEvents:UIControlEventTouchCancel];
		}
	}
	if (handlesSwipes)
	{
		touchLocation = CGPointZero;
	}
	
	if (touchDelegate!=nil)
	{
		[touchDelegate touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (handlesTaps)
	{
		twoFingerTapIsPossible = YES;
		multipleTouches = NO;
	}
	if (handlesTouches)
	{
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		NSDictionary *evt = [TiUtils pointToDictionary:point];
		NSMutableDictionary *ts = [NSMutableDictionary dictionary];
		for (UITouch* t in touches) {
			[ts setObject:[TiUtils pointToDictionary:[t locationInView:nil]] forKey:[NSString stringWithFormat:@"%p",t]];
		}
		[evt setValue:ts forKey:@"points"];
		if ([proxy _hasListeners:@"touchcancel"])
		{
			[proxy fireEvent:@"touchcancel" withObject:evt propagate:YES];
		}
	}
	if (handlesSwipes)
	{
		touchLocation = CGPointZero;
	}
	
	if (touchDelegate!=nil)
	{
		[touchDelegate touchesCancelled:touches withEvent:event];
	}
}
@end
