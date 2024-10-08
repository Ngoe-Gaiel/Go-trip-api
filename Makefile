install-tools:
	if [ ! $$(which go) ]; then \
		echo "goLang not found."; \
		echo "Try installing go..."; \
		exit 1; \
	fi
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.55.0
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@v4.15.1
	go install github.com/golang/mock/mockgen@v1.6.0
	go install github.com/axw/gocov/gocov@latest
	go get golang.org/x/tools/cmd/goimports
	go install golang.org/x/vuln/cmd/govulncheck@latest
	# apt install gcc
	go install github.com/AlekSi/gocov-xml@latest
	if [ ! $$( which migrate ) ]; then \
		echo "The 'migrate' command was not found in your path. You most likely need to add \$$HOME/go/bin to your PATH."; \
		exit 1; \
	fi

lint:
	golangci-lint run ./...

tidy:
	go mod tidy

test: tidy
	gocov test ./... | gocov report 

coverage: 
	gocov test ./...  | gocov-xml > coverage.cobertura.xml

build:
	mkdir -p ./bin
	CGO_ENABLED=0 GOOS=linux go build -o bin/api ./cmd/api/api.go

package:
	docker  build -t $(tag) . 

run:database
	go mod tidy
	go run ./cmd/api/api.go 

create-migration: ## usage: make name=new create-migration
	migrate create -ext sql -dir ./db/migrations -seq $(name)
	
stop:
	docker-compose down

database:
	docker-compose up -d
fix:
	golangci-lint run --fix

gen:
	mkdir -p ./temp_home/
	cp -r $$HOME/.ssh ./temp_home/.ssh
	ssh-keygen -p -N '' -f ./temp_home/.ssh/id_rsa 
	cp -r $$HOME/.gitconfig ./temp_home/.gitconfig
	docker build -t cliqkets-mockgen -f Dockerfile.mock .
	docker run  --name generat-mock-container --rm -v $$HOME/.ssh:/root/.ssh -v $$HOME/.gitconfig:/app/config -e GOPRIVATE=github.com/Iknite-Space  -v $$(pwd):/tmp/mock-vol -w /tmp/mock-vol cliqkets-mockgen sh -c 'go mod tidy && go generate ./...' 

scan:
	govulncheck ./...