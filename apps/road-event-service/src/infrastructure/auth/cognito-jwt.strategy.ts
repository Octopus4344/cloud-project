import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';

export interface CognitoJwtPayload {
  sub: string;
  email?: string;
  'custom:userId'?: string;
  token_use: string;
  iss: string;
}

@Injectable()
export class CognitoJwtStrategy extends PassportStrategy(
  Strategy,
  'cognito-jwt',
) {
  constructor(private readonly config: ConfigService) {
    const userPoolId = config.get<string>('COGNITO_USER_POOL_ID', '');
    const region = config.get<string>('AWS_REGION', 'us-east-1');
    const issuer = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`;

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      issuer,
      algorithms: ['RS256'],
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `${issuer}/.well-known/jwks.json`,
      }),
    });
  }

  validate(payload: CognitoJwtPayload): { userId: string; email: string } {
    // Cognito stores our internal userId in custom attribute set during registration;
    // fall back to `sub` (Cognito UUID) if not present.
    const userId = payload['custom:userId'] ?? payload.sub;
    return { userId, email: payload.email ?? '' };
  }
}
