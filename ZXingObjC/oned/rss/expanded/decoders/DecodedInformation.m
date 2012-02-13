#import "DecodedInformation.h"

@implementation DecodedInformation

@synthesize remaining, remainingValue, theNewString;

- (id) init:(int)aNewPosition newString:(NSString *)aNewString {
  if (self = [super initWithNewPosition:aNewPosition]) {
    theNewString = [aNewString copy];
    remaining = NO;
    remainingValue = 0;
  }
  return self;
}

- (id) init:(int)aNewPosition newString:(NSString *)aNewString remainingValue:(int)aRemainingValue {
  if (self = [super initWithNewPosition:newPosition]) {
    remaining = YES;
    remainingValue = aRemainingValue;
    theNewString = [aNewString copy];
  }
  return self;
}

- (void) dealloc {
  [theNewString release];
  [super dealloc];
}

@end
