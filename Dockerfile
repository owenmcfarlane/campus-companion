FROM node:24-bookworm-slim
WORKDIR /app
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src
COPY --chown=node:node web ./web
COPY --chown=node:node scripts ./scripts
COPY --chown=node:node examples ./examples
RUN mkdir /data && chown node:node /data
USER node
ENV CAMPUS_DATA_DIR=/data
EXPOSE 4173
CMD ["node", "src/server.mjs"]
