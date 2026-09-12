#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EngineBridge : NSObject
+ (NSString *)diagnoseGameFolderURL:(NSURL *)url;
+ (BOOL)isRuntimeLinked;
+ (NSString *)runtimeStatusText;
@end

NS_ASSUME_NONNULL_END
