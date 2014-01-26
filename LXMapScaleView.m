//
//  LXMapScaleView.m
//
//  Created by Tamas Lustyik on 2012.01.09..
//  Copyright (c) 2012 LKXF. All rights reserved.
//
//  Updated for iOS7 and ARC by Zoë Smith on 2014.10.25

#import "LXMapScaleView.h"


static const CGRect kDefaultViewRect = {{0,0},{300,30}};
static const CGFloat kMinimumWidth = 100.0f;
static const UIEdgeInsets kDefaultPadding = {30,10,10,10};

static const double kFeetPerMeter = 1.0/0.3048;
static const double kFeetPerMile = 5280.0;



@interface LXMapScaleView ()

@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) UILabel *zeroLabel;
@property (strong, nonatomic) UILabel *maxLabel;
@property (strong, nonatomic) UILabel *unitLabel;
@property (nonatomic) CGFloat scaleWidth;

- (id)initWithMapView:(MKMapView*)aMapView;
- (void)constructLabels;

@end

@implementation LXMapScaleView

// -----------------------------------------------------------------------------
// LXMapScaleView::mapScaleForMapView:
// -----------------------------------------------------------------------------
+ (LXMapScaleView *)mapScaleForMapView:(MKMapView *)mapView {
	
    if (!mapView) {
		return nil;
	}
	
	for (UIView *subview in mapView.subviews) {
		if ([subview isKindOfClass:[LXMapScaleView class]]) {
			return (LXMapScaleView *)subview;
		}
	}
	return [[LXMapScaleView alloc] initWithMapView:mapView];
}

// -----------------------------------------------------------------------------
// LXMapScaleView::initWithMapView:
// -----------------------------------------------------------------------------

- (void)commonInit {
    
    self.opaque = NO;
    self.clipsToBounds = YES;
    self.userInteractionEnabled = NO;
    
    _metric = [self userInMetricLocale];
    _style = kLXMapScaleStyleBar;
    _position = kLXMapScalePositionBottomLeft;
    _padding = kDefaultPadding;
    _maxWidth = kDefaultViewRect.size.width;
    
    [self constructLabels];
    
}

- (instancetype)initWithMapView:(MKMapView*)mapView {
    
	if ((self = [super initWithFrame:kDefaultViewRect])) {
		
        _mapView = mapView;
        [self commonInit];
		[mapView addSubview:self];
	}
	
	return self;
}

- (BOOL)userInMetricLocale {
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    return [[currentLocale objectForKey:NSLocaleUsesMetricSystem] boolValue];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::constructLabels
// -----------------------------------------------------------------------------
- (void)constructLabels
{
	UIFont* font = [UIFont systemFontOfSize:12.0f];
	self.zeroLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 8, 10)];
	self.zeroLabel.backgroundColor = [UIColor clearColor];
	self.zeroLabel.textColor = [UIColor blackColor];
	self.zeroLabel.shadowColor = [UIColor clearColor];
	self.zeroLabel.shadowOffset = CGSizeMake(1, 1);
	self.zeroLabel.text = @"0";
	self.zeroLabel.font = font;
	[self addSubview:self.zeroLabel];
	
	self.maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 10, 10)];
	self.maxLabel.backgroundColor = [UIColor clearColor];
	self.maxLabel.textColor = [UIColor blackColor];
	self.maxLabel.shadowColor = [UIColor clearColor];
	self.maxLabel.shadowOffset = CGSizeMake(1, 1);
	self.maxLabel.text = @"1";
	self.maxLabel.font = font;
	self.maxLabel.textAlignment = NSTextAlignmentRight;
	[self addSubview:self.maxLabel];
	
	self.unitLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 18, 10)];
	self.unitLabel.backgroundColor = [UIColor clearColor];
	self.unitLabel.textColor = [UIColor blackColor];
	self.unitLabel.shadowColor = [UIColor clearColor];
	self.unitLabel.shadowOffset = CGSizeMake(1, 1);
	self.unitLabel.text = @"m";
	self.unitLabel.font = font;
	[self addSubview:self.unitLabel];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::update
// -----------------------------------------------------------------------------
- (void)update
{
	if ( !self.mapView || !self.mapView.bounds.size.width )
	{
		return;
	}
	
	CLLocationDistance horizontalDistance = MKMetersPerMapPointAtLatitude(self.mapView.centerCoordinate.latitude);
	float metersPerPixel = self.mapView.visibleMapRect.size.width * horizontalDistance / self.mapView.bounds.size.width;
	
	CGFloat maxScaleWidth = self.maxWidth-40;
	
	NSUInteger maxValue = 0;
	NSString* unit = @"";
	
	if ( self.metric )
	{
		float meters = maxScaleWidth*metersPerPixel;
		
		if ( meters > 2000.0f )
		{
			// use kilometer scale
			unit = @"km";
			static const NSUInteger kKilometerScale[] = {1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000};
			float kilometers = meters / 1000.0f;
			
			for ( int i = 0; i < 15; ++i )
			{
				if ( kilometers < kKilometerScale[i] )
				{
					self.scaleWidth = maxScaleWidth * kKilometerScale[i-1]/kilometers;
					maxValue = kKilometerScale[i-1];
					break;
				}
			}
		}
		else
		{
			// use meter scale
			unit = @"m";
			static const NSUInteger kMeterScale[11] = {1,2,5,10,20,50,100,200,500,1000,2000};

			for ( int i = 0; i < 11; ++i )
			{
				if ( meters < kMeterScale[i] )
				{
					self.scaleWidth = maxScaleWidth * kMeterScale[i-1]/meters;
					maxValue = kMeterScale[i-1];
					break;
				}
			}
		}
	}
	else
	{
		float feet = maxScaleWidth*metersPerPixel*kFeetPerMeter;
		
		if ( feet > kFeetPerMile )
		{
			// user mile scale
			unit = @"mi";
			static const double kMileScale[] = {1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000};
			float miles = feet / kFeetPerMile;
			
			for ( int i = 0; i < 15; ++i )
			{
				if ( miles < kMileScale[i] )
				{
					self.scaleWidth = maxScaleWidth * kMileScale[i-1]/miles;
					maxValue = kMileScale[i-1];
					break;
				}
			}
		}
		else
		{
			// use foot scale
			unit = @"ft";
			static const double kFootScale[] = {1,2,5,10,20,50,100,200,500,1000,2000,5000,10000};

			for ( int i = 0; i < 13; ++i )
			{
				if ( feet < kFootScale[i] )
				{
					self.scaleWidth = maxScaleWidth * kFootScale[i-1]/feet;
					maxValue = kFootScale[i-1];
					break;
				}
			}
		}
	}
	
	self.maxLabel.text = [NSString stringWithFormat:@"%d",maxValue];
	self.unitLabel.text = unit;
	
	[self layoutSubviews];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setFrame:
// -----------------------------------------------------------------------------
- (void)setFrame:(CGRect)aFrame
{
	[self setMaxWidth:aFrame.size.width];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setBounds:
// -----------------------------------------------------------------------------
- (void)setBounds:(CGRect)aBounds
{
	[self setMaxWidth:aBounds.size.width];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setMaxWidth:
// -----------------------------------------------------------------------------
- (void)setMaxWidth:(CGFloat)aMaxWidth
{
	if ( _maxWidth != aMaxWidth && aMaxWidth >= kMinimumWidth )
	{
		_maxWidth = aMaxWidth;
		
		[self setNeedsLayout];
	}
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setAlpha:
// -----------------------------------------------------------------------------
- (void)setAlpha:(CGFloat)aAlpha
{
	[super setAlpha:aAlpha];
	self.zeroLabel.alpha = aAlpha;
	self.maxLabel.alpha = aAlpha;
	self.unitLabel.alpha = aAlpha;
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setStyle:
// -----------------------------------------------------------------------------
- (void)setStyle:(LXMapScaleStyle)aStyle
{
	if ( _style != aStyle )
	{
		_style = aStyle;
		
		[self setNeedsDisplay];
	}
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setPosition:
// -----------------------------------------------------------------------------
- (void)setPosition:(LXMapScalePosition)aPosition
{
	if ( _position != aPosition )
	{
		_position = aPosition;

		[self setNeedsLayout];
	}
}


// -----------------------------------------------------------------------------
// LXMapScaleView::setMetric:
// -----------------------------------------------------------------------------
- (void)setMetric:(BOOL)aIsMetric
{
	if ( self.metric != aIsMetric )
	{
		self.metric = aIsMetric;
		
		[self update];
	}
}


// -----------------------------------------------------------------------------
// LXMapScaleView::layoutSubviews
// -----------------------------------------------------------------------------
- (void)layoutSubviews
{
    CGSize maxLabelSize = [self.maxLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.maxLabel.font }];
	self.maxLabel.frame = CGRectMake(self.zeroLabel.frame.size.width/2.0f+1+self.scaleWidth+1 - (maxLabelSize.width+1)/2.0f,
								0, 
								maxLabelSize.width+1,
								self.maxLabel.frame.size.height);
	
	CGSize unitLabelSize = self.unitLabel.frame.size;
	self.unitLabel.frame = CGRectMake(CGRectGetMaxX(self.maxLabel.frame),
								 0,
								 unitLabelSize.width,
								 unitLabelSize.height);
	
	CGSize mapSize = self.mapView.bounds.size;
	CGRect frame = self.bounds;
	frame.size.width = CGRectGetMaxX(self.unitLabel.frame) - CGRectGetMinX(self.zeroLabel.frame);
	
	switch (self.position)
	{
		case kLXMapScalePositionTopLeft:
		{
			frame.origin = CGPointMake(self.padding.left,
									   self.padding.top);
			self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
			break;
		}
			
		case kLXMapScalePositionTop:
		{
			frame.origin = CGPointMake((mapSize.width - frame.size.width) / 2.0f,
									   self.padding.top);
			self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
			break;
		}
			
		case kLXMapScalePositionTopRight:
		{
			frame.origin = CGPointMake(mapSize.width - self.padding.right - frame.size.width,
									   self.padding.top);
			self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
			break;
		}
			
		default:
		case kLXMapScalePositionBottomLeft:
		{
			frame.origin = CGPointMake(self.padding.left,
									   mapSize.height - self.padding.bottom - frame.size.height);
			self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
			break;
		}
			
		case kLXMapScalePositionBottom:
		{
			frame.origin = CGPointMake((mapSize.width - frame.size.width) / 2.0f,
									   mapSize.height - self.padding.bottom - frame.size.height);
			self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
			break;
		}
			
		case kLXMapScalePositionBottomRight:
		{
			frame.origin = CGPointMake(mapSize.width - self.padding.right - frame.size.width,
									   mapSize.height - self.padding.bottom - frame.size.height);
			self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
			break;
		}
	}
	
	super.frame = frame;

	[self setNeedsDisplay];
}


// -----------------------------------------------------------------------------
// LXMapScaleView::drawRect:
// -----------------------------------------------------------------------------
- (void)drawRect:(CGRect)aRect
{
	if ( !self.mapView )
	{
		return;
	}

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if ( self.style == kLXMapScaleStyleTapeMeasure )
	{
		CGRect baseRect = CGRectZero;
		UIColor* strokeColor = [UIColor whiteColor];
		UIColor* fillColor = [UIColor blackColor];
		
		baseRect = CGRectMake(3, 24, self.scaleWidth+2, 3);
		[strokeColor setFill];
		CGContextFillRect(ctx, baseRect);
		
		baseRect = CGRectInset(baseRect, 1, 1);
		[fillColor setFill];
		CGContextFillRect(ctx, baseRect);

		baseRect = CGRectMake(3, 12, 3, 12);
		for ( int i = 0; i <= 5; ++i )
		{
			CGRect rodRect = baseRect;
			rodRect.origin.x += i*(self.scaleWidth-1)/5.0f;
			[strokeColor setFill];
			CGContextFillRect(ctx, rodRect);
			
			rodRect = CGRectInset(rodRect, 1, 1);
			rodRect.size.height += 2;
			[fillColor setFill];
			CGContextFillRect(ctx, rodRect);
		}
		
		baseRect = CGRectMake(3+(self.scaleWidth-1)/10.0f, 16, 3, 8);
		for ( int i = 0; i < 5; ++i )
		{
			CGRect rodRect = baseRect;
			rodRect.origin.x += i*(self.scaleWidth-1)/5.0f;
			[strokeColor setFill];
			CGContextFillRect(ctx, rodRect);

			rodRect = CGRectInset(rodRect, 1, 1);
			rodRect.size.height += 2;
			[fillColor setFill];
			CGContextFillRect(ctx, rodRect);
		}
	}
	else if ( self.style == kLXMapScaleStyleBar )
	{
		CGRect scaleRect = CGRectMake(4, 12, self.scaleWidth, 3);
		
		[[UIColor blackColor] setFill];
		CGContextFillRect(ctx, CGRectInset(scaleRect, -1, -1));
		
		[[UIColor whiteColor] setFill];
		CGRect unitRect = scaleRect;
		unitRect.size.width = self.scaleWidth/5.0f;
		
		for ( int i = 0; i < 5; i+=2 )
		{
			unitRect.origin.x = scaleRect.origin.x + unitRect.size.width*i;
			CGContextFillRect(ctx, unitRect);
		}
	}
	else if ( self.style == kLXMapScaleStyleAlternatingBar )
	{
		CGRect scaleRect = CGRectMake(4, 12, self.scaleWidth, 6);
		
		[[UIColor blackColor] setFill];
		CGContextFillRect(ctx, CGRectInset(scaleRect, -1, -1));
		
		[[UIColor whiteColor] setFill];
		CGRect unitRect = scaleRect;
		unitRect.size.width = self.scaleWidth/5.0f;
		unitRect.size.height = scaleRect.size.height/2.0f;
		
		for ( int i = 0; i < 5; ++i )
		{
			unitRect.origin.x = scaleRect.origin.x + unitRect.size.width*i;
			unitRect.origin.y = scaleRect.origin.y + unitRect.size.height*(i%2);
			CGContextFillRect(ctx, unitRect);
		}
	}
}


@end

