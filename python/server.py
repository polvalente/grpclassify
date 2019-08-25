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
        # session = tf.Session(graph=graph)

        # GPU
        session = tf.Session(graph=graph, config=tf.ConfigProto(log_device_placement=True))
        set_session(session)
        # try:
        if model_type is None:
            model = tf.keras.models.load_model(model_path)
            model._make_predict_function()

        else:
            model = self.load_from_bundle(model_path, model_type)
        self.model = model
        self.session = session

        tf.initializers.global_variables()

    def load_from_bundle(self, model_path, model_type):
        def format_line(line):
            return line.lstrip().rstrip().replace('display_name: ', '').replace('"', '')

        bundle = tf.saved_model.loader.load(
            self.session, ['serve'], model_path)
        tf.graph_util.import_graph_def(bundle.graph_def)
        with open(model_path + b'/labels.pbtxt', 'r') as f:
            label_names = [format_line(line) for line in f.readlines(
            ) if line.lstrip().rstrip().startswith('display_name')]
        labels = tensorflow_datasets.features.ClassLabel(names=label_names)
        return PseudoModel(self.session, labels, model_type)


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
    with open(filename, 'r') as f:
        for line in f.readlines():
            if 'model_path' in line:
                m = re.match(r'^\s*model_path: "([^"]*)"', line)
                return './priv/' + m.group(1)


def make_header(s):
    s = ' ' + s + ' '
    header = '||' + '=' * len(s) + '||\n'
    return header + '||' + s + '||\n' + header


def serve():
    global classifier
    model_path = get_model_path('./config/config.exs')

    classifier = Classifier(model_path, None)
    servicer = ImageClassifierServicer()

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=1))
    classipy_pb2_grpc.add_ImageClassifierServicer_to_server(servicer, server)
    server.add_insecure_port('localhost:8000')
    print(make_header("Starting server"))
    server.start()
    return server, servicer
