---
name: markitdown-skill
description: "Use when converting PDFs, DOCX, PPTX, XLSX, TXT, HTML, images, or audio files to Markdown with the local markitdown CLI or wrapper."
---

# MarkItDown

Use the local repository at `~/markitdown` and the wrapper script located in the skill's `bin/markitdown.sh` (within the skill directory) for all conversions. This skill is for using markitdown, not installing it.

## When to use
- Convert a single file to Markdown.
- Convert a file to a specific output path.
- Inspect or normalize document content before handing it back to the user.
- Run the local CLI instead of inventing a replacement parser.

## Workflow
1. Prefer `bin/markitdown.sh INPUT -o OUTPUT.md` when the user wants a Markdown file on disk.
2. Use `bin/markitdown.sh INPUT` when the user wants Markdown on stdout.
3. Use `-x` only when the input extension is ambiguous or unavailable.
4. For large or sensitive files, write to a file instead of pasting the full output in chat.
5. For any refinement step, inspect the raw conversion for that specific file first, then refine only that file; do not apply a corpus-wide cleanup without checking representative raw output for each document type.
6. After refinement, compare the refined file against the raw file to ensure no dates, titles, captions, table values, or formula fragments were removed or merged incorrectly.

## Runtime notes
- The wrapper executable is located at `bin/markitdown.sh` inside the skill directory.
- **Default Pathing**: By default, the wrapper targets the repository at `~/markitdown` and uses the virtual environment at `~/markitdown/.venv`.
- **Flexibility**: You can override the target repository path using the `MARKITDOWN_REPO` environment variable, and specify a custom virtual environment using the `MARKITDOWN_VENV` environment variable.
- The wrapper auto-detects `exiftool` and `ffmpeg` if they are installed on the host system.
- **Autonomous Setup**: If the `markitdown` local environment is missing, unconfigured, or broken (e.g., the virtual environment `.venv` does not exist or the wrapper executable complains that the environment is unbuilt), you MUST autonomously and automatically build/repair the environment without throwing a fatal error. Do not force the human to manually set up. Perform the following steps automatically:
  1. If the repository directory (default `~/markitdown` or specified by `MARKITDOWN_REPO`) does not exist, clone it from `https://github.com/microsoft/markitdown.git`.
  2. Create a virtual environment at the target path (default `.venv` inside the repo) using `python3 -m venv .venv`.
  3. Activate it and install dependencies with `pip install -U pip setuptools wheel && pip install -e 'packages/markitdown[all]'`.
  - While performing autonomous setup, briefly inform the user of the setup progress so they are kept up-to-date.
  - If optional tools like `exiftool` or `ffmpeg` are missing from the system, inform the user and suggest installing them, but proceed with the basic `markitdown` conversions.

## Safety
- Do not expose the MCP server on public interfaces.
- Avoid pasting secrets or large extracted content unless the user explicitly asks for it.
- For untrusted files, prefer local execution and keep the converted output in a file.

## Post-processing and Refinement
After conversion, especially for Japanese slide-based PDFs or OCR-heavy documents, the AI agent is responsible for refining the content. **CRITICAL: Preservation of information is the highest priority.**

**MANDATORY STEP**: You MUST proactively create the refined Markdown file (e.g., `filename_refined.md`) alongside the raw conversion. Do not wait for the user to explicitly ask for the refined version. If the user provides multiple files, you may process and refine them sequentially to ensure quality, but you must not refuse to create the refined files simply because they were provided in a batch.

1. **NO Information Loss**: Do NOT summarize or omit any text, terminology, numbers, or names. Every piece of information from the raw conversion must be present in the refined version.
2. **Formatting Only**: Focus on fixing layout issues, not changing content.
3. **Remove Artifacts**: Clean up form feeds (`\f`) and standalone page numbers only when they are clearly page markers; do not remove dates, slide titles, section labels, or other meaningful standalone lines.
4. **Structure with Headers**: Convert slide titles into Markdown headers (e.g., `##`).
5. **Standardize Lists**: Convert bullet symbols (e.g., `◆` or `・`) to `- `.
6. **Natural Text Flow**: Join lines that were split across pages or slides, but ensure every word is kept.
7. **Diagrams and Tables**: Represent text-based diagrams and tables as faithfully as possible without losing component names or values.
8. **Japanese Context**: Ensure proper punctuation while maintaining the original tone and terminology.

The goal is a "clean" but "complete" Markdown document, not a summary.

### Refinement Guardrails
- **Do not use automated scripts (e.g., Python regex scripts) for refinement.** The AI agent must directly generate and output the refined markdown (e.g., via `write_to_file`) to ensure nuanced text flow formatting.
- Do not run broad regex-based cleanup across an entire corpus if it can rewrite structured content by accident.
- Do not batch-convert a whole folder into refined Markdown unless each document has been spot-checked against its raw counterpart first.
- Do not infer or invent structure from OCR fragments, merged table cells, or broken equations.
- Do not rewrite tables into Markdown tables unless every cell/value can be verified from the raw conversion.
- Do not collapse, reorder, or reflow lines in ways that may join unrelated rows, list items, captions, or formula fragments.
- Do not treat dates such as `2026/04/23` or `2026/05/07` as page numbers; preserve them unless the source clearly shows they are non-content markers.
- Prefer leaving ambiguous structured sections close to the raw conversion rather than "improving" them incorrectly.
- If a document contains many tables, equations, or diagrams, verify a small sample against the raw output before applying any file-wide transformation.
- If a safe refinement is not obvious, keep the raw wording and only remove obvious artifacts such as page numbers and form feeds.

**Note on File Management**: Always keep the raw conversion result (e.g., `filename.md`) alongside the refined version (e.g., `filename_refined.md`). This allows for verification of the AI's refinement process and provides a fallback if any content was accidentally omitted during cleanup.
