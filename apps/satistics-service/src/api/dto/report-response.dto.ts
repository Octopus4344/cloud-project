export class ReportResponseDto {
  reportKey: string;
  generatedAt: string;
  totalEvents: number;
  byType: Array<{ type: string; count: number }>;
}
