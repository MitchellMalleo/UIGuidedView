# UIGuidedView

![](https://github.com/MitchellMalleo/UIGuidedView/blob/master/uiGuidedView.gif)

## Description

UIGuidedView is a simple control designed for guiding a user through a controlled flow.

## Requirements

- ARC
- iOS 5.0+
- xCode 7.0+

## Installation

1. UIGuidedView can be installed via [Cocoapods](http://cocoapods.org/) by adding `pod 'UIGuidedView'` to your podfile, or you can manually add `UIGuidedView.h/m` and `UIBezierPath+Circle.h/.m` into your project.
2. Create a `@property (strong, nonatomic) UIGuidedView *guidedView`, setup its frame, and in your class and set the guided view's dataSource. The only required method to implement is `- (NSInteger)numberOfNodesForGuidedView:(UIGuidedView *)view;`

		//YourViewController.m
		
		- (void)viewDidLoad {
			self.guidedView.dataSource = self
		}
		
		... //Other gloriously written code ...
		
		#pragma mark - UIGuidedViewDataSource
	    - (NSInteger)numberOfNodesForGuidedView:(UIGuidedView *)view {
	   		return 3;
	    }
		

## Usage

Thats all you need to implement for it to work! If you need a title for each node, there is a dataSource method for that as well

    - (NSString *)guidedView:(UIGuidedView *)guidedView titleForNodeAtIndex:(NSInteger)index {
    
    	NSString *title = @"";
    
	    if(index == 0){
	        title = @"Choose One";
	    }else if (index == 1){
	        title = @"Choose Another";
	    }else{
	        title = @"Confirm";
	    }
	    
	    return title;
	}

Validate your user's inputs by using the UIGuidedView's delegate methods, whether they are doing a single or multiple transition

    - (BOOL)guidedView:(UIGuidedView *)guidedView willSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
    
	- (BOOL)guidedView:(UIGuidedView *)guidedView willMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
	
	- (void)guidedView:(UIGuidedView *)guidedView didSingleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
	
	- (void)guidedView:(UIGuidedView *)guidedView didMultipleTransitionFromIndex:(NSInteger)index toIndex:(NSInteger)toIndex inDirection:(UIGuidedViewAnimationDirection)direction;
	
Modify the colors of the foreground and background line as you see fit alongside the title colors

	@property (strong, nonatomic) UIColor *lineColor;
	@property (strong, nonatomic) UIColor *backgroundLineColor;
	@property (strong, nonatomic) UIColor *selectedTitleColor;
	@property (strong, nonatomic) UIColor *unselectedTitleColor;
	
Customize if the guided view nodes are touchable

	@property (assign, nonatomic, getter = isTouchable) BOOL touchable;
	
Want to hide node title when they aren't selected? I've got the property for you!

	@property (assign, nonatomic) BOOL shouldHideTitlesForUnselectedNodes;
	
Examples are included in the project files. Enjoy. (:

## License

`UIGuidedView` is available under the `MIT` license. See the LICENSE file for more info.
