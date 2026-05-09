# TechAnalysis Workflow

Analyze how a specific technology works (architecture, internals, mechanisms).

## When to Use

- User asks "how does X work", "explain the architecture", "what's under the hood"
- Understanding technical systems
- Learning implementation details

## Process

1. **Define Analysis Scope**
   - High-level architecture OR deep internals?
   - Specific component OR entire system?
   - Theoretical OR practical focus?

2. **Gather Technical Information**
   - **Official architecture docs**
   - **Source code** (if open source)
   - **Technical talks/presentations**
   - **Engineering blog posts**
   - **RFCs/design documents**

3. **Break Down the System**
   - Components/layers
   - Data flow
   - Key algorithms
   - Performance characteristics
   - Design decisions and trade-offs

4. **Use Diagrams** (when helpful)
   - Architecture diagrams
   - Sequence diagrams
   - Data flow diagrams
   - Component relationships

5. **Structure Analysis**
   ```markdown
   # Technical Analysis: [Technology]

   ## Overview
   [What it is, what problem it solves]

   ## Architecture
   [High-level system design]

   ### Components
   - **Component A**: [Purpose and function]
   - **Component B**: [Purpose and function]

   ### Data Flow
   1. Step 1
   2. Step 2
   3. Step 3

   ## How It Works
   [Detailed mechanisms]

   ## Key Design Decisions
   - **Decision 1**: Why they chose X over Y
   - **Decision 2**: Trade-off analysis

   ## Performance Characteristics
   - Latency: [Details]
   - Throughput: [Details]
   - Scalability: [Details]

   ## Implementation Details
   [Code-level insights if relevant]

   ## Limitations & Trade-offs
   [What it's not good at]

   ## Sources
   [Technical documentation, papers, talks]
   ```

## Example: "How does JWT authentication work?"

```markdown
# Technical Analysis: JWT Authentication

## Overview
JWT (JSON Web Tokens) is a stateless authentication mechanism that
encodes user identity and claims in a cryptographically signed token.

## Architecture

### Components
- **Header**: Token type and signing algorithm
- **Payload**: Claims (user data, expiration, etc.)
- **Signature**: HMAC or RSA signature for verification

### Data Flow
1. User authenticates with credentials
2. Server generates JWT with user claims
3. Client stores JWT (localStorage/cookie)
4. Client includes JWT in Authorization header
5. Server verifies signature and extracts claims
6. Server processes request with user context

## How It Works

**Token Generation:**
\`\`\`
header = base64url({"alg":"HS256","typ":"JWT"})
payload = base64url({"sub":"user123","exp":1234567890})
signature = HMAC-SHA256(header + "." + payload, secret)
token = header + "." + payload + "." + signature
\`\`\`

**Token Verification:**
1. Split token by "."
2. Decode header and payload
3. Recompute signature with server secret
4. Compare signatures
5. Check expiration
6. Extract user claims

## Key Design Decisions

- **Stateless**: No server-side session storage required
  - Pro: Scales horizontally easily
  - Con: Can't revoke tokens before expiration

- **Self-contained**: All user data in token
  - Pro: No database lookup needed
  - Con: Token size grows with claims

## Performance Characteristics
- **Latency**: ~1ms for verification (HMAC)
- **Throughput**: Thousands of verifications/sec
- **Scalability**: Excellent (no shared state)

## Limitations & Trade-offs
- No built-in revocation mechanism
- Token size can be large
- Refresh token complexity
- Vulnerable to XSS if stored in localStorage

## Sources
1. [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
2. [JWT.io](https://jwt.io/)
[...]
```

## Tips

- **Start high-level** - Architecture before implementation details
- **Use analogies** - Help explain complex concepts
- **Show code** - Practical examples aid understanding
- **Explain trade-offs** - Every design has compromises
- **Link to sources** - Official docs trump blog posts
