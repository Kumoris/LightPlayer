/**
 * 专辑数据模型
 */
@Observed
export class Album {
  id: number = 0
  name: string = ''
  artist: string = ''
  coverUri: string = ''
  songCount: number = 0
  year: number = 0
}
