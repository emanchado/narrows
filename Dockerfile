FROM node:12.19

RUN mkdir -p /opt/narrows
ADD . /opt/narrows
WORKDIR /opt/narrows
RUN npm install && \
wget -O elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
gunzip elm.gz && \
chmod +x elm && \
mv elm /usr/local/bin/ && \
npm install -g pm2 && \
npm run build
RUN cp config/docker.js config/local-production.js
ENV NODE_ENV=production
EXPOSE 3333
CMD npm run dbmigrate && pm2-docker start build/index.js
