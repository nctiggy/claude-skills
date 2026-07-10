.PHONY: init build upload upload-all sync sync-project sync-private validate clean list list-remote flatten help

SKILL ?=
SKILLS_DIR := skills
SCRIPTS_DIR := scripts
DIST_DIR := dist

help:
	@echo "Skills Management"
	@echo ""
	@echo "  make init SKILL=name      Create new skill from template"
	@echo "  make build                Package all skills"
	@echo "  make build SKILL=name     Package specific skill"
	@echo "  make upload SKILL=name    Upload specific skill to API"
	@echo "  make upload-all           Upload all skills to API"
	@echo "  make sync                 Symlink skills to ~/.claude/skills"
	@echo "  make sync-project         Symlink skills to .claude/skills"
	@echo "  make sync-private         Symlink private-skills/ (never uploaded) to ~/.claude/skills"
	@echo "  make validate             Validate all skills"
	@echo "  make validate SKILL=name  Validate specific skill"
	@echo "  make flatten              Flatten all skills to dist/flattened/"
	@echo "  make flatten SKILL=name   Flatten specific skill"
	@echo "  make list                 List all local skills"
	@echo "  make list-remote          List skills on Anthropic API"
	@echo "  make clean                Remove dist/"
	@echo ""
	@echo "Environment variables:"
	@echo "  ANTHROPIC_API_KEY         Required for upload commands"

init:
ifndef SKILL
	$(error SKILL is required. Usage: make init SKILL=my-skill-name)
endif
	@python3 $(SCRIPTS_DIR)/init_skill.py $(SKILL)

build:
ifdef SKILL
	@python3 $(SCRIPTS_DIR)/package_skill.py $(SKILLS_DIR)/$(SKILL)
else
	@python3 $(SCRIPTS_DIR)/package_skill.py
endif

upload:
ifndef SKILL
	$(error SKILL is required. Usage: make upload SKILL=my-skill-name)
endif
	@python3 $(SCRIPTS_DIR)/upload_skill.py $(SKILLS_DIR)/$(SKILL)

upload-all:
	@python3 $(SCRIPTS_DIR)/upload_skill.py --all

sync:
	@bash $(SCRIPTS_DIR)/sync_local.sh

sync-project:
	@bash $(SCRIPTS_DIR)/sync_local.sh --project

# private-skills/ sits OUTSIDE skills/ on purpose: deploy.yml's path filter
# (skills/**) never uploads it. This symlink target is its only distribution.
sync-private:
	@mkdir -p $(HOME)/.claude/skills
	@for skill_dir in private-skills/*/; do \
		if [ -f "$$skill_dir/SKILL.md" ]; then \
			name=$$(basename "$$skill_dir"); \
			ln -sfn "$(CURDIR)/private-skills/$$name" "$(HOME)/.claude/skills/$$name"; \
			echo "  linked (private): $$name"; \
		fi \
	done

validate:
ifdef SKILL
	@python3 $(SCRIPTS_DIR)/quick_validate.py $(SKILLS_DIR)/$(SKILL)
else
	@for skill_dir in $(SKILLS_DIR)/*/; do \
		if [ -f "$$skill_dir/SKILL.md" ]; then \
			python3 $(SCRIPTS_DIR)/quick_validate.py "$$skill_dir"; \
		fi \
	done
	@python3 $(SCRIPTS_DIR)/secret_scan.py $(SKILLS_DIR)
endif

list:
	@echo "Local skills:"
	@echo ""
	@for skill_dir in $(SKILLS_DIR)/*/; do \
		if [ -f "$$skill_dir/SKILL.md" ]; then \
			skill_name=$$(basename "$$skill_dir"); \
			echo "  $$skill_name"; \
		fi \
	done
	@echo ""

list-remote:
	@python3 $(SCRIPTS_DIR)/upload_skill.py --list

flatten:
ifdef SKILL
	@python3 $(SCRIPTS_DIR)/flatten_skill.py $(SKILLS_DIR)/$(SKILL)
else
	@python3 $(SCRIPTS_DIR)/flatten_skill.py --all
endif

clean:
	@rm -rf $(DIST_DIR)
	@echo "Cleaned $(DIST_DIR)/"

delete:
ifndef ID
	$(error ID is required. Usage: make delete ID=skill_01abc123)
endif
	@python3 $(SCRIPTS_DIR)/upload_skill.py --delete $(ID)
