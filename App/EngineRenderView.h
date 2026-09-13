#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class EngineRuntimeHost;

@interface EngineRenderView : UIImageView
@property(nonatomic, weak, nullable) EngineRuntimeHost *runtimeHost;
@property(nonatomic) CGSize enginePixelSize;
@end

NS_ASSUME_NONNULL_END
