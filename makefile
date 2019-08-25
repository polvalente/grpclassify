SRC="./interop"
ELIXIR_DEST="./lib/interop"
PYTHON_DEST="./python/interop"

all: setup proto

setup:
	@mkdir -p $(SRC)
	@mkdir -p $(ELIXIR_DEST)
	@mkdir -p $(PYTHON_DEST)
	@pip install grpcio grpcio-tools
	@mix deps.get
	@mix compile

proto:
	python -m grpc_tools.protoc -I$(SRC) --python_out=$(PYTHON_DEST) --grpc_python_out=$(PYTHON_DEST) $(SRC)/*.proto
	protoc -I$(SRC) --elixir_out=plugins=grpc:$(ELIXIR_DEST) $(SRC)/*.proto

server:
	python -m python
