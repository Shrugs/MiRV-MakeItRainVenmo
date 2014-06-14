/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
#import "CKBlurView/CKBlurView.h"
#import "Venmo/VENPaymentService.h"
#import "Venmo/VENMakePaymentViewController.h"
#import "Venmo/VENPaymentView.h"
// #import <iOS7/Frameworks/QuartzCore/CAEmitterLayer.h>


static VENPaymentView *mostRecentPaymentView = nil;
static VENPaymentService *venPaymentService = nil;
static unsigned int amount = 0;
static UILabel *MiRLabel = nil;
static UILabel *MiRAmount = nil;
static BOOL didMakeItRain = false;
static unsigned int billsRainedUpon = 0;
static CKBlurView *frosty = nil;
// static CAEmitterLayer *_emitter = nil;


@interface MiRVOverlayView : UIView <UIGestureRecognizerDelegate>
-(void)handleSwipe:(UISwipeGestureRecognizer *)recognizer;
-(void)updateLabels;
@end

@implementation MiRVOverlayView

-(void)handleSwipe:(UISwipeGestureRecognizer *)recognizer {
    billsRainedUpon ++;
    [self updateLabels];
    NSLog(@"%i >= %i", billsRainedUpon, amount);
    if (billsRainedUpon >= amount) {
        // yay, call original function
        didMakeItRain = true;
        [venPaymentService sendTransaction];
    }

    // show particles lol

}

-(void)updateLabels {
    MiRAmount.text = [NSString stringWithFormat: @"~$%i", billsRainedUpon];
}

@end

static MiRVOverlayView *overlay = nil;

%hook VENPaymentService

- (void)sendTransaction {
    %log;
    venPaymentService = self;

    if (!didMakeItRain) {
        frosty = [[%c(CKBlurView) alloc] initWithFrame: [[[UIApplication sharedApplication] keyWindow] frame]];
        overlay = [[MiRVOverlayView alloc] initWithFrame: frosty.frame];
        UISwipeGestureRecognizer *swipeRecognizer =
              [[UISwipeGestureRecognizer alloc]
              initWithTarget:overlay
              action:@selector(handleSwipe:)];
        swipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
        [overlay addGestureRecognizer:swipeRecognizer];

        MiRLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 30, overlay.bounds.size.width, 30)];
        MiRLabel.textAlignment =  NSTextAlignmentCenter;
        MiRLabel.textColor = [UIColor blackColor];
        [MiRLabel setText: @"💸Make it Rain!💸"];
        [MiRLabel setFont:[UIFont systemFontOfSize:30]];
        MiRLabel.adjustsFontSizeToFitWidth = YES;
        [overlay addSubview: MiRLabel];
        MiRAmount = [[UILabel alloc] initWithFrame: CGRectMake(0, 130, overlay.bounds.size.width, 100)];
        MiRAmount.textAlignment =  NSTextAlignmentCenter;
        MiRAmount.textColor = [UIColor blackColor];
        [MiRAmount setFont:[UIFont systemFontOfSize:30]];
        MiRAmount.adjustsFontSizeToFitWidth = YES;
        [overlay addSubview: MiRAmount];

        [overlay updateLabels];

        // _emitter = (CAEmitterLayer*)overlay.layer;
        // _emitter.emitterPosition = CGPointMake(overlay.bounds.size.width, 60);
        // _emitter.emitterSize = CGSizeMake(10, 10);

        // CAEmitterCell* cell = [CAEmitterCell emitterCell];
        // cell.birthRate = 200;
        // cell.lifetime = 3.0;
        // cell.lifetimeRange = 0.5;
        // cell.color = [[UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.1]
        //   CGColor];

        // cell.velocity = 10;
        // cell.velocityRange = 20;
        // cell.emissionRange = M_PI_2;

        // cell.scaleSpeed = 0.3;
        // cell.spin = 0.5;

        // [cell setName:@"cell"];

        // _emitter.emitterCells = [NSArray arrayWithObject:cell];

        [[[UIApplication sharedApplication] keyWindow] addSubview: frosty];
        [[[UIApplication sharedApplication] keyWindow] insertSubview: overlay aboveSubview: frosty];

        amount = ceil([self amount]/100);
    } else {
        [frosty removeFromSuperview];
        [overlay removeFromSuperview];
        frosty = nil;
        overlay = nil;
        billsRainedUpon = 0;
        %orig;
    }

}

%end

%hook VENMakePaymentViewController

- (void)setPaymentView:(id)paymentView {
    // get reference to most recent paymentView for closing text field
    %log;
    mostRecentPaymentView = paymentView;
    didMakeItRain = false;
    %orig;
}

%end
