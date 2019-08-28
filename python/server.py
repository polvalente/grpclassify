from python.interop import (
    classipy_pb2_grpc,
    classipy_pb2
)

import grpc
import re
from concurrent import futures

import matplotlib.image as mpimg
import numpy as np
import tensorflow as tf
import json
import io

import tensorflow_datasets
from PIL import Image
from tensorflow.python.keras.backend import set_session


image_data = []
classifier = None
model = None
session = None
graph = None


class Classifier:
    def __init__(self, model_path, model_type):
        global session
        global model
        global graph

        graph = tf.get_default_graph()

        # CPU
        session = tf.Session(
            graph=graph, config=tf.ConfigProto(device_count={'GPU': 0}))

        # GPU
        # session = tf.Session(graph=graph, config=tf.ConfigProto(log_device_placement=True))
        set_session(session)
        # try:
        if model_type is None:
            model = tf.keras.models.load_model(model_path)
            model._make_predict_function()

        else:
            model = self.load_from_bundle(model_path, model_type, session)

        self.model = model
        self.session = session

        tf.initializers.global_variables()

    def load_from_bundle(self, model_path, model_type, session):
        def format_line(line):
            return line.lstrip().rstrip().replace('display_name: ', '').replace('"', '')

        bundle = tf.saved_model.loader.load(
            session, ['serve'], model_path)
        tf.graph_util.import_graph_def(bundle.graph_def)
        with open(model_path + '/labels.pbtxt', 'r') as f:
            label_names = [format_line(line) for line in f.readlines(
            ) if line.lstrip().rstrip().startswith('display_name')]
        labels = tensorflow_datasets.features.ClassLabel(names=label_names)
        return PseudoModel(session, labels, model_type)


class PseudoModel():
    def __init__(self, session, labels, model_type):
        self.session = session
        self.model_type = model_type
        self.labels = labels
        print(labels)

    def predict(self, data):
        def get_tensor(name):
            return self.session.graph.get_tensor_by_name(name)

        if self.model_type == b"ssd_mobilenet":
            image_tensor = get_tensor("image_tensor:0")

            fetches = [get_tensor(x) for x in ["detection_boxes:0", "detection_classes:0",
                                               "detection_scores:0", "num_detections:0"]]

            results = self.session.run(fetches, feed_dict={image_tensor: data})
            results = [x.tolist() for x in results]
            results[1] = [self.labels.int2str(int(x)) for x in results[1][0]]
            return results


def np_array_from_image_byte_array(image_byte_array, gray=False):
    # reads grayscale PIL.Images from bytestream list
    imgs = [Image.open(io.BytesIO(x)) for x in image_byte_array]
    if gray:
        imgs = np.array([np.array(img.convert('L')) / 255.0 for img in imgs])
        imgs = imgs.reshape(tuple(list(imgs.shape) + [1]))
    else:
        imgs = np.array([np.array(img) for img in imgs])
    return np.array(imgs)


def classify(image_byte_array=[], gray=False):
    global model
    global graph

    with graph.as_default():
        set_session(session)
        data = np_array_from_image_byte_array(image_byte_array, gray)
        preds = model.predict(data)
        try:
            return preds.tolist()
        except:
            return preds


class ImageClassifierServicer(classipy_pb2_grpc.ImageClassifierServicer):
    def Classify(self, request, context):
        global classifier
        sender_pid = request.sender_pid
        # print([i.filename for i in request.images])

        def format_result(result):
            as_idx = [x.index(max(x)) for x in result]
            classes = ['cat', 'dog']
            as_class = [classipy_pb2.ClassificationResult(
                category=classes[idx]) for idx in as_idx]
            return as_class

        classification_result = format_result(classify(
            [i.content for i in request.images], True))

        # print(classification_result)

        result = classipy_pb2.ImageResult(
            sender_pid=sender_pid,
            total_execution_time=0,
            classifications=classification_result
        )

        return result


def get_model_path(filename):
    path = None
    with open(filename, 'r') as f:
        for line in f.readlines():
            if 'model_path' in line:
                try:
                    m = re.match(r'^\s*model_path: "([^"]*)",', line)
                    if m and m.group(1):
                        path = './apps/grpclassify/priv/' + m.group(1)
                        print("model_path: ", path)
                        break
                except Exception as e:
                    print(e)
                    pass
    if path is None:
        exit(1)

    return path


def print_header(s):
    s = ' ' + s + ' '
    header = '||' + '=' * len(s) + '||\n'
    print(header + '||' + s + '||\n' + header)


def serve():
    server_address = 'localhost:8001'

    global classifier
    print_header("Getting model path")
    model_path = get_model_path('./config/config.exs')

    print_header("Building classifier")
    classifier = Classifier(model_path, "ssd")

    print_header("Building server")
    servicer = ImageClassifierServicer()

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=1))
    classipy_pb2_grpc.add_ImageClassifierServicer_to_server(servicer, server)
    server.add_insecure_port(server_address)
    print_header("Starting server")
    print("Serving at address: " + server_address)
    server.start()
    return server, servicer
