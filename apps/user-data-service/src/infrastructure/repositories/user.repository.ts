import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

export interface UserRecord {
  userId: string;
  name: string;
  lastName: string;
  birthDate?: string;
  phoneNumber: string;
  email: string;
}

@Injectable()
export class UserRepository {
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
    this.tableName = config.get<string>('DYNAMODB_USERS_TABLE', 'dev-users');
  }

  async findById(userId: string): Promise<UserRecord | null> {
    const result = await this.docClient.send(
      new GetCommand({ TableName: this.tableName, Key: { userId } }),
    );
    return (result.Item as UserRecord) ?? null;
  }

  async create(
    data: Omit<UserRecord, 'userId'>,
    userId?: string,
  ): Promise<UserRecord> {
    const item: UserRecord = {
      ...data,
      userId: userId ?? uuidv4(),
    };
    await this.docClient.send(
      new PutCommand({ TableName: this.tableName, Item: item }),
    );
    return item;
  }
}
