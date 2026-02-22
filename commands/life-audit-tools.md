---
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
argument-hint: [language]
description: Audit project quality tools and propose strict configurations
---

# /life-audit-tools — Quality Tooling Audit

Scan the project for existing quality tools and propose strict configurations. This command is separate from `/life-init` — run it when you want to set up or review linters, formatters, type checkers, and other quality gates.

## Phase 1: Project Detection

Scan the project root for manifest files to identify the tech stack:

| Manifest | Language/Framework |
|----------|--------------------|
| `package.json` | JavaScript/TypeScript — check for Next.js, React, Vue, Angular, Node.js, etc. |
| `tsconfig.json` | TypeScript (confirm strict mode settings) |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python |
| `go.mod` | Go |
| `pom.xml` / `build.gradle` / `build.gradle.kts` | Java/Kotlin |
| `*.sln` / `*.csproj` | C#/.NET |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `pubspec.yaml` | Dart/Flutter |
| `Package.swift` | Swift |
| `Makefile` / `CMakeLists.txt` | C/C++ |

Read the manifest to understand dependencies, scripts, and existing tooling.

## Phase 2: Audit Existing Quality Tools

For the detected language(s), check what's already configured:

**Check for config files:**
- Linters: `.eslintrc*`, `eslint.config.*`, `.flake8`, `ruff.toml`, `.golangci.yml`, `clippy.toml`
- Formatters: `.prettierrc*`, `biome.json`, `rustfmt.toml`, `.editorconfig`
- Type checkers: `tsconfig.json` (check `strict`), `mypy.ini`, `pyrightconfig.json`
- Dead code: `knip.json`, `knip.config.ts`
- Dependencies: `.dependency-cruiser.js`, `.jscpd.json`
- Git hooks: `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml`
- Commit lint: `commitlint.config.*`, `.czrc`
- Security: `.snyk`, `.trivyignore`, `semgrep.yml`
- CI: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`

**Check package.json scripts** (for JS/TS):
- lint, lint:fix, format, format:check, typecheck, test, build
- Any quality-related scripts

## Phase 3: Propose ALL Quality Tools in STRICT Mode

Present a comprehensive proposal. ALL rules must be set to ERROR level (not warn). The agent must have NO choice but to fix violations — warnings are too easy to ignore.

### For JavaScript/TypeScript Projects

| Category | Tool | Strict Configuration |
|----------|------|---------------------|
| **Linter** | ESLint (flat config, v9+) | All recommended rules on `error`. No `warn`. |
| **Plugin: Code Quality** | eslint-plugin-sonarjs | `sonarjs.configs.recommended` — cognitive-complexity: error at 15 |
| **Plugin: Accessibility** | eslint-plugin-jsx-a11y | `plugin:jsx-a11y/strict` — all rules on error |
| **Plugin: Architecture** | eslint-plugin-boundaries | Define layer hierarchy, default: disallow |
| **Plugin: Imports** | eslint-plugin-simple-import-sort | Sorting on error |
| **Plugin: Unused** | eslint-plugin-unused-imports | Remove unused imports on error |
| **Formatter** | Prettier (or Biome) | Enforced via pre-commit hook, check on CI |
| **Type Checker** | TypeScript | `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true` |
| **Dead Code** | knip | Strict mode, minimal ignores |
| **Circular Deps** | dependency-cruiser | Circular = error, orphans = error |
| **Circular Deps** | madge | `--circular` as separate check |
| **Copy-Paste** | jscpd | threshold: 5%, minLines: 15, minTokens: 80 |
| **Security** | npm audit | Run in CI, fail on high/critical |
| **Commit Lint** | commitlint + @commitlint/config-conventional | Enforced via husky commit-msg hook |
| **Pre-Commit** | husky + lint-staged | eslint --fix + prettier --write on staged files |
| **Pre-Push** | husky pre-push | tsc --noEmit + test + lint + knip + build |
| **Bundle Size** | size-limit (optional) | Warn on regression |

### For Python Projects

| Category | Tool | Strict Configuration |
|----------|------|---------------------|
| **Linter + Formatter** | ruff | All rules enabled, select only relevant, all on error |
| **Type Checker** | mypy | `strict = true`, `disallow_any_generics`, `warn_return_any` |
| **Security** | bandit | All checks enabled |
| **Dead Code** | vulture | Min confidence 80% |
| **Import Sort** | isort (or ruff) | Enforced, profile=black |
| **Formatter** | black (or ruff format) | Line length 88/100 |
| **Pre-Commit** | pre-commit framework | All hooks: ruff, mypy, bandit |
| **Deps Audit** | pip-audit | Fail on known vulnerabilities |

### For Rust Projects

| Category | Tool | Strict Configuration |
|----------|------|---------------------|
| **Linter** | clippy | `#![deny(warnings)]`, `-D clippy::all -D clippy::pedantic` |
| **Formatter** | rustfmt | Enforced, check in CI |
| **Security** | cargo audit | Fail on any advisory |
| **Licenses** | cargo deny | Check advisories + licenses |
| **Dead Deps** | cargo udeps | Error on unused dependencies |

### For Go Projects

| Category | Tool | Strict Configuration |
|----------|------|---------------------|
| **Linter** | golangci-lint | Enable ALL linters, disable only irrelevant |
| **Formatter** | gofmt / goimports | Enforced |
| **Security** | govulncheck | Fail on known vulnerabilities |
| **Dead Code** | deadcode | Error mode |

## Phase 4: Present to User

Show the user:
1. What's already configured (with assessment: strict enough or too lenient?)
2. What's missing (categorized by priority: critical / recommended / nice-to-have)
3. A concrete action plan: which packages to install, which configs to create/modify

Ask the user what they want to proceed with. Do NOT install anything without approval.

## Phase 5: Update Project CLAUDE.md (if approved)

If the user approved quality tooling changes, add a section to the project's CLAUDE.md:

```markdown
## Quality Rules (enforced by 100 Days system)

- ALL linter rules are set to ERROR — warnings are not acceptable
- Pre-commit hook: lint-staged runs eslint --fix + prettier on staged files
- Pre-push hook: full quality gate (tsc + tests + lint + knip + build)
- Architectural boundaries: [list the layer hierarchy]
- Run `npm run lint:all` before considering any task complete
```
