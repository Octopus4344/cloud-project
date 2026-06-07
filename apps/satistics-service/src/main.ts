import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: true, credentials: true });
  app.setGlobalPrefix('statistics', { exclude: ['health'] });
  await app.listen(3005);
  Logger.log('Statistics Service is running on port 3005');
}
bootstrap();
