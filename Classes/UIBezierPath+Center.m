//
//  UIBezierPath+Center.m
//  UIGuidedViewExample
//
//  Created by Malleo, Mitch on 12/30/15.
//  Copyright © 2015 MitchellMalleo. All rights reserved.
//

#import "UIBezierPath+Center.h"

@implementation UIBezierPath (Center)

- (CGPoint)center{
  return CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

@end
