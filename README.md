# GRPClassify

## Utilização

Para utilizar o projeto, três processos devem ser iniciados em paralelo:

```shell
# Inicializar o classificador de imagens
python -m python`
```

```shell
# Inicializar o streamer de vídeos
cd apps/camera_mock
iex -S mix grpc.server

# Inicializar o streamer de vídeos com frame_drop habilitado
cd app/camera_mock
DROP_FRAMES=true iex -S mix grpc.server
```

```shell
# Inicializar o sistema gerenciador
cd apps/grpclassify
iex -S mix
iex> {:ok, worker_id} = GRPClassify.Worker.start_link()
{:ok, PID(x.y.z)}
```
