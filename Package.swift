// swift-tools-version: 6.0

import PackageDescription

let featureTargets: [(name: String, dependencies: [String])] = [
    ("FeatureHome", ["Domain", "Data", "CoreDesign", "CoreSession", "FeatureNotifications"]),
    ("FeatureTimetable", ["Domain", "Data", "CoreDesign"]),
    ("FeatureCourses", ["Domain", "Data", "CoreDesign"]),
    ("FeatureAssessments", ["Domain", "Data", "CoreDesign"]),
    ("FeatureMessages", ["Domain", "Data", "CoreDesign", "CoreSession"]),
    ("FeatureNotices", ["Domain", "Data", "CoreDesign"]),
    ("FeaturePortals", ["Domain", "Data", "CoreDesign", "CoreSession"]),
    ("FeatureSettings", ["Domain", "Data", "CoreDesign", "CoreSession", "FeatureNotifications"]),
    ("FeatureNotifications", ["CoreSession", "Domain", "CoreDesign"]),
    ("FeatureCalendarSync", ["Domain", "Data", "CoreDesign", "CoreCommon"]),
]

func targetDeps(_ names: [String]) -> [Target.Dependency] {
    names.map { .target(name: $0) }
}

let package = Package(
    name: "BetterSEQTALearn",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BetterSEQTALearn",
            targets: ["BetterSEQTALearnApp"]
        ),
        .library(name: "CoreCommon", targets: ["CoreCommon"]),
        .library(name: "CoreDesign", targets: ["CoreDesign"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "CoreSession", targets: ["CoreSession"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "FeatureAuth", targets: ["FeatureAuth"]),
        .library(name: "LearnWidget", targets: ["LearnWidget"]),
    ] + featureTargets.map { .library(name: $0.name, targets: [$0.name]) },
    targets: [
        .target(name: "CoreCommon"),
        .target(
            name: "Domain",
            dependencies: ["CoreCommon"]
        ),
        .target(
            name: "CoreSession",
            dependencies: ["Domain", "CoreCommon"]
        ),
        .target(
            name: "CoreNetworking",
            dependencies: ["CoreSession", "CoreCommon"]
        ),
        .target(
            name: "Data",
            dependencies: ["CoreNetworking", "CoreSession", "Domain", "CoreCommon"]
        ),
        .target(
            name: "CoreDesign",
            dependencies: ["CoreCommon"]
        ),
        .target(
            name: "FeatureAuth",
            dependencies: ["CoreSession", "Domain", "CoreDesign"]
        ),
        .target(
            name: "LearnWidget",
            dependencies: ["CoreDesign", "Domain"],
            path: "Extensions/LearnWidget"
        ),
    ]
    + featureTargets.map { feature in
        .target(
            name: feature.name,
            dependencies: targetDeps(feature.dependencies)
        )
    }
    + [
        .target(
            name: "BetterSEQTALearnApp",
            dependencies: targetDeps([
                "FeatureAuth",
                "FeatureHome",
                "FeatureTimetable",
                "FeatureCourses",
                "FeatureAssessments",
                "FeatureMessages",
                "FeatureNotices",
                "FeaturePortals",
                "FeatureSettings",
                "FeatureNotifications",
                "FeatureCalendarSync",
                "CoreDesign",
                "CoreSession",
                "Domain",
                "Data",
            ])
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data"],
            resources: [.copy("../Fixtures")]
        ),
        .testTarget(
            name: "FeatureAuthTests",
            dependencies: ["FeatureAuth"]
        ),
    ]
)
