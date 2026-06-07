import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: true, credentials: true });
  app.setGlobalPrefix('road-events', { exclude: ['health'] });
  await app.listen(3000);
  Logger.log('Road Event Service is running on port 3000');
}
bootstrap();
