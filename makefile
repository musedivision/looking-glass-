SHELL:=/bin/bash


.ONESHELL:
.DEFAULT=all
.PHONY: help test

export PUBLIC_PORT := 8889

export VERSION											:= 3
export PROJECT_NAME								  := looking-glass
export FUNCTION_NAME								:= notebooks
export NETWORK_NAME                 := fastai
export DOCKER_REPO									:= musedivision
export WORK_DIR											:=/home/ubuntu/
export uname												:= $(shell uname)
export Proc													:= CPU

include .password
ifeq ($(JUPYTER_PASSWORD_SHA),)
	JUPYTER_PASSWORD_SHA := sha1:d099ba973173:e1a4b6b64952819109324498080df9f8c0715a25
endif

# detect if running on AWS GPU
ifeq "$(uname)" "Linux"
	runtime := --runtime=nvidia
	Proc	:= GPU
endif

help: ## This help.
	@echo "_________________________________________________"
	@echo "XXX-     ${Proc} ${runtime}       ${uname}   -XXX"
	@echo "_________________________________________________"
	@echo "CURRENT VERSION: ${VERSION}"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

############################################################
# RUN
############################################################


up: build run

compile: # compile python dependency list 
	pip-compile requirements.in > requirements.txt

venv:
	source ${PROJECT_NAME}/bin/activate

open: ## open
	open http://localhost:8889

build: ## Build the container
	docker build -t $(PROJECT_NAME)-${FUNCTION_NAME} .

build-nc: ## Build the container without caching
	docker build --no-cache -t $(PROJECT_NAME)-${FUNCTION_NAME} .

restart: ## restart container
	${MAKE} stop start-local

run:
	docker run -d --rm \
					-p 8889:8888 \
					-e LANG=C.UTF-8 \
					-e LC_ALL=C.UTF-8 \
					-e JUPYTER_ENABLE_LAB=yes \
					-v $$HOME/data:${WORK_DIR}/data \
					-v $$HOME/code:${WORK_DIR}/code \
					-v $$HOME/Library/Application\ Support/Anki2/muse/collection.media/:${WORK_DIR}/anki \
					-v $$HOME/data/fastai:/root/.fastai \
					-v $$HOME/data/torch:/root/.torch \
					--ipc=host \
					--shm-size 50G \
					$(runtime)\
					--name="$(PROJECT_NAME)-${FUNCTION_NAME}" \
					${cont} \
					jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.password='${JUPYTER_PASSWORD_SHA}'

start-local: ## run local build
	${MAKE} run cont=$(PROJECT_NAME)-${FUNCTION_NAME} 

start: ## start dockerhub container
	${MAKE} run cont=$(DOCKER_REPO)/$(PROJECT_NAME) 

stop: ## stop
	docker stop $(PROJECT_NAME)-${FUNCTION_NAME} $(DOCKER_REPO)/$(PROJECT_NAME) || true

clean_images: ## clean_images
	docker rmi -f $(PROJECT_NAME)-${FUNCTION_NAME} $(DOCKER_REPO)/$(PROJECT_NAME) || true

bash: ## bash
	docker exec -it $(PROJECT_NAME)-${FUNCTION_NAME} /bin/bash

