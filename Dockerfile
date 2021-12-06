FROM nginx:alpine
ENV HOME=/var/lib/git
RUN set -x && \
  apk --update upgrade                                  &&  \
  apk add git git-daemon bash fcgiwrap spawn-fcgi wget             &&  \
  mkdir /var/lib/git                                    && \
  touch /var/lib/git/index.html                          && \
  chown nginx.nginx /var/lib/git                       &&  \ 
  mkdir -p /root/.config/git/                             && \
  chown nginx.nginx /root/.config/git/                 && \

  git config --system http.receivepack true             &&  \
  git config --system http.uploadpack true              &&  \
  git config --system user.email "gitserver@git.com"    &&  \
  git config --system user.name "Git Server"            &&  \

  ln -sf /dev/stdout /var/log/nginx/access.log          &&  \
  ln -sf /dev/stderr /var/log/nginx/error.log


COPY ./git-http.conf /etc/nginx/conf.d/
COPY configure_git.sh  /docker-entrypoint.d/99-configure_git.sh
