import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { Logger } from '@nestjs/common';
import crypto from 'node:crypto';
// Assign crypto to globalThis for TypeOrm utils
// @ts-ignore
globalThis.crypto = crypto;

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const rabbitMQUrl = process.env.RABBITMQ_URL;
  if (!rabbitMQUrl) {
    throw new Error('RABBITMQ_URL is not defined');
  }
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.RMQ,
    options: {
      urls: [rabbitMQUrl],
      queue: 'authorities-queue',
      queueOptions: {
        durable: true,
      },
    },
  });
  await app.startAllMicroservices();
  await app.listen(3006);
  Logger.log('Authorities Service is running on port 3006');
  // console.log('Road Event Service is running on port 4000');
  // console.log(
  //   `Application road event service is running on: ${await app.getUrl()}`,
  // );
}
bootstrap();
