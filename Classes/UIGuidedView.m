//
//  UIGuidedView.m
//  UIGuidedViewExample
//
//  Created by Malleo, Mitch on 12/29/15.
//  Copyright © 2015 MitchellMalleo. All rights reserved.
//

#import "UIGuidedView.h"
#import "UIBezierPath+Center.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define kBackgroundLineUIColorDefault [UIColor colorWithRed:215.0/255.0 green:215.0/255.0 blue:215.0/255.0 alpha:1.0]
#define kNodeUIColorDefault [UIColor colorWithRed:103.0/255.0 green:142.0/255.0 blue:180.0/255.0 alpha:1.0]
#define kNodeSpacing self.backgroundLinePath.bounds.origin.x + i * self.backgroundLinePath.bounds.size.width / (self.numberOfNodes - 1)

#define kNewPathKey @"path"
#define kNewNodeKey @"newNode"
#define kOldNodeKey @"oldNode"
#define kDirectionKey @"animationDirection"
#define kNodeSelection @"selectNode"
#define kNodeRadius 4.5
#define kGuidedViewPadding 35
#define kUIGuidedViewNodeTitleLabelYValue 20
#define kDidFailBackwardsTransition @"didFailBackwardsTransition"

@interface UIGuidedViewNode : NSObject

@property (strong, nonatomic) UIGuidedView *view;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) CAShapeLayer *backgroundLayer;
@property (strong, nonatomic) UIBezierPath *backgroundPath;

@property (strong, nonatomic) CAShapeLayer *layer;
@property (strong, nonatomic) UIBezierPath *path;
@property (strong, nonatomic) UIBezierPath *retractPath;
@property (assign, nonatomic) NSInteger index;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL displaying;

@end

@implementation UIGuidedViewNode

- (instancetype)init {
    
    self = [super init];
    
    if(self){
        self.titleLabel = [UILabel new];
    }
    
    return self;
}

- (void)setDisplaying:(BOOL)displaying {
    
    if(displaying){
        self.layer.path = self.path.CGPath;
        self.layer.lineWidth = kNodeRadius;
    }else {
        self.layer.lineWidth = 0;
        self.layer.path = self.retractPath.CGPath;
    }
    
    _displaying = displaying;
}

- (void)setSelected:(BOOL)selected {
    
    if(selected){
        self.displaying = YES;
        self.layer.lineWidth = kNodeRadius;
        [self.titleLabel setTextColor:self.view.selectedTitleColor];
        self.titleLabel.hidden = NO;
        
    } else {
        
        if(self.view.shouldHideTitlesForUnselectedNodes){
            self.titleLabel.hidden = YES;
        }
        
        [self.titleLabel setTextColor:self.view.unselectedTitleColor];
    }
    
    
    
    _selected = selected;
}

- (void)setPath:(UIBezierPath *)path {
    _path = path;
    
    self.retractPath = [UIBezierPath bezierPathWithArcCenter:path.center radius:0 startAngle:DEGREES_TO_RADIANS(270) endAngle:DEGREES_TO_RADIANS(270.01) clockwise:NO];
}

@end

@interface UIGuidedView()

@property (strong, nonatomic) CAShapeLayer *backgroundLine;
@property (strong, nonatomic) UIBezierPath *backgroundLinePath;
@property (strong, nonatomic) CAShapeLayer *foregroundLine;
@property (strong, nonatomic) UIBezierPath *foregroundLinePath;
@property (strong, nonatomic) UIBezierPath *line;
@property (strong, nonatomic) UIGuidedViewNode *selectedNode;
@property (strong, nonatomic) NSMutableArray *animationArray;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL didFailValidation;
@property (nonatomic) NSInteger numberOfNodes;

@property (strong, nonatomic) NSMutableArray <__kindof UIGuidedViewNode *> *nodes;

@end

#pragma mark - UIGuidedView Implementation

@implementation UIGuidedView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if(self){
        self.selectedNode = nil;
        [self setupDefaults];
        [self setupUI];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if(self){
        self.selectedNode = nil;
        [self setupDefaults];
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupPaths];
        [self setupBackgroundLine];
        
        if(self.dataSource){
            [self setupNodes];
            [self setupForegroundLine];
        }
    });
}

#pragma mark - Custom Accessors

- (void)setSelectedNode:(UIGuidedViewNode *)selectedNode {
    
    _selectedNode.selected = NO;
    selectedNode.selected = YES;
    
    _selectedNode = selectedNode;
}

- (void)setForegroundLinePath:(UIBezierPath *)foregroundLinePath {
    
    self.foregroundLine.path = foregroundLinePath.CGPath;
    
    _foregroundLinePath = foregroundLinePath;
}

- (void)setBackgroundLineColor:(UIColor *)backgroundLineColor {
    
    if(self.backgroundLine != nil) {
        self.backgroundLine.strokeColor = backgroundLineColor.CGColor;
        self.backgroundLine.fillColor = backgroundLineColor.CGColor;
    }
    
    _backgroundLineColor = backgroundLineColor;
}

- (void)setUnselectedTitleColor:(UIColor *)unselectedTitleColor {
    
    if([self.nodes count] > 0){
        
        for(UIGuidedViewNode *node in self.nodes) {
            
            if(!node.selected){
                [node.titleLabel setTextColor:unselectedTitleColor];
            }
        }
    }
    
    _unselectedTitleColor = unselectedTitleColor;
}

- (void)setSelectedTitleColor:(UIColor *)selectedTitleColor {
    
    if([self.nodes count] > 0){
        
        for(UIGuidedViewNode *node in self.nodes) {
            
            if(node.selected){
                [node.titleLabel setTextColor:selectedTitleColor];
            }
        }
    }
    
    _selectedTitleColor = selectedTitleColor;
}

- (void)setLineColor:(UIColor *)lineColor {
    
    for(UIGuidedViewNode *node in self.nodes){
        node.layer.fillColor = lineColor.CGColor;
        node.layer.fillColor = lineColor.CGColor;
    }
    
    self.foregroundLine.fillColor = lineColor.CGColor;
    self.foregroundLine.strokeColor = lineColor.CGColor;
    
    _lineColor = lineColor;
}

- (void)setDataSource:(id<UIGuidedViewDataSource>)dataSource{
    
    _dataSource = dataSource;
    
    self.numberOfNodes = [self.dataSource numberOfNodesForGuidedView:self];
    
    if(self.numberOfNodes < 2) {
        [NSException raise:@"Invalid number of nodes" format:@"There must be at least two nodes in a UIGuidedView"];
    }
}

#pragma mark - Public Methods

- (NSInteger)selectedNodeIndex{
    
    return self.selectedNode.index;
}


- (void)selectNodeAtIndex:(NSInteger)index {
    
    if(!self.isAnimating){
        NSLog(@"select node function");
        [self validateAnimationToNode:[self.nodes objectAtIndex:index] fromNode:self.selectedNode];
    }
}

- (void)reloadNodeTitleAtIndex:(NSInteger)index {
    
    if(self.nodes.count - 1 >= index){
        UIGuidedViewNode *node = [self.nodes objectAtIndex:index];
        
        if([self.dataSource respondsToSelector:@selector(guidedView:titleForNodeAtIndex:)]){
            node.titleLabel.text = [self.dataSource guidedView:self titleForNodeAtIndex:node.index];
        } else {
            node.titleLabel.text = @"";
        }
    }
}

- (void)reloadNodeTitles {
    
    for(UIGuidedViewNode *node in self.nodes){
        [self reloadNodeTitleAtIndex:node.index];
    }
}

#pragma mark - Private Methods

- (void)setupDefaults {
    self.isAnimating = NO;
    self.didFailValidation = NO;
    self.touchable = YES;
    self.animationSpeed = 1.0f;
    self.animationArray = [NSMutableArray new];
    self.nodes = [NSMutableArray new];
    self.shouldHideTitlesForUnselectedNodes = NO;
    self.backgroundLineColor = kBackgroundLineUIColorDefault;
    self.selectedTitleColor = [UIColor grayColor];
    self.unselectedTitleColor = kBackgroundLineUIColorDefault;
    self.lineColor = kNodeUIColorDefault;
}

- (void)setupPaths {
    
    self.foregroundLinePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(kGuidedViewPadding, (self.frame.size.height / 3) + 1, 1, 3) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(kGuidedViewPadding / 2, kGuidedViewPadding / 2)];
    self.backgroundLinePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(kGuidedViewPadding, (self.frame.size.height / 3) + 1, self.frame.size.width - kGuidedViewPadding * 2, 3.5) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(kGuidedViewPadding / 2, kGuidedViewPadding / 2)];
}

- (void)setupBackgroundLine {
    
    self.backgroundLine = [CAShapeLayer layer];
    self.backgroundLine.path = self.backgroundLinePath.CGPath;
    self.backgroundLine.lineCap = kCALineCapRound;
    self.backgroundLine.fillColor = self.backgroundLineColor.CGColor;
    self.backgroundLine.lineWidth = self.backgroundLinePath.bounds.size.height;
    self.backgroundLine.strokeColor = self.backgroundLineColor.CGColor;
    self.backgroundLine.strokeEnd = 1.0;
    self.backgroundLine.zPosition = -1;
    
    [self.layer addSublayer:self.backgroundLine];
}

- (void)setupForegroundLine {
    
    self.foregroundLine = [CAShapeLayer layer];
    self.foregroundLine.path = self.foregroundLinePath.CGPath;
    self.foregroundLine.lineCap = kCALineCapRound;
    self.foregroundLine.fillColor = self.lineColor.CGColor;
    self.foregroundLine.lineWidth = 1;
    self.foregroundLine.strokeColor = self.lineColor.CGColor;
    self.foregroundLine.strokeEnd = 1.0;
    self.foregroundLine.zPosition = -1;
    self.foregroundLine.rasterizationScale = 2.0 * [UIScreen mainScreen].scale;
    self.foregroundLine.shouldRasterize = YES;
    
    [self.layer addSublayer:self.foregroundLine];
}

- (void)setIsAnimating:(BOOL)isAnimating{
    NSLog(@"%@", isAnimating ? @"YES" : @"NO");
    _isAnimating = isAnimating;
}

- (void)setupNodes {
    
    for(NSInteger i = 0; i < self.numberOfNodes; i++){
        
        UIBezierPath *path = [self shapeLayerPathForIndex:i];
        
        CAShapeLayer *backgroundCircle = [CAShapeLayer layer];
        backgroundCircle.path = path.CGPath;
        backgroundCircle.lineWidth = path.bounds.size.height;
        backgroundCircle.lineCap = kCALineCapRound;
        backgroundCircle.fillColor = self.backgroundLineColor.CGColor;
        backgroundCircle.strokeColor = self.backgroundLineColor.CGColor;
        backgroundCircle.strokeEnd = 1.0;
        backgroundCircle.zPosition = -1;
        
        CAShapeLayer *nodeCircle = [CAShapeLayer layer];
        nodeCircle.path = path.CGPath;
        nodeCircle.lineWidth = kNodeRadius;
        nodeCircle.lineCap = kCALineCapRound;
        nodeCircle.fillColor = self.lineColor.CGColor;
        nodeCircle.strokeColor = self.lineColor.CGColor;
        nodeCircle.strokeEnd = 1.0;
        
        UIGuidedViewNode *node = [[UIGuidedViewNode alloc] init];
        node.backgroundPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(kNodeSpacing, self.backgroundLinePath.center.y) radius:12 startAngle:DEGREES_TO_RADIANS(270) endAngle:DEGREES_TO_RADIANS(270.01) clockwise:NO];
        node.backgroundLayer = nodeCircle;
        node.index = i;
        node.path = path;
        node.layer = nodeCircle;
        node.view = self;
        
        if([self.dataSource respondsToSelector:@selector(guidedView:titleForNodeAtIndex:)] && [self.dataSource guidedView:self titleForNodeAtIndex:i] != nil){
            
            node.titleLabel = [self titleLabelForPath:path title:[self.dataSource guidedView:self titleForNodeAtIndex:i] atIndex:i];
            [self addSubview:node.titleLabel];
        }
        
        if(i == 0){
            self.selectedNode = node;
        }else{
            node.selected = NO;
            node.displaying = NO;
        }
        
        [self.nodes addObject:node];
        
        [self.layer addSublayer:node.layer];
        [self.layer addSublayer:backgroundCircle];
    }
}

- (void)createAnimationToNode:(UIGuidedViewNode *)newNode fromNode:(UIGuidedViewNode *)oldNode inDirection:(UIGuidedViewAnimationDirection)direction andSelectNode:(BOOL)shouldSelect {
    
    if(!self.didFailValidation){
        
        CABasicAnimation *increaseLineWidthAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        increaseLineWidthAnimation.delegate = self;
        increaseLineWidthAnimation.beginTime = CACurrentMediaTime() + self.animationArray.count * 0.2f / self.animationSpeed;
        increaseLineWidthAnimation.duration = 0.2f / self.animationSpeed;
        [increaseLineWidthAnimation setValue:[NSNumber numberWithInteger:direction] forKey:kDirectionKey];
        [increaseLineWidthAnimation setValue:newNode forKey:kNewNodeKey];
        [increaseLineWidthAnimation setValue:oldNode forKey:kOldNodeKey];
        [increaseLineWidthAnimation setValue:[NSNumber numberWithBool:shouldSelect] forKey:kNodeSelection];
        
        if(direction == UIGuidedViewAnimationDirectionBackwards && [self.delegate respondsToSelector:@selector(guidedView:didMultipleTransitionFromIndex:toIndex:inDirection:)]){
            
            if([self.delegate guidedView:self willSingleTransitionFromIndex:oldNode.index toIndex:oldNode.index - 1 inDirection:UIGuidedViewAnimationDirectionBackwards] == NO){
                [increaseLineWidthAnimation setValue:[NSNumber numberWithBool:YES] forKey:kNodeSelection];
                self.didFailValidation = YES;
            }
            
        }
        
        [self.animationArray addObject:increaseLineWidthAnimation];
        
    }
    
    if(shouldSelect){
        [self nextAnimation];
    }
}

- (void)setPathForAnimation:(CABasicAnimation *)animation{
    
    UIBezierPath *path = [self pathFromBaseNodeToNode:(UIGuidedViewNode *)[animation valueForKey:kNewNodeKey]];
    animation.fromValue = (id)self.foregroundLinePath.CGPath;
    animation.toValue = (id)path.CGPath;
    [animation setValue:path forKey:kNewPathKey];
}

- (void)nextAnimation{
    
    CABasicAnimation *animation = [self.animationArray objectAtIndex:0];
    [self.animationArray removeObject:animation];
    
    [self setPathForAnimation:animation];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.foregroundLine addAnimation:animation forKey:@"path"];
    });
}

- (UIBezierPath *)pathFromBaseNodeToNode:(UIGuidedViewNode *)furtherNode {
    
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(kGuidedViewPadding, (self.frame.size.height / 3) + 1, furtherNode.index * self.backgroundLinePath.bounds.size.width / (self.numberOfNodes - 1), 3) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(kGuidedViewPadding / 2, kGuidedViewPadding / 2)];
}

- (void)validateAnimationToNode:(UIGuidedViewNode *)newNode fromNode:(UIGuidedViewNode *)oldNode {
    self.isAnimating = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(newNode.index != oldNode.index){
            
            if(oldNode.index < newNode.index) {
                
                if([self canMakeMultipleTransitionToNode:newNode fromNode:oldNode inDirection:UIGuidedViewAnimationDirectionForwards]){
                    
                    for(NSInteger oldIndex = oldNode.index; oldIndex < newNode.index; oldIndex++){
                        
                        NSInteger nextIndex = oldIndex + 1;
                        
                        if([self.delegate respondsToSelector:@selector(guidedView:willSingleTransitionFromIndex:toIndex:inDirection:)]){
                            
                            if([self.delegate guidedView:self willSingleTransitionFromIndex:oldIndex toIndex:nextIndex inDirection:UIGuidedViewAnimationDirectionForwards]){
                                
                                if(nextIndex == newNode.index){
                                    [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionForwards andSelectNode:YES];
                                }else{
                                    [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionForwards andSelectNode:NO];
                                }
                                
                            } else {
                                [self createAnimationToNode:[self.nodes objectAtIndex:oldIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionForwards andSelectNode:YES];
                                break;
                            }
                            
                        } else {
                            
                            if(nextIndex == newNode.index){
                                [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionForwards andSelectNode:YES];
                            }else{
                                [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionForwards andSelectNode:NO];
                            }
                        }
                    }
                }
                
            } else {
                
                if([self canMakeMultipleTransitionToNode:newNode fromNode:oldNode inDirection:UIGuidedViewAnimationDirectionBackwards]){
                    
                    for(NSInteger oldIndex = oldNode.index; oldIndex > newNode.index; oldIndex--){
                        
                        NSInteger nextIndex = oldIndex - 1;
                        
                        if([self.delegate respondsToSelector:@selector(guidedView:willSingleTransitionFromIndex:toIndex:inDirection:)]){
                            
                            if([self.delegate guidedView:self willSingleTransitionFromIndex:oldIndex toIndex:nextIndex inDirection:UIGuidedViewAnimationDirectionBackwards]){
                                
                                if(nextIndex == newNode.index){
                                    [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionBackwards andSelectNode:YES];
                                }else{
                                    [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionBackwards andSelectNode:NO];
                                }
                                
                            } else {
                                [self createAnimationToNode:[self.nodes objectAtIndex:oldIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionBackwards andSelectNode:YES];
                                break;
                            }
                            
                        } else {
                            
                            if(nextIndex == newNode.index){
                                [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionBackwards andSelectNode:YES];
                            }else{
                                [self createAnimationToNode:[self.nodes objectAtIndex:nextIndex] fromNode:[self.nodes objectAtIndex:oldIndex] inDirection:UIGuidedViewAnimationDirectionBackwards andSelectNode:NO];
                            }
                        }
                    }
                }
            }
        }
    });
    
}

- (BOOL)canMakeMultipleTransitionToNode:(UIGuidedViewNode *)node fromNode:(UIGuidedViewNode *)fromNode inDirection:(UIGuidedViewAnimationDirection)direction {
    
    BOOL canMultipleTransition = YES;
    
    if([self.delegate respondsToSelector:@selector(guidedView:willMultipleTransitionFromIndex:toIndex:inDirection:)] && labs(node.index - fromNode.index) > 1){
        
        canMultipleTransition = [self.delegate guidedView:self willMultipleTransitionFromIndex:fromNode.index toIndex:node.index inDirection:direction];
    }
    
    return canMultipleTransition;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!self.isAnimating && self.isTouchable){
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint location = [touch locationInView:touch.view];
        
        for(UIGuidedViewNode *node in self.nodes){
            if(CGPathContainsPoint(node.backgroundPath.CGPath, 0, location, YES)){
                [self validateAnimationToNode:node fromNode:self.selectedNode];
            }
        }
    }
}

- (UIBezierPath *)shapeLayerPathForIndex:(NSInteger)index {
    
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.backgroundLinePath.bounds.origin.x + index * self.backgroundLinePath.bounds.size.width / (self.numberOfNodes - 1), self.backgroundLinePath.center.y) radius:4 startAngle:DEGREES_TO_RADIANS(270) endAngle:DEGREES_TO_RADIANS(270.01) clockwise:NO];
    
}

- (UILabel *)titleLabelForPath:(UIBezierPath *)path title:(NSString *)title atIndex:(NSInteger)index {
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Medium" size:9],
                                 NSForegroundColorAttributeName:kBackgroundLineUIColorDefault,
                                 NSParagraphStyleAttributeName: paragraphStyle
                                 };
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title
                                                                                       attributes:attributes];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.backgroundLinePath.bounds.origin.y + kUIGuidedViewNodeTitleLabelYValue, self.backgroundLinePath.bounds.size.width / self.numberOfNodes * 1.1, 10)];
    titleLabel.center = CGPointMake(path.center.x, titleLabel.frame.origin.y);
    titleLabel.attributedText = attributedText;
    
    return titleLabel;
}

#pragma mark - CABasicAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim {
    
    UIGuidedViewNode *oldNode = [anim valueForKey:kOldNodeKey];
    UIGuidedViewNode *newNode = [anim valueForKey:kNewNodeKey];
    UIBezierPath *path = (UIBezierPath *)[anim valueForKey:kNewPathKey];
    UIGuidedViewAnimationDirection direction = [(NSNumber *)[anim valueForKey:kDirectionKey] integerValue];
    
    self.foregroundLinePath = path;
    
    if([[anim valueForKey:kNodeSelection] boolValue]){
        
        if(direction == UIGuidedViewAnimationDirectionBackwards && oldNode != newNode){
            dispatch_async(dispatch_get_main_queue(), ^{
                oldNode.displaying = NO;
            });
        }
        
    }else{
        
        if(direction == UIGuidedViewAnimationDirectionBackwards && oldNode != newNode){
            dispatch_async(dispatch_get_main_queue(), ^{
                oldNode.displaying = NO;
            });
        }
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    UIGuidedViewAnimationDirection direction = [(NSNumber *)[anim valueForKey:kDirectionKey] integerValue];
    UIGuidedViewNode *newNode = [anim valueForKey:kNewNodeKey];
    UIGuidedViewNode *oldNode = [anim valueForKey:kOldNodeKey];
    BOOL shouldSelect = (BOOL)[[anim valueForKey:kNodeSelection] boolValue];
    
    
    if([self.delegate respondsToSelector:@selector(guidedView:didSingleTransitionFromIndex:toIndex:inDirection:)] && oldNode.index != newNode.index){
        [self.delegate guidedView:self didSingleTransitionFromIndex:oldNode.index toIndex:newNode.index inDirection:direction];
    }
    
    if(shouldSelect){
        
        if([self.delegate respondsToSelector:@selector(guidedView:didMultipleTransitionFromIndex:toIndex:inDirection:)] && labs(self.selectedNodeIndex - newNode.index) > 1){
            [self.delegate guidedView:self didMultipleTransitionFromIndex:self.selectedNode.index toIndex:newNode.index inDirection:direction];
        }
        
        self.isAnimating = NO;
        self.selectedNode = newNode;
        
    } else {
        newNode.displaying = YES;
    }
    
    if(direction == UIGuidedViewAnimationDirectionBackwards && oldNode != newNode){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            oldNode.displaying = NO;
        });
        
    }
    
    if(self.animationArray.count > 0){
        [self nextAnimation];
    } else {
        self.didFailValidation = NO;
    }
}

@end
