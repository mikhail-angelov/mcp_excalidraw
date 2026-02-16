# Excalidraw Agent Deployment Makefile

# Configuration - Dynamically loaded from .env
VPS_USER = root
VPS_HOST = $(shell grep '^HOST=' .env | cut -d '=' -f 2)
VPS_PATH = /opt/mcp_excalidraw
IMAGE_NAME = ghcr.io/mikhail-angelov/mcp-excalidraw-agent:latest

.PHONY: build push init-config deploy logs status

# 1. Build the Docker image locally
build:
	docker build -f Dockerfile.agent -t $(IMAGE_NAME) .

# 2. Push the image to the registry (requires docker login ghcr.io)
push: build
	docker push $(IMAGE_NAME)

# 3. Initial deployment: Create directory and copy configuration files
init-config:
	ssh $(VPS_USER)@$(VPS_HOST) "mkdir -p $(VPS_PATH)"
	scp docker-compose.agent.yml $(VPS_USER)@$(VPS_HOST):$(VPS_PATH)/docker-compose.yml
	scp .env $(VPS_USER)@$(VPS_HOST):$(VPS_PATH)/

# 4. Standard deployment: Build, push, pull on VPS, and restart
deploy:
	ssh $(VPS_USER)@$(VPS_HOST) "cd $(VPS_PATH) && \
		docker compose pull && \
		docker compose up -d"

# Helper: View logs on the VPS
logs:
	ssh $(VPS_USER)@$(VPS_HOST) "cd $(VPS_PATH) && docker compose logs -f"

# Helper: Check service status on the VPS
status:
	ssh $(VPS_USER)@$(VPS_HOST) "cd $(VPS_PATH) && docker compose ps"
