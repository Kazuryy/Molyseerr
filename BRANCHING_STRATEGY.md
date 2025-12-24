# Git Branching Strategy

This document defines the Git workflow and branch management strategy for **Molyseerr**, ensuring consistent collaboration practices across the development team.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Branch Types](#branch-types)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Main Branch Protection](#main-branch-protection)
- [Pull Request Workflow](#pull-request-workflow)
- [Version Tagging Strategy](#version-tagging-strategy)
- [Merge Policies](#merge-policies)
- [Quick Reference](#quick-reference)

---

## Overview

We use a **modified Git Flow** strategy optimized for Swift/iOS development teams. This workflow balances stability, feature development, and rapid bug fixes while maintaining a clean, traceable history.

### Workflow Diagram

```
main (production)
  ├── develop (integration)
  │   ├── feature/trending-view
  │   ├── feature/search-functionality
  │   ├── bugfix/status-badge-color
  │   └── refactor/api-service-cleanup
  ├── release/1.0.0 (release preparation)
  └── hotfix/critical-crash-fix (emergency fixes)
```

### Key Principles

- **main** is always production-ready and deployable
- **develop** is the integration branch for ongoing work
- **Features** are developed in isolated branches
- **Releases** are prepared in dedicated branches
- **Hotfixes** go directly to main for critical issues

---

## Branch Types

### 1. Main Branch (`main`)

**Purpose**: Production-ready code, always stable and deployable.

- Contains only thoroughly tested, release-ready code
- Protected branch with strict rules (see [Main Branch Protection](#main-branch-protection))
- Tagged with semantic versions (e.g., `v1.0.0`, `v1.1.0`)
- Direct commits are **prohibited**

**Allowed merges from**:
- `release/*` branches (for new releases)
- `hotfix/*` branches (for critical fixes)

---

### 2. Development Branch (`develop`)

**Purpose**: Integration branch for ongoing development.

- Always ahead of `main` with the latest features
- Should remain stable enough for QA testing
- Protected from force pushes
- Source for all feature/bugfix branches

**Allowed merges from**:
- `feature/*` branches
- `bugfix/*` branches
- `refactor/*` branches
- `hotfix/*` branches (after merging to main)

---

### 3. Feature Branches (`feature/*`)

**Purpose**: Develop new features or enhancements.

**Base branch**: `develop`
**Merge back to**: `develop`
**Lifetime**: Short to medium (days to weeks)

**When to use**:
- Adding new functionality (e.g., trending view, search)
- Implementing new screens or components
- Adding new API integrations

**Naming examples**:
```
feature/trending-content-view
feature/search-multi-endpoint
feature/kingfisher-integration
feature/user-authentication
```

**Workflow**:
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/trending-content-view

# Work on feature
git add .
git commit -m "feat(trending): add trending view model"

# Keep updated with develop
git fetch origin
git rebase origin/develop

# Push and create PR
git push origin feature/trending-content-view
```

---

### 4. Bugfix Branches (`bugfix/*`)

**Purpose**: Fix non-critical bugs found in `develop`.

**Base branch**: `develop`
**Merge back to**: `develop`
**Lifetime**: Short (hours to days)

**When to use**:
- Fixing bugs discovered during development
- Addressing issues from code reviews
- Resolving failing tests

**Naming examples**:
```
bugfix/status-badge-incorrect-color
bugfix/focus-engine-not-working
bugfix/api-response-parsing
bugfix/memory-leak-in-image-cache
```

**Workflow**:
```bash
# Create bugfix branch
git checkout develop
git pull origin develop
git checkout -b bugfix/status-badge-incorrect-color

# Fix the bug
git add .
git commit -m "fix(ui): correct status badge color for processing state"

# Push and create PR
git push origin bugfix/status-badge-incorrect-color
```

---

### 5. Hotfix Branches (`hotfix/*`)

**Purpose**: Emergency fixes for critical production bugs.

**Base branch**: `main`
**Merge back to**: `main` AND `develop`
**Lifetime**: Very short (hours)

**When to use**:
- Critical crashes in production
- Security vulnerabilities
- Data loss bugs
- App Store rejection issues

**Naming examples**:
```
hotfix/critical-crash-on-launch
hotfix/api-authentication-failure
hotfix/memory-corruption-bug
```

**Workflow**:
```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-crash-on-launch

# Fix the critical issue
git add .
git commit -m "fix: resolve crash on launch when API key is missing"

# Push and create PR to main
git push origin hotfix/critical-crash-on-launch

# After merging to main, also merge to develop
git checkout develop
git pull origin develop
git merge hotfix/critical-crash-on-launch
git push origin develop
```

**Important**: Hotfixes increment the patch version (e.g., `v1.0.0` → `v1.0.1`).

---

### 6. Release Branches (`release/*`)

**Purpose**: Prepare a new production release.

**Base branch**: `develop`
**Merge back to**: `main` AND `develop`
**Lifetime**: Short (days)

**When to use**:
- Finalizing a version for production
- Last-minute bug fixes
- Version number updates
- Release notes preparation

**Naming convention**:
```
release/1.0.0
release/1.1.0
release/2.0.0-beta.1
```

**Workflow**:
```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# Update version numbers, changelog, etc.
# Commit only bug fixes and release prep (NO new features)
git add .
git commit -m "chore(release): prepare v1.0.0"

# Push and create PR to main
git push origin release/1.0.0

# After merging to main and tagging, merge back to develop
git checkout develop
git merge release/1.0.0
git push origin develop
```

---

### 7. Refactor Branches (`refactor/*`)

**Purpose**: Code refactoring without changing behavior.

**Base branch**: `develop`
**Merge back to**: `develop`
**Lifetime**: Short to medium

**When to use**:
- Improving code structure
- Removing technical debt
- Optimizing performance
- Renaming for clarity

**Naming examples**:
```
refactor/api-service-error-handling
refactor/view-model-structure
refactor/consolidate-models
```

---

### 8. Documentation Branches (`docs/*`)

**Purpose**: Documentation updates only.

**Base branch**: `develop` (or `main` for urgent fixes)
**Merge back to**: Same as base
**Lifetime**: Very short

**When to use**:
- Updating README, guides, or markdown files
- API documentation changes
- Code comment improvements

**Naming examples**:
```
docs/update-installation-guide
docs/add-api-examples
docs/fix-typos-in-readme
```

---

## Branch Naming Conventions

### Format

```
<type>/<description>
```

### Rules

1. **All lowercase**: Use lowercase letters only
2. **Hyphens**: Separate words with hyphens (`-`), not underscores
3. **Descriptive**: Be clear and concise (3-6 words)
4. **No special characters**: Only alphanumeric characters and hyphens
5. **No trailing slashes**: End with the description

### Valid Examples

✅ **Good**:
```
feature/trending-content-view
bugfix/status-badge-incorrect-color
hotfix/critical-crash-on-launch
release/1.0.0
refactor/api-service-cleanup
docs/update-contributing-guide
```

❌ **Bad**:
```
feature/Feature                    # Capital letters
my-feature                         # Missing type prefix
feature/add_trending_view          # Underscores instead of hyphens
fix-bug                            # Too vague
feature/trending-view/             # Trailing slash
feature/impl-#42                   # Special characters
```

### Type Prefixes

| Prefix | Purpose | Base Branch |
|--------|---------|-------------|
| `feature/` | New features | `develop` |
| `bugfix/` | Bug fixes | `develop` |
| `hotfix/` | Critical production fixes | `main` |
| `release/` | Release preparation | `develop` |
| `refactor/` | Code refactoring | `develop` |
| `docs/` | Documentation | `develop` or `main` |
| `test/` | Test additions/fixes | `develop` |
| `chore/` | Build/tooling changes | `develop` |

---

## Main Branch Protection

The `main` branch is protected with the following rules:

### Branch Protection Rules

#### 1. Require Pull Request Reviews
- **Minimum 1 approval** from a code owner or maintainer
- **Dismiss stale reviews** when new commits are pushed
- **Require review from code owners** (if CODEOWNERS file exists)

#### 2. Require Status Checks
- ✅ All CI/CD checks must pass
- ✅ Build must succeed (Xcode)
- ✅ Unit tests must pass
- ✅ SwiftLint must pass (when configured)
- ✅ Code coverage threshold met (80%+)

#### 3. Require Signed Commits
- All commits must be signed with GPG (recommended for security)

#### 4. Prohibit Force Pushes
- **Force push disabled** to prevent history rewriting
- Protects against accidental data loss

#### 5. Prohibit Deletions
- Branch cannot be deleted

#### 6. Require Linear History
- Enforces merge commits or squash merges (no messy merge histories)

### Who Can Merge to Main?

- **Repository administrators**
- **Designated release managers**
- Only through approved pull requests

### Exception: Hotfixes

Hotfixes can be merged to `main` with expedited review when:
- The issue is critical (crashes, security, data loss)
- At least 1 maintainer approval is obtained
- All automated checks pass

---

## Pull Request Workflow

### 1. Before Creating a PR

**Checklist**:
- [ ] Code builds successfully (⌘B in Xcode)
- [ ] All tests pass (⌘U in Xcode)
- [ ] No compiler warnings
- [ ] SwiftLint passes (if configured)
- [ ] Code is self-reviewed
- [ ] Branch is up-to-date with base branch
- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/)

### 2. Creating the Pull Request

1. **Push your branch** to your fork or the repository
2. **Navigate to GitHub** and click "New Pull Request"
3. **Select branches**:
   - **Base**: `develop` (or `main` for hotfixes/releases)
   - **Compare**: Your feature branch
4. **Fill out the PR template** (see template below)
5. **Assign reviewers** (at least 1)
6. **Add labels**: `enhancement`, `bug`, `documentation`, etc.
7. **Link related issues**: "Closes #42" or "Relates to #123"

### 3. PR Title Convention

Follow the same format as commit messages:

```
<type>(<scope>): <description>

Examples:
feat(ui): add trending content view with focus engine
fix(api): resolve authentication token expiration
docs: update branching strategy guide
refactor(service): simplify error handling logic
```

### 4. PR Description Template

```markdown
## Description
Brief description of what this PR accomplishes and why it's needed.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Refactoring (code improvement without behavior change)
- [ ] Documentation update
- [ ] Chore (build, dependencies, tooling)

## Related Issues
Closes #42
Relates to #56

## Changes Made
- Added TrendingViewModel with @Published properties
- Integrated SeerrService.getTrending() API
- Implemented loading and error states
- Added unit tests for view model

## Screenshots (if UI changes)
[Attach screenshots or screen recordings here]

## Testing Performed
- [ ] Tested on Apple TV Simulator (tvOS 17.0)
- [ ] Tested on physical Apple TV 4K
- [ ] Added unit tests (coverage: XX%)
- [ ] Verified with different Seerr server versions
- [ ] Tested edge cases (empty data, network errors)

## Checklist
- [ ] My code follows the Swift API Design Guidelines
- [ ] I have followed TECH_RULES.md (no `onTapGesture`, Focus Engine support)
- [ ] I have performed a self-review of my code
- [ ] I have commented complex logic
- [ ] I have updated relevant documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] All new and existing tests pass
```

### 5. Code Review Process

#### For Reviewers
- **Response time**: Within 2 business days
- **Focus areas**:
  - Correctness and logic
  - tvOS compliance (TECH_RULES.md)
  - Performance considerations
  - Test coverage
  - Documentation clarity

#### Review Feedback Types
- **Approve**: Code is ready to merge
- **Request Changes**: Blocking issues must be fixed
- **Comment**: Non-blocking suggestions

#### Required Approvals
- **Feature/Bugfix PRs**: 1 approval minimum
- **Hotfix PRs**: 1 approval (expedited)
- **Release PRs**: 2 approvals recommended

### 6. Addressing Review Comments

```bash
# Make requested changes
git add .
git commit -m "refactor: address code review feedback"

# Push updates
git push origin feature/my-feature

# PR updates automatically, re-request review
```

### 7. Merging the PR

**Before merging**:
- ✅ All required approvals obtained
- ✅ All CI/CD checks pass
- ✅ No merge conflicts
- ✅ Branch is up-to-date with base

**Merge button options**:
- See [Merge Policies](#merge-policies) section

### 8. After Merging

1. **Delete the branch** (GitHub prompts automatically)
2. **Update local repository**:
   ```bash
   git checkout develop
   git pull origin develop
   git branch -d feature/my-feature  # Delete local branch
   ```
3. **Close related issues** (if not auto-closed)

---

## Version Tagging Strategy

We follow **[Semantic Versioning](https://semver.org/)** (SemVer).

### Version Format

```
vMAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Examples:
v1.0.0
v1.1.0
v2.0.0-beta.1
v1.0.1+20250115
```

### Version Components

| Component | When to Increment | Example |
|-----------|-------------------|---------|
| **MAJOR** | Breaking changes, incompatible API changes | `v1.0.0` → `v2.0.0` |
| **MINOR** | New features, backward-compatible additions | `v1.0.0` → `v1.1.0` |
| **PATCH** | Bug fixes, backward-compatible fixes | `v1.0.0` → `v1.0.1` |
| **PRERELEASE** | Alpha, beta, rc versions | `v1.0.0-beta.1` |
| **BUILD** | Build metadata (optional) | `v1.0.0+20250115` |

### Tagging Workflow

#### For Regular Releases

```bash
# After merging release/1.0.0 to main
git checkout main
git pull origin main

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0 - Initial public release

Features:
- Trending content view
- Search functionality
- Media request system

See CHANGELOG.md for full details."

# Push tag to remote
git push origin v1.0.0

# Verify tag
git describe --tags
```

#### For Hotfixes

```bash
# After merging hotfix to main
git checkout main
git pull origin main

# Increment patch version
git tag -a v1.0.1 -m "Hotfix v1.0.1 - Critical crash fix

Fixes:
- Resolved crash on launch when API key is missing"

git push origin v1.0.1
```

### Pre-release Tags

**Beta releases**:
```bash
git tag -a v1.0.0-beta.1 -m "Beta release 1.0.0-beta.1"
git push origin v1.0.0-beta.1
```

**Release candidates**:
```bash
git tag -a v1.0.0-rc.1 -m "Release candidate 1.0.0-rc.1"
git push origin v1.0.0-rc.1
```

### Tag Naming Rules

- **Always start with `v`** (e.g., `v1.0.0`, not `1.0.0`)
- **Use annotated tags** (not lightweight): `git tag -a`
- **Include release notes** in the tag message
- **Never delete or move tags** (they're immutable in the release process)

### GitHub Releases

After tagging, create a GitHub Release:

1. Go to **Releases** → **Draft a new release**
2. Select the tag (e.g., `v1.0.0`)
3. Set release title: `Version 1.0.0 - Feature Name`
4. Add release notes (copy from CHANGELOG.md)
5. Attach build artifacts (if applicable)
6. Mark as pre-release (for beta/rc)
7. **Publish release**

---

## Merge Policies

### Merge Strategies

We use different merge strategies based on the branch type and PR size.

#### 1. Squash and Merge (Preferred for Features)

**When to use**:
- Feature branches (`feature/*`)
- Large PRs with many small commits
- When commit history is messy

**How it works**:
- All commits are squashed into a single commit
- Commit message uses PR title
- Keeps `develop` history clean

**Example**:
```bash
# GitHub UI: "Squash and merge" button

# Result in develop:
feat(ui): add trending content view with focus engine (#42)
```

**Pros**:
- Clean, linear history
- Easy to revert entire features
- Reduces noise in git log

**Cons**:
- Loses granular commit history

---

#### 2. Rebase and Merge (For Clean PRs)

**When to use**:
- Bugfix branches (`bugfix/*`)
- Small, well-structured PRs
- When commits are already clean

**How it works**:
- Individual commits are replayed onto base branch
- No merge commit created
- Maintains commit history

**Example**:
```bash
# GitHub UI: "Rebase and merge" button

# Result in develop:
fix(ui): correct status badge color
test(ui): add status badge color tests
```

**Pros**:
- Preserves individual commits
- Clean, linear history
- Detailed history for debugging

**Cons**:
- Requires clean commits upfront

---

#### 3. Merge Commit (For Releases and Hotfixes)

**When to use**:
- Release branches (`release/*`)
- Hotfix branches (`hotfix/*`)
- When preserving branch history is important

**How it works**:
- Creates a merge commit
- Preserves branch structure
- Shows entire branch history

**Example**:
```bash
# GitHub UI: "Create a merge commit" button

# Result in main:
Merge branch 'release/1.0.0' into main
```

**Pros**:
- Preserves complete history
- Clear branch points
- Easy to identify releases

**Cons**:
- Can create complex history

---

### Policy by Branch Type

| Source Branch | Target Branch | Strategy | Rationale |
|---------------|---------------|----------|-----------|
| `feature/*` | `develop` | **Squash and Merge** | Clean history, atomic features |
| `bugfix/*` | `develop` | **Rebase and Merge** | Preserve fix details |
| `hotfix/*` | `main` | **Merge Commit** | Track emergency fixes |
| `hotfix/*` | `develop` | **Merge Commit** | Keep fix history |
| `release/*` | `main` | **Merge Commit** | Mark release points |
| `release/*` | `develop` | **Merge Commit** | Sync release changes |
| `refactor/*` | `develop` | **Squash and Merge** | Clean refactor history |
| `docs/*` | `develop` | **Squash and Merge** | Simple doc updates |

---

### Commit Message Requirements (for Squash)

When using "Squash and Merge", the final commit message should follow:

```
<type>(<scope>): <description>

<body>

<footer>
```

**Example**:
```
feat(ui): add trending content view with focus engine

- Implemented TrendingViewModel with @Published properties
- Created TrendingView with LazyVGrid and media cards
- Added Focus Engine support with scale effects
- Integrated Kingfisher for image loading

Closes #42
```

---

### Preventing Merge Conflicts

**Before merging**:

```bash
# Update your branch with latest develop
git checkout feature/my-feature
git fetch origin
git rebase origin/develop

# Resolve any conflicts
# Then force push (only for feature branches)
git push --force-with-lease origin feature/my-feature
```

**Conflict resolution**:
1. **Resolve conflicts** in your feature branch (not in `develop`)
2. **Test thoroughly** after resolving
3. **Re-request review** if significant changes were made

---

## Quick Reference

### Common Commands

```bash
# Start a new feature
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# Keep feature branch updated
git fetch origin
git rebase origin/develop

# Push feature branch
git push origin feature/my-feature

# Create a hotfix
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# Create a release
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# Tag a release
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Delete merged branch
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

---

### Decision Tree

**Starting new work?**
```
Is it a critical production bug?
├── Yes → Create hotfix/* from main
└── No
    ├── Is it a new feature? → Create feature/* from develop
    ├── Is it a bug in develop? → Create bugfix/* from develop
    ├── Is it refactoring? → Create refactor/* from develop
    └── Is it documentation? → Create docs/* from develop
```

**Ready to merge?**
```
What type of branch?
├── feature/* → Squash and merge to develop
├── bugfix/* → Rebase and merge to develop
├── hotfix/* → Merge commit to main (then develop)
├── release/* → Merge commit to main (then develop)
└── refactor/* → Squash and merge to develop
```

**Ready to release?**
```
1. Create release/* from develop
2. Bug fixes only (no new features)
3. Update version numbers and CHANGELOG
4. Merge to main with merge commit
5. Tag with v*.*.*
6. Merge back to develop
7. Publish GitHub Release
```

---

## Additional Resources

- **Conventional Commits**: [conventionalcommits.org](https://www.conventionalcommits.org/)
- **Semantic Versioning**: [semver.org](https://semver.org/)
- **Swift API Design Guidelines**: [swift.org/documentation/api-design-guidelines](https://swift.org/documentation/api-design-guidelines/)
- **CONTRIBUTING.md**: [Full contribution guide](CONTRIBUTING.md)
- **TECH_RULES.md**: [Technical rules and constraints](TECH_RULES.md)

---

**Last Updated**: 2025-12-24
**Version**: 1.0.0
