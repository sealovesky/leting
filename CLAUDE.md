# 乐听 - Flutter 音乐播放器

## 项目概述

本地音乐播放器 App，Apple Music 风格深色主题 UI，支持 Android / iOS / macOS。

- **Flutter SDK**: ^3.10.8
- **状态管理**: Provider
- **数据库**: SQLite (sqflite)
- **音频播放**: just_audio + audio_service

## 目录结构

```
lib/
├── main.dart                    # 入口，MultiProvider 注入，首次启动引导
├── theme/
│   └── app_theme.dart           # 颜色和主题配置
├── models/
│   ├── song.dart                # 歌曲模型（对应 songs 表）
│   ├── artist.dart              # 艺人模型（内存聚合，无独立表）
│   ├── album.dart               # 专辑模型（内存聚合，无独立表）
│   ├── playlist.dart            # 歌单模型（对应 playlists 表）
│   └── play_mode.dart           # 播放模式枚举
├── services/
│   ├── audio_player_service.dart    # just_audio 封装 + audio_service 后台播放
│   ├── local_music_service.dart     # 本地音乐扫描 + 元数据提取
│   ├── storage_service.dart         # SQLite 数据库，所有表的 CRUD
│   └── preference_service.dart      # SharedPreferences KV 存储
├── providers/
│   ├── player_provider.dart     # 播放状态：当前歌曲/队列/进度/音量/模式
│   ├── library_provider.dart    # 音乐库：歌曲列表/艺人/专辑/收藏/历史/扫描
│   ├── playlist_provider.dart   # 歌单管理：创建/删除/增删歌曲
│   ├── search_provider.dart     # 搜索：模糊查询 + 历史记录
│   └── settings_provider.dart   # 设置：音质/通知/扫描状态
├── screens/
│   ├── home_screen.dart         # 首页（推荐歌单/最近播放/艺人/排行榜）
│   ├── search_screen.dart       # 搜索（实时搜索 + 历史 + 结果分区）
│   ├── library_screen.dart      # 资料库（最近播放/收藏/全部歌曲/自建歌单）
│   ├── playlist_screen.dart     # 播放列表（当前队列管理）
│   ├── player_screen.dart       # 全屏播放器（进度条/控制/音量/模式）
│   ├── playlist_detail_screen.dart  # 歌单详情（接收 Playlist 参数）
│   ├── artist_screen.dart       # 艺人详情（接收 artistName 参数）
│   ├── scan_screen.dart         # 本地音乐扫描页面
│   └── settings_screen.dart     # 设置页面
└── widgets/
    ├── album_cover.dart         # 专辑封面（支持 imagePath/imageData/渐变占位）
    ├── bottom_nav.dart          # 底部导航栏（4 个 Tab）
    ├── mini_player_bar.dart     # 迷你播放条（全局同步播放状态）
    └── song_list_tile.dart      # 通用歌曲列表项组件
```

## 数据库表结构

```sql
songs (id TEXT PK, title, artist, album, duration INT, file_path, cover_path, is_local INT, added_at TEXT)
playlists (id TEXT PK, name, description, gradient_index INT, created_at TEXT, updated_at TEXT)
playlist_songs (playlist_id TEXT, song_id TEXT, sort_order INT, added_at TEXT, PK(playlist_id, song_id))
favorites (song_id TEXT PK, added_at TEXT)
play_history (id INTEGER PK AUTO, song_id TEXT, played_at TEXT)
```

## 第三方依赖

| 包名 | 用途 |
|------|------|
| provider | 状态管理 |
| just_audio | 音频播放引擎 |
| audio_service | 后台播放 + 通知栏控制 |
| flutter_media_metadata | 读取 ID3 标签（标题/艺人/封面） |
| permission_handler | Android/iOS 存储和媒体库权限 |
| sqflite | SQLite 本地数据库 |
| shared_preferences | KV 持久化（设置/搜索历史等） |
| path_provider + path | 获取存储目录和路径操作 |

## 平台配置

### Android (`android/app/src/main/AndroidManifest.xml`)
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` — 本地音乐扫描
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` / `WAKE_LOCK` — 后台播放

### iOS (`ios/Runner/Info.plist`)
- `UIBackgroundModes: audio` — 后台音频
- `NSAppleMusicUsageDescription` — 音乐库权限说明

### macOS (`macos/Runner/Configs/AppInfo.xcconfig`)
- 应用名称 `PRODUCT_NAME = 乐听`

## 设计规范

- **背景色**: #0D0D0D
- **卡片色**: #1C1C1E / #2C2C2E
- **主色调**: #FC3E4E (红色)
- **文字色**: #FFFFFF (前景) / #8E8E93 (次要)
- **圆角**: 12px / 16px / 999px (药丸)
- **毛玻璃**: MiniPlayerBar 和顶栏使用 BackdropFilter

## 架构说明

1. **Services 层** 不依赖 Flutter，纯 Dart 逻辑。Provider 层调用 Services 层并通过 `notifyListeners()` 驱动 UI。
2. **main.dart** 在 `main()` 中初始化所有 Service 实例，通过 `MultiProvider` 注入到 Widget 树。
3. **Artist / Album** 没有独立的数据库表，而是从 `songs` 表聚合生成，存在 `LibraryProvider` 内存中。
4. **PlayerProvider** 监听 `AudioPlayerService` 的 Stream（position/duration/playerState），自动驱动 UI 更新。
5. **首次启动**会弹窗引导用户扫描本地音乐。

## 当前状态

所有 7 个开发阶段已完成：
1. 基础架构（模型/服务/Provider/依赖注入）
2. 音频播放核心（play/pause/seek/volume/mode/队列）
3. 本地音乐扫描（文件系统遍历 + ID3 元数据 + 封面提取）
4. 资料库与歌单管理（CRUD + 收藏 + 播放历史）
5. 搜索功能（模糊搜索 + 搜索历史持久化）
6. 首页数据驱动 + 全局导航
7. 设置持久化 + 后台播放（audio_service 通知栏控制）

## 下一步开发计划

### P0 - 核心体验完善（优先）

1. **Android 真机权限请求**
   - `permission_handler` 的 `request()` 调用尚未在 UI 中触发
   - 扫描前需请求 `READ_MEDIA_AUDIO`（Android 13+）或 `READ_EXTERNAL_STORAGE`
   - 涉及文件：`lib/screens/scan_screen.dart`、`lib/providers/library_provider.dart`

2. **macOS 音乐目录扫描适配**
   - macOS 沙盒已添加文件读取权限（entitlements），但 `LocalMusicService` 中的扫描路径仅配置了 Android/iOS
   - 需添加 macOS 音乐目录 `~/Music`
   - 涉及文件：`lib/services/local_music_service.dart`

3. **添加歌曲到歌单**
   - 当前歌单可以创建/删除，但没有「添加歌曲」的 UI 入口
   - 方案：歌曲列表项长按弹出底部菜单，选择目标歌单
   - 涉及文件：`lib/widgets/song_list_tile.dart`、新增底部菜单组件

4. **收藏按钮集成**
   - PlayerScreen 和 SongListTile 中添加收藏/取消收藏按钮
   - 涉及文件：`lib/screens/player_screen.dart`、`lib/widgets/song_list_tile.dart`

### P1 - 功能增强

5. **歌词展示**
   - PlayerScreen 中间区域目前为空白，用于显示当前歌词
   - 需要歌词解析服务（支持 .lrc 文件或内嵌歌词）
   - 涉及文件：新建 `lib/services/lyrics_service.dart`、修改 `lib/screens/player_screen.dart`

6. **拖拽排序播放列表**
   - PlaylistScreen 中的队列支持拖拽排序
   - 使用 `ReorderableListView`
   - 涉及文件：`lib/screens/playlist_screen.dart`

7. **全部歌曲页面**
   - LibraryScreen 中「全部歌曲」点击后进入独立页面，支持排序/筛选
   - 涉及文件：新建 `lib/screens/all_songs_screen.dart`

8. **收藏歌曲页面**
   - LibraryScreen 中「喜欢的歌曲」点击后进入独立页面
   - 涉及文件：新建 `lib/screens/favorites_screen.dart`

### P2 - 体验优化

9. **播放器页面手势**
   - 下滑关闭全屏播放器（DraggableScrollableSheet）
   - MiniPlayerBar 上滑展开全屏播放器

10. **过渡动画**
    - MiniPlayerBar → PlayerScreen 的 Hero 动画（封面图放大过渡）
    - 页面切换动画统一

11. **均衡器功能**
    - just_audio 支持 AndroidEqualizer
    - 涉及文件：`lib/screens/settings_screen.dart`、`lib/services/audio_player_service.dart`

12. **主题切换**
    - 支持浅色模式
    - 涉及文件：`lib/theme/app_theme.dart`、`lib/providers/settings_provider.dart`

### P2.5 - 多语言支持（优先支持英文）

13. **国际化（i18n）**
    - 使用 Flutter 官方 `flutter_localizations` + `intl` 方案
    - 默认语言：中文（zh），优先新增：英文（en）
    - 所有用户可见的硬编码中文字符串提取为本地化 key
    - 涉及文件：新建 `lib/l10n/` 目录，`l10n.yaml` 配置，`app_zh.arb`、`app_en.arb` 资源文件
    - 修改：所有 screens 和 widgets 中的硬编码文本替换为 `AppLocalizations.of(context)!.xxx`
    - `lib/providers/settings_provider.dart` 新增语言切换功能
    - `lib/main.dart` 配置 `localizationsDelegates` 和 `supportedLocales`

### P3 - 质量保证

14. **单元测试** — models 和 services 层
15. **Widget 测试** — 关键页面
16. **集成测试** — 端到端播放流程
