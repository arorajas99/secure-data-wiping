# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

CleanSlate is a secure mobile application designed to safely and permanently wipe sensitive data from mobile devices. This is a security-focused project that implements industry-standard data wiping algorithms and follows strict security guidelines.

## Commands

### Development Commands
```bash
# Start development server (not yet configured)
npm run dev

# Build the application (not yet configured)
npm run build

# Run tests (not yet configured)
npm test

# Run linting (not yet configured)
npm run lint
```

**Note**: All npm scripts currently show "not configured yet" messages. These will need to be set up based on the chosen mobile development framework.

## Architecture and Code Structure

### High-Level Architecture
This mobile application is structured around three core modules as defined in the API documentation:

1. **Data Wiping Module** - Core functionality for secure data deletion
   - Implements multiple wiping standards: DoD 5220.22-M, NIST 800-88, Gutmann method, random overwrite, zero-fill
   - Provides verification capabilities to ensure successful data destruction
   - Configurable wiping passes and methods

2. **Security Module** - Authentication and cryptographic operations
   - User authentication for sensitive operations
   - Cryptographically secure random data generation
   - Role-based access control

3. **Utility Module** - Supporting functionality
   - System compatibility checks
   - Operation time estimation
   - Cross-platform support

### Directory Structure
```
data-wiping-mobile-app/
├── src/           # Source code (currently empty)
├── assets/        # Images, icons, and other assets (currently empty)
├── docs/          # Documentation (API.md, SECURITY.md)
├── tests/         # Test files (currently empty)
├── config/        # Configuration files (currently empty)
├── package.json   # Project metadata and scripts
└── README.md      # Project overview
```

## Security Requirements

This project handles sensitive data operations and must adhere to strict security guidelines:

### Data Wiping Standards
- Implement DoD 5220.22-M (3-pass)
- Support NIST 800-88 Guidelines
- Include Gutmann method (35-pass)
- Provide random data overwrite and zero-fill options

### Security Principles
- **Secure by Design**: All operations must be secure by default
- **Data Protection**: No sensitive data in logs, secure memory clearing required
- **Authentication**: User authentication required for sensitive operations
- **Cryptographic Standards**: Use industry-standard encryption and secure key management

### Compliance Considerations
- GDPR compliance for data handling
- Industry-specific regulations (HIPAA, PCI-DSS, etc.)
- Local data protection laws

## API Design Patterns

The application follows a Promise-based API pattern with consistent error handling:

```javascript
try {
  const result = await wipeData({
    method: 'dod',
    target: '/path/to/sensitive/data',
    passes: 3,
    verify: true
  });
  // Handle success
} catch (error) {
  // Handle error
  console.error('Wiping failed:', error.message);
}
```

## Development Guidelines

### Mobile Framework Decision
The project structure supports multiple mobile development frameworks:
- React Native (based on .gitignore entries)
- Expo (based on .gitignore entries)
- Flutter (based on .gitignore entries)
- Cordova (based on .gitignore entries)

Choose the appropriate framework and update the npm scripts accordingly.

### Security Testing Requirements
- Security testing for all data wiping functions
- Penetration testing
- Code review for security vulnerabilities
- Verification of successful data destruction

### Error Handling
- All API methods must follow consistent error handling patterns
- Log operations for audit purposes (excluding sensitive data)
- Implement rate limiting to prevent abuse

## Important Files

- `docs/API.md` - Detailed API specifications for core modules
- `docs/SECURITY.md` - Security requirements and compliance guidelines
- `package.json` - Project configuration and dependency management
- `.gitignore` - Configured for multiple mobile development frameworks

## Project Status

This project is in the early setup phase:
- Basic project structure is established
- API and security documentation is defined
- npm scripts placeholders are in place
- Source code implementation has not yet begun

When implementing, prioritize security considerations from `docs/SECURITY.md` and follow the API patterns defined in `docs/API.md`.
