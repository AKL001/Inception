# ==============================================================================
# Variables
# ==============================================================================
DOMAIN				= $(USER).42.fr
VOLUME_PATH			= /home/$(USER)/data
WORDPRESS_VOLUME	= $(VOLUME_PATH)/wordpress
MARIADB_VOLUME		= $(VOLUME_PATH)/mariadb
COMPOSE				= docker compose -f srcs/docker-compose.yaml

# ==============================================================================
# Rules
# ==============================================================================

all: setup build

setup:
	@echo "=== Creating data directories ==="
	@sudo mkdir -p $(WORDPRESS_VOLUME)
	@sudo mkdir -p $(MARIADB_VOLUME)

start:
	@echo "=== STARTING CONTAINERS ==="
	$(COMPOSE) up -d

build:
	@echo "=== Building and starting containers ==="
	$(COMPOSE) up -d --build

stop:
	@echo "=== Stopping containers ==="
	$(COMPOSE) down

clean: stop
	@echo "=== Cleaning Docker environment ==="
	$(COMPOSE) down -v --remove-orphans
	docker volume prune -f

fclean: clean
	@echo "=== Wiping host data directories ==="
	@sudo rm -rf $(MARIADB_VOLUME)
	@sudo rm -rf $(WORDPRESS_VOLUME)

re: fclean all

.PHONY: all setup build stop clean fclean re start