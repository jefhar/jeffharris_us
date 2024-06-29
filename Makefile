# https://gist.github.com/rsperl/d2dfe88a520968fbc1f49db0a29345b9
SHELL=/bin/bash
.PHONY: no_targets__ info help deploy doc
	no_targets__:
.DEFAULT_GOAL := help

# to see all colors, run
# bash -c 'for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo =$c; done'
# the first 15 entries are the 8-bit colors

# define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0)
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	WHITE        := $(shell tput -Txterm setaf 7)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

# set target color
TARGET_COLOR := $(BLUE)
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
IMAGE:=ruby:3.2.2-bookworm

watch: ## Watch for updates and automatically rebuild
	docker run --rm  -v "$(ROOT_DIR):/src" $(IMAGE) sh -c 'cd /src && bundle install && bundle exec jekyll build --watch'

build: ## Build for production
	docker run --rm  -v "$(ROOT_DIR):/src" $(IMAGE) sh -c 'cd /src && bundle install && bundle exec jekyll build'

run: ## Run nginx server on localhost:80
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" --name apache nginx:1.23.4-alpine

shell: ## Drop into a shell in the ruby environment
	docker run --rm -it -v "$(ROOT_DIR):/src" $(IMAGE) bash

serve: ## Serve from ruby
	docker run --rm -p 4000:4000 -v "$(ROOT_DIR):/src" ruby:latest sh -c 'cd /src && bundle install && bundle exec jekyll serve --host 0.0.0.0'

test: ## Run tests
	gitlab-runner exec docker test

updategem: ## Update gemfile
	docker run --rm -v $(ROOT_DIR):/usr/src/app -w /usr/src/app $(IMAGE) bundle lock --update

update: ## Update everything
	docker run --rm -v "$(ROOT_DIR):/src" $(IMAGE) sh -c "cd /src/ && bundle config set path 'vendor/bundle' && bundle lock"

newpost: ## Create a new draft post file
	echo "---\nlayout: post\ntitle: title\n---" > app/_drafts/`date +%Y-%m-%d-`title_`date +%H_%M`.md

help: ## See this list.
	@echo "${BLACK}-----------------------------------------------------------------${RESET}"
	@grep -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "${TARGET_COLOR}%-30s${RESET} %s\n", $$1, $$2}'
