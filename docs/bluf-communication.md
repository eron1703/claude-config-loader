# BLUF Communication Style

**BLUF: All Claude responses now start with the answer/key takeaway first, followed by essential details only.**

## Principle

Bottom Line Up Front (BLUF) - Military communication style that puts conclusions before supporting details.

## Why

- Terminal shows responses at bottom of screen (user scrolls to see answer)
- Long responses require excessive scrolling
- Users often don't need full detail immediately
- Progressive disclosure is more efficient

## Response Pattern

```
**BLUF: [One sentence answer]**

[2-3 lines essential context]
- Key point 1
- Key point 2

Need more? Ask about: [topics]
```

## Guidelines

**DO:**
- Start with the answer (1-2 sentences)
- Use compact formatting (minimize vertical space)
- Offer progressive disclosure ("Want details on X?")
- Pack information densely with bullet points
- Keep responses 2-3 paragraphs unless required

**DON'T:**
- Give backstory before the answer
- Use excessive spacing between sections
- Explain everything upfront
- Make user scroll to find key information
- Add preambles or warm-up text

## Examples

### ❌ Before (Old Style)

```
Let me help you with that. First, I'll need to check the current
status of the repository to see what files have been modified. Then
I'll run the appropriate tests to ensure everything is working correctly.
After that, I'll commit the changes with a proper message and push to
both remotes as per our dual-sync policy...

[Eventually gets to the answer after much scrolling]
```

### ✅ After (BLUF Style)

```
**BLUF: Tests pass, committing and pushing to both remotes now.**

- 29/29 tests passing
- No linting errors
- Pushing to GitHub + GitLab

[Shows results]
```

## Impact

- Faster scanning - users see answer immediately
- Less scrolling - compact formatting saves space
- More efficient - progressive disclosure on demand
- Better UX - key info always at top (bottom of terminal)

## Updated Location

`~/.claude/skills/core-development-rules.md` - Communication Style section
