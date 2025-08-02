.PHONY: lua_deps test test-cov test-only test-file test-pattern test-ci help

# Show available make targets
help:
	@echo "Available targets:"
	@echo "  lua_deps          - Install Lua dependencies using luarocks"
	@echo "  test                - Run all tests without coverage"
	@echo "  test-cov           - Run all tests with coverage"
	@echo "  test-only           - Run tests tagged with 'only'"
	@echo "  test-file FILE=...  - Run tests for a specific file"
	@echo "                        Example: make test-file FILE=LibPixelPerfect-1.0_spec/Features/Currency_spec.lua"
	@echo "  test-pattern PATTERN=... - Run tests matching a pattern"
	@echo "                        Example: make test-pattern PATTERN=\"quantity mismatch\""
	@echo "  test-ci             - Run tests for CI (TAP output)"

# Variables
ROCKSBIN := $(HOME)/.luarocks/bin

test:
	@$(ROCKSBIN)/busted LibPixelPerfect-1.0_spec

test-only:
	@$(ROCKSBIN)/busted --tags=only LibPixelPerfect-1.0_spec

# Run tests with coverage
test-cov:
	@rm -rf luacov-html && rm -rf luacov.*out && mkdir -p luacov-html && $(ROCKSBIN)/busted --coverage LibPixelPerfect-1.0_spec && $(ROCKSBIN)/luacov && echo "\nCoverage report generated at luacov-html/index.html"

# Run tests for a specific file
# Usage: make test-file FILE=LibPixelPerfect-1.0_spec/Features/Currency_spec.lua
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=path/to/test_file.lua"; \
		exit 1; \
	fi
	@$(ROCKSBIN)/busted --verbose "$(FILE)"

# Run tests matching a specific pattern
# Usage: make test-pattern PATTERN="quantity mismatch"
test-pattern:
	@if [ -z "$(PATTERN)" ]; then \
		echo "Usage: make test-pattern PATTERN=\"test description\""; \
		exit 1; \
	fi
	@$(ROCKSBIN)/busted --verbose --filter="$(PATTERN)" LibPixelPerfect-1.0_spec

test-ci:
	@rm -rf luacov-html && rm -rf luacov.*out && mkdir -p luacov-html && $(ROCKSBIN)/busted --coverage -o=TAP LibPixelPerfect-1.0_spec && $(ROCKSBIN)/luacov

lua_deps:
	@luarocks install busted --local
	@luarocks install luacov --local
	@luarocks install luacov-html --local
