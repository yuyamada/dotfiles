# Technical Answers

## Cite Sources for All Technical Claims

When answering any technical question — including API usage, library behavior,
CLI flags, configuration options, version-specific behavior, or implementation
choices — you MUST verify against an authoritative source before responding:

1. **Official documentation**: Use the `context7` MCP tool
   (`mcp__plugin_context7_context7__query-docs`) to fetch up-to-date docs for
   any library, framework, SDK, or cloud service. Do this even when you think
   you know the answer — training data may be outdated.

2. **Source code**: When docs are unavailable or ambiguous, read the actual
   source code (via Read/Grep tools) and cite the file and line number.

3. **Never answer from memory alone**: If you cannot find an authoritative
   reference, say so explicitly rather than stating uncertain information as
   fact.

## What Counts as Technical

- API method signatures, parameters, return types
- CLI flags, config keys, default values
- Library/framework behavior and version differences
- Cloud service limits, pricing, feature availability
- Protocol specifications and standards compliance

## What Does Not Require a Reference

- General programming concepts with no version-sensitive behavior
- Code you are writing fresh based on the user's spec
- Architecture trade-offs grounded in the user's own codebase
