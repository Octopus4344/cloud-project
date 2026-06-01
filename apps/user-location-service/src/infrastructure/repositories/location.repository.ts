import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from '@aws-sdk/lib-dynamodb';

export interface LocationRecord {
  eventId: string;
  userId: string;
  latitude: number;
  longitude: number;
  created_at: string;
}

@Injectable()
export class LocationRepository {
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
      'DYNAMODB_LOCATIONS_TABLE',
      'dev-locations',
    );
  }

  async findByEventId(eventId: string): Promise<LocationRecord | null> {
    const result = await this.docClient.send(
      new GetCommand({ TableName: this.tableName, Key: { eventId } }),
    );
    return (result.Item as LocationRecord) ?? null;
  }

  async save(partial: {
    eventId: string;
    userId: string;
    latitude: number;
    longitude: number;
  }): Promise<LocationRecord> {
    const item: LocationRecord = {
      ...partial,
      created_at: new Date().toISOString(),
    };
    await this.docClient.send(
      new PutCommand({ TableName: this.tableName, Item: item }),
    );
    return item;
  }
}
