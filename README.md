# ✨ Welcome to ECI's GitHub Repository Template! ✨

🚀 Ready to launch your next stellar project? You've landed on the right launchpad! This repository is your ultimate starter kit for blasting off a new company GitHub repository.

## Important Considerations

For the best experience, please follow these guidelines:

### Template Setup Notes

This template includes starter defaults that should be reviewed for each new repository.

- `environments/*.env` contains default repository and container paths.
- `docker-compose.yml` uses portable relative mounts by default.
- `scripts/ci/run-ci.sh` runs a template smoke test and should be replaced with project-specific checks.
- `.github/workflows/cd.yml` includes `scripts` in deployment files so reusable project scripts are available during deployment.

### Required Branches on GitHub

- `main` - The main branch for the repository.
- `staging` - The staging branch for the repository.
- `production` - The production branch for the repository.
- `release` - The release branch for the repository.
- `gh-pages` - The GitHub Pages branch for the repository.

### Minimum Directory Structure

The following directory structure is required for the template to work correctly.

```plaintext
|--- .github/
      |--- workflows/
           |--- ci.yml
           |--- cd.yml
           |--- docs.yml
           |--- guard.yml
           |--- release-log.yml
           |--- super-linter.yml
|--- LICENSE  # ECI Proprietary License file / Apache 2.0
|--- README.md
```

## Status

| Workflow | Status |
|----------|--------|
| **Continuous Integration** | [![Continuous-Integration](https://github.com/ec-intl/workflow-templates/actions/workflows/ci.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/ci.yml) |
| **Continuous Deployment** | [![Continuous Deployment](https://github.com/ec-intl/workflow-templates/actions/workflows/cd.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/cd.yml) |
| **Documentation Status** | [![Documentation](https://github.com/ec-intl/workflow-templates/actions/workflows/docs.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/docs.yml) |
| **Guard Main Branch** | [![Guard Main](https://github.com/ec-intl/workflow-templates/actions/workflows/guard.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/guard.yml) |
| **Code Standards Checks** | [![Lint Codebase](https://github.com/ec-intl/workflow-templates/actions/workflows/super-linter.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/super-linter.yml) |
| **Release Logging** | [![Release Log](https://github.com/ec-intl/workflow-templates/actions/workflows/release-log.yml/badge.svg)](https://github.com/ec-intl/workflow-templates/actions/workflows/release-log.yml) |

## Why Use This Template?

- **Ignite Your Engines:** Accelerate your projects with pre-configured settings, branching strategies, and essential files.
- **Mission Control:** Standardized structure makes it easier for your team to collaborate and navigate your repositories.

## What's in the Cargo Bay?

- **README.MD:** This is a helpful guide!
- **LICENSE:** Choose the appropriate license for your project.
- **.gitignore:** Ignore files that shouldn't be tracked in your repository.
- **.github/workflows:** GitHub Actions for CI/CD.
- **Dockerfile:** Build your project into a container.
- **Jupyter Notebook:** A sample notebook to get you started.
- **docker-compose.yml:** A sample Docker Compose file.
- **run-ci:** A script to run CI checks locally but with Docker.
- **run-linter:** A script to run linters locally.
- **[Optional Folders]:** Examples: `docs/`, `notebooks/`, `src/`, `environments/`, `.github/`, and `.devcontainer/`

## 🚀 3... 2... 1... Liftoff! 🚀

1. **Create the repository from this template.**
2. **Create or confirm the required branches:** `main`, `staging`, `production`, `release`, and `gh-pages`.
3. **Replace template placeholders:** update `template-repository`, `Template Repository`, sample files, and paths with the new project details.
4. **Update project metadata:** review `README.md`, `CHANGELOG.md`, `VERSION`, and `LICENSE`.
5. **Review environment files:** update values that affect behavior, such as `PROJECT_HOME`, in `environments/*.env`.
6. **Review Docker and Compose settings:** confirm volume mounts, container paths, and any hardcoded container user/path defaults match the new project.
7. **Replace the template CI smoke test:** update `scripts/ci/run-ci.sh` with project-specific tests.
8. **Confirm documentation setup:** update `docs/` and `.github/workflows/docs.yml` for the project.
9. **Run local checks before opening the first PR.**

## 🌌 Repository Structure 🌌

```plaintext
|--- .devcontainer/          # Dev Container settings
      |--- bash-src
           |--- aliases
           |--- functions
      |--- install
|--- .github/                # GitHub Actions
      |--- workflows/
           |--- ci.yml
           |--- cd.yml
           |--- docs.yml
           |--- guard.yml
           |--- release-log.yml
           |--- super-linter.yml
|--- docs/
      |--- index.html
      |--- static/
           |--- css/
                |--- site.css
           |--- js/
                |--- site.js
|--- environments/
      |--- development.env
      |--- production.env
      |--- staging.env
      |--- testing.env
|--- notebooks/
      |--- sample.ipynb
|--- scripts/
      |--- ci
            |--- run-ci.sh
      |--- dev
            |--- .sleeping_daemon.sh
|--- src/
      |--- sample_module.py
|--- .dockerignore
|--- .gitignore
|--- Dockerfile
|--- LICENSE
|--- README.md
|--- docker-compose.yml
|--- VERSION
```
