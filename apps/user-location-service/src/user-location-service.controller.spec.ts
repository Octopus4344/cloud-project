import { Test, TestingModule } from '@nestjs/testing';
import { UserLocationServiceController } from './user-location-service.controller';
import { UserLocationServiceService } from './user-location-service.service';

describe('UserLocationServiceController', () => {
  let userLocationServiceController: UserLocationServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [UserLocationServiceController],
      providers: [UserLocationServiceService],
    }).compile();

    userLocationServiceController = app.get<UserLocationServiceController>(UserLocationServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(userLocationServiceController.getHello()).toBe('Hello World!');
    });
  });
});
