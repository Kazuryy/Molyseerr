# 📺 Molyseerr

> [!WARNING]
> **Unofficial Third-Party Client**
>
> Molyseerr is an **independent, community-driven project** and is **NOT affiliated with, endorsed by, or maintained by the [Seerr team](https://github.com/seerr-app/seerr)**. This is an unofficial client created by the community to bring Seerr functionality to Apple TV.

<div align="center">

![tvOS](https://img.shields.io/badge/tvOS-17.0+-black.svg?style=flat&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-blue.svg?style=flat)
![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)
[![CI](https://github.com/VOTRE_USERNAME/molyseerr/workflows/CI/badge.svg)](https://github.com/VOTRE_USERNAME/molyseerr/actions)

**A native Apple TV client for [Seerr](https://github.com/seerr-app/seerr) - The ultimate media request and management system**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Development](#-development) • [Contributing](#-contributing)

<img src="docs/images/hero-screenshot.png" alt="Molyseerr Hero" width="800"/>

</div>

---

## 🎯 Overview

**Molyseerr** brings the power of Seerr to your Apple TV. Browse trending movies and TV shows, discover new content, and request media directly from your couch with a native, fluid tvOS experience.

> **Note**: This is an independent third-party application developed by the community, separate from the official Seerr project.

### What is Seerr?

[Seerr](https://github.com/seerr-app/seerr) is a fork of Overseerr that allows users to request movies and TV shows, which are then automatically added to your Plex/Jellyfin/Emby server via Radarr and Sonarr.

### Why Molyseerr?

- 🍎 **Native tvOS Experience**: Built 100% in SwiftUI with full Focus Engine support
- 🚀 **Performance**: Optimized for 4K displays with aggressive image caching (Kingfisher)
- 🎮 **Remote-First**: Designed from the ground up for the Siri Remote
- 🎨 **Beautiful UI**: Faithful to Seerr's design system with tvOS adaptations
- 🔒 **Secure**: API key authentication with Keychain storage (coming soon)

---

## ✨ Features

### Current (Phase 1 - Data Layer ✅)

- ✅ Complete API integration with Seerr backend
- ✅ Async/await networking with URLSession
- ✅ Comprehensive data models (Movies, TV Shows, Requests)
- ✅ Status system (Available, Pending, Processing, etc.)
- ✅ Error handling and type-safe API
- ✅ TMDB image URL configuration
- ✅ Seerr color palette integration

### Coming Soon (Roadmap)

#### Phase 2 - ViewModels (Next)
- 🔄 MVVM architecture with ObservableObject
- 🔄 Trending content view model
- 🔄 Discovery view model
- 🔄 Request management
- 🔄 Search functionality

#### Phase 3 - UI Components
- 📺 Media card grid with Focus Engine
- 🎨 Status badges with dynamic colors
- 🖼️ Poster/backdrop image loading (Kingfisher)
- 🎯 Interactive buttons and navigation

#### Phase 4 - Navigation & Features
- 🧭 Tab-based navigation (Home, Discover, Search, Requests, Settings)
- 🔍 Multi-search (movies, TV, people)
- ⚙️ Settings and configuration
- 📊 Request history and management

#### Phase 5 - Polish & Optimization
- ⚡ Infinite scroll with prefetching
- 🎞️ Smooth animations and transitions
- 💾 Intelligent caching strategies
- 🌐 Localization support

---

## 📋 Requirements

- **Apple TV**: 4th generation or later (Apple TV HD, Apple TV 4K)
- **tvOS**: 17.0 or later
- **Seerr Server**: Version 1.0 or later
- **Xcode**: 15.0+ (for development)
- **Swift**: 5.9+

---

## 🚀 Installation

### For Users (TestFlight - Coming Soon)

1. Join the TestFlight beta program (link will be provided)
2. Install Sir Seerr on your Apple TV
3. Configure your Seerr server URL and API key
4. Start browsing and requesting content!

### For Developers

1. **Clone the repository**
   ```bash
   git clone https://github.com/VOTRE_USERNAME/molyseerr.git
   cd molyseerr
   ```

2. **Open in Xcode**
   ```bash
   open "Molyseerr.xcodeproj"
   ```

3. **Install dependencies** (Kingfisher via SPM)
   - File → Add Package Dependencies...
   - URL: `https://github.com/onevcat/Kingfisher.git`
   - Version: `8.0.0` or later

4. **Configure your Seerr instance**
   - Create a configuration file (not tracked by git):
   ```swift
   // Create: Molyseerr/SeerrCredentials.swift
   import Foundation

   enum SeerrCredentials {
       static let baseURL = "http://your-seerr-server.com:5055"
       static let apiKey = "YOUR_API_KEY_HERE"
   }
   ```

5. **Build and run** (⌘R)

---

## 📖 Usage

### Basic Configuration

```swift
import SwiftUI

@main
struct MolyseerrApp: App {
    init() {
        // Configure the Seerr service
        SeerrService.shared.setBaseURL("http://localhost:5055")
        SeerrService.shared.setApiKey("YOUR_API_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Fetching Trending Content

```swift
Task {
    do {
        let trending = try await SeerrService.shared.getTrending(page: 1)
        print("Found \(trending.totalResults) trending items")
    } catch {
        print("Error: \(error)")
    }
}
```

For more examples, see [USAGE_GUIDE.md](USAGE_GUIDE.md).

---

## 🏗️ Architecture

Molyseerr follows a **strict MVVM architecture** to ensure maintainability and testability:

```
Molyseerr/
├── Models/              # Data models (Codable structs)
├── Services/            # API service layer (Singleton)
├── ViewModels/          # Business logic (@ObservableObject)
├── Views/               # SwiftUI interface
└── Extensions/          # Utilities and helpers
```

### Key Design Principles

- **No `onTapGesture`**: tvOS uses a remote, not a touch screen
- **Focus Engine First**: All interactive elements support focus states
- **Async/await**: Modern Swift concurrency (no completion handlers)
- **Type Safety**: Strongly-typed API with comprehensive error handling
- **Immutability**: All models are immutable structs

For detailed architecture, see [TVOS_ARCH_SPEC.md](TVOS_ARCH_SPEC.md).

---

## 🛠️ Development

### Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (100% declarative)
- **Networking**: URLSession with async/await
- **Image Loading**: [Kingfisher](https://github.com/onevcat/Kingfisher) (SPM)
- **Platform**: tvOS 17.0+

### Project Structure

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for complete project organization.

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for consistency (configuration coming soon)
- Document complex logic with inline comments
- Keep files under 500 lines

### Building

```bash
# Build for Debug
xcodebuild -project "Molyseerr.xcodeproj" -scheme "Molyseerr" -configuration Debug

# Build for Release
xcodebuild -project "Molyseerr.xcodeproj" -scheme "Molyseerr" -configuration Release
```

### Testing

```bash
# Run unit tests
xcodebuild test -project "Molyseerr.xcodeproj" -scheme "Molyseerr" -destination 'platform=tvOS Simulator,name=Apple TV'
```

---

## 🤝 Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- Setting up your development environment
- Branching strategy (Git Flow)
- Code review process
- Commit message conventions

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📚 Documentation

- **[TECH_RULES.md](TECH_RULES.md)**: Technical rules and constraints
- **[TVOS_ARCH_SPEC.md](TVOS_ARCH_SPEC.md)**: Architecture specification and business logic
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)**: Project organization and roadmap
- **[USAGE_GUIDE.md](USAGE_GUIDE.md)**: API usage examples
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Contribution guidelines

---

## 🔐 Security

- Never commit API keys or credentials
- Use `.gitignore` to exclude sensitive files
- Report security vulnerabilities via GitHub Security Advisories

---

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

---

## ⚖️ Disclaimer

Molyseerr is an independent, third-party application and is **not officially associated with, endorsed by, or maintained by the Seerr team**. This is a community-driven project created to enhance the Seerr experience on Apple TV.

For official Seerr support and development, please visit the [official Seerr repository](https://github.com/seerr-app/seerr).

---

## 🙏 Acknowledgments

- **[Seerr](https://github.com/seerr-app/seerr)**: The amazing backend that powers this app (Note: Molyseerr is not affiliated with the Seerr team)
- **[Overseerr](https://github.com/sct/overseerr)**: The original project that inspired Seerr
- **[Kingfisher](https://github.com/onevcat/Kingfisher)**: Excellent image caching library
- **[The Movie Database (TMDB)](https://www.themoviedb.org/)**: Movie and TV show metadata

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/VOTRE_USERNAME/molyseerr/issues)
- **Discussions**: [GitHub Discussions](https://github.com/VOTRE_USERNAME/molyseerr/discussions)
- **Seerr Discord**: Join the Seerr community

---

## 🗺️ Roadmap

- [x] Phase 1: Data Layer (Complete)
- [ ] Phase 2: ViewModels (In Progress)
- [ ] Phase 3: UI Components
- [ ] Phase 4: Navigation & Features
- [ ] Phase 5: Polish & Optimization
- [ ] Beta Release (TestFlight)
- [ ] App Store Submission

---

<div align="center">

**Made with ❤️ for the tvOS and Seerr communities**

[⬆ Back to top](#-molyseerr)

</div>
