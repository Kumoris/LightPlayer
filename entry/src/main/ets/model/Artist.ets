/**
 * 艺术家数据模型
 */
@Observed
export class Artist {
  id: number = 0
  name: string = ''
  albumCount: number = 0
  songCount: number = 0
  coverUri: string = ''
}
