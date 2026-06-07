import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
  InitiateAuthCommand,
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

  async registerUser(email: string, password: string): Promise<string | null> {
    const userPoolId = this.config.get<string>('COGNITO_USER_POOL_ID');
    if (!userPoolId) {
      this.logger.warn(
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

  async login(
    email: string,
    password: string,
  ): Promise<{ accessToken: string; idToken: string; refreshToken?: string }> {
    const clientId = this.config.get<string>('COGNITO_APP_CLIENT_ID');
    if (!clientId) {
      throw new Error('COGNITO_APP_CLIENT_ID is not configured');
    }

    const result = await this.client.send(
      new InitiateAuthCommand({
        AuthFlow: 'USER_PASSWORD_AUTH',
        ClientId: clientId,
        AuthParameters: {
          USERNAME: email,
          PASSWORD: password,
        },
      }),
    );

    const auth = result.AuthenticationResult;
    if (!auth?.AccessToken || !auth?.IdToken) {
      throw new Error('Authentication failed: Cognito did not return tokens');
    }

    return {
      accessToken: auth.AccessToken,
      idToken: auth.IdToken,
      refreshToken: auth.RefreshToken,
    };
  }
}
