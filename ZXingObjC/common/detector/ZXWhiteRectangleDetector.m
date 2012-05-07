#import "ZXNotFoundException.h"
#import "ZXWhiteRectangleDetector.h"

@interface ZXWhiteRectangleDetector ()

@property (nonatomic, retain) ZXBitMatrix *image;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int leftInit;
@property (nonatomic, assign) int rightInit;
@property (nonatomic, assign) int downInit;
@property (nonatomic, assign) int upInit;

- (NSArray *)centerEdges:(ZXResultPoint *)y z:(ZXResultPoint *)z x:(ZXResultPoint *)x t:(ZXResultPoint *)t;
- (BOOL)containsBlackPoint:(int)a b:(int)b fixed:(int)fixed horizontal:(BOOL)horizontal;
- (ZXResultPoint *)blackPointOnSegment:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY;
- (int)distanceL2:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY;

@end

int const INIT_SIZE = 30;
int const CORR = 1;

@implementation ZXWhiteRectangleDetector

@synthesize image;
@synthesize height;
@synthesize width;
@synthesize leftInit;
@synthesize rightInit;
@synthesize downInit;
@synthesize upInit;

- (id)initWithImage:(ZXBitMatrix *)anImage {
  self = [super init];
  if (self) {
    self.image = anImage;
    self.height = anImage.height;
    self.width = anImage.width;
    self.leftInit = (self.width - INIT_SIZE) >> 1;
    self.rightInit = (self.width + INIT_SIZE) >> 1;
    self.upInit = (self.height - INIT_SIZE) >> 1;
    self.downInit = (self.height + INIT_SIZE) >> 1;
    if (self.upInit < 0 || self.leftInit < 0 || self.downInit >= self.height || self.rightInit >= self.width) {
      @throw [ZXNotFoundException notFoundInstance];
    }
  }

  return self;
}

- (id)initWithImage:(ZXBitMatrix *)anImage initSize:(int)initSize x:(int)x y:(int)y {
  self = [super init];
  if (self) {
    self.image = anImage;
    self.height = anImage.height;
    self.width = anImage.width;
    int halfsize = initSize >> 1;
    self.leftInit = x - halfsize;
    self.rightInit = x + halfsize;
    self.upInit = y - halfsize;
    self.downInit = y + halfsize;
    if (self.upInit < 0 || self.leftInit < 0 || self.downInit >= self.height || self.rightInit >= self.width) {
      @throw [ZXNotFoundException notFoundInstance];
    }
  }

  return self;
}

- (void)dealloc {
  [image release];

  [super dealloc];
}

/**
 * Detects a candidate barcode-like rectangular region within an image. It
 * starts around the center of the image, increases the size of the candidate
 * region until it finds a white rectangular region.
 * 
 * Returns a ResultPoint NSArray describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 */
- (NSArray *)detect {
  int left = self.leftInit;
  int right = self.rightInit;
  int up = self.upInit;
  int down = self.downInit;
  BOOL sizeExceeded = NO;
  BOOL aBlackPointFoundOnBorder = YES;
  BOOL atLeastOneBlackPointFoundOnBorder = NO;

  while (aBlackPointFoundOnBorder) {
    aBlackPointFoundOnBorder = NO;

    // .....
    // .   |
    // .....
    BOOL rightBorderNotWhite = YES;
    while (rightBorderNotWhite && right < self.width) {
      rightBorderNotWhite = [self containsBlackPoint:up b:down fixed:right horizontal:NO];
      if (rightBorderNotWhite) {
        right++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (right >= self.width) {
      sizeExceeded = YES;
      break;
    }

    // .....
    // .   .
    // .___.
    BOOL bottomBorderNotWhite = YES;
    while (bottomBorderNotWhite && down < self.height) {
      bottomBorderNotWhite = [self containsBlackPoint:left b:right fixed:down horizontal:YES];
      if (bottomBorderNotWhite) {
        down++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (down >= self.height) {
      sizeExceeded = YES;
      break;
    }

    // .....
    // |   .
    // .....
    BOOL leftBorderNotWhite = YES;
    while (leftBorderNotWhite && left >= 0) {
      leftBorderNotWhite = [self containsBlackPoint:up b:down fixed:left horizontal:NO];
      if (leftBorderNotWhite) {
        left--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (left < 0) {
      sizeExceeded = YES;
      break;
    }

    // .___.
    // .   .
    // .....
    BOOL topBorderNotWhite = YES;
    while (topBorderNotWhite && up >= 0) {
      topBorderNotWhite = [self containsBlackPoint:left b:right fixed:up horizontal:YES];
      if (topBorderNotWhite) {
        up--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (up < 0) {
      sizeExceeded = YES;
      break;
    }

    if (aBlackPointFoundOnBorder) {
      atLeastOneBlackPointFoundOnBorder = YES;
    }
  }

  if (!sizeExceeded && atLeastOneBlackPointFoundOnBorder) {
    int maxSize = right - left;

    ZXResultPoint * z = nil;
    for (int i = 1; i < maxSize; i++) {
      z = [self blackPointOnSegment:left aY:down - i bX:left + i bY:down];
      if (z != nil) {
        break;
      }
    }

    if (z == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }

    ZXResultPoint * t = nil;
    for (int i = 1; i < maxSize; i++) {
      t = [self blackPointOnSegment:left aY:up + i bX:left + i bY:up];
      if (t != nil) {
        break;
      }
    }

    if (t == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }

    ZXResultPoint * x = nil;
    for (int i = 1; i < maxSize; i++) {
      x = [self blackPointOnSegment:right aY:up + i bX:right - i bY:up];
      if (x != nil) {
        break;
      }
    }

    if (x == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }

    ZXResultPoint * y = nil;
    for (int i = 1; i < maxSize; i++) {
      y = [self blackPointOnSegment:right aY:down - i bX:right - i bY:down];
      if (y != nil) {
        break;
      }
    }

    if (y == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    return [self centerEdges:y z:z x:x t:t];
  } else {
    @throw [ZXNotFoundException notFoundInstance];
  }
}


/**
 * Ends up being a bit faster than round(). This merely rounds its
 * argument to the nearest int, where x.5 rounds up.
 */
- (int)round:(float)d {
  return (int)(d + 0.5f);
}

- (ZXResultPoint *)blackPointOnSegment:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY {
  int dist = [self distanceL2:aX aY:aY bX:bX bY:bY];
  float xStep = (bX - aX) / dist;
  float yStep = (bY - aY) / dist;

  for (int i = 0; i < dist; i++) {
    int x = [self round:aX + i * xStep];
    int y = [self round:aY + i * yStep];
    if ([self.image get:x y:y]) {
      return [[[ZXResultPoint alloc] initWithX:x y:y] autorelease];
    }
  }

  return nil;
}

- (int)distanceL2:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY {
  float xDiff = aX - bX;
  float yDiff = aY - bY;
  return [self round:(float)sqrt(xDiff * xDiff + yDiff * yDiff)];
}


/**
 * recenters the points of a constant distance towards the center
 *
 * returns a ResultPoint NSArray describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 */
- (NSArray *)centerEdges:(ZXResultPoint *)y z:(ZXResultPoint *)z x:(ZXResultPoint *)x t:(ZXResultPoint *)t {
  //
  //       t            t
  //  z                      x
  //        x    OR    z
  //   y                    y
  //

  float yi = y.x;
  float yj = y.y;
  float zi = z.x;
  float zj = z.y;
  float xi = x.x;
  float xj = x.y;
  float ti = t.x;
  float tj = t.y;

  if (yi < self.width / 2) {
    return [NSArray arrayWithObjects:[[[ZXResultPoint alloc] initWithX:ti - CORR y:tj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:zi + CORR y:zj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:xi - CORR y:xj - CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:yi + CORR y:yj - CORR] autorelease], nil];
  } else {
    return [NSArray arrayWithObjects:[[[ZXResultPoint alloc] initWithX:ti + CORR y:tj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:zi + CORR y:zj - CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:xi - CORR y:xj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:yi - CORR y:yj - CORR] autorelease], nil];
  }
}


/**
 * Determines whether a segment contains a black point
 */
- (BOOL)containsBlackPoint:(int)a b:(int)b fixed:(int)fixed horizontal:(BOOL)horizontal {
  if (horizontal) {
    for (int x = a; x <= b; x++) {
      if ([self.image get:x y:fixed]) {
        return YES;
      }
    }
  } else {
    for (int y = a; y <= b; y++) {
      if ([self.image get:fixed y:y]) {
        return YES;
      }
    }
  }

  return NO;
}

@end