#import "EngineRuntimeHost.h"
#import <QuartzCore/QuartzCore.h>

#if KIRIPAD_ENGINE_LINKED
#include "EngineApiABI.hpp"
#endif

#include <algorithm>
#include <atomic>
#include <chrono>
#include <memory>
#include <vector>

static NSString * const KiriPadRuntimeErrorDomain = @"KiriPadRuntime";

@interface EngineRuntimeHost () {
#if KIRIPAD_ENGINE_LINKED
    engine_handle_t _engine;
    dispatch_source_t _timer;
    dispatch_queue_t _engineQueue;
    uint64_t _lastFrameSerial;
#endif
    std::atomic_bool _runningAtomic;
}
@end

@implementation EngineRuntimeHost

+ (BOOL)isEngineLinked {
#if KIRIPAD_ENGINE_LINKED
    return YES;
#else
    return NO;
#endif
}

+ (NSString *)backendDescription {
#if KIRIPAD_ENGINE_LINKED
    return @"KrKr2-Next engine_api (experimental iOS runtime)";
#else
    return @"ランタイム未リンク版（診断・起動前プローブのみ）";
#endif
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _runningAtomic.store(false);
#if KIRIPAD_ENGINE_LINKED
        _engine = nullptr;
        _timer = nil;
        _engineQueue = dispatch_queue_create("dev.kiripad.engine", DISPATCH_QUEUE_SERIAL);
        _lastFrameSerial = 0;
#endif
    }
    return self;
}

- (BOOL)isRunning {
    return _runningAtomic.load();
}

- (void)notifyLog:(NSString *)text {
    if (!text.length) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        id<EngineRuntimeHostDelegate> delegate = self.delegate;
        if (delegate) [delegate engineRuntimeHost:self didAppendLog:text];
    });
}

- (void)notifyRunning:(BOOL)running {
    _runningAtomic.store(running);
    dispatch_async(dispatch_get_main_queue(), ^{
        id<EngineRuntimeHostDelegate> delegate = self.delegate;
        if (delegate) [delegate engineRuntimeHost:self didChangeRunning:running];
    });
}

#if KIRIPAD_ENGINE_LINKED
- (NSString *)lastEngineError {
    if (!_engine) return @"engine handle is null";
    const char *msg = engine_get_last_error(_engine);
    if (!msg || !*msg) return @"(no detail)";
    return [NSString stringWithUTF8String:msg] ?: @"(invalid UTF-8 error)";
}

- (void)drainStartupLogs {
    if (!_engine) return;
    char buffer[16384];
    uint32_t written = 0;
    for (int i = 0; i < 8; ++i) {
        written = 0;
        const auto result = engine_drain_startup_logs(_engine, buffer, sizeof(buffer) - 1, &written);
        if (result != ENGINE_RESULT_OK || written == 0) break;
        buffer[std::min<uint32_t>(written, sizeof(buffer) - 1)] = '\0';
        NSString *line = [[NSString alloc] initWithBytes:buffer length:written encoding:NSUTF8StringEncoding];
        if (line.length) [self notifyLog:line];
        if (written < sizeof(buffer) - 1) break;
    }
}

- (void)captureFrameIfAvailable {
    if (!_engine) return;
    engine_frame_desc_t desc{};
    desc.struct_size = sizeof(desc);
    if (engine_get_frame_desc(_engine, &desc) != ENGINE_RESULT_OK) return;
    if (desc.width == 0 || desc.height == 0 || desc.stride_bytes == 0) return;
    if (desc.pixel_format != ENGINE_PIXEL_FORMAT_RGBA8888) return;
    if (desc.frame_serial != 0 && desc.frame_serial == _lastFrameSerial) return;

    const size_t bytes = static_cast<size_t>(desc.stride_bytes) * desc.height;
    if (bytes == 0 || bytes > 256ull * 1024ull * 1024ull) return;
    std::vector<uint8_t> storage(bytes);
    if (engine_read_frame_rgba(_engine, storage.data(), storage.size()) != ENGINE_RESULT_OK) return;
    _lastFrameSerial = desc.frame_serial;

    const uint32_t width = desc.width;
    const uint32_t height = desc.height;
    const uint32_t stride = desc.stride_bytes;
    NSData *frameData = [NSData dataWithBytes:storage.data() length:storage.size()];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)frameData);
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaLast;
        CGImageRef cg = CGImageCreate(width, height, 8, 32, stride, cs, bitmapInfo,
                                     provider, nullptr, false, kCGRenderingIntentDefault);
        UIImage *image = cg ? [UIImage imageWithCGImage:cg] : nil;
        if (cg) CGImageRelease(cg);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(cs);
        if (image) {
            id<EngineRuntimeHostDelegate> delegate = self.delegate;
            if (delegate) [delegate engineRuntimeHost:self didProduceImage:image pixelSize:CGSizeMake(width, height)];
        }
    });
}

- (void)tickOnce {
    if (!_engine || !_runningAtomic.load()) return;
    const auto result = engine_tick(_engine, 16);
    [self drainStartupLogs];

    uint32_t startupState = ENGINE_STARTUP_STATE_IDLE;
    engine_get_startup_state(_engine, &startupState);
    if (startupState == ENGINE_STARTUP_STATE_FAILED) {
        [self notifyLog:[NSString stringWithFormat:@"\n[Phase2A] startup FAILED: %@\n", [self lastEngineError]]];
        [self stopOnEngineQueue];
        return;
    }
    if (result != ENGINE_RESULT_OK && result != ENGINE_RESULT_INVALID_STATE) {
        [self notifyLog:[NSString stringWithFormat:@"\n[Phase2A] engine_tick error=%d: %@\n", (int)result, [self lastEngineError]]];
    }
    [self captureFrameIfAvailable];
}

- (void)stopOnEngineQueue {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    if (_engine) {
        [self drainStartupLogs];
        engine_destroy(_engine);
        _engine = nullptr;
    }
    _lastFrameSerial = 0;
    [self notifyRunning:NO];
}
#endif

- (BOOL)startGameAtURL:(NSURL *)gameRoot error:(NSError **)error {
#if !KIRIPAD_ENGINE_LINKED
    if (error) {
        *error = [NSError errorWithDomain:KiriPadRuntimeErrorDomain code:1
                                 userInfo:@{NSLocalizedDescriptionKey: @"このIPAはランタイム未リンク版です。Phase 2A Runtime workflowでビルドしてください。"}];
    }
    return NO;
#else
    if (!gameRoot.isFileURL) {
        if (error) *error = [NSError errorWithDomain:KiriPadRuntimeErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:@"ゲームルートがファイルURLではありません。"}];
        return NO;
    }
    if (_runningAtomic.exchange(true)) {
        if (error) *error = [NSError errorWithDomain:KiriPadRuntimeErrorDomain code:3 userInfo:@{NSLocalizedDescriptionKey:@"ランタイムはすでに起動中です。"}];
        return NO;
    }

    NSString *rootPath = gameRoot.path;
    NSString *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *writePath = [support stringByAppendingPathComponent:@"KiriPadRuntime"];
    NSString *cachePath = [cache stringByAppendingPathComponent:@"KiriPadRuntime"];
    NSFileManager *fm = NSFileManager.defaultManager;
    [fm createDirectoryAtPath:writePath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];

    [self notifyRunning:YES];
    [self notifyLog:[NSString stringWithFormat:@"\n[Phase2A] backend: %@\n[Phase2A] opening: %@\n", [EngineRuntimeHost backendDescription], rootPath]];

    dispatch_async(_engineQueue, ^{
        uint32_t runtimeVersion = 0;
        auto versionResult = engine_get_runtime_api_version(&runtimeVersion);
        if (versionResult != ENGINE_RESULT_OK || (runtimeVersion >> 24u) != (ENGINE_API_VERSION >> 24u)) {
            [self notifyLog:[NSString stringWithFormat:@"[Phase2A] engine ABI mismatch: runtime=0x%08x expected=0x%08x\n", runtimeVersion, ENGINE_API_VERSION]];
            [self stopOnEngineQueue];
            return;
        }

        engine_create_desc_t desc{};
        desc.struct_size = sizeof(desc);
        desc.api_version = ENGINE_API_VERSION;
        desc.writable_path_utf8 = writePath.UTF8String;
        desc.cache_path_utf8 = cachePath.UTF8String;
        auto createResult = engine_create(&desc, &_engine);
        if (createResult != ENGINE_RESULT_OK || !_engine) {
            [self notifyLog:[NSString stringWithFormat:@"[Phase2A] engine_create failed: %d\n", (int)createResult]];
            [self stopOnEngineQueue];
            return;
        }

        engine_set_surface_size(_engine, 1280, 720);
        auto openResult = engine_open_game_async(_engine, rootPath.UTF8String, nullptr);
        if (openResult != ENGINE_RESULT_OK) {
            [self notifyLog:[NSString stringWithFormat:@"[Phase2A] engine_open_game_async failed: %d / %@\n", (int)openResult, [self lastEngineError]]];
            [self stopOnEngineQueue];
            return;
        }

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _engineQueue);
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 16 * NSEC_PER_MSEC, 3 * NSEC_PER_MSEC);
        __weak EngineRuntimeHost *weakSelf = self;
        dispatch_source_set_event_handler(_timer, ^{
            EngineRuntimeHost *strongSelf = weakSelf;
            if (strongSelf) [strongSelf tickOnce];
        });
        dispatch_resume(_timer);
    });
    return YES;
#endif
}

- (void)stop {
#if KIRIPAD_ENGINE_LINKED
    if (!_runningAtomic.load()) return;
    dispatch_async(_engineQueue, ^{ [self stopOnEngineQueue]; });
#else
    [self notifyRunning:NO];
#endif
}

- (void)sendPointerType:(NSUInteger)type x:(double)x y:(double)y pointerID:(NSInteger)pointerID {
#if KIRIPAD_ENGINE_LINKED
    if (!_runningAtomic.load()) return;
    dispatch_async(_engineQueue, ^{
        if (!_engine) return;
        engine_input_event_t event{};
        event.struct_size = sizeof(event);
        event.type = (uint32_t)type;
        event.timestamp_micros = (uint64_t)(CACurrentMediaTime() * 1000000.0);
        event.x = x;
        event.y = y;
        event.pointer_id = (int32_t)pointerID;
        event.button = 0;
        engine_send_input(_engine, &event);
    });
#else
    (void)type; (void)x; (void)y; (void)pointerID;
#endif
}

- (void)dealloc {
    [self stop];
}

@end
