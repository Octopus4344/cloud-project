import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
  Message,
} from '@aws-sdk/client-sqs';
import { RoadEventCompletedHandler } from '../event-handlers/road-event-completed.handler';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';

@Injectable()
export class SqsConsumerService implements OnModuleInit, OnModuleDestroy {
  private readonly client: SQSClient;
  private readonly logger = new Logger(SqsConsumerService.name);
  private running = false;

  constructor(
    private readonly config: ConfigService,
    private readonly roadEventCompletedHandler: RoadEventCompletedHandler,
  ) {
    this.client = new SQSClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  onModuleInit(): void {
    this.running = true;
    this.poll().catch((err) =>
      this.logger.error('Polling loop terminated unexpectedly', err),
    );
  }

  onModuleDestroy(): void {
    this.running = false;
  }

  private async poll(): Promise<void> {
    const queueUrl = this.config.get<string>('SQS_STATISTICS_QUEUE_URL')!;
    this.logger.log(`Starting SQS consumer for ${queueUrl}`);

    while (this.running) {
      try {
        const { Messages = [] } = await this.client.send(
          new ReceiveMessageCommand({
            QueueUrl: queueUrl,
            MaxNumberOfMessages: 10,
            WaitTimeSeconds: 20,
          }),
        );

        for (const msg of Messages) {
          await this.processMessage(msg, queueUrl);
        }
      } catch (err) {
        this.logger.error('SQS receive error', err);
        await sleep(3000);
      }
    }
  }

  private async processMessage(msg: Message, queueUrl: string): Promise<void> {
    try {
      const { pattern, data } = parseBody(msg.Body!);
      await this.dispatch(pattern, data);
      await this.client.send(
        new DeleteMessageCommand({
          QueueUrl: queueUrl,
          ReceiptHandle: msg.ReceiptHandle!,
        }),
      );
    } catch (err) {
      this.logger.error(`Failed to process message ${msg.MessageId}`, err);
    }
  }

  private async dispatch(pattern: string, data: unknown): Promise<void> {
    switch (pattern) {
      case 'road.event.completed':
        await this.roadEventCompletedHandler.handle(
          data as RoadEventCompletedEvent,
        );
        break;
      default:
        this.logger.warn(`Unknown pattern: ${pattern}`);
    }
  }
}

function parseBody(body: string): { pattern: string; data: unknown } {
  const outer = JSON.parse(body) as Record<string, unknown>;
  if (outer['Type'] === 'Notification') {
    return JSON.parse(outer['Message'] as string) as {
      pattern: string;
      data: unknown;
    };
  }
  return outer as { pattern: string; data: unknown };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
