ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:latest sh -c 'cd /src && bundle config set path 'vendor/bundle' && bundle install && bundle exec jekyll build'

run: build
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" nginx:alpine

test:
	gitlab-runner exec docker test

update:
	docker run --rm -v "$(ROOT_DIR):/src" ruby:latest sh -c 'cd /src/ && bundle config set path 'vendor/bundle' && bundle update'
