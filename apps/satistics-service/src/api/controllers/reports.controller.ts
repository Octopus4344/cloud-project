import { Controller, Get, Post, Query } from '@nestjs/common';
import { ReportService } from '../../infrastructure/services/report.service';
import { ReportResponseDto } from '../dto/report-response.dto';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportService: ReportService) {}

  @Post()
  async createReport(): Promise<ReportResponseDto> {
    return this.reportService.generateReport();
  }

  @Get()
  async listReports(
    @Query('limit') limit?: string,
  ): Promise<Array<{ key: string; lastModified: string; size: number }>> {
    const parsedLimit = limit ? Number(limit) : 20;
    return this.reportService.listReports(
      Number.isNaN(parsedLimit) ? 20 : parsedLimit,
    );
  }
}
