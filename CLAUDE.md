# CLAUDE.md - AI Assistant Context for MyDemo Project

## Project Purpose
This is a **UI demo collection** for exploring and implementing modern SwiftUI APIs and techniques. NOT a production app - focus on technical implementation details rather than architecture patterns.

## Core Focus Areas (IMPORTANT)

### What TO Focus On:
1. **SwiftUI API Usage**
   - Modern APIs (iOS 17+)
   - Animation techniques (matchedGeometryEffect, withAnimation variants)
   - Layout modifiers and their combinations
   - ScrollView behaviors and optimizations
   - Gesture recognizers and interactions

2. **Extensions & Utilities**
   - Reusable helper extensions
   - Type-safe convenience methods
   - SwiftUI view modifiers
   - Property wrappers usage

3. **Animation & Effects**
   - Transition implementations
   - Interactive animations
   - Performance considerations
   - Smooth state changes
   - Visual polish techniques

4. **Technical Problem Solving**
   - Creative solutions using SwiftUI APIs
   - Workarounds for SwiftUI limitations
   - Performance optimizations
   - Edge case handling

### What to IGNORE:
- App architecture debates (MVVM vs MVC vs TCA)
- Dependency injection patterns
- Network layer implementations
- Database design
- Testing strategies
- CI/CD considerations
- Code organization for large teams

## Project Structure Context

```
MyDemo/
├── Demo/           # Each folder = standalone UI technique demo
├── Sample/         # Quick experiments, API behavior tests
└── Resources/      # Assets for visual demos
```

## Working Guidelines

### When Creating New Demos:
1. Pick ONE specific UI challenge or effect
2. Implement using latest SwiftUI APIs
3. Create minimal ViewModel if needed (don't over-engineer)
4. Extract reusable parts to extensions
5. Add inline comments ONLY for non-obvious techniques

### When Reviewing/Improving Code:
- Suggest newer/better APIs if available
- Focus on animation smoothness
- Optimize for readability of the technique being demonstrated
- Don't refactor for "production readiness"

### Code Style Preferences:
- Concise over verbose
- Modern Swift/SwiftUI idioms
- Inline modifiers over extracted views (unless reusability needed)
- Computed properties over functions for UI logic
- Direct state manipulation over complex state machines

## Current Demo Contexts

### TaskManager
**Purpose**: Demonstrate scroll-position binding, matchedGeometry animations, and weekly calendar UI
**Key Learning**: How to sync selection state with scroll position bidirectionally

### State_Published Sample
**Purpose**: Understand SwiftUI re-render triggers
**Key Learning**: @Published always triggers, @State only on actual change

## Technical Exploration Areas (Future)

Priority topics for new demos:
1. Custom gesture combinations
2. Canvas/Drawing APIs
3. Metal shaders in SwiftUI
4. Advanced Grid layouts
5. Custom navigation transitions
6. Timeline animations
7. Physics-based animations
8. Parallax effects
9. Custom scroll behaviors
10. Dynamic Island integration

## Response Approach

When asked to implement something:
1. First check if similar technique exists in project
2. Use latest available API (check iOS version)
3. Implement minimal viable demo
4. Focus on the core technique, not surrounding infrastructure
5. Extract only if reusability is obvious

When asked to fix/improve:
1. Focus on the UI/animation aspect
2. Don't suggest architectural changes
3. Prefer SwiftUI-native solutions
4. Keep it simple and demonstrative

## Important Notes

- This is a LEARNING/EXPLORATION project
- Each demo should teach ONE clear concept
- Code should be readable as educational material
- Performance matters only for UI smoothness
- Don't add unnecessary abstraction layers
- Inline magic numbers are OK for demos
- Hardcoded data is fine
- No need for error handling unless demonstrating that specific API

## Key Questions to Ask Yourself

Before implementing:
- What specific SwiftUI technique am I demonstrating?
- Is this the most modern way to achieve this in SwiftUI?
- Can someone learn from reading this code?
- Am I over-engineering for a demo?

## Current iOS Target
iOS 17.0+ (Use latest APIs freely)