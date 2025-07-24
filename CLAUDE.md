# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an InvoiceBuilder universal macOS and iOS native application project. The app is designed to run natively on both platforms, leveraging platform-specific features while maintaining a shared codebase architecture.

## Key Development Workflows

The project uses a structured AI-assisted development approach with these key phases:

### 1. PRD Generation (`ai-dev-tasks/create-prd.md`)
- Start with brief feature descriptions
- Ask clarifying questions using letter/number lists for easy responses
- Generate detailed Product Requirements Documents
- Save PRDs as `prd-[feature-name].md` in `/tasks` directory
- Target audience: junior developers

### 2. Task Generation (`ai-dev-tasks/generate-tasks.md`)
- Create step-by-step task lists from PRDs
- Two-phase approach:
  - Phase 1: Generate 5 high-level parent tasks, wait for "Go" confirmation
  - Phase 2: Break down into detailed sub-tasks
- Save as `tasks-[prd-file-name].md` in `/tasks` directory

### 3. Task Management (`ai-dev-tasks/process-task-list.md`)
- Implement one sub-task at a time
- Wait for user permission between sub-tasks
- Mark completed tasks with `[x]`
- When all sub-tasks complete: run tests → stage changes → commit → mark parent task complete
- Use conventional commit format with descriptive messages

## Development Process

1. **PRD First**: Create detailed requirements before coding
2. **Task Breakdown**: Convert PRDs into actionable development tasks
3. **Incremental Implementation**: Complete sub-tasks one at a time with user approval
4. **Test-Driven**: Run full test suite before committing parent tasks
5. **Clean Commits**: Use conventional commit format with detailed descriptions

## Directory Structure

- `/ai-dev-tasks/` - Development workflow guidelines
- `/tasks/` - Generated PRDs and task lists (to be created)

## Swift/iOS/macOS Development Guidelines

### Architecture Patterns
- **MVVM + Combine**: Use Model-View-ViewModel pattern with Combine for reactive programming
- **SwiftUI First**: Prioritize SwiftUI for UI development, fall back to UIKit/AppKit only when necessary
- **Dependency Injection**: Use protocols and dependency injection for testable, modular code
- **Repository Pattern**: Abstract data sources behind repository protocols

### Code Organization
- **Feature-Based Modules**: Organize code by features, not layers (`Invoice/`, `Customer/`, `Report/`)
- **Shared Core**: Common business logic in `Core/` module (models, services, utilities)
- **Platform-Specific**: Separate platform code in `iOS/` and `macOS/` targets
- **Extensions**: Group extensions by functionality in dedicated files

### Swift Best Practices
- **Value Types**: Prefer structs over classes for data models
- **Optionals**: Use nil-coalescing and optional chaining appropriately
- **Error Handling**: Use Result types and proper error propagation
- **Memory Management**: Avoid retain cycles with [weak self] and [unowned self]
- **Async/Await**: Use modern concurrency over completion handlers
- **Property Wrappers**: Leverage @State, @StateObject, @ObservedObject correctly

### Testing Strategy
- **Unit Tests**: Test business logic, models, and services
- **UI Tests**: Critical user flows only
- **Mock Dependencies**: Use protocols for mockable dependencies
- **Test Naming**: Use `test_methodName_whenCondition_shouldExpectedResult` convention

### Platform-Specific Considerations
- **iOS**: Follow Human Interface Guidelines, support iPhone/iPad layouts
- **macOS**: Leverage menu bar, toolbar, and window management features
- **Shared Logic**: Business rules, data models, and network layer should be shared
- **Platform Features**: Use platform-specific APIs (Touch ID/Face ID, file system access)

### Data Management
- **Core Data**: Use for complex relational data with proper NSManagedObjectContext handling
- **UserDefaults**: Simple app preferences only
- **Keychain**: Sensitive data storage (API keys, user credentials)
- **File System**: Document-based architecture for invoice files

### Performance Guidelines
- **Lazy Loading**: Load data on-demand, especially for large lists
- **Image Caching**: Implement proper image caching for invoice attachments
- **Background Processing**: Use background queues for heavy operations
- **Memory Monitoring**: Monitor memory usage in data-heavy operations

### Build Configuration
- **Schemes**: Separate schemes for Debug/Release/Testing
- **Configuration Files**: Use .xcconfig files for build settings
- **Code Signing**: Proper provisioning profiles and certificates management
- **CI/CD**: Fastlane for automated builds and deployment

## Important Notes

- This project emphasizes structured planning before implementation
- All development should follow the AI-assisted workflow defined in `/ai-dev-tasks/`
- Task lists must be updated in real-time as work progresses
- Follow Apple's Human Interface Guidelines for both iOS and macOS
- Prioritize accessibility and localization from the start
- Use Xcode's built-in tools: Instruments, Static Analyzer, and SwiftLint

## MCP Servers

- Use the XcodeBuildMCP server to build and run the macOS application
- Before launching the app, kill the app if it's already running using the command "killall Context || true"
- NEVER use the stop_mac_app tool from XcodeBuildMCP, always use the killall command
- Use the build_run_mac_proj tool from XcodeBuildMCP to build and run the Mac app