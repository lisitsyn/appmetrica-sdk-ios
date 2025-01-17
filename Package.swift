// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

enum AppMetricaTarget: String {
    case core = "AppMetricaCore"
    case crashes = "AppMetricaCrashes"
    case coreExtension = "AppMetricaCoreExtension"
    case adSupport = "AppMetricaAdSupport"
    case webKit = "AppMetricaWebKit"
    case log = "AppMetricaLog"
    case coreUtils = "AppMetricaCoreUtils"
    case testUtils = "AppMetricaTestUtils"
    case network = "AppMetricaNetwork"
    case hostState = "AppMetricaHostState"
    case platform = "AppMetricaPlatform"
    case protobufUtils = "AppMetricaProtobufUtils"
    case storageUtils = "AppMetricaStorageUtils"
    case encodingUtils = "AppMetricaEncodingUtils"
    
    case protobuf = "AppMetrica_Protobuf"
    case fmdb = "AppMetrica_FMDB"
    
    var name: String { rawValue }
    var testsName: String { rawValue + "Tests" }
    var path: String { "\(rawValue)/Sources" }
    var testsPath: String { "\(rawValue)/Tests" }
    var dependency: Target.Dependency { .target(name: rawValue) }
}

//MARK: - Target Dependencies -
let kiwi = Target.Dependency.byName(name: "Kiwi")
let ksKrash = Target.Dependency.byName(name: "KSCrash")

let package = Package(
    name: "AppMetrica",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11),
    ],
    products: [
        .library(name: "AppMetricaCore", targets: [AppMetricaTarget.core.name,
                                                   AppMetricaTarget.coreExtension.name]),
        .library(name: "AppMetricaAnalytics", targets: [AppMetricaTarget.core.name,
                                                        AppMetricaTarget.coreExtension.name,
                                                        AppMetricaTarget.adSupport.name,
                                                        AppMetricaTarget.webKit.name]),
        .library(name: "AppMetricaCrashes", targets: [AppMetricaTarget.crashes.name]),
        .library(name: "AppMetricaAnalyticsNoAdSupport", targets: [AppMetricaTarget.core.name,
                                                                   AppMetricaTarget.coreExtension.name,
                                                                   AppMetricaTarget.webKit.name]),
        .library(name: "AppMetricaAdSupport", targets: [AppMetricaTarget.adSupport.name]),
        .library(name: "AppMetricaWebKit", targets: [AppMetricaTarget.webKit.name]),
    ],
    dependencies: [
        // Crash dependencies
        .package(name: "KSCrash", url: "https://github.com/kstenerud/KSCrash", .upToNextMinor(from: "1.16.1")),
        // Test dependencies
        .package(name: "Kiwi", url: "https://github.com/appmetrica/Kiwi", .upToNextMinor(from: "3.0.1-spm")),
    ],
    targets: [
        //MARK: - AppMetrica SDK -
        .target(
            target: .core,
            dependencies: [
                .network, .log, .coreUtils, .hostState, .protobufUtils, .platform, .storageUtils, .encodingUtils, .protobuf, .fmdb
            ],
            outerDependencies: [],
            searchPaths: [
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension", "./**"
            ]
        ),
        .testTarget(
            target: .core,
            dependencies: [
                .core, .coreExtension, .webKit, .testUtils, .hostState, .protobufUtils, .platform
            ],
            outerDependencies: [kiwi],
            searchPaths: [
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension", "./**", "../Sources/**"
            ],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica Crashes
        .target(
            target: .crashes,
            dependencies: [
                .core, .log, .coreExtension, .hostState, .protobufUtils, .platform, .storageUtils, .encodingUtils, .protobuf
            ],
            outerDependencies: [ksKrash],
            searchPaths: ["./**"]
        ),
        .testTarget(
            target: .crashes,
            dependencies: [.crashes, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**", "./Helpers"],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica CoreExtension
        .target(
            target: .coreExtension,
            dependencies: [.core, .storageUtils],
            searchPaths: ["./**"]
        ),
        
        //MARK: - AppMetrica Log
        .target(target: .log),
        .testTarget(
            target: .log,
            dependencies: [.log],
            searchPaths: ["../Sources"]
        ),
        
        //MARK: - AppMetrica Protobuf
        .target(target: .protobuf),
        
        //MARK: - AppMetrica ProtobufUtils
        .target(target: .protobufUtils, dependencies: [.protobuf]),
        .testTarget(
            target: .protobufUtils,
            dependencies: [.protobufUtils]
        ),
        
        //MARK: - AppMetrica CoreUtils
        .target(
            target: .coreUtils,
            dependencies: [.log],
            searchPaths: ["./**"]
        ),
        .testTarget(
            target: .coreUtils,
            dependencies: [.coreUtils, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["Utilities", "../Sources/include/AppMetricaCoreUtils"]
        ),
        
        //MARK: - AppMetrica TestUtils
        .target(target: .testUtils, dependencies: [.coreUtils, .network, .storageUtils, .hostState], outerDependencies: [kiwi]),
        
        //MARK: - AppMetrica Network
        .target(
            target: .network,
            dependencies: [.log, .coreUtils, .platform]
        ),
        .testTarget(
            target: .network,
            dependencies: [.network, .platform, .coreExtension, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["Utilities", "../Sources/include/AppMetricaNetwork"]
        ),
        
        //MARK: - AppMetrica AdSupport
        .target(target: .adSupport, dependencies: [.core, .coreExtension]),
        .testTarget(
            target: .adSupport,
            dependencies: [.adSupport, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica WebKit
        .target(target: .webKit, dependencies: [.core, .log, .coreUtils]),
        .testTarget(
            target: .webKit,
            dependencies: [.webKit, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica HostState
        .target(target: .hostState, dependencies: [.coreUtils, .log]),
        .testTarget(
            target: .hostState,
            dependencies: [.hostState, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica Platform
        .target(target: .platform, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .platform,
            dependencies: [.platform, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica StorageUtils
        .target(target: .storageUtils, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .storageUtils,
            dependencies: [.storageUtils, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica EncodingUtils
        .target(target: .encodingUtils, dependencies: [.log, .platform, .coreUtils]),
        .testTarget(
            target: .encodingUtils,
            dependencies: [.encodingUtils, .testUtils],
            outerDependencies: [kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica FMDB
        .target(target: .fmdb),
    ]
)

extension Target {
    static func target(target: AppMetricaTarget,
                       dependencies: [AppMetricaTarget] = [],
                       outerDependencies: [Target.Dependency] = [],
                       searchPaths: [String] = []) -> Target {
        return .target(
            name: target.name,
            dependencies: combinedDependencies(from: dependencies, outerDependencies: outerDependencies),
            path: target.path,
            cSettings: combinedSettings(from: searchPaths, path: target.path)
        )
    }
    
    static func testTarget(target: AppMetricaTarget,
                           dependencies: [AppMetricaTarget] = [],
                           testUtils: [AppMetricaTarget] = [],
                           outerDependencies: [Target.Dependency] = [],
                           searchPaths: [String] = [],
                           resources: [Resource]? = nil) -> Target {
        
        return .testTarget(
            name: target.testsName,
            dependencies: combinedDependencies(from: dependencies, outerDependencies: outerDependencies),
            path: target.testsPath,
            resources: resources,
            cSettings: combinedSettings(from: searchPaths, path: target.testsPath)
        )
    }
    
    private static func combinedSettings(from searchPaths: [String], path: String) -> [CSetting] {
        var cSettings: [CSetting] = []
        for searchPath in searchPaths {
            if searchPath.hasSuffix("**") {
                cSettings += headerSearchPaths(path, relativeSearchPath: String(searchPath.dropLast(2)))
            } else {
                cSettings.append(.headerSearchPath(searchPath))
            }
        }
        return cSettings
    }
    
    private static func combinedDependencies(from dependencies: [AppMetricaTarget],
                                             outerDependencies: [Target.Dependency]) -> [Target.Dependency] {
        return dependencies.map { $0.dependency } + outerDependencies
    }
    
    private static func headerSearchPaths(_ targetPath: String, relativeSearchPath: String = ".") -> [CSetting] {
        let fileManager = FileManager.default
        let packageDirectoryURL = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let targetPathURL = packageDirectoryURL.appendingPathComponent(targetPath)
        let fullPathURL = targetPathURL.appendingPathComponent(relativeSearchPath).resolvingSymlinksInPath()
        
        var settings: [CSetting] = []
        
        settings.append(.headerSearchPath(relativeSearchPath))
        
        guard let enumerator = fileManager.enumerator(at: fullPathURL, includingPropertiesForKeys: nil) else {
            return settings
        }
        for case let fileOrDirURL as URL in enumerator {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: fileOrDirURL.path, isDirectory: &isDir), isDir.boolValue {
                if let relativePath = relativePath(from: fullPathURL, toDestination: fileOrDirURL) {
                    let combinedPath = [relativeSearchPath, relativePath]
                        .joined(separator: "/")
                        .replacingOccurrences(of: "//", with: "/")
                    settings.append(.headerSearchPath(combinedPath))
                }
            }
        }
        
        return settings
    }

    private static func relativePath(from base: URL, toDestination dest: URL) -> String? {
        let destComponents = dest.pathComponents
        let baseComponents = base.pathComponents
        
        let commonCount = zip(destComponents, baseComponents).prefix(while: { $0.0 == $0.1 }).count

        let downwardPaths = destComponents[commonCount...]

        return downwardPaths.joined(separator: "/")
    }
}
