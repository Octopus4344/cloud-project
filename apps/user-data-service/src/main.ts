import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('user-data', { exclude: ['health'] });
  await app.listen(3001);
  Logger.log('User Data Service is running on port 3001');
}
bootstrap();
