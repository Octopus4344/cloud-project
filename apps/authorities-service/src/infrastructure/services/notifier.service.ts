import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

@Injectable()
export class NotifierService {
  private readonly client: SNSClient;
  private readonly logger = new Logger(NotifierService.name);

  constructor(private readonly config: ConfigService) {
    this.client = new SNSClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async notify(type: string, lat: number, lon: number): Promise<number> {
    const topicArn = this.config.get<string>('SNS_ROAD_EVENTS_COMPLETED_ARN');
    const refNo = Math.floor(Math.random() * 1_000_000);

    this.logger.log(
      `Notifying authorities: ${type} @ (${lat}, ${lon}), ref=${refNo}`,
    );

    if (topicArn) {
      await this.client.send(
        new PublishCommand({
          TopicArn: topicArn,
          Subject: `High-priority road event: ${type}`,
          Message: JSON.stringify({
            type,
            latitude: lat,
            longitude: lon,
            referenceNumber: refNo,
            timestamp: new Date().toISOString(),
          }),
          MessageAttributes: {
            eventType: { DataType: 'String', StringValue: type },
            priority: { DataType: 'String', StringValue: 'HIGH' },
          },
        }),
      );
    }

    return refNo;
  }
}
