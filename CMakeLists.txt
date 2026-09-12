cmake_minimum_required(VERSION 3.21)
project(KiriPadPhase1 LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(KIRIPAD_BUNDLE_ID "dev.kiripad.phase1" CACHE STRING "iOS bundle identifier")
option(KIRIPAD_CODE_SIGNING "Enable Xcode code signing settings" ON)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
  message(FATAL_ERROR "KiriPad app target is intended for iOS. Configure with -DCMAKE_SYSTEM_NAME=iOS")
endif()

add_executable(KiriPad MACOSX_BUNDLE
  App/main.mm
  App/AppDelegate.mm
  App/KiriPadViewController.mm
  App/EngineBridge.mm
  Core/GameSignatureScanner.cpp
)

target_include_directories(KiriPad PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/App
  ${CMAKE_CURRENT_SOURCE_DIR}/Core
)

target_compile_options(KiriPad PRIVATE
  $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra>
  $<$<COMPILE_LANGUAGE:OBJCXX>:-Wall -Wextra>
)

target_link_libraries(KiriPad PRIVATE
  "-framework UIKit"
  "-framework Foundation"
  "-framework UniformTypeIdentifiers"
)

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
