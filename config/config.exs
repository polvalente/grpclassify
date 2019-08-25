import Config

config :logger, backends: []

config :grpclassify, GRPClassify,
  model_path: "models/catsdogs/cnn_catsdogs_50.h5",
  image_path: "images/catsdogs/50"
