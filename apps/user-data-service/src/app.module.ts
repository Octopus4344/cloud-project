import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ApiModule } from './api/api.module';
import * as process from 'node:process';
import { InfrastructureModule } from './infrastructure/infrastructure.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'postgres',
        url: process.env.DATABASE_URL,
        synchronize: true,
        autoLoadEntities: true,
      }),
    }),
    InfrastructureModule,
    ApiModule,
  ],
})
export class AppModule {}
