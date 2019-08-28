SRC=./interop
ELIXIR_DEST=./apps/grpclassify/lib/interop
PYTHON_DEST=./python/interop
ELIXIR_VIDEO_SERVER_DEST=./apps/camera_mock/lib/interop

all: setup proto

setup:
	@mkdir -p $(SRC)
	@mkdir -p $(ELIXIR_DEST)
	@mkdir -p $(PYTHON_DEST)
	@mkdir -p $(ELIXIR_VIDEO_SERVER_DEST)
	@pip install grpcio grpcio-tools
	@mix deps.get
	@mix compile

proto:
	python -m grpc_tools.protoc -I$(SRC) --python_out=$(PYTHON_DEST) --grpc_python_out=$(PYTHON_DEST) $(SRC)/classipy.proto
	protoc -I$(SRC) --elixir_out=plugins=grpc:$(ELIXIR_DEST) $(SRC)/classipy.proto

	protoc -I$(SRC) --elixir_out=plugins=grpc:$(ELIXIR_DEST) $(SRC)/video_server.proto
	protoc -I$(SRC) --elixir_out=plugins=grpc:$(ELIXIR_VIDEO_SERVER_DEST) $(SRC)/video_server.proto

server:
	python -m python