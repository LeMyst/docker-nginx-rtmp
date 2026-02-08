# docker-nginx-rtmp

A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with
default settings for HLS live streaming. Built on Alpine Linux.

* Nginx 1.28.2 (Mainline version compiled from [source](https://github.com/nginx/nginx.git))
* nginx-rtmp-module dev (compiled from [source](https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/))
* ffmpeg 8.0.1 (compiled from [source](https://git.ffmpeg.org/ffmpeg.git))
* Default HLS settings (See: [nginx.conf](nginx.conf))

[![Docker Stars](https://img.shields.io/docker/stars/lemyst/docker-nginx-rtmp.svg)](https://hub.docker.com/r/lemyst/docker-nginx-rtmp/)
[![Docker Pulls](https://img.shields.io/docker/pulls/lemyst/docker-nginx-rtmp.svg)](https://hub.docker.com/r/lemyst/docker-nginx-rtmp/)
[![Docker Automated build](https://img.shields.io/docker/automated/lemyst/docker-nginx-rtmp.svg)](https://hub.docker.com/r/lemyst/docker-nginx-rtmp/builds/)
[![Build Status](https://travis-ci.org/lemyst/docker-nginx-rtmp.svg?branch=master)](https://travis-ci.org/lemyst/docker-nginx-rtmp)

## Usage

### Server

* Pull docker image and run:

```
docker pull ghcr.io/lemyst/docker-nginx-rtmp
docker run -it -p 1935:1935 -p 8080:80 --rm ghcr.io/lemyst/docker-nginx-rtmp
```

or

* Build and run container from source:

```
docker build -t nginx-rtmp .
docker run -it -p 1935:1935 -p 8080:80 --rm nginx-rtmp
```

* Stream live content to:

```
rtmp://localhost:1935/stream/$STREAM_NAME
```

### SSL

To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:

```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is **highly recommended** to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

I recommend using [Certbot](https://certbot.eff.org/docs/install.html) from [Let's Encrypt](https://letsencrypt.org).

### Environment Variables

This Docker image uses `envsubst` for environment variable substitution. You can define additional environment variables in `nginx.conf` as `${var}` and pass them in your `docker-compose` file or `docker` command.

### Custom `nginx.conf`

If you wish to use your own `nginx.conf`, mount it as a volume in your `docker-compose` or `docker` command as `nginx.conf.template`:

```yaml
volumes:
- ./nginx.conf:/etc/nginx/nginx.conf.template
```

## Authentication

The /stat endpoint is protected by basic authentication. The default username and password are `admin` and `admin`.  
You can mount your own `htpasswd` file to `/etc/nginx/htpasswd` to change the credentials.

```yaml
volumes:
- ./htpasswd:/etc/nginx/htpasswd
```

### OBS Configuration

* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Stream Key: `hello`

### Watch Stream

* Load up the example hls.js player in your browser:

```
http://localhost:8080/player.html?url=http://localhost:8080/live/hello.m3u8
```

* Or in Safari, VLC or any HLS player, open:

```
http://localhost:8080/live/$STREAM_NAME.m3u8
```

* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [HLS.js Player](https://hls-js.netlify.app/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`

### FFmpeg Build

```
$ ffmpeg -buildconf
ffmpeg version n8.0.1 Copyright (c) 2000-2025 the FFmpeg developers
  built with gcc 15.2.0 (Alpine 15.2.0)
  configuration: --prefix=/usr/local --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-libfreetype --enable-openssl --disable-debug --disable-doc --disable-ffplay --extra-libs='-lpthread -lm'
  libavutil      60.  8.100 / 60.  8.100
  libavcodec     62. 11.100 / 62. 11.100
  libavformat    62.  3.100 / 62.  3.100
  libavdevice    62.  1.100 / 62.  1.100
  libavfilter    11.  4.100 / 11.  4.100
  libswscale      9.  1.100 /  9.  1.100
  libswresample   6.  1.100 /  6.  1.100

  configuration:
    --prefix=/usr/local
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-libfreetype
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
    --extra-libs='-lpthread -lm'
```

## Resources

* https://alpinelinux.org/
* http://nginx.org
* https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/
* https://www.ffmpeg.org
* https://obsproject.com
