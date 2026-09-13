#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EngineRuntimeHost;

@protocol EngineRuntimeHostDelegate <NSObject>
- (void)engineRuntimeHost:(EngineRuntimeHost *)host didAppendLog:(NSString *)text;
- (void)engineRuntimeHost:(EngineRuntimeHost *)host didProduceImage:(UIImage *)image pixelSize:(CGSize)pixelSize;
- (void)engineRuntimeHost:(EngineRuntimeHost *)host didChangeRunning:(BOOL)running;
@end

@interface EngineRuntimeHost : NSObject
@property(nonatomic, weak, nullable) id<EngineRuntimeHostDelegate> delegate;
@property(nonatomic, readonly, getter=isRunning) BOOL running;
+ (BOOL)isEngineLinked;
+ (NSString *)backendDescription;
- (BOOL)startGameAtURL:(NSURL *)gameRoot error:(NSError * _Nullable * _Nullable)error;
- (void)stop;
- (void)sendPointerType:(NSUInteger)type x:(double)x y:(double)y pointerID:(NSInteger)pointerID;
@end

NS_ASSUME_NONNULL_END
