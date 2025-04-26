import { Injectable } from '@nestjs/common';

@Injectable()
export class UserLocationServiceService {
  getHello(): string {
    return 'Hello World!';
  }
}
