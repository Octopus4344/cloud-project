import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('user-location'); // Dodanie globalnego prefiksu

  const rabbitMQUrl = process.env.RABBITMQ_URL;
  if (!rabbitMQUrl) {
    throw new Error('RABBITMQ_URL is not defined');
  }
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.RMQ,
    options: {
      urls: [rabbitMQUrl],
      queue: 'user-loc-queue',
      queueOptions: {
        durable: true,
      },
    },
  });
  await app.startAllMicroservices();
  await app.listen(3004);
  Logger.log('User Location Service is running on port 3004');
  // console.log('Road Event Service is running on port 4000');
  // console.log(
  //   `Application road event service is running on: ${await app.getUrl()}`,
  // );
}
bootstrap();
