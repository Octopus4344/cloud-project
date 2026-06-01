import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  SQSClient,
  SendMessageCommand,
  SendMessageCommandInput,
} from '@aws-sdk/client-sqs';

@Injectable()
export class SqsProducerService {
  private readonly client: SQSClient;
  private readonly logger = new Logger(SqsProducerService.name);

  constructor(private readonly config: ConfigService) {
    this.client = new SQSClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async send(queueUrl: string, pattern: string, data: unknown): Promise<void> {
    const input: SendMessageCommandInput = {
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify({ pattern, data }),
    };
    await this.client.send(new SendMessageCommand(input));
    this.logger.log(`Sent [${pattern}] to ${queueUrl}`);
  }
}
