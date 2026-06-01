import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
  MessageActionType,
} from '@aws-sdk/client-cognito-identity-provider';

@Injectable()
export class CognitoService {
  private readonly client: CognitoIdentityProviderClient;
  private readonly logger = new Logger(CognitoService.name);

  constructor(private readonly config: ConfigService) {
    this.client = new CognitoIdentityProviderClient({
      region: config.get<string>('AWS_REGION', 'us-east-1'),
      ...(config.get<string>('AWS_ENDPOINT_URL') && {
        endpoint: config.get<string>('AWS_ENDPOINT_URL'),
      }),
    });
  }

  async registerUser(const userPool if (!userPoolId)    this.logger.warn(
        'COGNITO_USER_POOL_ID not set – skipping Cognito registration',
      );
      return null;
    }

    this.logger.log(`Registering user ${email} in Cognito`);

    const result = await this.client.send(
      new AdminCreateUserCommand({
        UserPoolId: userPoolId,
        Username: email,
        MessageAction: MessageActionType.SUPPRESS,
        UserAttributes: [
          { Name: 'email', Value: email },
          { Name: 'email_verified', Value: 'true' },
        ],
      }),
    );

    const sub =
      result.User?.Attributes?.find((a) => a.Name === 'sub')?.Value ?? null;

    await this.client.send(
      new AdminSetUserPasswordCommand({
        UserPoolId: userPoolId,
        Username: email,
        Password: password,
        Permanent: true,
      }),
    );

    return sub;
  }
}
