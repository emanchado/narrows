FROM node:6.11

RUN mkdir -p /opt/narrows
ADD . /opt/narrows
WORKDIR /opt/narrows
RUN npm install && \
npm install -g elm@0.18 && \
npm install -g pm2 && \
elm-package install --yes && \
npm run build
RUN cp config/docker.js config/local-production.js
ENV NODE_ENV=production
EXPOSE 3333
CMD npm run dbmigrate && pm2-docker start build/index.js
