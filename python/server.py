from python.interop import (
    classipy_pb2_grpc,
    classipy_pb2
)

import grpc
from concurrent import futures


class ImageClassifierServicer(classipy_pb2_grpc.ImageClassifierServicer):
    def Classify(self, request, context):
        sender_pid = request.sender_pid
        classification_result = classipy_pb2.ClassificationResult(
            category='pong')
        result = classipy_pb2.ImageResult(
            sender_pid=sender_pid,
            total_execution_time=0,
            classifications=classification_result
        )

        return result


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=1))
    classipy_pb2_grpc.add_ImageClassifierServicer_to_server(
        ImageClassifierServicer(), server)
    server.add_insecure_port('localhost:8000')
    server.start()
    return server
