import { NestFactory } from '@nestjs/core';
import { UserLocationServiceModule } from './user-location-service.module';

async function bootstrap() {
  const app = await NestFactory.create(UserLocationServiceModule);
  await app.listen(process.env.port ?? 3000);
}
bootstrap();
