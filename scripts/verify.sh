#!/bin/bash
# verify.sh — Unified verification for godot-skills
# Usage: ./scripts/verify.sh
set -e
cd "$(dirname "$0")/.."

PASS=0
FAIL=0

pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "=========================================="
echo "godot-skills — Verification"
echo "=========================================="
echo ""

# [1] Skills validation (delegates to existing script)
echo "[1] Skills validation"
if bash scripts/validate-skills.sh > /dev/null 2>&1; then
    pass "All skills pass Agent Skills Open Standard checks"
else
    fail "Skills validation failed — run scripts/validate-skills.sh for details"
fi

# [1b] Lint checks
echo ""
echo "[1b] SKILL.md lint"
if bash scripts/lint-skills.sh > /dev/null 2>&1; then
    pass "SKILL.md lint checks pass"
else
    fail "SKILL.md lint failed — run scripts/lint-skills.sh for details"
fi

# [1c] Agent extension validation
echo ""
echo "[1c] Agent extension validation"
if bash scripts/check-agent-extensions.sh > /dev/null 2>&1; then
    pass "Agent extension checks pass"
else
    fail "Agent extension validation failed — run scripts/check-agent-extensions.sh for details"
fi

# [1d] references/ links resolve
# A skill needs no references/ at all; what breaks an agent is a link to a file
# that isn't there.
echo ""
echo "[1d] Reference links"
REF_BROKEN=0
for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    for target in $(grep -o 'references/[A-Za-z0-9._-]*\.md' "$skill_dir/SKILL.md" 2>/dev/null | sort -u); do
        if [ ! -f "$skill_dir$target" ]; then
            fail "$skill_name — SKILL.md links to missing $target"
            REF_BROKEN=$((REF_BROKEN+1))
        fi
    done
done
if [ "$REF_BROKEN" -eq 0 ]; then
    pass "Reference links all resolve"
fi

# [2] Package structure
echo ""
echo "[2] Package structure"
[ -f "LICENSE" ] && pass "LICENSE present" || fail "LICENSE missing"
[ -f "README.md" ] && pass "README.md present" || fail "README.md missing"
[ -f "AGENTS.md" ] && pass "AGENTS.md present" || fail "AGENTS.md missing"
[ -f "CHANGELOG.md" ] && pass "CHANGELOG.md present" || fail "CHANGELOG.md missing"

# [3] Examples
echo ""
echo "[3] Example projects"
for example in minimal-rpg platformer-2d multiplayer-lobby; do
    if [ -d "examples/$example" ] && [ -f "examples/$example/README.md" ]; then
        pass "Example: $example"
    else
        fail "Example: $example (missing or incomplete)"
    fi
done

# [4] Docs
echo ""
echo "[4] Documentation"
[ -f "docs/architecture.md" ] && pass "docs/architecture.md" || fail "docs/architecture.md missing"
[ -f "docs/contributing.md" ] && pass "docs/contributing.md" || fail "docs/contributing.md missing"
[ -f "docs/cross-agent-testing.md" ] && pass "docs/cross-agent-testing.md" || fail "docs/cross-agent-testing.md missing"

# [5] ADR count
echo ""
echo "[5] Architecture Decision Records"
ADR_COUNT=$(find docs/adr -name "*.md" 2>/dev/null | wc -l)
if [ "$ADR_COUNT" -gt 0 ]; then
    pass "docs/adr/ has $ADR_COUNT ADR files"
else
    fail "docs/adr/ is empty"
fi

# [6] Scripts
echo ""
echo "[6] Scripts"
[ -f "scripts/validate-skills.sh" ] && pass "scripts/validate-skills.sh" || fail "scripts/validate-skills.sh missing"
[ -f "scripts/verify.sh" ] && pass "scripts/verify.sh" || fail "scripts/verify.sh missing"
[ -f "scripts/lint-skills.sh" ] && pass "scripts/lint-skills.sh" || fail "scripts/lint-skills.sh missing"
[ -f "scripts/check-agent-extensions.sh" ] && pass "scripts/check-agent-extensions.sh" || fail "scripts/check-agent-extensions.sh missing"
[ -f "scripts/new-skill.sh" ] && pass "scripts/new-skill.sh" || fail "scripts/new-skill.sh missing"

# [7] CI/CD
echo ""
echo "[7] CI/CD configuration"
[ -f ".github/workflows/ci.yml" ] && pass "GitHub Actions CI workflow" || fail "GitHub Actions CI workflow missing"

# [8] Community docs
echo ""
echo "[8] Community & release docs"
[ -f "docs/ecosystem.md" ] && pass "docs/ecosystem.md" || fail "docs/ecosystem.md missing"
[ -f "docs/release-process.md" ] && pass "docs/release-process.md" || fail "docs/release-process.md missing"
[ -f "docs/changelog-guide.md" ] && pass "docs/changelog-guide.md" || fail "docs/changelog-guide.md missing"
[ -d "docs/skill-template" ] && pass "docs/skill-template/ exists" || fail "docs/skill-template/ missing"

# [9] Template completeness
echo ""
echo "[9] Skill template files"
[ -f "docs/skill-template/SKILL.md" ] && pass "skill-template/SKILL.md" || fail "skill-template/SKILL.md missing"
[ -f "docs/skill-template/agents/claude-code.yaml" ] && pass "skill-template/agents/claude-code.yaml" || fail "skill-template agents/ missing"
[ -f "docs/skill-template/references/DETAIL.md" ] && pass "skill-template/references/DETAIL.md" || fail "skill-template references/ missing"

echo ""
echo "=========================================="
TOTAL=$((PASS+FAIL))
if [ "$FAIL" -eq 0 ]; then
    echo "ALL CHECKS PASSED: $PASS/$TOTAL"
else
    echo "RESULTS: $PASS passed, $FAIL failed ($TOTAL total)"
    exit 1
fi
echo "=========================================="
