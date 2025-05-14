FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build authorities-service

EXPOSE 3006

ENV NODE_ENV=production
ENV DATABASE_URL=postgresql://postgres.sfbspjuexczprymnpoer:postgres@aws-0-eu-central-2.pooler.supabase.com:5432/postgres
ENV RABBITMQ_URL=amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih

CMD ["node", "dist/apps/authorities-service/main"]