# Technology Stack

## Build System
- **Xcode Project**: Standard iOS app project structure
- **Build Tool**: Xcode 14.0+ required
- **Swift Version**: Swift 6.0+
- **Deployment Target**: iOS 18.0+
- **Bundle ID**: GrinSolve.Tiny-Pilots

## Frameworks & Libraries
- **SpriteKit**: Core 2D game engine for rendering and physics
- **GameplayKit**: Game logic and AI components
- **GameKit**: Game Center integration for leaderboards and achievements
- **UIKit**: UI components and app lifecycle management
- **Foundation**: Core system services

## Common Commands

### Building & Running
```bash
# Open project in Xcode
open "Tiny Pilots.xcodeproj"

# Build from command line (if needed)
xcodebuild -project "Tiny Pilots.xcodeproj" -scheme "Tiny Pilots" -configuration Debug

# Run tests
xcodebuild test -project "Tiny Pilots.xcodeproj" -scheme "Tiny Pilots" -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Project Structure
- Main app target: "Tiny Pilots"
- Unit tests: "Tiny PilotsTests" 
- UI tests: "Tiny PilotsUITests"

## Development Requirements
- macOS with Xcode 14.0+
- iOS Simulator or physical iOS device for testing
- Apple Developer account for device testing and App Store distribution

## Performance Considerations
- Target 60 FPS on standard displays, 120 FPS on ProMotion
- SpriteKit physics engine for realistic airplane behavior
- Particle systems for visual effects (wind, trails)
- Asset optimization for various device resolutions