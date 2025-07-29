# Development Tasks: Invoice Maker iOS/Mac Native Application

Based on the PRD analysis and current state assessment (greenfield project), here are the detailed tasks required to implement the Invoice Maker application.

## Relevant Files

### Core Architecture
- `InvoiceBuilder.xcodeproj` - Main Xcode project file
- `InvoiceBuilder.xcworkspace` - Workspace containing project and packages
- `InvoiceBuilderApp.swift` - Main app entry point with SwiftUI App protocol
- `ContentView.swift` - Root view coordinator
- `AppDelegate.swift` - Legacy app delegate for system integration

### Data Layer
- `Models/Invoice.swift` - Core invoice data model
- `Models/Client.swift` - Client information model
- `Models/BusinessProfile.swift` - User business profile model
- `Models/InvoiceItem.swift` - Individual invoice line item model
- `Models/InvoiceTemplate.swift` - Template configuration model
- `Services/CoreDataStack.swift` - Core Data persistence layer
- `Services/CloudSyncService.swift` - Cross-platform synchronization service
- `InvoiceBuilder.xcdatamodeld` - Core Data model file

### Authentication & User Management
- `Services/AuthenticationService.swift` - Authentication logic and session management
- `ViewModels/AuthViewModel.swift` - Authentication state management
- `Views/Auth/LoginView.swift` - Login interface
- `Views/Auth/SignUpView.swift` - Registration interface
- `Views/Onboarding/OnboardingView.swift` - User onboarding flow
- `Views/Onboarding/BusinessSetupView.swift` - Business profile setup

### Business Features
- `ViewModels/BusinessProfileViewModel.swift` - Business profile management
- `ViewModels/ClientViewModel.swift` - Client data management
- `ViewModels/InvoiceViewModel.swift` - Invoice creation and management
- `Views/Profile/BusinessProfileView.swift` - Business profile interface
- `Views/Clients/ClientListView.swift` - Client management interface
- `Views/Clients/ClientDetailView.swift` - Individual client editing
- `Views/Items/ItemsListView.swift` - Service/product items management

### Invoice System
- `Views/Invoice/InvoiceBuilderView.swift` - Main invoice creation interface
- `Views/Invoice/InvoiceListView.swift` - Invoice listing and management
- `Views/Invoice/InvoiceDetailView.swift` - Individual invoice view
- `Views/Templates/TemplateSelectionView.swift` - Template picker interface
- `Services/InvoiceTemplateService.swift` - Template rendering engine
- `Services/PDFGenerationService.swift` - PDF export functionality
- `Utils/InvoiceCalculator.swift` - Tax and total calculations

### Analytics & Reporting
- `ViewModels/AnalyticsViewModel.swift` - Dashboard data management
- `Views/Analytics/DashboardView.swift` - Main analytics dashboard
- `Views/Reports/ReportsView.swift` - Business reports interface
- `Services/AnalyticsService.swift` - Revenue tracking and calculations

### Subscription System
- `Services/SubscriptionService.swift` - App Store subscription management
- `ViewModels/SubscriptionViewModel.swift` - Subscription state management
- `Views/Subscription/PaywallView.swift` - Subscription upgrade interface
- `Views/Subscription/SubscriptionStatusView.swift` - Current plan display

### Utilities & Extensions
- `Utils/Constants.swift` - App-wide constants and configuration
- `Utils/Extensions/` - Swift extensions for common functionality
- `Utils/Validators.swift` - Input validation utilities
- `Utils/KeychainHelper.swift` - Secure storage utilities

### Tests
- `InvoiceBuilderTests/` - Unit test directory
- `InvoiceBuilderUITests/` - UI test directory
- `Models/InvoiceTests.swift` - Invoice model unit tests
- `Services/AuthenticationServiceTests.swift` - Authentication service tests
- `ViewModels/InvoiceViewModelTests.swift` - Invoice view model tests

### Notes

- Unit tests should be placed in the `InvoiceBuilderTests/` directory with corresponding structure
- UI tests for critical user flows should be in `InvoiceBuilderUITests/`
- Use `swift test` or Xcode's test navigator to run tests
- Follow SwiftUI and MVVM patterns consistently across the codebase

## Tasks

- [ ] 1.0 Project Setup & Architecture Foundation
  - [x] 1.1 Create new Xcode project with iOS and macOS targets using SwiftUI
  - [x] 1.2 Configure project settings, bundle identifiers, and deployment targets
  - [x] 1.3 Set up workspace with Swift Package Manager dependencies
  - [x] 1.4 Implement basic MVVM architecture structure with Combine
  - [x] 1.5 Create app entry point and root navigation structure
  - [x] 1.6 Configure build schemes for Debug/Release configurations
  - [x] 1.7 Set up basic folder structure for Models, Views, ViewModels, Services
  - [x] 1.8 Initialize Git repository and create initial commit

- [ ] 2.0 Core Data Models & Database Layer
  - [ ] 2.1 Design and implement Core Data model (.xcdatamodeld) with all entities
  - [ ] 2.2 Create Invoice model with relationships to items and clients
  - [ ] 2.3 Create Client model with contact information properties
  - [ ] 2.4 Create BusinessProfile model for user business information
  - [ ] 2.5 Create InvoiceItem model for line items with pricing
  - [ ] 2.6 Create InvoiceTemplate model for template configurations
  - [ ] 2.7 Implement CoreDataStack service with persistence container
  - [ ] 2.8 Add Core Data CRUD operations for all models
  - [ ] 2.9 Implement data validation and error handling
  - [ ] 2.10 Create unit tests for all data models and Core Data operations

- [ ] 3.0 Authentication & User Management System
  - [ ] 3.1 Implement AuthenticationService with multiple sign-in options
  - [ ] 3.2 Add Apple Sign-In integration with proper entitlements
  - [ ] 3.3 Add Google Sign-In SDK integration and configuration
  - [ ] 3.4 Implement email/password authentication with validation
  - [ ] 3.5 Add phone number authentication as backup option
  - [ ] 3.6 Create AuthViewModel for managing authentication state
  - [ ] 3.7 Build LoginView with all authentication options
  - [ ] 3.8 Build SignUpView with form validation
  - [ ] 3.9 Implement secure session management with Keychain storage
  - [ ] 3.10 Add logout functionality and session cleanup
  - [ ] 3.11 Create unit tests for authentication services and view models

- [ ] 4.0 Business Profile & Client Management Features
  - [ ] 4.1 Create comprehensive onboarding flow with business setup
  - [ ] 4.2 Implement BusinessProfileView with all required fields
  - [ ] 4.3 Add business logo upload and management functionality
  - [ ] 4.4 Implement signature capture and storage
  - [ ] 4.5 Create BusinessProfileViewModel with form validation
  - [ ] 4.6 Build ClientListView with search and filtering capabilities
  - [ ] 4.7 Create ClientDetailView for adding/editing client information
  - [ ] 4.8 Implement ClientViewModel with CRUD operations
  - [ ] 4.9 Add client avatar/image support with photo picker
  - [ ] 4.10 Create ItemsListView for managing reusable service/product items
  - [ ] 4.11 Add item icons and pricing management
  - [ ] 4.12 Implement data persistence for all profile and client data
  - [ ] 4.13 Create unit tests for business profile and client management

- [ ] 5.0 Invoice Creation & Template Engine
  - [ ] 5.1 Design and implement 15+ professional invoice templates
  - [ ] 5.2 Create InvoiceTemplateService for template rendering and customization
  - [ ] 5.3 Build TemplateSelectionView with preview functionality
  - [ ] 5.4 Implement template customization (colors, fonts, layout)
  - [ ] 5.5 Create InvoiceBuilderView with intuitive creation interface
  - [ ] 5.6 Add automatic invoice numbering with custom options
  - [ ] 5.7 Implement date/due date pickers and PO number support
  - [ ] 5.8 Add multiple currency support with proper formatting
  - [ ] 5.9 Create dynamic item addition with quantity and pricing
  - [ ] 5.10 Implement InvoiceCalculator for taxes, discounts, and totals
  - [ ] 5.11 Add tax rate configuration per item
  - [ ] 5.12 Create invoice preview functionality before saving
  - [ ] 5.13 Implement InvoiceListView with status filtering and search
  - [ ] 5.14 Add invoice status management (paid/unpaid/overdue)
  - [ ] 5.15 Create InvoiceDetailView for viewing and editing
  - [ ] 5.16 Add invoice duplication for recurring billing
  - [ ] 5.17 Implement PDFGenerationService for high-quality PDF export
  - [ ] 5.18 Create unit tests for invoice creation and template system

- [ ] 6.0 Analytics Dashboard & Reporting System
  - [ ] 6.1 Create AnalyticsService for revenue calculations and tracking
  - [ ] 6.2 Implement DashboardView with key business metrics
  - [ ] 6.3 Add revenue analytics with trend visualization
  - [ ] 6.4 Display outstanding payment amounts and aging
  - [ ] 6.5 Show paid vs unpaid invoice ratios with charts
  - [ ] 6.6 Implement monthly/yearly revenue comparisons
  - [ ] 6.7 Add top clients by revenue ranking
  - [ ] 6.8 Display invoice status distribution analytics
  - [ ] 6.9 Create ReportsView for detailed business reporting
  - [ ] 6.10 Add exportable report functionality (PDF/CSV)
  - [ ] 6.11 Implement AnalyticsViewModel for dashboard state management
  - [ ] 6.12 Add real-time updates when invoice data changes
  - [ ] 6.13 Create unit tests for analytics calculations and reporting

- [ ] 7.0 Cross-Platform Sync & Cloud Integration
  - [ ] 7.1 Implement CloudSyncService with abstracted storage layer
  - [ ] 7.2 Add iCloud/CloudKit integration for primary sync
  - [ ] 7.3 Implement Dropbox API integration
  - [ ] 7.4 Add Google Drive API integration
  - [ ] 7.5 Implement OneDrive API integration
  - [ ] 7.6 Create sync conflict resolution logic
  - [ ] 7.7 Add offline functionality with queue-based sync
  - [ ] 7.8 Implement sync status indicators in UI
  - [ ] 7.9 Add background sync capabilities
  - [ ] 7.10 Create platform-specific features (Mac: drag & drop, iOS: share sheet)
  - [ ] 7.11 Implement proper state restoration and handoff
  - [ ] 7.12 Add sync settings and preferences
  - [ ] 7.13 Create unit tests for sync services and conflict resolution

- [ ] 8.0 Subscription Management & Monetization
  - [ ] 8.1 Integrate App Store subscription framework (StoreKit 2)
  - [ ] 8.2 Configure subscription products (monthly, yearly, lifetime)
  - [ ] 8.3 Implement SubscriptionService for purchase management
  - [ ] 8.4 Create usage tracking for free invoice limit (3 invoices)
  - [ ] 8.5 Build PaywallView with pricing tiers and features
  - [ ] 8.6 Add subscription status display and management
  - [ ] 8.7 Implement subscription restoration across devices
  - [ ] 8.8 Add upgrade prompts at appropriate usage points
  - [ ] 8.9 Create SubscriptionViewModel for state management
  - [ ] 8.10 Implement feature gating based on subscription status
  - [ ] 8.11 Add subscription analytics and conversion tracking
  - [ ] 8.12 Handle subscription lifecycle events (renewal, cancellation)
  - [ ] 8.13 Create unit tests for subscription management and purchase flow