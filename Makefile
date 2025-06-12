.PHONY: build run dev test clean

# Build the application
build:
	go build -o bin/server cmd/server/main.go

# Run the application
run:
	go run cmd/server/main.go

# Run with hot reload (requires air)
dev:
	air

# Run tests
test:
	go test -v ./...

# Clean build artifacts
clean:
	rm -rf bin/

# Install dependencies
deps:
	go mod download
	go mod tidy

# Format code
fmt:
	go fmt ./...

# Run linter (requires golangci-lint)
lint:
	golangci-lint run

# Generate Supabase types
gen-types:
	supabase gen types typescript --local > types/supabase.ts

# Infrastructure commands
.PHONY: infra-init infra-plan-dev infra-apply-dev infra-plan-prod infra-apply-prod infra-destroy-dev infra-destroy-prod

# Initialize Terraform
infra-init:
	cd infra && terraform init

# Development environment
infra-plan-dev:
	@echo "Loading environment variables and planning development infrastructure..."
	@if [ ! -f .env ]; then echo "Error: .env file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh dev && cd infra && \
		terraform workspace select dev || terraform workspace new dev && \
		terraform plan

infra-apply-dev:
	@echo "Loading environment variables and applying development infrastructure..."
	@if [ ! -f .env ]; then echo "Error: .env file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh dev && cd infra && \
		terraform workspace select dev || terraform workspace new dev && \
		terraform apply

infra-destroy-dev:
	@echo "Loading environment variables and destroying development infrastructure..."
	@if [ ! -f .env ]; then echo "Error: .env file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh dev && cd infra && \
		terraform workspace select dev && \
		terraform destroy

# Production environment
infra-plan-prod:
	@echo "Loading environment variables and planning production infrastructure..."
	@if [ ! -f .env.prod ]; then echo "Error: .env.prod file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh prod && cd infra && \
		terraform workspace select prod || terraform workspace new prod && \
		terraform plan

infra-apply-prod:
	@echo "Loading environment variables and applying production infrastructure..."
	@if [ ! -f .env.prod ]; then echo "Error: .env.prod file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh prod && cd infra && \
		terraform workspace select prod || terraform workspace new prod && \
		terraform apply

infra-destroy-prod:
	@echo "Loading environment variables and destroying production infrastructure..."
	@if [ ! -f .env.prod ]; then echo "Error: .env.prod file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh prod && cd infra && \
		terraform workspace select prod && \
		terraform destroy

# Get outputs
infra-output-dev:
	@echo "Getting development infrastructure outputs..."
	@if [ ! -f .env ]; then echo "Error: .env file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh dev && cd infra && \
		terraform workspace select dev && \
		terraform output

infra-output-prod:
	@echo "Getting production infrastructure outputs..."
	@if [ ! -f .env.prod ]; then echo "Error: .env.prod file not found. Please create it from .env.example"; exit 1; fi
	@source scripts/load-env.sh prod && cd infra && \
		terraform workspace select prod && \
		terraform output

# Docker commands
.PHONY: docker-build docker-run docker-push

docker-build:
	docker build -t shisha-log .

docker-run:
	docker run --env-file .env -p 8080:8080 shisha-log

docker-push:
	@echo "Pushing to ECR Public..."
	@if [ -z "$$ECR_ALIAS" ]; then echo "Error: ECR_ALIAS environment variable not set"; exit 1; fi
	@aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
	@docker tag shisha-log:latest public.ecr.aws/$$ECR_ALIAS/shisha-log:latest
	@docker push public.ecr.aws/$$ECR_ALIAS/shisha-log:latest

# Setup commands
.PHONY: setup-ecr setup-env

setup-ecr:
	@echo "Setting up ECR Public repository..."
	@./scripts/setup-ecr-public.sh

setup-env:
	@if [ ! -f .env ]; then cp .env.example .env && echo "Created .env from .env.example. Please edit .env with your values."; else echo ".env already exists"; fi
	@if [ ! -f .env.prod ]; then cp .env.example .env.prod && echo "Created .env.prod from .env.example. Please edit .env.prod with your production values."; else echo ".env.prod already exists"; fi

# Help
help:
	@echo "Available commands:"
	@echo "  Development:"
	@echo "    make build          - Build the Go application"
	@echo "    make run            - Run the application"
	@echo "    make dev            - Run with hot reload"
	@echo "    make test           - Run tests"
	@echo "    make fmt            - Format code"
	@echo "    make lint           - Run linter"
	@echo ""
	@echo "  Infrastructure:"
	@echo "    make setup-env      - Create .env files from example"
	@echo "    make setup-ecr      - Setup ECR Public repository"
	@echo "    make infra-init     - Initialize Terraform"
	@echo "    make infra-plan-dev - Plan development infrastructure"
	@echo "    make infra-apply-dev - Apply development infrastructure"
	@echo "    make infra-plan-prod - Plan production infrastructure"
	@echo "    make infra-apply-prod - Apply production infrastructure"
	@echo "    make infra-output-dev - Show development outputs"
	@echo "    make infra-output-prod - Show production outputs"
	@echo ""
	@echo "  Docker:"
	@echo "    make docker-build   - Build Docker image"
	@echo "    make docker-run     - Run Docker container"
	@echo "    make docker-push    - Push to ECR Public (set ECR_ALIAS)"