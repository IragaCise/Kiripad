cmake_minimum_required(VERSION 3.21)
project(KiriPadPhase2A LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(KIRIPAD_BUNDLE_ID "dev.kiripad.phase1" CACHE STRING "iOS bundle identifier")
option(KIRIPAD_CODE_SIGNING "Enable Xcode code signing settings" ON)
option(KIRIPAD_ENGINE_LINKED "Link experimental KrKr2-Next engine archives" OFF)
set(KIRIPAD_ENGINE_PROJECT_LIB "" CACHE FILEPATH "Path to libengine_project.a")
set(KIRIPAD_ENGINE_VENDOR_LIB "" CACHE FILEPATH "Path to libengine_vendors.a")

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
  message(FATAL_ERROR "KiriPad app target is intended for iOS. Configure with -DCMAKE_SYSTEM_NAME=iOS")
endif()

add_executable(KiriPad MACOSX_BUNDLE
  App/main.mm
  App/AppDelegate.mm
  App/KiriPadViewController.mm
  App/EngineBridge.mm
  App/EngineRuntimeHost.mm
  App/EngineRenderView.mm
  Core/GameSignatureScanner.cpp
  Core/GameRootResolver.cpp
  Core/StartupProbe.cpp
)

target_include_directories(KiriPad PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/App
  ${CMAKE_CURRENT_SOURCE_DIR}/Core
)

target_compile_options(KiriPad PRIVATE
  $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra>
  $<$<COMPILE_LANGUAGE:OBJCXX>:-Wall -Wextra>
)

target_compile_definitions(KiriPad PRIVATE
  KIRIPAD_ENGINE_LINKED=$<BOOL:${KIRIPAD_ENGINE_LINKED}>
)

target_link_libraries(KiriPad PRIVATE
  "-framework UIKit"
  "-framework Foundation"
  "-framework UniformTypeIdentifiers"
  "-framework CoreGraphics"
  "-framework QuartzCore"
)

if(KIRIPAD_ENGINE_LINKED)
  if(NOT EXISTS "${KIRIPAD_ENGINE_PROJECT_LIB}")
    message(FATAL_ERROR "KIRIPAD_ENGINE_PROJECT_LIB does not exist: ${KIRIPAD_ENGINE_PROJECT_LIB}")
  endif()
  if(NOT EXISTS "${KIRIPAD_ENGINE_VENDOR_LIB}")
    message(FATAL_ERROR "KIRIPAD_ENGINE_VENDOR_LIB does not exist: ${KIRIPAD_ENGINE_VENDOR_LIB}")
  endif()

  target_link_libraries(KiriPad PRIVATE
    "${KIRIPAD_ENGINE_PROJECT_LIB}"
    "${KIRIPAD_ENGINE_VENDOR_LIB}"
    "-framework IOSurface"
    "-framework CoreVideo"
    "-framework Metal"
    "-framework Accelerate"
    "-framework AudioToolbox"
    "-framework AVFoundation"
    "-framework CoreAudio"
    "-framework CoreFoundation"
    "-framework CoreMotion"
    "-framework CoreMedia"
    "-framework CoreBluetooth"
    "-framework CoreText"
    "-framework OpenGLES"
    "-framework VideoToolbox"
    "-framework Security"
    "-lxml2"
    "-lz"
    "-lbz2"
    "-liconv"
    "-lresolv"
  )

  # Upstream's iOS bridge force-loads project objects so static initializers and
  # plug-in registrations are retained, while vendor archives are linked normally.
  target_link_options(KiriPad PRIVATE
    "-ObjC"
    "SHELL:-weak_framework GameController"
    "SHELL:-weak_framework CoreHaptics"
    "-Wl,-force_load,${KIRIPAD_ENGINE_PROJECT_LIB}"
  )
endif()

set_target_properties(KiriPad PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Resources/Info.plist.in"
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${KIRIPAD_BUNDLE_ID}"
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "2"
  XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "15.0"
  XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
  XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
)

if(NOT KIRIPAD_CODE_SIGNING)
  set_target_properties(KiriPad PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
  )
endif()
