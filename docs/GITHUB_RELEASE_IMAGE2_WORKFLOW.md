# GitHub Release Image2 Workflow

All future GitHub project releases should use this workflow before the repository is announced or tagged. The goal is to make every published project visually complete, easy to recognize, and reusable by Codex and Claude Code.

## Required Gate

Before a GitHub project is published or released:

1. Generate or prepare Image2 visual assets for the project.
2. Add the assets to the repository or release notes.
3. Reference the assets from `README.md` when useful.
4. Verify the README, agent guide, and release notes point to the same project story.
5. Run tests and smoke checks.
6. Publish to GitHub only after the visual and agent workflows are aligned.

## Image2 Asset Pack

Use Image2 for these assets when the project has a public-facing release:

- repository social preview or hero image,
- README workflow diagram or visual overview,
- release card for social sharing,
- icon/logo when the project needs a recognizable mark,
- optional screenshot-style mockup showing how Codex or Claude Code uses the tool.

Recommended output folder:

```text
assets/image2/
```

Recommended filenames:

```text
assets/image2/social-preview.png
assets/image2/readme-hero.png
assets/image2/workflow-overview.png
assets/image2/release-card-v0.1.0.png
```

## Prompt Contract

Every generated asset should have a prompt record:

```text
assets/image2/prompts/
```

Example:

```text
assets/image2/prompts/social-preview.md
```

Prompt records should include:

- project name,
- intended asset,
- prompt,
- size and quality,
- date,
- manual review notes,
- whether text in the image was checked for legibility.

## Agent Workflow

Codex and Claude Code should both follow this order:

1. Run project checks:

```bash
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

2. Inspect or create the Image2 asset plan:

```text
assets/image2/prompts/*.md
```

3. Generate or update required assets with Image2.
4. Update `README.md`, `AGENT_GUIDE.md`, and release notes to reference the assets.
5. Run verification:

```bash
python -m unittest discover -s tests -p "test_*.py"
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

6. Publish or tag the GitHub release.

## Safety Boundary

Do not use non-Image2 image models by default for project publishing assets. Do not use account cookies, platform login automation, upload automation, or payment links as part of this release workflow.

If Image2 is unavailable in the current environment, record the blocker in release notes and do not claim the project has completed the Image2 release gate.
