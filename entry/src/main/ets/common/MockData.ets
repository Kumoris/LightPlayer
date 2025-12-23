import { Song, createSong } from '../model/Song'
import { Playlist, createPlaylist } from '../model/Playlist'

/**
 * 模拟数据 - 用于静态 UI 预览
 */
export class MockData {
  /**
   * 获取模拟歌曲列表
   */
  static getMockSongs(): Song[] {
    const songs: Song[] = []

    songs.push(createSong(
      1,
      '晴天',
      '周杰伦',
      '叶惠美',
      269000,
      '/storage/Music/晴天.mp3',
      '',
      Date.now(),
      5242880,
      'audio/mpeg'
    ))

    songs.push(createSong(
      2,
      '稻香',
      '周杰伦',
      '魔杰座',
      234000,
      '/storage/Music/稻香.mp3',
      '',
      Date.now(),
      4718592,
      'audio/mpeg'
    ))

    songs.push(createSong(
      3,
      '七里香',
      '周杰伦',
      '七里香',
      299000,
      '/storage/Music/七里香.mp3',
      '',
      Date.now(),
      6029312,
      'audio/mpeg'
    ))

    songs.push(createSong(
      4,
      '夜曲',
      '周杰伦',
      '十一月的萧邦',
      285000,
      '/storage/Music/夜曲.mp3',
      '',
      Date.now(),
      5767168,
      'audio/mpeg'
    ))

    songs.push(createSong(
      5,
      '青花瓷',
      '周杰伦',
      '我很忙',
      239000,
      '/storage/Music/青花瓷.mp3',
      '',
      Date.now(),
      4825600,
      'audio/mpeg'
    ))

    songs.push(createSong(
      6,
      '告白气球',
      '周杰伦',
      '周杰伦的床边故事',
      215000,
      '/storage/Music/告白气球.mp3',
      '',
      Date.now(),
      4350976,
      'audio/mpeg'
    ))

    songs.push(createSong(
      7,
      '简单爱',
      '周杰伦',
      '范特西',
      272000,
      '/storage/Music/简单爱.mp3',
      '',
      Date.now(),
      5490688,
      'audio/mpeg'
    ))

    songs.push(createSong(
      8,
      '一路向北',
      '周杰伦',
      '头文字D电影原声带',
      295000,
      '/storage/Music/一路向北.mp3',
      '',
      Date.now(),
      5955584,
      'audio/mpeg'
    ))

    songs.push(createSong(
      9,
      '听妈妈的话',
      '周杰伦',
      '依然范特西',
      261000,
      '/storage/Music/听妈妈的话.mp3',
      '',
      Date.now(),
      5267456,
      'audio/mpeg'
    ))

    songs.push(createSong(
      10,
      '双截棍',
      '周杰伦',
      '范特西',
      192000,
      '/storage/Music/双截棍.mp3',
      '',
      Date.now(),
      3932160,
      'audio/mpeg'
    ))

    return songs
  }

  /**
   * 获取模拟播放列表
   */
  static getMockPlaylists(): Playlist[] {
    const playlists: Playlist[] = []

    playlists.push(createPlaylist(
      1,
      '我喜欢的音乐',
      '收藏喜欢的歌曲',
      '',
      [1, 2, 3, 4, 5],
      Date.now(),
      Date.now()
    ))

    playlists.push(createPlaylist(
      2,
      '跑步歌单',
      '适合运动时听的歌曲',
      '',
      [6, 7, 8],
      Date.now(),
      Date.now()
    ))

    playlists.push(createPlaylist(
      3,
      '睡前音乐',
      '安静舒缓的音乐',
      '',
      [9, 10],
      Date.now(),
      Date.now()
    ))

    return playlists
  }

  /**
   * 获取默认的当前播放歌曲
   */
  static getCurrentSong(): Song {
    return createSong(
      1,
      '晴天',
      '周杰伦',
      '叶惠美',
      269000,
      '/storage/Music/晴天.mp3',
      '',
      Date.now(),
      5242880,
      'audio/mpeg'
    )
  }
}
