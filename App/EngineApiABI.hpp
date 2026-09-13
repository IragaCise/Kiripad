#pragma once

// Minimal ABI declarations used by KiriPad Phase 2A.
// These names/layouts match the public KrKr2-Next engine_api ABI v1.
// The upstream engine itself is NOT redistributed in this repository.

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ENGINE_API_VERSION 0x01000000u

typedef struct engine_handle_s* engine_handle_t;
typedef enum engine_result_t {
    ENGINE_RESULT_OK = 0,
    ENGINE_RESULT_INVALID_ARGUMENT = -1,
    ENGINE_RESULT_INVALID_STATE = -2,
    ENGINE_RESULT_NOT_SUPPORTED = -3,
    ENGINE_RESULT_IO_ERROR = -4,
    ENGINE_RESULT_INTERNAL_ERROR = -5
} engine_result_t;

typedef struct engine_create_desc_t {
    uint32_t struct_size;
    uint32_t api_version;
    const char* writable_path_utf8;
    const char* cache_path_utf8;
    void* user_data;
    uint64_t reserved_u64[4];
    void* reserved_ptr[4];
} engine_create_desc_t;

typedef enum engine_pixel_format_t {
    ENGINE_PIXEL_FORMAT_UNKNOWN = 0,
    ENGINE_PIXEL_FORMAT_RGBA8888 = 1
} engine_pixel_format_t;

typedef struct engine_frame_desc_t {
    uint32_t struct_size;
    uint32_t width;
    uint32_t height;
    uint32_t stride_bytes;
    uint32_t pixel_format;
    uint64_t frame_serial;
    uint64_t reserved_u64[4];
    void* reserved_ptr[4];
} engine_frame_desc_t;

typedef enum engine_input_event_type_t {
    ENGINE_INPUT_EVENT_POINTER_DOWN = 1,
    ENGINE_INPUT_EVENT_POINTER_MOVE = 2,
    ENGINE_INPUT_EVENT_POINTER_UP = 3,
    ENGINE_INPUT_EVENT_POINTER_SCROLL = 4,
    ENGINE_INPUT_EVENT_KEY_DOWN = 5,
    ENGINE_INPUT_EVENT_KEY_UP = 6,
    ENGINE_INPUT_EVENT_TEXT_INPUT = 7,
    ENGINE_INPUT_EVENT_BACK = 8
} engine_input_event_type_t;

typedef enum engine_startup_state_t {
    ENGINE_STARTUP_STATE_IDLE = 0,
    ENGINE_STARTUP_STATE_RUNNING = 1,
    ENGINE_STARTUP_STATE_SUCCEEDED = 2,
    ENGINE_STARTUP_STATE_FAILED = 3
} engine_startup_state_t;

typedef struct engine_input_event_t {
    uint32_t struct_size;
    uint32_t type;
    uint64_t timestamp_micros;
    double x;
    double y;
    double delta_x;
    double delta_y;
    int32_t pointer_id;
    int32_t button;
    int32_t key_code;
    int32_t modifiers;
    uint32_t unicode_codepoint;
    uint32_t reserved_u32;
    uint64_t reserved_u64[2];
    void* reserved_ptr[2];
} engine_input_event_t;

engine_result_t engine_get_runtime_api_version(uint32_t* out_api_version);
engine_result_t engine_create(const engine_create_desc_t* desc, engine_handle_t* out_handle);
engine_result_t engine_destroy(engine_handle_t handle);
engine_result_t engine_open_game_async(engine_handle_t handle, const char* game_root_path_utf8, const char* startup_script_utf8);
engine_result_t engine_get_startup_state(engine_handle_t handle, uint32_t* out_state);
engine_result_t engine_drain_startup_logs(engine_handle_t handle, char* out_buffer, uint32_t buffer_size, uint32_t* out_bytes_written);
engine_result_t engine_tick(engine_handle_t handle, uint32_t delta_ms);
engine_result_t engine_set_surface_size(engine_handle_t handle, uint32_t width, uint32_t height);
engine_result_t engine_get_frame_desc(engine_handle_t handle, engine_frame_desc_t* out_frame_desc);
engine_result_t engine_read_frame_rgba(engine_handle_t handle, void* out_pixels, size_t out_pixels_size);
engine_result_t engine_send_input(engine_handle_t handle, const engine_input_event_t* event);
const char* engine_get_last_error(engine_handle_t handle);

#ifdef __cplusplus
}
#endif
