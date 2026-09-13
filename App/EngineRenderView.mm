#import "EngineRenderView.h"
#import "EngineRuntimeHost.h"

@implementation EngineRenderView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = NO;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = UIColor.blackColor;
        self.enginePixelSize = CGSizeMake(1280, 720);
    }
    return self;
}

- (CGPoint)enginePointForTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self];
    const CGFloat vw = self.bounds.size.width;
    const CGFloat vh = self.bounds.size.height;
    const CGFloat ew = MAX(self.enginePixelSize.width, 1);
    const CGFloat eh = MAX(self.enginePixelSize.height, 1);
    const CGFloat scale = MIN(vw / ew, vh / eh);
    const CGFloat drawW = ew * scale;
    const CGFloat drawH = eh * scale;
    const CGFloat ox = (vw - drawW) * 0.5;
    const CGFloat oy = (vh - drawH) * 0.5;
    CGFloat x = (p.x - ox) / MAX(scale, 0.0001);
    CGFloat y = (p.y - oy) / MAX(scale, 0.0001);
    x = MIN(MAX(x, 0), ew - 1);
    y = MIN(MAX(y, 0), eh - 1);
    return CGPointMake(x, y);
}

- (void)sendTouch:(UITouch *)touch type:(NSUInteger)type {
    CGPoint p = [self enginePointForTouch:touch];
    [self.runtimeHost sendPointerType:type x:p.x y:p.y pointerID:0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    UITouch *touch = touches.anyObject;
    if (touch) [self sendTouch:touch type:1];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    UITouch *touch = touches.anyObject;
    if (touch) [self sendTouch:touch type:2];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    UITouch *touch = touches.anyObject;
    if (touch) [self sendTouch:touch type:3];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

@end
