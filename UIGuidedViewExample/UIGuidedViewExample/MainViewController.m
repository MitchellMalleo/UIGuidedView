//
//  ViewController.m
//  UIGuidedViewExample
//
//  Created by Malleo, Mitch on 12/29/15.
//  Copyright © 2015 MitchellMalleo. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (strong, nonatomic) IBOutlet UIGuidedView *guidedView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation MainViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.guidedView.dataSource = self;
    self.guidedView.delegate = self;
    
    [self.segmentedControl addTarget:self action:@selector(segmentedControlWasTouched:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Private Methods

- (void)segmentedControlWasTouched:(id)sender {
    
    UISegmentedControl *segmentedControl = (UISegmentedControl*) sender;
    [self.guidedView selectNodeAtIndex:segmentedControl.selectedSegmentIndex];
}

#pragma mark - UIGuidedViewDelegate

- (BOOL)guidedView:(UIGuidedView *)guidedView willSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction{
    
    NSLog(@"Will single transition from %li to %li", (long)index, (long)toIndex);
    
    return YES;
}

- (BOOL)guidedView:(UIGuidedView *)guidedView willMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction{
    
    NSLog(@"Will multiple transition from %li to %li", (long)index, (long)toIndex);
    
    return YES;
}

- (void)guidedView:(UIGuidedView *)guidedView didSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction{
    
    NSLog(@"Did single transition from %li to %li", (long)index, (long)toIndex);
}

- (void)guidedView:(UIGuidedView *)guidedView didMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction{
    
    NSLog(@"Did multiple transition from %li to %li", (long)index, (long)toIndex);
}

#pragma mark - UIGuidedViewDataSource

- (NSInteger)numberOfNodesForGuidedView:(UIGuidedView *)view {
    return 5;
}

- (NSString *)guidedView:(UIGuidedView *)guidedView titleForNodeAtIndex:(NSInteger)index {
    
    NSString *title = @"";
    
    if(index == 0){
        title = @"Choose one";
    }else if (index == 1){
        title = @"Choose another";
    }else if (index == 2){
        title = @"Select a color";
    }else if (index == 3){
        title = @"Select a price";
    }else if (index == 4){
        title = @"Confirm";
    }
    
    return title;
}

@end
