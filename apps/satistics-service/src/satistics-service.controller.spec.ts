import { Test, TestingModule } from '@nestjs/testing';
import { SatisticsServiceController } from './satistics-service.controller';
import { SatisticsServiceService } from './satistics-service.service';

describe('SatisticsServiceController', () => {
  let satisticsServiceController: SatisticsServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [SatisticsServiceController],
      providers: [SatisticsServiceService],
    }).compile();

    satisticsServiceController = app.get<SatisticsServiceController>(SatisticsServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(satisticsServiceController.getHello()).toBe('Hello World!');
    });
  });
});
