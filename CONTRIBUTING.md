# Contributing to Molyseerr

First off, thank you for considering contributing to Molyseerr! 🎉

This document provides guidelines and instructions for contributing to the project. Following these guidelines helps maintain code quality and ensures a smooth collaboration process.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Branching Strategy](#branching-strategy)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Process](#pull-request-process)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## Getting Started

### Prerequisites

- **macOS**: Ventura (13.0) or later
- **Xcode**: 15.0 or later
- **Apple TV**: Physical device or tvOS Simulator
- **Git**: Latest version
- **Seerr Server**: Access to a running Seerr instance for testing

### Initial Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/molyseerr.git
   cd molyseerr
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/molyseerr.git
   git fetch upstream
   ```

3. **Open in Xcode**
   ```bash
   open "Molyseerr.xcodeproj"
   ```

4. **Install dependencies**
   - In Xcode: File → Add Package Dependencies...
   - Add Kingfisher: `https://github.com/onevcat/Kingfisher.git`

5. **Create configuration file** (not committed to git)
   ```swift
   // Create: Molyseerr/SeerrCredentials.swift
   import Foundation

   enum SeerrCredentials {
       static let baseURL = "http://your-test-server.com:5055"
       static let apiKey = "YOUR_TEST_API_KEY"
   }
   ```

6. **Build and verify**
   ```bash
   xcodebuild -project "Molyseerr.xcodeproj" -scheme "Molyseerr" -configuration Debug
   ```

---

## Development Workflow

### Git Flow Strategy

We use a modified **Git Flow** workflow:

```
main
  ├── develop
  │   ├── feature/trending-view
  │   ├── feature/search-functionality
  │   └── bugfix/status-badge-color
  ├── release/1.0.0
  └── hotfix/critical-crash
```

#### Branch Types

| Branch Type | Naming Convention | Purpose | Base Branch |
|-------------|-------------------|---------|-------------|
| **main** | `main` | Production-ready code | - |
| **develop** | `develop` | Integration branch for features | `main` |
| **feature** | `feature/feature-name` | New features | `develop` |
| **bugfix** | `bugfix/bug-description` | Bug fixes | `develop` |
| **hotfix** | `hotfix/critical-issue` | Critical production fixes | `main` |
| **release** | `release/X.Y.Z` | Release preparation | `develop` |

### Typical Development Flow

1. **Start a new feature**
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/my-awesome-feature
   ```

2. **Make changes and commit regularly**
   ```bash
   git add .
   git commit -m "feat: add awesome feature"
   ```

3. **Keep your branch updated**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/my-awesome-feature
   ```

5. **Create a Pull Request** (see [Pull Request Process](#pull-request-process))

---

## Branching Strategy

### Branch Naming Rules

- Use **lowercase** with **hyphens** (kebab-case)
- Be **descriptive** but **concise**
- Include the **type prefix**

✅ **Good Examples**:
- `feature/trending-content-view`
- `bugfix/status-badge-incorrect-color`
- `refactor/api-service-error-handling`
- `docs/update-installation-guide`

❌ **Bad Examples**:
- `my-feature` (no type prefix)
- `feature/Feature` (capitalization)
- `fix-bug` (too vague)
- `feature/add_trending_view` (underscores)

### Branch Lifecycle

1. **Create** from `develop` (or `main` for hotfixes)
2. **Work** on your changes
3. **Rebase** regularly with upstream
4. **Test** thoroughly
5. **Submit** Pull Request
6. **Review** and address feedback
7. **Merge** via squash or merge commit
8. **Delete** branch after merge

---

## Commit Message Convention

We follow **[Conventional Commits](https://www.conventionalcommits.org/)** specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| **feat** | New feature | `feat(api): add search endpoint` |
| **fix** | Bug fix | `fix(ui): correct status badge color` |
| **docs** | Documentation only | `docs: update README installation steps` |
| **style** | Code style changes (formatting, semicolons) | `style: format code with SwiftLint` |
| **refactor** | Code refactoring (no behavior change) | `refactor(service): simplify error handling` |
| **perf** | Performance improvements | `perf(images): add aggressive caching` |
| **test** | Adding or updating tests | `test(service): add unit tests for API calls` |
| **chore** | Build process, dependencies | `chore: update Kingfisher to 8.1` |
| **ci** | CI/CD changes | `ci: add GitHub Actions workflow` |

### Scope (Optional)

Indicates the affected module:
- `api`, `service`, `ui`, `models`, `viewmodels`, `networking`, `config`

### Examples

✅ **Good Commits**:
```
feat(trending): implement trending content view

- Add TrendingViewModel with @Published properties
- Integrate with SeerrService.getTrending()
- Handle loading and error states

Closes #42
```

```
fix(status): correct badge color for processing state

The processing state was using green instead of indigo.
Updated MediaStatus+Helpers to use seerrIndigo500.

Fixes #38
```

```
docs: add API usage examples to USAGE_GUIDE.md
```

❌ **Bad Commits**:
```
update stuff
```

```
Fixed bug
```

```
WIP
```

---

## Pull Request Process

### Before Opening a PR

1. ✅ **Code builds successfully** (⌘B in Xcode)
2. ✅ **All tests pass** (⌘U in Xcode)
3. ✅ **No SwiftLint warnings** (if configured)
4. ✅ **Documentation updated** (if applicable)
5. ✅ **Commits follow convention**
6. ✅ **Branch is up-to-date** with `develop`

### Opening a Pull Request

1. **Push your branch** to your fork
2. **Go to GitHub** and click "New Pull Request"
3. **Select branches**:
   - Base: `develop` (or `main` for hotfixes)
   - Compare: `your-feature-branch`
4. **Fill out the PR template** (see below)
5. **Request reviewers** (optional)
6. **Add labels** (e.g., `enhancement`, `bug`, `documentation`)

### PR Title Convention

Follow the same format as commit messages:

```
feat(ui): add trending content view with focus engine
```

### PR Template

Your PR description should include:

```markdown
## Description
Brief description of the changes and their purpose.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #123
Relates to #456

## Changes Made
- Added TrendingViewModel
- Implemented trending content API integration
- Created TrendingView with LazyVGrid

## Screenshots (if applicable)
[Add screenshots or GIFs here]

## Testing
- [ ] Tested on Apple TV Simulator
- [ ] Tested on physical Apple TV
- [ ] Added unit tests
- [ ] Verified with different server configurations

## Checklist
- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **At least 1 approval** from a maintainer
3. **All review comments** must be addressed
4. **No merge conflicts** with target branch

### Merging

- **Squash and merge**: For feature branches (preferred)
- **Merge commit**: For release branches
- **Rebase and merge**: For simple bug fixes

After merge, **delete your branch**.

---

## Code Style Guidelines

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with additional tvOS-specific rules.

#### General Rules

1. **Use SwiftUI** for all UI code (no UIKit)
2. **Use async/await** for asynchronous code (no completion handlers)
3. **Use structs** for immutable models
4. **Use classes** for view models (`@ObservableObject`)

#### tvOS-Specific Rules

⚠️ **CRITICAL RULES** (from TECH_RULES.md):

1. ❌ **NEVER use `onTapGesture`** - tvOS uses a remote, not a touch screen
2. ✅ **ALWAYS use `Button` or `NavigationLink`** for interactive elements
3. ✅ **Support Focus Engine** - Add `.focusable()` and focus states
4. ✅ **Add visual feedback** - Scale/shadow on focus

#### Naming Conventions

```swift
// ✅ Good
struct MovieResult { }
class TrendingViewModel: ObservableObject { }
func getTrendingMovies() async throws -> [Movie] { }
let seerrIndigo500 = Color(hex: "6366f1")

// ❌ Bad
struct movieResult { }  // PascalCase for types
class trendingVM { }    // No abbreviations
func getTrending() { }  // Be specific
let INDIGO = Color(hex: "6366f1")  // camelCase for properties
```

#### Code Organization

```swift
// MARK: - Type Definition
struct MovieCard: View {

    // MARK: - Properties
    let movie: MovieResult
    @FocusState private var isFocused: Bool

    // MARK: - Body
    var body: some View {
        // ...
    }

    // MARK: - Private Methods
    private func handleSelection() {
        // ...
    }
}
```

#### Comments

- Use `//` for single-line comments
- Use `///` for documentation comments
- Explain **why**, not **what**

```swift
// ✅ Good
/// Determines the display state for the request button
/// Based on TVOS_ARCH_SPEC.md Section 2.2 business logic
func determineButtonDisplay(mediaInfo: MediaInfo?) -> ButtonState {
    // Check blacklist status first (highest priority)
    guard mediaInfo?.status != .blacklisted else {
        return .blacklisted
    }
    // ...
}

// ❌ Bad
// This function gets the button state
func getButtonState() { }
```

---

## Testing Guidelines

### Unit Tests

- Place tests in `Sir SeerrTests/`
- Name test files with `Tests` suffix: `SeerrServiceTests.swift`
- Use XCTest framework

```swift
import XCTest
@testable import Molyseerr

final class SeerrServiceTests: XCTestCase {

    func testGetTrendingReturnsResults() async throws {
        // Given
        let service = SeerrService.shared

        // When
        let response = try await service.getTrending(page: 1)

        // Then
        XCTAssertGreaterThan(response.results.count, 0)
        XCTAssertEqual(response.page, 1)
    }
}
```

### UI Tests

- Focus on critical user flows
- Test focus engine behavior
- Verify navigation

### Test Coverage

- Aim for **>80% coverage** on service layer
- Cover all error cases
- Test edge cases (empty responses, network errors)

---

## Documentation

### What to Document

1. **Public APIs**: All public functions and types
2. **Complex Logic**: Business rules, algorithms
3. **tvOS-Specific Code**: Focus engine, remote handling
4. **Configuration**: Setup and initialization

### Documentation Style

Use Swift's documentation comments:

```swift
/// Fetches trending media from the Seerr API
///
/// This method retrieves mixed movie and TV show results based on TMDB's
/// trending algorithm. Results are cached for 30 minutes.
///
/// - Parameters:
///   - page: The page number to fetch (starts at 1)
///   - timeWindow: Time window for trending ("day" or "week")
/// - Returns: A paginated response containing trending media
/// - Throws: `SeerrError` if the request fails
func getTrending(
    page: Int = 1,
    timeWindow: String = "day"
) async throws -> PaginatedResponse<MediaResult>
```

### README Updates

When adding features, update:
- Features section
- Usage examples
- Roadmap (check off completed items)

---

## Questions or Issues?

- **General Questions**: [GitHub Discussions](https://github.com/VOTRE_USERNAME/molyseerr/discussions)
- **Bug Reports**: [GitHub Issues](https://github.com/VOTRE_USERNAME/molyseerr/issues)
- **Security Issues**: See [SECURITY.md](SECURITY.md)

---

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes
- README acknowledgments section

Thank you for contributing to Molyseerr! 🎉
