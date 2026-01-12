---
name: Code Review
description: Perform a comprehensive code review comparing the current branch against the default branch.
argument-hint: Optional: specify focus areas or files to review
---

Perform a complete code review on the current branch compared to origin/main (or the default branch). Focus on the following categories:

## Security & Vulnerabilities

- OWASP Top 10 vulnerabilities
- Data leakage risks
- Insecure dependencies or imports
- Improper error handling that could expose sensitive information
- Path traversal, injection, or unsafe deserialization

## Performance & Efficiency

- O(n²) or worse algorithms in hot paths
- Unnecessary object allocations or memory leaks
- Blocking I/O operations
- Reactivity bottlenecks (for frontend frameworks)
- Missing caching opportunities

## Maintainability & Code Quality

- DRY (Don't Repeat Yourself) violations
- SOLID principle adherence
- Function/variable naming clarity
- Component modularity and separation of concerns
- Type safety and proper interface definitions
- Dead code or unused variables

## Correctness & Edge Cases

- Off-by-one errors
- Null/undefined access risks
- Race conditions
- Improper state management
- Unhandled promise rejections
- Missing input validation
- Timezone and date handling issues

## Testing Coverage & Quality

- Missing or inadequate test cases for new code
- Tests that don't validate edge cases
- Lack of integration or E2E tests for critical paths
- Flaky or overly brittle tests

## Documentation & Communication

- Missing or outdated docstrings
- Lack of inline comments specifically for complex logic
- README or documentation not updated for new features
- Changelog entries missing for significant changes

## Configuration & Secrets Management

- Hardcoded configuration values
- Secrets or API keys in code (even if commented)
- Environment-specific logic that should be configurable
- Missing environment variable validation

## Breaking Changes & Compatibility

- Potential breaking changes in public APIs
- Backward compatibility issues
- Database migration concerns
- Version compatibility with dependencies

## Logging & Observability

- Insufficient logging for debugging production issues
- Overly verbose logging in production
- Missing error tracking/telemetry
- Lack of meaningful log context

## Resource Management

- File handles, database connections, or sockets not properly closed
- Memory-intensive operations without cleanup
- Missing timeout configurations

## Accessibility (for frontend code)

- Missing ARIA labels or semantic HTML
- Keyboard navigation issues
- Color contrast or screen reader compatibility problems

## Code Style & Conventions

- Inconsistency with project style guidelines
- Linting rule violations
- Import organization

## Positive Patterns Section

- Explicitly call out well-implemented features
- Highlight clever solutions or good architectural decisions
- Reinforce good practices for encouragement

## Guidelines

- **Do not hallucinate issues.** Only report high-confidence findings.
- If the code is simple and safe, it is acceptable to return nothing or a positive insight.
- Organize findings by severity (High, Medium, Low).
- Provide specific file locations and line numbers for each issue.
- Include code snippets and recommended fixes where applicable.
- Summarize findings in a table at the end.
