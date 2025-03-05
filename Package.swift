// swift-tools-version: 6.1

import PackageDescription

let targetSwiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableExperimentalFeature("StrictConcurrency"),
  .enableExperimentalFeature("LifetimeDependence"),
  .enableExperimentalFeature("NoImplicitCopy"),
]

let testTargetSwiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableExperimentalFeature("StrictConcurrency"),
  .enableExperimentalFeature("LifetimeDependence"),
  .enableExperimentalFeature("NoImplicitCopy"),
]

func experimentTargets(
  targetName: String,
  targetDependencies: [Target.Dependency] = [],
  targetSwiftSettings: [SwiftSetting] = targetSwiftSettings,
  testTargetName: String,
  testTargetDependencies: [Target.Dependency] = [],
  testTargetSwiftSettings: [SwiftSetting] = testTargetSwiftSettings,
) -> [Target] {
  [
    .target(
      name: targetName,
      dependencies: targetDependencies,
      swiftSettings: targetSwiftSettings,
    ),
    .testTarget(
      name: testTargetName,
      dependencies: [.byName(name: targetName)] + testTargetDependencies,
      swiftSettings: testTargetSwiftSettings,
    ),
  ]
}

let package: Package = Package(
  name: "ExperimentalConcurrency",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
  ],
  products: [
    .library(
      name: "ExperimentalConcurrency",
      targets: [
        "ImmediateCancellation",
        "Lock",
        "SafeContinuation",
        "Unsafe",
      ],
    )
  ],
  targets: []
  + experimentTargets(
      targetName: "Unsafe",
      testTargetName: "UnsafeTests"
    )
  + experimentTargets(
      targetName: "Lock",
      targetDependencies: ["Unsafe"],
      testTargetName: "LockTests",
      testTargetDependencies: ["Unsafe"],
    )
  + experimentTargets(
      targetName: "SafeContinuation",
      targetDependencies: ["Lock", "Unsafe"],
      testTargetName: "SafeContinuationTests",
      testTargetDependencies: ["Lock"],
    )
  + experimentTargets(
      targetName: "ImmediateCancellation",
      targetDependencies: ["Lock", "SafeContinuation", "Unsafe"],
      testTargetName: "ImmediateCancellationTests",
      testTargetDependencies: ["Lock", "SafeContinuation", "Unsafe"],
    )
)
