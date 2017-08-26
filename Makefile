ifeq ($(OS),Windows_NT)
    ARCH = windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
			ARCH = linux
    endif
    ifeq ($(UNAME_S),Darwin)
			ARCH = darwin
    endif
endif
REPO_VERSION := $$(git describe --abbrev=0 --tags)
BUILD_DATE := $$(date +%Y-%m-%d-%H:%M)
GIT_HASH := $$(git rev-parse --short HEAD)
GOBUILD_VERSION_ARGS := -ldflags "-s -X main.Version=$(REPO_VERSION) -X main.GitCommit=$(GIT_HASH) -X main.BuildDate=$(BUILD_DATE)"
BINARY := fseopt
MAIN_PKG := github.com/ralreegorganon/fseopt/cmd/fseopt

REGISTRY := registry.ralreegorganon.com
IMAGE_NAME := $(BINARY)

DB_USER := fseopt
DB_PASSWORD := fseopt
DB_PORT_MIGRATION := 9432

FSEOPT_CONNECTION_STRING_LOCAL := postgres://$(DB_USER):$(DB_PASSWORD)@localhost:5432/$(DB_USER)?sslmode=disable
FSEOPT_CONNECTION_STRING_DOCKER := postgres://$(DB_USER):$(DB_PASSWORD)@db:5432/$(DB_USER)?sslmode=disable
FSEOPT_CONNECTION_STRING_MIGRATION_DOCKER := postgres://$(DB_USER):$(DB_PASSWORD)@localhost:$(DB_PORT_MIGRATION)/$(DB_USER)?sslmode=disable

FSEOPT_MIGRATIONS_PATH := file://migrations

FSEOPT_FSE_USER_KEY := NOPE

dep:
	dep ensure

build:
	go build -i -v -o build/bin/$(ARCH)/$(BINARY) $(GOBUILD_VERSION_ARGS) $(MAIN_PKG)

run: build
	FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_LOCAL)" FSEOPT_MIGRATIONS_PATH="$(FSEOPT_MIGRATIONS_PATH)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" ./build/bin/$(ARCH)/$(BINARY)

install:
	go install $(GOBUILD_VERSION_ARGS) $(MAIN_PKG)

migrate:
	cd migrations/ && FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_LOCAL)" ./run-migrations

docker:
	mkdir -p build/migrations && cp migrations/*.sql build/migrations
	GOOS=linux GOARCH=amd64 go build -o build/bin/linux/$(BINARY) $(GOBUILD_VERSION_ARGS) $(MAIN_PKG)
	docker build --pull -t $(REGISTRY)/$(IMAGE_NAME):latest build

run-docker: docker
	cd build/ && DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_PORT_MIGRATION=$(DB_PORT_MIGRATION) FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_DOCKER)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" docker-compose -p fseopt rm -f fseopt
	DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_PORT_MIGRATION=$(DB_PORT_MIGRATION) FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_DOCKER)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" docker-compose -f build/docker-compose.yml -p fseopt build
	DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_PORT_MIGRATION=$(DB_PORT_MIGRATION) FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_DOCKER)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" docker-compose -f build/docker-compose.yml -p fseopt up -d

stop-docker:
	cd build/ && DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_PORT_MIGRATION=$(DB_PORT_MIGRATION) FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_DOCKER)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" docker-compose -p fseopt stop

migrate-docker:
	cd migrations/ && FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_MIGRATION_DOCKER)" ./run-migrations

docker-logs: 
	cd build/ && DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_PORT_MIGRATION=$(DB_PORT_MIGRATION) FSEOPT_CONNECTION_STRING="$(FSEOPT_CONNECTION_STRING_DOCKER)" FSEOPT_FSE_USER_KEY="$(FSEOPT_FSE_USER_KEY)" docker-compose -p fseopt logs

clean:
	rm -rf build/bin/*

release: docker
	docker push $(REGISTRY)/$(IMAGE_NAME):latest
	docker tag $(REGISTRY)/$(IMAGE_NAME):latest $(REGISTRY)/$(IMAGE_NAME):$(REPO_VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(REPO_VERSION)

.PHONY: build install
