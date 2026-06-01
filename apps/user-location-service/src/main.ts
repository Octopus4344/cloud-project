import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('user-location', { exclude: ['health'] });
  await app.listen(3004);
  Logger.log('User Location Service is running on port 3004');
}
bootstrap();
