from flask import Flask, request, Response
import os

app = Flask(__name__)

# Replace this with your actual secret key or a list of allowed keys
VALID_STREAM_KEYS = os.environ.get('VALID_STREAM_KEYS', '').split(',')


@app.route('/auth', methods=['POST'])
def authenticate():
    # Get the stream key in the 'name' form parameter
    stream_key = request.form.get('name')

    if stream_key in VALID_STREAM_KEYS:
        # Return HTTP 200 to allow the stream
        return Response("Authorized", status=200)
    else:
        # Return HTTP 403 to reject the stream
        return Response("Unauthorized", status=403)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
