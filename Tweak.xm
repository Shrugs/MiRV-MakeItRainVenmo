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
#import "Venmo/VENTransactionRecipient.h"
// #import <iOS7/Frameworks/QuartzCore/CAEmitterLayer.h>


static VENPaymentView *mostRecentPaymentView = nil;
static VENPaymentService *venPaymentService = nil;
static unsigned int amount = 0;
static UILabel *MiRLabel = nil;
static UILabel *MiRAmount = nil;
static BOOL didMakeItRain = false;
static unsigned int billsRainedUpon = 0;
static CKBlurView *frosty = nil;
static NSString *moneyType = @"dollars";
// static CAEmitterLayer *_emitter = nil;

@interface MiRVMoneyBag : UIView
- (void) moveTo:(CGPoint)destination duration:(float)secs;
- (void) fadeIn;
- (float) rFloat:(float)m;
@end

@implementation MiRVMoneyBag
- (float) rFloat:(float)m {
    return arc4random() / ((pow(2, 32)-1)) * m;
}
-(id)initWithFrame:(CGRect) frame {
    self = [super initWithFrame: frame];
    if (self) {
        UILabel *myLabel = [[UILabel alloc] initWithFrame: CGRectMake(0,0,frame.size.width, frame.size.height)];
        myLabel.lineBreakMode = NSLineBreakByWordWrapping;
        myLabel.numberOfLines = 0;
        myLabel.text = @"💸";
        self.alpha = 0;
        [self addSubview:myLabel];
    }
    return self;
}
- (void) fadeIn {
    [UIView animateWithDuration:1 delay:[self rFloat:1] options:UIViewAnimationOptionCurveEaseOut
        animations:^{
            self.alpha = 1;
        }
        completion:nil];
}
- (void) moveTo:(CGPoint)destination duration:(float)secs
{
    [UIView animateWithDuration:(1+[self rFloat:1]) delay:0.0 options:UIViewAnimationOptionCurveEaseOut
        animations:^{
            self.frame = CGRectMake(destination.x,destination.y, self.frame.size.width, self.frame.size.height);
            self.alpha = 0;
        }
        completion:nil];
}
@end

@interface MiRVOverlayView : UIView <UIGestureRecognizerDelegate>
-(void)handleSwipe:(UISwipeGestureRecognizer *)recognizer;
-(void)updateLabels;
-(float)rFloat:(float)m;
@end

@implementation MiRVOverlayView
- (float) rFloat:(float)m {
    return arc4random() / ((pow(2, 32)-1)) * m;
}
-(void)handleSwipe:(UISwipeGestureRecognizer *)recognizer {
    billsRainedUpon ++;
    [self updateLabels];
    NSLog(@"%i >= %i", billsRainedUpon, amount);
    if (billsRainedUpon >= amount) {
        // yay, call original function
        didMakeItRain = true;
        [venPaymentService sendTransaction];
    }

    // show particle lol
    MiRVMoneyBag *mb = [[MiRVMoneyBag alloc] initWithFrame: CGRectMake(30 + 52*[self rFloat:5], 60, 40, 40)];
    [self addSubview:mb];
    [mb fadeIn];
    [mb moveTo:CGPointMake(mb.center.x, 300) duration:0];


}

-(void)updateLabels {
    if ([moneyType isEqualToString:@"dollars"]) {
        MiRAmount.text = [NSString stringWithFormat: @"~$%i", billsRainedUpon];
    } else {
        MiRAmount.text = [NSString stringWithFormat: @"%i¢", billsRainedUpon];
    }
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
        [MiRLabel setText: [NSString stringWithFormat: @"💸Make it Rain on %@!💸", [(VENTransactionRecipient *)[(NSOrderedSet *)mostRecentPaymentView.recipients firstObject] firstName]]];
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

        [[[UIApplication sharedApplication] keyWindow] addSubview: frosty];
        [[[UIApplication sharedApplication] keyWindow] insertSubview: overlay aboveSubview: frosty];

        NSRange textRange =[[[self note] lowercaseString] rangeOfString:[@"hail" lowercaseString]];

        if(textRange.location != NSNotFound) {
            amount = [self amount];
            [MiRLabel setText: [NSString stringWithFormat: @"💸Make it Hail on %@!💸", [(VENTransactionRecipient *)[(NSOrderedSet *)mostRecentPaymentView.recipients firstObject] firstName]]];
            moneyType = @"cents";
        } else {
            amount = ceil([self amount]/100);
            moneyType = @"dollars";
        }
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
