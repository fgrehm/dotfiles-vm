.PHONY: create start stop destroy snapshot revert list ssh help

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

create: ## Create the VM (preseed + KDE + dotfiles mount)
	@./scripts/create.sh

destroy: ## Permanently delete the VM and its disk
	@./scripts/destroy.sh

snapshot: ## Create a snapshot (usage: make snapshot NAME=fresh-kde)
	@./scripts/snapshot.sh create $(NAME)

revert: ## Revert to a snapshot (usage: make revert NAME=fresh-kde)
	@./scripts/snapshot.sh revert $(NAME)

list: ## List all snapshots
	@./scripts/snapshot.sh list

start: ## Start the VM
	@./scripts/start.sh

stop: ## Gracefully shut down the running VM
	@./scripts/stop.sh

ssh: ## SSH into the running VM
	@./scripts/ssh.sh
