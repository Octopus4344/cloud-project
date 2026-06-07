import { Controller, Get, Query } from '@nestjs/common';
import { ArchiveService } from '../../infrastructure/services/archive.service';
import { ArchiveResponseDto } from '../dto/archive-response.dto';

@Controller('archive')
export class ArchiveController {
  constructor(private readonly archiveService: ArchiveService) {}

  @Get()
  async listArchive(
    @Query('limit') limit?: string,
  ): Promise<ArchiveResponseDto[]> {
    const parsedLimit = limit ? Number(limit) : 20;
    return this.archiveService.listRecent(Number.isNaN(parsedLimit) ? 20 : parsedLimit);
  }
}