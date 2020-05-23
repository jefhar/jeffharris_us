ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:latest sh -c 'cd /src && bundle config set path 'vendor/bundle' && bundle install && bundle exec jekyll build'

run: build
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" nginx:alpine

test:
	gitlab-runner exec docker test

updategem:
	docker run --rm -v $(ROOT_DIR):/usr/src/app -w /usr/src/app ruby:latest bundle lock --update

update:
	docker run --rm -v "$(ROOT_DIR):/src" ruby:latest sh -c "cd /src/ && bundle config set path 'vendor/bundle' && bundle lock"

newpost:
	echo "---\nlayout: post\ntitle: title\n---" > app/_posts/`date +%Y-%m-%d-`title_`date +%H_%M`.md
