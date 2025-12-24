## Description
<!-- Provide a brief description of the changes in this PR -->



## Type of Change
<!-- Check all that apply -->

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] 🎨 UI/UX improvement
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test addition/update

## Related Issues
<!-- Link related issues using "Closes #123" or "Relates to #456" -->

Closes #
Relates to #

## Changes Made
<!-- Provide a detailed list of changes -->

-
-
-

## Screenshots/Recordings
<!-- If applicable, add screenshots or screen recordings to demonstrate the changes -->
<!-- For tvOS, simulator recordings are very helpful! -->



## Testing Checklist
<!-- Check all that apply and were tested -->

- [ ] Tested on tvOS Simulator
- [ ] Tested on physical Apple TV
- [ ] Tested with different Seerr server configurations
- [ ] Tested focus engine behavior (remote navigation)
- [ ] Tested with different content types (movies, TV shows)
- [ ] Added/updated unit tests
- [ ] All existing tests pass

## Technical Details
<!-- Optional: Add technical implementation details, architectural decisions, or trade-offs -->



## Performance Impact
<!-- Optional: Describe any performance implications -->

- [ ] No performance impact
- [ ] Improves performance
- [ ] May impact performance (details below)

Details:

## Documentation
<!-- Check all that apply -->

- [ ] README.md updated (if needed)
- [ ] USAGE_GUIDE.md updated (if needed)
- [ ] Code comments added/updated for complex logic
- [ ] API documentation updated (if applicable)

## Code Quality Checklist
<!-- Verify your code meets project standards -->

- [ ] My code follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [ ] I have followed the tvOS-specific rules in [TECH_RULES.md](../TECH_RULES.md)
  - [ ] No `onTapGesture` usage
  - [ ] All interactive elements use `Button` or `NavigationLink`
  - [ ] Focus Engine support added
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] I have made corresponding changes to the documentation
- [ ] My code builds successfully (⌘B)
- [ ] SwiftLint passes (if configured)

## Git Checklist
<!-- Verify git hygiene -->

- [ ] My branch is up-to-date with the target branch
- [ ] My commits follow the [Conventional Commits](https://www.conventionalcommits.org/) convention
- [ ] I have rebased my branch (if needed)
- [ ] No merge conflicts exist

## Security Checklist
<!-- Verify no sensitive information is committed -->

- [ ] No API keys or credentials committed
- [ ] No `.env` files or secrets files committed
- [ ] Sensitive files are listed in `.gitignore`

## Additional Notes
<!-- Add any additional notes, concerns, or questions for reviewers -->



---

**Reviewer Notes:**
<!-- For maintainers/reviewers -->

- [ ] Code review completed
- [ ] Architecture aligns with project goals
- [ ] Performance acceptable
- [ ] Documentation sufficient
- [ ] Tests adequate
