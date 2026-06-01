import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  ScanCommand,
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

export interface IncidentRecord {
  incidentId: string;
  userId: string;
  eventId: string;
  authoritiesType: string;
  reportNumber: number;
  created_at: string;
}

@Injectable()
export class IncidentRepository {
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
      'DYNAMODB_INCIDENTS_TABLE',
      'dev-incidents',
    );
  }

  async save(
    partial: Omit<IncidentRecord, 'incidentId' | 'created_at'>,
  ): Promise<IncidentRecord> {
    const item: IncidentRecord = {
      ...partial,
      incidentId: uuidv4(),
      created_at: new Date().toISOString(),
    };
    await this.docClient.send(
      new PutCommand({ TableName: this.tableName, Item: item }),
    );
    return item;
  }

  async countByType(): Promise<{ type: string; count: string }[]> {
    const result = await this.docClient.send(
      new ScanCommand({ TableName: this.tableName }),
    );
    const counts = new Map<string, number>();
    for (const item of result.Items ?? []) {
      const type = (item as IncidentRecord).authoritiesType;
      counts.set(type, (counts.get(type) ?? 0) + 1);
    }
    return Array.from(counts.entries()).map(([type, count]) => ({
      type,
      count: String(count),
    }));
  }
}
