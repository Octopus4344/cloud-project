import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  ListObjectsV2Command,
} from '@aws-sdk/client-s3';
import { StatisticsRepository } from '../repositories/statistics.repository';

@Injectable()
export class ReportService {
  private readonly client: S3Client;

  constructor(
    private readonly config: ConfigService,
    private readonly statisticsRepository: StatisticsRepository,
  ) {
    this.client = new S3Client({
      region: this.config.get<string>('AWS_REGION', 'eu-north-1'),
      ...(this.config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: this.config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async generateReport(): Promise<{
    reportKey: string;
    generatedAt: string;
    totalEvents: number;
    byType: Array<{ type: string; count: number }>;
  }> {
    const bucket = this.config.get<string>('S3_ARCHIVE_BUCKET');
    if (!bucket) {
      throw new Error('S3_ARCHIVE_BUCKET is not configured');
    }

    const raw = await this.statisticsRepository.countByType();
    const byType = raw.map((r) => ({ type: r.type, count: parseInt(r.count, 10) }));
    const totalEvents = byType.reduce((acc, item) => acc + item.count, 0);
    const generatedAt = new Date().toISOString();
    const reportKey = `reports/statistics-report-${Date.now()}.json`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: reportKey,
        Body: JSON.stringify(
          {
            generatedAt,
            totalEvents,
            byType,
          },
          null,
          2,
        ),
        ContentType: 'application/json',
        ServerSideEncryption: 'AES256',
      }),
    );

    return { reportKey, generatedAt, totalEvents, byType };
  }

  async listReports(limit = 20): Promise<Array<{ key: string; lastModified: string; size: number }>> {
    const bucket = this.config.get<string>('S3_ARCHIVE_BUCKET');
    if (!bucket) {
      return [];
    }

    const response = await this.client.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: 'reports/',
        MaxKeys: Math.min(Math.max(limit, 1), 100),
      }),
    );

    return (response.Contents ?? [])
      .filter((obj) => !!obj.Key)
      .sort(
        (a, b) =>
          (b.LastModified?.getTime() ?? 0) - (a.LastModified?.getTime() ?? 0),
      )
      .slice(0, limit)
      .map((obj) => ({
        key: obj.Key ?? '',
        lastModified: obj.LastModified?.toISOString() ?? '',
        size: obj.Size ?? 0,
      }));
  }
}
