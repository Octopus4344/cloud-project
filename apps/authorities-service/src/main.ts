import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('authorities', { exclude: ['health'] });
  await app.listen(3006);
  Logger.log('Authorities Service is running on port 3006');
}
bootstrap();
