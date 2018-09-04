//
//  UIGuidedView.h
//  UIGuidedViewExample
//
//  Created by Malleo, Mitch on 12/29/15.
//  Copyright © 2015 MitchellMalleo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIGuidedView;

typedef NS_ENUM(NSInteger, UIGuidedViewAnimationDirection){
  UIGuidedViewAnimationDirectionForwards = 0,
  UIGuidedViewAnimationDirectionBackwards = 1
};

@protocol UIGuidedViewDelegate <NSObject>

@optional
- (BOOL)guidedView:(UIGuidedView *)guidedView willSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
- (BOOL)guidedView:(UIGuidedView *)guidedView willMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;

- (void)guidedView:(UIGuidedView *)guidedView didSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
- (void)guidedView:(UIGuidedView *)guidedView didMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;

@end

@protocol UIGuidedViewDataSource <NSObject>

- (NSInteger)numberOfNodesForGuidedView:(UIGuidedView *)view;

@optional
- (NSString *)guidedView:(UIGuidedView *)guidedView titleForNodeAtIndex:(NSInteger)index;

@end

@interface UIGuidedView : UIView <UIApplicationDelegate>

@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *backgroundLineColor;
@property (strong, nonatomic) UIColor *selectedTitleColor;
@property (strong, nonatomic) UIColor *unselectedTitleColor;

@property (assign, nonatomic) float animationSpeed;
@property (assign, nonatomic) BOOL shouldHideTitlesForUnselectedNodes;
@property (assign, nonatomic, getter = isTouchable) BOOL touchable;

- (NSInteger)selectedNodeIndex;
- (void)selectNodeAtIndex:(NSInteger)index;

- (void)reloadNodeTitles;
- (void)reloadNodeTitleAtIndex:(NSInteger)index;

@property (weak, nonatomic) IBOutlet id<UIGuidedViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id<UIGuidedViewDataSource> dataSource;

@end
