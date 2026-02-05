ARG NGINX_VERSION=1.28.2
ARG NGINX_RTMP_VERSION=1.2.2
ARG FFMPEG_VERSION=8.0.1
ARG ALPINE_VERSION=3.23

##############################
# Build the base build image.
FROM alpine:${ALPINE_VERSION} AS build-base

RUN apk upgrade --no-cache --latest && apk add --no-cache \
  build-base \
  ca-certificates \
  curl \
  libass \
  openssl \
  openssl-dev \
  pcre \
  pkgconf \
  pkgconfig \
  x264-dev \
  x265-dev

##############################
# Build the NGINX-build image.
FROM build-base AS build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --no-cache \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  pcre-dev \
  zlib-dev

WORKDIR /tmp

# Get nginx source.
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && \
  rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
WORKDIR /tmp/nginx-${NGINX_VERSION}
RUN \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-http_stub_status_module \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  make -j$(nproc) && \
  make install

###############################
# Build the FFmpeg-build image.
FROM build-base AS build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local

# FFmpeg build dependencies.
RUN apk add --no-cache \
  coreutils \
  fdk-aac-dev \
  freetype-dev \
  lame-dev \
  libogg-dev \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  opus-dev \
  rtmpdump-dev \
  wget \
  x264-dev \
  x265-dev \
  nasm

WORKDIR /tmp

# Get FFmpeg source.
RUN wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
WORKDIR /tmp/ffmpeg-${FFMPEG_VERSION}
RUN \
  ./configure \
  --prefix=${PREFIX} \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make -j$(nproc) && \
  make install && \
  make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM build-base
LABEL MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>

# Set default ports.
ENV HTTP_PORT 80
ENV HTTPS_PORT 443
ENV RTMP_PORT 1935

RUN apk add --no-cache \
  fdk-aac \
  freetype \
  gettext \
  lame-libs \
  libogg \
  libtheora \
  libvorbis \
  libvpx \
  libwebp \
  libwebpmux \
  libxcb \
  opus \
  pcre \
  rtmpdump \
  x264 \
  x265

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-ffmpeg /usr/local /usr/local

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
COPY nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data && mkdir /www
COPY static /www/static

EXPOSE 1935
EXPOSE 80

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx
