import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, ListObjectsV2Command } from '@aws-sdk/client-s3';

@Injectable()
export class ArchiveService {
  private readonly client: S3Client;

  constructor(private readonly config: ConfigService) {
    this.client = new S3Client({
      region: this.config.get<string>('AWS_REGION', 'eu-north-1'),
      ...(this.config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: this.config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async listRecent(
    limit = 20,
  ): Promise<Array<{ key: string; lastModified: string; size: number }>> {
    const bucket = this.config.get<string>('S3_ARCHIVE_BUCKET');
    if (!bucket) {
      return [];
    }

    const response = await this.client.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: 'events/',
        MaxKeys: Math.min(Math.max(limit, 1), 100),
      }),
    );

    const items = (response.Contents ?? [])
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

    return items;
  }
}
