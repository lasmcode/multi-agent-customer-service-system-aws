.PHONY: setup lint format typecheck config seed infra-deploy infra-status test-unit demo chat deploy invoke test-all clean-aws help

setup: ## Install dependencies with uv
	uv sync --all-groups

lint: ## Lint with ruff
	uv run ruff check src tests config.py

format: ## Format with black
	uv run black src tests config.py

typecheck: ## Static type check with mypy
	uv run mypy src config.py

config: ## Print resolved configuration (validates AWS + CloudFormation exports)
	uv run python config.py

infra-deploy: ## Deploy the CloudFormation foundation stack
	aws cloudformation deploy \
		--template-file infrastructure/cloudformation/stack.yaml \
		--stack-name novamart-agentcore \
		--capabilities CAPABILITY_NAMED_IAM \
		--region us-east-1

infra-status: ## Check CloudFormation stack status
	aws cloudformation describe-stacks \
		--stack-name novamart-agentcore \
		--query "Stacks[0].StackStatus" \
		--region us-east-1

seed: ## Seed DynamoDB + S3 with sample data
	uv run python scripts/seed_data.py

test-unit: ## Run task-scoped unit tests (usage: make test-unit TASK=task2)
	uv run python tests/test_agent.py $(TASK)

test-all: ## Run the full graded test suite (target: 120/120)
	uv run python tests/test_agent.py all

demo: ## Run one scripted end-to-end scenario
	uv run python src/demo.py

chat: ## Interactive terminal chat with live agent trace
	uv run python src/agent_orchestrator.py chat

deploy: ## Deploy guardrail + agent graph to AgentCore Runtime
	uv run python src/agent_orchestrator.py deploy

invoke: ## Invoke the deployed runtime (usage: make invoke MSG="...")
	uv run python src/agent_orchestrator.py invoke "$(MSG)"

clean-aws: ## Delete all AWS resources created by this project (dry run first)
	uv run python infrastructure/cleanup.py

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'