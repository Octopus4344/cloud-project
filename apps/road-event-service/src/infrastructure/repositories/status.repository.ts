import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  UpdateCommand,
} from '@aws-sdk/lib-dynamodb';

export interface EventStatusRecord {
  eventId: string;
  userReceived: boolean;
  locReceived: boolean;
}

@Injectable()
export class StatusRepository {
  private readonly docClient: DynamoDBDocumentClient;
  private readonly tableName: string;

  constructor(private readonly config: ConfigService) {
    const client = new DynamoDBClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
    this.docClient = DynamoDBDocumentClient.from(client);
    this.tableName = config.get<string>(
      'DYNAMODB_EVENT_STATUS_TABLE',
      'dev-event-status',
    );
  }

  async create(eventId: string): Promise<void> {
    await this.docClient.send(
      new PutCommand({
        TableName: this.tableName,
        Item: { eventId, userReceived: false, locReceived: false },
      }),
    );
  }

  async markUser(eventId: string): Promise<void> {
    await this.docClient.send(
      new UpdateCommand({
        TableName: this.tableName,
        Key: { eventId },
        UpdateExpression: 'SET userReceived = :val',
        ExpressionAttributeValues: { ':val': true },
      }),
    );
  }

  async markLoc(eventId: string): Promise<void> {
    await this.docClient.send(
      new UpdateCommand({
        TableName: this.tableName,
        Key: { eventId },
        UpdateExpression: 'SET locReceived = :val',
        ExpressionAttributeValues: { ':val': true },
      }),
    );
  }

  async isComplete(eventId: string): Promise<boolean> {
    const result = await this.docClient.send(
      new GetCommand({ TableName: this.tableName, Key: { eventId } }),
    );
    const item = result.Item as EventStatusRecord | undefined;
    return (item?.userReceived ?? false) && (item?.locReceived ?? false);
  }
}
