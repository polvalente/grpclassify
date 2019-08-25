import python.server as svr
import time

if __name__ == "__main__":
    print("Starting server on port 8000")

    server, servicer = svr.serve()
    try:
        while(True):
            time.sleep(7 * 24 * 3600)
    except KeyboardInterrupt:
        print("Exiting server")
        server.stop(grace=True)
