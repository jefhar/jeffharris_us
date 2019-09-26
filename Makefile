ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:2.6.4 sh -c 'cd /src && bundle install --path vendor/bundle  && bundle exec jekyll build'

run: build
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" nginx:latest

test:
	gitlab-runner exec docker test
