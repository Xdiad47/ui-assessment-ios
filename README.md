# Itzeazy iOS App 🚀

A pixel-perfect, production-ready reconstruction of the "Itzeazy" application UI using **SwiftUI**. This application is built with a strictly enforced **MVVM (Model-View-ViewModel)** architecture to ensure scalable, maintainable, and robust code.

## 🌟 Features

- **Pixel-Perfect UI**: Precisely mirrors design specifications, including component layouts, typography, shadows, and color schemes.
- **MVVM Architecture**: Clean separation of concerns with robust ViewModels managing the application state.
- **Modularized Interface**: Reusable SwiftUI components (e.g., `InfoCardView`, `BannerCardView`) for a scrollable and dynamic user experience.
- **Static Repository**: Mock data integration simulating real-world data flow and making the application ready for backend connection.

## 📸 Screenshots & Demo

Here is a look at the reconstructed UI:

<div align="center">
  <img src="./Screenshots:Video/Home%20screen.PNG" width="250" alt="Home Screen Top" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="./Screenshots:Video/Home%20screen%20bottom.PNG" width="250" alt="Home Screen Bottom" />
</div>

### 🎥 Video Demonstration

Check out the interactive SwiftUI experience and animations in the video below:

[Watch the iOS App Demo](./Screenshots:Video/ios_app_on%20iphone.mp4)

*(Note: GitHub supports `.mp4` playback. You can click the link above or view it directly in the `Screenshots:Video` folder.)*

## 🛠 Tech Stack

- **Framework**: SwiftUI
- **Language**: Swift
- **Architecture**: MVVM (Model-View-ViewModel)
- **Deployment Target**: iOS 15.0+

## 📁 Project Structure

- `Models/` - Data structures and entities (e.g., `Models.swift`).
- `Views/` - SwiftUI views.
  - `Screens/` - Main views like `HomeView`.
  - `Components/` - Reusable UI components like `InfoCardView` and `BannerCardView`.
- `ViewModels/` - Logic bridging Models and Views.
- `Repository/` - Data access layer (e.g., `MockRepository`).

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/Xdiad47/ui-assessment-ios.git
   ```
2. Open `Itzeazy.xcodeproj` in Xcode.
3. Select your preferred iOS Simulator or device.
4. Press `Cmd + R` to build and run the app.

---
*Developed with ❤️ using SwiftUI.*
