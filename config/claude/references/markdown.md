# Markdown Formatting

## List Markers

- Use `-` for bullet lists; don't mix `*` or `+` within the same document
- Consistent markers keep list nesting visually predictable across renderers

## Code Blocks

- Always specify a language on fenced code blocks (e.g. ` ```bash `, ` ```json `)
- Use `text` for plain output/logs with no language semantics, rather than
  leaving the fence unlabeled

## Headings

- Surround headings with a blank line on both sides
- Some renderers (including GitHub) misparse a heading glued to adjacent text

## Bold

- Use bold sparingly — only for the one or two points a skimming reader must
  not miss
- Bolding every other phrase defeats the purpose: nothing stands out
