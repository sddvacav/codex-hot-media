# GitHub Project Image2 Construction Workflow

This is the required workflow for building and publishing GitHub projects. It is not only a final upload or release step. It applies before and during project construction whenever the project needs to explain what it is, why it matters, how it works, or how users and agents should use it.

The standard is: world-class presentation, world-class taste, visual-first explanation, and agent-ready structure.

## Core Rule

Any public-facing GitHub project must be built with an Image2 visual layer. If the project includes a README, launch page, release page, architecture explanation, workflow description, feature introduction, project meaning, or user-facing concept explanation, those materials need Image2-generated visuals unless there is a recorded blocker.

Do not treat images as decoration. Images are part of the explanation and acceptance standard.

## Where Image2 Is Required

Use Image2 when creating or revising:

- repository social preview,
- README hero section,
- project launch or release page,
- feature introduction sections,
- architecture overview,
- workflow explanation,
- agent workflow explanation for Codex or Claude Code,
- project meaning, positioning, or value proposition,
- release card for GitHub releases or social sharing,
- diagrams or visual metaphors that help users understand the project,
- screenshot-style mockups showing expected usage.

## Required Project Visual Pack

Every serious GitHub project should have an Image2 asset pack:

```text
assets/image2/
```

Recommended minimum:

```text
assets/image2/social-preview.png
assets/image2/readme-hero.png
assets/image2/workflow-overview.png
assets/image2/architecture-overview.png
assets/image2/release-card-v0.1.0.png
```

For smaller tools, a reduced pack is allowed only if it still explains the project visually:

```text
assets/image2/readme-hero.png
assets/image2/workflow-overview.png
```

## Required Publishing Page

When a project needs a web page, launch page, or release page, create a project publishing page that includes:

- a first-viewport project identity visual,
- concise project positioning,
- what the tool does,
- why it matters,
- how Codex uses it,
- how Claude Code uses it,
- supported network projects or ecosystem integrations,
- safety boundaries,
- install and verification commands,
- release status.

The page should not be a generic landing page. It should be a functional project presentation page that helps users understand and adopt the tool quickly.

Recommended path:

```text
docs/site/index.html
```

or, for GitHub Pages:

```text
docs/index.html
```

## Prompt Record Contract

Every Image2 asset must have a prompt record:

```text
assets/image2/prompts/
```

Example:

```text
assets/image2/prompts/readme-hero.md
```

Each prompt record should include:

- project name,
- intended asset,
- target page or document,
- prompt,
- size and quality,
- date,
- manual review notes,
- whether image text was checked for legibility,
- whether the image accurately explains the project.

## README Requirements

README construction should be visual-first:

1. Project name and one-sentence positioning.
2. Image2 hero or workflow visual.
3. What the project does.
4. Why it matters.
5. How the tool works.
6. Codex usage.
7. Claude Code usage.
8. Supported network projects.
9. Safety boundary.
10. Install and verification commands.

If README lacks a relevant Image2 visual and there is no recorded blocker, it does not meet the publishing standard.

## Architecture Requirements

Architecture explanations should include an Image2 visual or a generated diagram asset. For agent tools, the visual should show:

- input sources,
- core CLI or service,
- Codex entry,
- Claude Code entry,
- optional MCP entry,
- generated outputs,
- safety boundary.

## Agent Workflow

Codex and Claude Code should both follow this order for GitHub project construction:

1. Read this workflow.
2. Define the project story: what it is, why it matters, who uses it.
3. Define the Image2 asset pack.
4. Generate or update Image2 visuals.
5. Record prompts.
6. Build README, project page, architecture docs, and release notes around those visuals.
7. Run verification:

```bash
python -m unittest discover -s tests -p "test_*.py"
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

8. Publish or tag only after the visual layer and agent workflow are aligned.

## Acceptance Standard

A GitHub project is release-ready only when:

- it has a clear project story,
- it has Image2 visual assets or a recorded Image2 blocker,
- README and project page use those assets meaningfully,
- architecture and workflow are visually explainable,
- Codex and Claude Code paths are documented,
- install and verification commands work,
- safety boundaries are visible,
- CI passes.

## Safety Boundary

Do not use non-Image2 image models by default for project publishing assets. Do not use account cookies, platform login automation, upload automation, payment links, or final publishing automation as part of this workflow.

If Image2 is unavailable in the current environment, record the blocker in project docs and do not claim the project has met the Image2 publishing standard.
