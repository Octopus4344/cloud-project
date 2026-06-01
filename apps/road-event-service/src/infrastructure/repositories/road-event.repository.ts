import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';

export interface RoadEventRecord {
  eventId: string;
  userId: string;
  eventType: RoadEventType;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
}

@Injectable()
export class RoadEventRepository {
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
      'DYNAMODB_ROAD_EVENTS_TABLE',
      'dev-road-events',
    );
  }

  async save(
    partial: Omit<RoadEventRecord, 'eventId' | 'created_at'>,
  ): Promise<RoadEventRecord> {
    const item: RoadEventRecord = {
      ...partial,
      eventId: uuidv4(),
      created_at: new Date().toISOString(),
    };
    await this.docClient.send(
      new PutCommand({ TableName: this.tableName, Item: item }),
    );
    return item;
  }

  async findOne(id: string): Promise<RoadEventRecord | null> {
    const result = await this.docClient.send(
      new GetCommand({ TableName: this.tableName, Key: { eventId: id } }),
    );
    return (result.Item as RoadEventRecord) ?? null;
  }
}
