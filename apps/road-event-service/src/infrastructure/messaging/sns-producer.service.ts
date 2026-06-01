import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

@Injectable()
export class SnsProducerService {
  private readonly client: SNSClient;
  private readonly logger = new Logger(SnsProducerService.name);

  constructor(private readonly config: ConfigService) {
    this.client = new SNSClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async publish(
    topicArn: string,
    pattern: string,
    data: unknown,
  ): Promise<void> {
    await this.client.send(
      new PublishCommand({
        TopicArn: topicArn,
        Message: JSON.stringify({ pattern, data }),
        MessageAttributes: {
          pattern: {
            DataType: 'String',
            StringValue: pattern,
          },
        },
      }),
    );
    this.logger.log(`Published [${pattern}] to SNS topic ${topicArn}`);
  }
}
