# Game Center Integration Guide for Tiny Pilots

This document provides instructions for setting up and testing Game Center integration in the Tiny Pilots game.

## Setup Instructions

### 1. Enable Game Center Capability in Xcode

1. Open your project in Xcode
2. Select the "Tiny Pilots" project in the Project Navigator
3. Select the "Tiny Pilots" target
4. Go to the "Signing & Capabilities" tab
5. Click the "+" button to add a capability
6. Select "Game Center" from the list
7. Verify that the Game Center capability is now added to your project

### 2. Configure Game Center in App Store Connect

1. Log in to App Store Connect (https://appstoreconnect.apple.com/)
2. Go to "My Apps" and select your app (or create a new one if it doesn't exist)
3. Go to the "Features" tab
4. Select "Game Center" from the sidebar
5. Configure your leaderboards and achievements:

#### Leaderboards

Create the following leaderboards with the exact IDs:

| Display Name | Leaderboard ID | Format |
|--------------|----------------|--------|
| Distance (Free Play) | com.tinypilots.leaderboard.distance.freeplay | Numeric (meters) |
| Distance (Challenge) | com.tinypilots.leaderboard.distance.challenge | Numeric (meters) |
| Distance (Daily Run) | com.tinypilots.leaderboard.distance.dailyrun | Numeric (meters) |
| Flight Time | com.tinypilots.leaderboard.flighttime | Time (seconds) |
| High Score | com.tinypilots.leaderboard.highscore | Numeric (points) |

#### Achievements

Create the following achievements with the exact IDs:

| Display Name | Achievement ID | Points |
|--------------|----------------|--------|
| First Flight | com.tinypilots.achievement.firstflight | 10 |
| 1000m Flight | com.tinypilots.achievement.distance1000 | 20 |
| 5000m Flight | com.tinypilots.achievement.distance5000 | 30 |
| 10000m Flight | com.tinypilots.achievement.distance10000 | 50 |
| 3-Day Streak | com.tinypilots.achievement.dailystreak3 | 20 |
| 7-Day Streak | com.tinypilots.achievement.dailystreak7 | 30 |
| 30-Day Streak | com.tinypilots.achievement.dailystreak30 | 50 |
| 1 Hour Flight Time | com.tinypilots.achievement.flighttime1hour | 30 |
| All Airplanes | com.tinypilots.achievement.allairplanes | 40 |
| All Environments | com.tinypilots.achievement.allenvironments | 40 |
| First Challenge | com.tinypilots.achievement.firstchallenge | 20 |
| 10 Challenges | com.tinypilots.achievement.challenges10 | 30 |

### 3. Testing Game Center

#### Development Testing

1. Make sure you're signed in to Game Center on your test device or simulator
2. Use the Sandbox environment for testing
3. Use the built-in debug menu in the game to test Game Center features

#### Using the Debug Menu

The game includes a debug menu for testing Game Center features:

1. In the main menu, tap the hidden debug button in the bottom-right corner
2. Select "Game Center Debug" from the menu
3. Choose a test to run:
   - Test Authentication: Verifies that the user is authenticated with Game Center
   - Test Leaderboard Submission: Submits a random score to the distance leaderboard
   - Test Achievement Reporting: Reports 100% completion for the distance achievement
   - Test Challenge Code: Tests generating and validating a challenge code
   - Test Invalid Challenge Code: Tests handling an invalid challenge code

#### Troubleshooting

If you encounter issues with Game Center integration:

1. Check the console logs for detailed error messages
2. Verify that all leaderboard and achievement IDs match between code and App Store Connect
3. Make sure the Game Center capability is enabled in Xcode
4. Ensure you're signed in to Game Center on your test device
5. Restart the app and try again

## Implementation Details

The Game Center integration is implemented in the following files:

- `GameCenterManager.swift`: Main manager class for Game Center integration
- `GameCenterConfig.swift`: Configuration constants for Game Center
- `GameCenterTestScript.swift`: Test script for Game Center features

The `GameCenterManager` class provides methods for:

- Authenticating with Game Center
- Submitting scores to leaderboards
- Reporting achievement progress
- Generating and validating challenge codes
- Showing Game Center UI

## Additional Resources

- [Game Center Programming Guide](https://developer.apple.com/documentation/gamekit/game_center)
- [Game Center for iOS: Leaderboards](https://developer.apple.com/documentation/gamekit/gkleaderboard)
- [Game Center for iOS: Achievements](https://developer.apple.com/documentation/gamekit/gkachievement) 