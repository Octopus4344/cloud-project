import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotifierService {
  async notify(type: string, lat: number, lon: number) {
    Logger.log(`Calling the authorities: ${type}@(${lat},${lon})`)
    await new Promise(r=> setTimeout(r,500))
    const ref = 4
    Logger.log(`Received a reference ${ref}`)
    return ref;
  }
}