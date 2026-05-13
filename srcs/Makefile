# ==============================================================================
# Variables
# ==============================================================================
DOMAIN				= $(USER).42.fr
VOLUME_PATH			= /home/$(USER)/data
WORDPRESS_VOLUME	= $(VOLUME_PATH)/wordpress
MARIADB_VOLUME		= $(VOLUME_PATH)/mariadb

# ==============================================================================
# Rules
# ==============================================================================

# 'all' ensures directories exist (setup) BEFORE building the containers
all: setup build

# Safely creates directories with the correct permissions and sets the local domain
setup:
	@echo "=== Creating data directories ==="
	@sudo mkdir -p $(WORDPRESS_VOLUME)
	@sudo mkdir -p $(MARIADB_VOLUME)
	@sudo chmod 777 $(WORDPRESS_VOLUME)
	@sudo chmod 777 $(MARIADB_VOLUME)
# 	@echo "=== Setting up hosts file ==="
# 	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
# 		echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
# 	fi
start:
	@echo "=== STARTING CONTIANERS ==="
	docker compose up -d
# Builds and starts containers in the background
build:
	@echo "=== Building and starting containers ==="
	docker compose up -d --build

# Safely stops containers without destroying data
stop:
	@echo "=== Stopping containers ==="
	docker compose down

# Cleans up containers, networks, and Docker volumes (but NOT the host physical files)
clean: stop
	@echo "=== Cleaning Docker environment ==="
	docker compose down -v
# 	docker system prune -af

# The NUCLEAR OPTION. Cleans Docker AND completely deletes host data folders
fclean: clean
	@echo "=== Wiping host data directories ==="
	@sudo rm -rf $(MARIADB_VOLUME)
	@sudo rm -rf $(WORDPRESS_VOLUME)

# Completely wipes everything, THEN recreates the directories, THEN builds fresh
reb: fclean all

# Standard alias for 'reb' (make re is the standard for 42 projects)
re: fclean all

# .PHONY prevents Make from confusing rules with actual files
.PHONY: all setup build stop clean fclean reb re start