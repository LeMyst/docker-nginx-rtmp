from flask import Flask, request, Response
import os
import logging

app = Flask(__name__)

# Configure logging to ensure debug messages are visible
logging.basicConfig(level=os.environ.get('LOGLEVEL', 'INFO').upper())

# Replace this with your actual secret key or a list of allowed keys
VALID_STREAM_KEYS = os.environ.get('VALID_STREAM_KEYS', '').split(',')


@app.route('/auth', methods=['POST'])
def authenticate():
    # Get the stream key in the 'name' form parameter
    stream_key = request.form.get('name')

    # Log the received key
    app.logger.debug(f"Received auth request for stream key: {stream_key}")

    if stream_key in VALID_STREAM_KEYS:
        # Return HTTP 200 to allow the stream
        app.logger.debug(f"Stream key '{stream_key}' authorized.")
        return Response("Authorized", status=200)
    else:
        # Return HTTP 403 to reject the stream
        app.logger.warning(f"Stream key '{stream_key}' rejected.")
        return Response("Unauthorized", status=403)


if __name__ == '__main__':
    app.run()
