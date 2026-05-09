# InvestigateError Workflow

Systematic error investigation and resolution.

## Process

1. **Gather Information**
   - Error message
   - Stack trace
   - Code where error occurs
   - Input that triggers it
   - Environment (OS, versions, etc.)

2. **Analyze Error**
   - Error type (TypeError, ReferenceError, etc.)
   - Line number and file
   - Call stack
   - Variable values at failure

3. **Identify Likely Causes**
   - Common causes for this error type
   - Code logic issues
   - Type mismatches
   - Null/undefined values
   - Async timing issues

4. **Test Hypotheses**
   - Add logging
   - Check variable types
   - Verify assumptions
   - Test edge cases

5. **Provide Solution**
   - Explain root cause
   - Show fix with code
   - Explain why it works
   - Suggest prevention strategy

## Example

**Error:** `TypeError: Cannot read property 'name' of undefined`

**Investigation:**
1. Variable `user` is undefined
2. Likely cause: async data not loaded yet
3. Solution: Add null check or ensure data loaded first
