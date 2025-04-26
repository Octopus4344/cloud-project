import { NestFactory } from '@nestjs/core';
import { SatisticsServiceModule } from './satistics-service.module';

async function bootstrap() {
  const app = await NestFactory.create(SatisticsServiceModule);
  await app.listen(process.env.port ?? 3000);
}
bootstrap();
