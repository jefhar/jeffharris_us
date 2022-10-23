ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

watch:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:3.1.2-alpine3.16 sh -c 'cd /src && bundle install && bundle exec jekyll build --watch'

build:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:3.1.2-alpine3.16 sh -c 'cd /src && bundle install && bundle exec jekyll build'

run:
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" --name apache nginx:1.23.2-alpine

shell:
	docker run --rm -it -v "$(ROOT_DIR):/src" ruby:3.1.2-alpine3.16 bash

test:
	gitlab-runner exec docker test

updategem:
	docker run --rm -v $(ROOT_DIR):/usr/src/app -w /usr/src/app ruby:3.1.2-alpine3.16 bundle lock --update

update:
	docker run --rm -v "$(ROOT_DIR):/src" ruby:3.1.2-alpine3.16 sh -c "cd /src/ && bundle config set path 'vendor/bundle' && bundle lock"

newpost:
	echo "---\nlayout: post\ntitle: title\n---" > app/_drafts/`date +%Y-%m-%d-`title_`date +%H_%M`.md
