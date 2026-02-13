ARG NGINX_VERSION=1.28.2
ARG NGINX_RTMP_VERSION=59aa590969536c5cce235f665fcca4b35f3f5676
ARG FFMPEG_VERSION=8.0.1
ARG ALPINE_VERSION=3.23
ARG USERNAME=nginx
ARG USER_UID=1000
ARG USER_GID=$USER_UID

##############################
# Build the base build image.
FROM alpine:${ALPINE_VERSION} AS build-base

RUN apk upgrade --no-cache --latest && apk add --no-cache \
  build-base \
  ca-certificates \
  git \
  openssl-dev

##############################
# Build the NGINX-build image.
FROM build-base AS build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --no-cache \
  linux-headers \
  pcre-dev \
  zlib-dev

WORKDIR /tmp

# Get nginx source.
RUN git clone -c advice.detachedHead=false --branch release-${NGINX_VERSION} --depth 1 https://github.com/nginx/nginx.git /tmp/nginx

# Get nginx-rtmp module.
RUN wget https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/${NGINX_RTMP_VERSION}.zip && \
  unzip ${NGINX_RTMP_VERSION}.zip && \
  rm ${NGINX_RTMP_VERSION}.zip

# Compile nginx with nginx-rtmp module.
WORKDIR /tmp/nginx

RUN \
  ./auto/configure \
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
## Build the FFmpeg-build image.
FROM build-base AS build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local

# FFmpeg build dependencies.
RUN apk add --no-cache \
  fdk-aac-dev \
  git \
  lame-dev \
  libass-dev \
  libtheora-dev \
  libvorbis-dev \
  libvpx-dev \
  libwebp-dev \
  nasm \
  opus-dev \
  x264-dev \
  x265-dev

# Get FFmpeg source.
RUN git clone -c advice.detachedHead=false --branch n${FFMPEG_VERSION} --depth 1 https://git.ffmpeg.org/ffmpeg.git /tmp/ffmpeg

# Compile ffmpeg.
WORKDIR /tmp/ffmpeg

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

##########################
# Build the release image.
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Alfred Gutierrez <alf.g.jr@gmail.com>"
ARG USERNAME
ARG USER_UID
ARG USER_GID

# Set default ports.
ENV HTTP_PORT=80
ENV HTTPS_PORT=443
ENV RTMP_PORT=1935

RUN addgroup -g ${USER_GID} -S ${USERNAME} && \
  adduser -u ${USER_UID} -D -S -G ${USERNAME} ${USERNAME}

RUN apk upgrade --no-cache --latest && apk add --no-cache \
  ca-certificates \
  fdk-aac \
  freetype \
  gettext \
  lame-libs \
  libass \
  libtheora \
  libvorbis \
  libvpx \
  libwebp \
  libwebpmux \
  libxcb \
  openssl \
  opus \
  pcre \
  rtmpdump \
  x264-libs \
  x265-libs

RUN mkdir -p /opt/data && \
    mkdir -p /srv/www && \
    chown -R ${USERNAME}:${USERNAME} /opt/data && \
	chown -R ${USERNAME}:${USERNAME} /srv/www

USER ${USERNAME}

COPY --chown=${USERNAME}:${USERNAME} --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --chown=${USERNAME}:${USERNAME} --from=build-nginx /etc/nginx /etc/nginx
COPY --chown=${USERNAME}:${USERNAME} --from=build-ffmpeg /usr/local /usr/local

# Add NGINX path, config and static files.
ENV PATH="${PATH}:/usr/local/nginx/sbin"
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY htpasswd /etc/nginx/htpasswd
COPY tech_diff_fred_seibert_cc-by-nc-nd-2.jpg /etc/nginx/tech_diff_fred_seibert_cc-by-nc-nd-2.jpg
COPY static /srv/www/static
COPY --chmod=755 entrypoint.sh /entrypoint.sh

EXPOSE 1935
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
