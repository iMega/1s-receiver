TAG = latest
IMG = imega/1s-receiver

build:
	@docker build -t $(IMG):$(TAG) .

test:
	@mkdir -p $(CURDIR)/log
	@docker run --rm -v $(CURDIR):/data -w /data \
		-e TEST_NGINX_ERROR_LOG=/data/log/error_log.log \
		imega/openresty-prove:0.0.3 -r -v t/

clean:
	@rm -rf $(CURDIR)/log

release: build
	@docker login --username $(DOCKER_USER) --password $(DOCKER_PASS)
	@docker push $(IMG):$(TAG)
