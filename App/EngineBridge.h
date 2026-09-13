#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EngineBridge : NSObject
+ (nullable NSURL *)resolvedGameRootURLForSelectedURL:(NSURL *)url;
+ (NSString *)diagnoseGameFolderURL:(NSURL *)url;
+ (NSString *)startupProbeForGameFolderURL:(NSURL *)url;
+ (BOOL)isRuntimeLinked;
+ (NSString *)runtimeStatusText;
@end

NS_ASSUME_NONNULL_END
