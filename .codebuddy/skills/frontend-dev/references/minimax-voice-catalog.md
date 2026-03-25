# MiniMax 声音目录

MiniMax 语音 API 所有可用声音的完整参考。

## 目录

- [声音推荐](#声音推荐) — 按内容类型和特征查找声音
- [系统声音列表（按语言分类）](#系统声音列表按语言分类) — 按语言的完整声音数据库
- [声音参数](#声音参数) — 配置声音设置（语速、音量、音调、情绪）
- [自定义声音](#自定义声音) — 声音克隆和声音设计选项
- [声音对比表](#声音对比表) — 快速参考对比
- [声音 ID 快速参考](#声音-id-快速参考) — 热门声音一览

---

## 1. 如何选择声音

选择声音时，请遵循以下两步决策流程，确保声音与角色场景、性别、年龄和语言相匹配。

### 步骤 1：确定使用场景

首先，确定您的内容是否属于**第 2.1 节**中列出的**三个专业领域**：

| 专业领域 | 示例 |
|---|---|
| **叙事与故事讲述** | 适用于有声书、小说 narration、故事讲述中的旁白 |
| **新闻与公告** | 适用于新闻广播、正式公告、新闻发布 |
| **纪录片** | 适用于纪录片旁白、评论、教育片 |

**如果您的内容匹配其中一个专业领域：**
→ 优先从**第 2.1 节**的推荐声音中选择，按场景和说话人的**性别**筛选。
这些声音专门针对各自的专业用途进行了优化（节奏、清晰度、语调）。

**如果您的内容不属于这三个专业领域：**
→ 继续下面的步骤 2。

### 步骤 2：按特征选择（性别 + 年龄 + 语言）

对于非专业场景，按以下三个特征（严格按优先级顺序）从**第 2.2 节**选择声音：

1. **性别**（最高优先级，不可妥协）
   - 男性角色 → **必须**使用男声
   - 女性角色 → **必须**使用女声
   - 切勿性别错配，即使其他特征看似匹配

2. **年龄**（决定查看哪个小节）
   - **儿童** → 第 2.2 节"儿童声音"
   - **青年**（青少年、年轻成人）→ 第 2.2 节"青年声音"
   - **成人** → 第 2.2 节"成人声音"
   - **老年** → 第 2.2 节"老年声音"

3. **语言**（必须与内容语言匹配）
   - 声音**必须**与所生成内容的语言匹配
   - 中文内容 → 选择中文声音；韩语内容 → 选择韩语声音；英语内容 → 选择英语声音，以此类推
   - 如果第 2.2 节中没有精确的语言匹配，回退到目标语言的完整**系统声音列表**（第 3 节）

根据这三个特征缩小候选范围后，根据每个声音条目的**个性**、**语调**和**用途**选择最佳匹配。

### 快速参考决策流程

```
内容类型？
├── 故事/叙事/新闻/纪录片 → 第 2.1 节（按场景 + 性别筛选）
└── 其他场景 → 第 2.2 节：
    ├── 1. 匹配性别（强制）
    ├── 2. 匹配年龄段（儿童/青年/成人/老年/专业）
    ├── 3. 匹配语言（必须与内容语言匹配）
    └── 4. 按个性/语调选择最佳匹配
```

---

## 2. 声音推荐

### 2.1 按内容类型

**叙事与故事讲述**
- 推荐：`audiobook_female_1`、`audiobook_male_1`
- 特征：适合讲故事，持续表演，吐字清晰，节奏良好

**新闻与公告**
- 推荐：`Chinese (Mandarin)_News_Anchor`、`Chinese (Mandarin)_Male_Announcer`
- 特征：权威，清晰，专业节奏

**纪录片**
- 推荐：`doc_commentary`
- 特征：专业，清晰，节奏一致


### 2.2 按特征

#### 儿童声音

| voice_id | 名称 | 描述 | 最佳用途 | 语言 |
|----------|------|-------------|----------|------|
| `clever_boy` | 聪明男童 | 聪明，机智的男孩声音 | 儿童内容，教育 | 中文（普通话） |
| `cute_boy` | 可爱男童 | 可爱，幼年男孩声音 | 儿童内容，动画 | 中文（普通话） |
| `lovely_girl` | 萌萌女童 | 可爱，甜美的女孩声音 | 儿童故事，游戏 | 中文（普通话） |
| `cartoon_pig` | 卡通猪小琪 | 卡通角色声音 | 动画，喜剧，娱乐 | 中文（普通话） |
| `Korean_SweetGirl` | Sweet Girl | 可爱，迷人的幼年女孩声音 | 儿童内容，浪漫 | 韩语 |
| `Indonesian_SweetGirl` | Sweet Girl | 可爱，迷人的女孩声音 | 儿童内容，友好 | 印尼语 |
| `English_Sweet_Girl` | Sweet Girl | 可爱，天真的幼年女孩声音 | 儿童内容，友好 | 英语 |
| `Spanish_Kind-heartedGirl` | Kind-hearted Girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 | 西班牙语 |
| `Portuguese_Kind-heartedGirl` | Kind-hearted Girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 | 葡萄牙语 |

#### 青年声音

| voice_id | 名称 | 描述 | 最佳用途 | 语言 |
|----------|------|-------------|----------|------|
| `male-qn-qingse` | 青涩青年 | 年轻，生涩的男性声音 | 校园故事，成长期内容 | 中文（普通话） |
| `male-qn-daxuesheng` | 青年大学生 | 年轻大学生声音 | 校园内容，教育 | 中文（普通话） |
| `female-shaonv` | 少女 | 年轻少女声音 | 浪漫，青年内容 | 中文（普通话） |
| `bingjiao_didi` | 病娇弟弟 | 傲娇弟弟声音 | 浪漫，角色驱动内容 | 中文（普通话） |
| `junlang_nanyou` | 俊朗男友 | 英俊男友声音 | 浪漫，恋爱内容 | 中文（普通话） |
| `chunzhen_xuedi` | 纯真学弟 | 天真学弟声音 | 校园故事，青年内容 | 中文（普通话） |
| `lengdan_xiongzhang` | 冷淡学长 | 高冷学长声音 | 校园故事，浪漫 | 中文（普通话） |
| `diadia_xuemei` | 嗲嗲学妹 | 撒娇学妹声音 | 浪漫，恋爱内容 | 中文（普通话） |
| `danya_xuejie` | 淡雅学姐 | 淡雅学姐声音 | 校园故事，浪漫 | 中文（普通话） |
| `Chinese (Mandarin)_Straightforward_Boy` | 率真弟弟 | 直率，坦诚的男孩声音 | 休闲，直接内容 | 中文（普通话） |
| `Chinese (Mandarin)_Sincere_Adult` | 真诚青年 | 真诚的年轻成人声音 | 诚实，真挚内容 | 中文（普通话） |
| `Chinese (Mandarin)_Pure-hearted_Boy` | 清澈邻家弟弟 | 纯洁的邻居男孩声音 | 天真，纯真内容 | 中文（普通话） |
| `Korean_CheerfulBoyfriend` | Cheerful Boyfriend | 活力四射，深情的男友声音 | 浪漫，恋爱内容 | 韩语 |
| `Korean_ShyGirl` | Shy Girl | 害羞，内敛的女孩声音 | 喜剧，浪漫 | 韩语 |
| `Japanese_SportyStudent` | Sporty Student | 活力四射的运动员学生声音 | 体育，青年内容 | 日语 |
| `Japanese_InnocentBoy` | Innocent Boy | 纯洁，天真的幼年男孩声音 | 儿童内容 | 日语 |
| `Spanish_SincereTeen` | SincereTeen | 诚实，真挚的青少年声音 | 青年，真实 | 西班牙语 |
| `Spanish_Strong-WilledBoy` | Strong-willed Boy | 坚定，有决心的男孩声音 | 青年，励志 | 西班牙语 |

#### 成人声音

| voice_id | 名称 | 描述 | 最佳用途 | 语言 |
|----------|------|-------------|----------|------|
| `female-chengshu` | 成熟女性 | 成熟女性声音 | 精致，成人内容 | 中文（普通话） |
| `female-yujie` | 御姐 | 成熟，优雅的女性声音 | 浪漫，专业内容 | 中文（普通话） |
| `female-tianmei` | 甜美女性 | 甜美，宜人的女性声音 | 柔和，温柔内容 | 中文（普通话） |
| `badao_shaoye` | 霸道少爷 | 傲慢少爷声音 | 戏剧，角色扮演 | 中文（普通话） |
| `wumei_yujie` | 妩媚御姐 | 妩媚成熟女性声音 | 浪漫，成熟内容 | 中文（普通话） |
| `Chinese (Mandarin)_Gentleman` | 温润男声 | 温和，优雅的男性声音 | 叙事，故事讲述 | 中文（普通话） |
| `Chinese (Mandarin)_Unrestrained_Young_Man` | 不羁青年 | 不羁青年声音 | 休闲，娱乐内容 | 中文（普通话） |
| `Chinese (Mandarin)_Southern_Young_Man` | 南方小哥 | 南方小哥声音 | 地域特色，休闲内容 | 中文（普通话） |
| `Chinese (Mandarin)_Gentle_Youth` | 温润青年 | 温和青年声音 | 叙事，平静内容 | 中文（普通话） |
| `Chinese (Mandarin)_Warm_Girl` | 温暖少女 | 温暖少女声音 | 友好，支持性内容 | 中文（普通话） |
| `Chinese (Mandarin)_Soft_Girl` | 柔和少女 | 柔和少女声音 | 平静，舒缓内容 | 中文（普通话） |
| `Korean_PlayboyCharmer` | Playboy Charmer | 圆滑，调情的男性声音 | 浪漫，娱乐 | 韩语 |
| `Korean_CalmLady` | Calm Lady | 沉稳，镇定的女性声音 | 冥想，放松 | 韩语 |
| `Spanish_ConfidentWoman` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 | 西班牙语 |
| `Portuguese_ConfidentWoman` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 | 葡萄牙语 |

#### 老年声音

| voice_id | 名称 | 描述 | 最佳用途 | 语言 |
|----------|------|-------------|----------|------|
| `Chinese (Mandarin)_Humorous_Elder` | 搞笑大爷 | 幽默大爷声音 | 喜剧，娱乐 | 中文（普通话） |
| `Chinese (Mandarin)_Kind-hearted_Elder` | 花甲奶奶 | 慈祥老奶奶声音 | 故事，温暖内容 | 中文（普通话） |
| `Chinese (Mandarin)_Kind-hearted_Antie` | 热心大婶 | 热心大婶声音 | 温暖，友好内容 | 中文（普通话） |
| `Japanese_IntellectualSenior` | Intellectual Senior | 智慧，博学的老者声音 | 叙事，教育 | 日语 |
| `Korean_IntellectualSenior` | Intellectual Senior | 智慧，博学的老者声音 | 教育，叙事 | 韩语 |
| `Spanish_Wiselady` | Wise Lady | 经验丰富，睿智的女性声音 | 指导，建议 | 西班牙语 |
| `Portuguese_Wiselady` | Wise Lady | 经验丰富，睿智的女性声音 | 指导，建议 | 葡萄牙语 |
| `Spanish_SereneElder` | Serene Elder | 平静，安详的老年声音 | 冥想，智慧 | 西班牙语 |
| `Portuguese_SereneElder` | Serene Elder | 平静，安详的老年声音 | 冥想，智慧 | 葡萄牙语 |
| `English_Gentle-voiced_man` | Gentle-voiced Man | 轻声细语，和蔼的男性声音 | 平静，支持性内容 | 英语 |

---

## 系统声音列表（按语言分类）

### 中文普通话声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `male-qn-qingse` | 青涩青年 | 年轻，生涩的男性声音 | 校园故事，成长期内容 |
| `male-qn-badao` | 霸道青年 | 傲慢，强势的青年声音 | 戏剧，浪漫，角色扮演 |
| `male-qn-daxuesheng` | 青年大学生 | 年轻大学生声音 | 校园内容，教育 |
| `female-shaonv` | 少女 | 年轻少女声音 | 浪漫，青年内容 |
| `female-yujie` | 御姐 | 成熟，优雅的女性声音 | 浪漫，专业内容 |
| `female-chengshu` | 成熟女性 | 成熟女性声音 | 精致，成人内容 |
| `female-tianmei` | 甜美女性 | 甜美，宜人的女性声音 | 柔和，温柔内容 |
| `clever_boy` | 聪明男童 | 聪明，机智的男孩声音 | 儿童内容，教育 |
| `cute_boy` | 可爱男童 | 可爱，幼年男孩声音 | 儿童内容，动画 |
| `lovely_girl` | 萌萌女童 | 可爱，甜美的女孩声音 | 儿童故事，游戏 |
| `cartoon_pig` | 卡通猪小琪 | 卡通角色声音 | 动画，喜剧，娱乐 |
| `bingjiao_didi` | 病娇弟弟 | 傲娇弟弟声音 | 浪漫，角色驱动内容 |
| `junlang_nanyou` | 俊朗男友 | 英俊男友声音 | 浪漫，恋爱内容 |
| `chunzhen_xuedi` | 纯真学弟 | 天真学弟声音 | 校园故事，青年内容 |
| `lengdan_xiongzhang` | 冷淡学长 | 高冷学长声音 | 校园故事，浪漫 |
| `badao_shaoye` | 霸道少爷 | 傲慢少爷声音 | 戏剧，角色扮演 |
| `tianxin_xiaoling` | 甜心小玲 | 甜心小玲声音 | 角色扮演，动画 |
| `qiaopi_mengmei` | 俏皮萌妹 | 俏皮可爱女孩声音 | 喜剧，轻松内容 |
| `wumei_yujie` | 妩媚御姐 | 妩媚成熟女性声音 | 浪漫，成熟内容 |
| `diadia_xuemei` | 嗲嗲学妹 | 撒娇学妹声音 | 浪漫，恋爱内容 |
| `danya_xuejie` | 淡雅学姐 | 淡雅学姐声音 | 校园故事，浪漫 |
| `Arrogant_Miss` | 嚣张小姐 | 傲慢小姐声音 | 戏剧，角色扮演 |
| `Robot_Armor` | 机械战甲 | 机械战甲声音 | 科幻，游戏角色 |
| `Chinese (Mandarin)_Reliable_Executive` | 沉稳高管 | 沉稳高管声音 | 企业，商业内容 |
| `Chinese (Mandarin)_News_Anchor` | 新闻女声 | 新闻主播女声 | 新闻广播，时事 |
| `Chinese (Mandarin)_Mature_Woman` | 傲娇御姐 | 傲娇御姐声音 | 浪漫，角色驱动内容 |
| `Chinese (Mandarin)_Unrestrained_Young_Man` | 不羁青年 | 不羁青年声音 | 休闲，娱乐内容 |
| `male-qn-jingying` | 精英青年 | 精英，野心勃勃的青年声音 | 商业，专业内容 |
| `Chinese (Mandarin)_Kind-hearted_Antie` | 热心大婶 | 热心大婶声音 | 温暖，友好内容 |
| `Chinese (Mandarin)_HK_Flight_Attendant` | 港普空姐 | 港式普通话空姐声音 | 地域特色，娱乐 |
| `Chinese (Mandarin)_Humorous_Elder` | 搞笑大爷 | 幽默大爷声音 | 喜剧，娱乐 |
| `Chinese (Mandarin)_Gentleman` | 温润男声 | 温和，优雅的男性声音 | 叙事，故事讲述 |
| `Chinese (Mandarin)_Warm_Bestie` | 温暖闺蜜 | 温暖闺蜜女性声音 | 友好，支持性内容 |
| `Chinese (Mandarin)_Male_Announcer` | 播报男声 | 男播报员声音 | 公告，广播 |
| `Chinese (Mandarin)_Sweet_Lady` | 甜美女声 | 甜美女性声音 | 柔和，温柔内容 |
| `Chinese (Mandarin)_Southern_Young_Man` | 南方小哥 | 南方小哥声音 | 地域特色，休闲内容 |
| `Chinese (Mandarin)_Wise_Women` | 阅历姐姐 | 阅历丰富的智慧女性声音 | 建议，指导内容 |
| `Chinese (Mandarin)_Gentle_Youth` | 温润青年 | 温和青年声音 | 叙事，平静内容 |
| `Chinese (Mandarin)_Warm_Girl` | 温暖少女 | 温暖少女声音 | 友好，支持性内容 |
| `Chinese (Mandarin)_Kind-hearted_Elder` | 花甲奶奶 | 慈祥老奶奶声音 | 故事，温暖内容 |
| `Chinese (Mandarin)_Cute_Spirit` | 憨憨萌兽 | 可爱卡通神兽声音 | 动画，儿童内容 |
| `Chinese (Mandarin)_Radio_Host` | 电台男主播 | 电台男主播声音 | 播客，电台节目 |
| `Chinese (Mandarin)_Lyrical_Voice` | 抒情男声 | 抒情男声 | 音乐，歌唱内容 |
| `Chinese (Mandarin)_Straightforward_Boy` | 率真弟弟 | 直率，坦诚的男孩声音 | 休闲，直接内容 |
| `Chinese (Mandarin)_Sincere_Adult` | 真诚青年 | 真诚的年轻成人声音 | 诚实，真挚内容 |
| `Chinese (Mandarin)_Gentle_Senior` | 温柔学姐 | 温柔学姐声音 | 校园故事，支持性内容 |
| `Chinese (Mandarin)_Stubborn_Friend` | 嘴硬竹马 | 嘴硬青梅竹马声音 | 戏剧，角色驱动内容 |
| `Chinese (Mandarin)_Crisp_Girl` | 清脆少女 | 清脆，清亮的少女声音 | 清晰，明亮内容 |
| `Chinese (Mandarin)_Pure-hearted_Boy` | 清澈邻家弟弟 | 纯洁的邻居男孩声音 | 天真，纯真内容 |
| `Chinese (Mandarin)_Soft_Girl` | 柔和少女 | 柔和少女声音 | 平静，舒缓内容 |

### 中文粤语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Cantonese_ProfessionalHost（F)` | 专业女主持 | 专业女主播声音 | 粤语广播，主持 |
| `Cantonese_GentleLady` | 温柔女声 | 温柔粤语女声 | 柔和，温暖粤语内容 |
| `Cantonese_ProfessionalHost（M)` | 专业男主持 | 专业男主播声音 | 粤语广播，主持 |
| `Cantonese_PlayfulMan` | 活泼男声 | 活泼粤语男声 | 娱乐，休闲内容 |
| `Cantonese_CuteGirl` | 可爱女孩 |可爱粤语女孩声音 | 儿童内容，动画 |
| `Cantonese_KindWoman` | 善良女声 | 善良粤语女声 | 温暖，友好内容 |

### 英语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Santa_Claus` | Santa Claus | 节日，欢乐的男性声音 | 节日内容，儿童故事 |
| `Grinch` | Grinch | 爱抱怨，调皮的声音 | 喜剧，娱乐，节日 |
| `Rudolph` | Rudolph | 可爱，鼻音的驯鹿声音 | 儿童内容，节日 |
| `Arnold` | Arnold | 深沉，机械的终结者声音 | 科幻，动作，角色扮演 |
| `Charming_Santa` | Charming Santa | 圆滑，有魅力的圣诞老人声音 | 节日，娱乐 |
| `Charming_Lady` | Charming Lady | 优雅，精致的女性声音 | 专业，浪漫 |
| `Sweet_Girl` | Sweet Girl | 可爱，天真的幼年女孩声音 | 儿童内容，友好 |
| `Cute_Elf` | Cute Elf | 俏皮，小精灵声音 | 幻想，儿童内容 |
| `Attractive_Girl` | Attractive Girl | 有魅力，吸引人的女性声音 | 娱乐，营销 |
| `Serene_Woman` | Serene Woman | 平静，安详的女性声音 | 冥想，放松 |
| `English_Trustworthy_Man` | Trustworthy Man | 可靠，真诚的男性声音 | 商业，叙事 |
| `English_Graceful_Lady` | Graceful Lady | 优雅，精致的女性声音 | 正式，专业 |
| `English_Aussie_Bloke` | Aussie Bloke | 休闲，友好的澳大利亚男性声音 | 休闲，娱乐 |
| `English_Whispering_girl` | Whispering Girl | 轻柔，低语声音 | 浪漫，亲密内容 |
| `English_Diligent_Man` | Diligent Man | 勤奋，认真的男性声音 | 励志，教育 |
| `English_Gentle-voiced_man` | Gentle-voiced Man | 轻声细语，和蔼的男性声音 | 平静，支持性内容 |

### 日语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Japanese_IntellectualSenior` | Intellectual Senior | 智慧，博学的老者声音 | 叙事，教育 |
| `Japanese_DecisivePrincess` | Decisive Princess | 自信，皇家公主声音 | 动画，游戏，戏剧 |
| `Japanese_LoyalKnight` | Loyal Knight | 勇敢，忠诚的骑士声音 | 幻想，游戏，故事 |
| `Japanese_DominantMan` | Dominant Man | 强大，有命令力的男性声音 | 动作，领导力 |
| `Japanese_SeriousCommander` | Serious Commander | 严肃，威严的指挥官声音 | 军事，游戏 |
| `Japanese_ColdQueen` | Cold Queen | 疏远，威严的女王声音 | 戏剧，幻想 |
| `Japanese_DependableWoman` | Dependable Woman | 可靠，支持性的女性声音 | 支持性，指导 |
| `Japanese_GentleButler` | Gentle Butler | 有礼貌，优雅的管家声音 | 喜剧，动画 |
| `Japanese_KindLady` | Kind Lady | 温暖，温柔的高贵女性声音 | 温暖，慰藉 |
| `Japanese_CalmLady` | Calm Lady | 沉稳，镇定的女性声音 | 冥想，放松 |
| `Japanese_OptimisticYouth` | Optimistic Youth | 开朗，积极的年轻人声音 | 青年内容，励志 |
| `Japanese_GenerousIzakayaOwner` | Generous Izakaya Owner | 友好，热情的酒馆老板声音 | 休闲，喜剧 |
| `Japanese_SportyStudent` | Sporty Student | 活力四射的运动员学生声音 | 体育，青年内容 |
| `Japanese_InnocentBoy` | Innocent Boy | 纯洁，天真的幼年男孩声音 | 儿童内容 |
| `Japanese_GracefulMaiden` | Graceful Maiden | 优雅，温柔的年轻女性声音 | 浪漫，戏剧 |

### 韩语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Korean_SweetGirl` | Sweet Girl | 可爱，迷人的幼年女孩声音 | 儿童内容，浪漫 |
| `Korean_CheerfulBoyfriend` | Cheerful Boyfriend | 活力四射，深情的男友声音 | 浪漫，恋爱内容 |
| `Korean_EnchantingSister` | Enchanting Sister | 迷人，令人着迷的姐姐声音 | 家庭，戏剧 |
| `Korean_ShyGirl` | Shy Girl | 害羞，内敛的女孩声音 | 喜剧，浪漫 |
| `Korean_ReliableSister` | Reliable Sister | 值得信赖，可依靠的姐姐声音 | 支持性，指导 |
| `Korean_StrictBoss` | Strict Boss | 权威，要求严格的老板声音 | 商业，戏剧 |
| `Korean_SassyGirl` | Sassy Girl | 大胆，机智的女孩声音 | 喜剧，娱乐 |
| `Korean_ChildhoodFriendGirl` | Childhood Friend Girl | 熟悉，友好的青梅竹马女孩声音 | 浪漫，怀旧 |
| `Korean_PlayboyCharmer` | Playboy Charmer | 圆滑，调情的男性声音 | 浪漫，娱乐 |
| `Korean_ElegantPrincess` | Elegant Princess | 优雅，皇家公主声音 | 动画，幻想 |
| `Korean_BraveFemaleWarrior` | Brave Female Warrior | 勇敢的女战士声音 | 动作，幻想 |
| `Korean_BraveYouth` | Brave Youth | 英勇的年轻人声音 | 动作，青年 |
| `Korean_CalmLady` | Calm Lady | 沉稳，镇定的女性声音 | 冥想，放松 |
| `Korean_EnthusiasticTeen` | EnthusiasticTeen | 兴奋，精力充沛的青少年声音 | 青年内容 |
| `Korean_SoothingLady` | Soothing Lady | 令人平静，安慰的女性声音 | 放松，支持 |
| `Korean_IntellectualSenior` | Intellectual Senior | 智慧，博学的老者声音 | 教育，叙事 |
| `Korean_LonelyWarrior` | Lonely Warrior | 孤独，忧郁的战士声音 | 戏剧，幻想 |
| `Korean_MatureLady` | MatureLady | 精致，成熟女性声音 | 专业，戏剧 |
| `Korean_InnocentBoy` | Innocent Boy | 纯洁，天真的幼年男孩声音 | 儿童内容 |
| `Korean_CharmingSister` | Charming Sister | 迷人，可爱的姐姐声音 | 家庭，浪漫 |
| `Korean_AthleticStudent` | Athletic Student | 运动型，精力充沛的学生声音 | 体育，青年 |
| `Korean_BraveAdventurer` | Brave Adventurer | 勇敢探险者声音 | 冒险，幻想 |
| `Korean_CalmGentleman` | Calm Gentleman | 沉稳，优雅的绅士声音 | 正式，专业 |
| `Korean_WiseElf` | Wise Elf | 古老，神秘的精灵声音 | 幻想，叙事 |
| `Korean_CheerfulCoolJunior` | Cheerful Cool Junior | 受欢迎，友好的学弟声音 | 青年，娱乐 |
| `Korean_DecisiveQueen` | Decisive Queen | 权威，有决断力的女王声音 | 戏剧，幻想 |
| `Korean_ColdYoungMan` | Cold Young Man | 疏远，冷漠的年轻男性声音 | 戏剧，浪漫 |
| `Korean_MysteriousGirl` | Mysterious Girl | 神秘，莫测高深的女孩声音 | 悬疑，戏剧 |
| `Korean_QuirkyGirl` | Quirky Girl | 古怪，独特的女孩声音 | 喜剧，娱乐 |
| `Korean_ConsiderateSenior` | Considerate Senior | 体贴，关心他人的长者声音 | 温暖，支持 |
| `Korean_CheerfulLittleSister` | Cheerful Little Sister | 俏皮，可爱的小妹妹声音 | 家庭，喜剧 |
| `Korean_DominantMan` | Dominant Man | 强大，有命令力的男性声音 | 领导力，动作 |
| `Korean_AirheadedGirl` | Airheaded Girl | 活泼，有点迷糊的女孩声音 | 喜剧，娱乐 |
| `Korean_ReliableYouth` | Reliable Youth | 值得信赖，可依靠的年轻人声音 | 支持性，青年 |
| `Korean_FriendlyBigSister` | Friendly Big Sister | 温暖，保护性的大姐声音 | 家庭，支持 |
| `Korean_GentleBoss` | Gentle Boss | 和善，体贴的老板声音 | 商业，支持性 |
| `Korean_ColdGirl` | Cold Girl | 冷漠，疏远的女孩声音 | 戏剧，浪漫 |
| `Korean_HaughtyLady` | Haughty Lady | 傲慢，骄傲的女性声音 | 戏剧，喜剧 |
| `Korean_CharmingElderSister` | Charming Elder Sister | 迷人，优雅的大姐声音 | 浪漫，家庭 |
| `Korean_IntellectualMan` | Intellectual Man | 聪明，博学的男性声音 | 教育，专业 |
| `Korean_CaringWoman` | Caring Woman | 体贴，支持性的女性声音 | 支持性，温暖 |
| `Korean_WiseTeacher` | Wise Teacher | 经验丰富，知识渊博的教师声音 | 教育 |
| `Korean_ConfidentBoss` | Confident Boss | 自信，能干的老板声音 | 商业，领导力 |
| `Korean_AthleticGirl` | Athletic Girl | 运动型，精力充沛的女孩声音 | 体育，健身 |
| `Korean_PossessiveMan` | PossessiveMan | 强烈，保护欲强的男性声音 | 浪漫，戏剧 |
| `Korean_GentleWoman` | Gentle Woman | 轻声细语，和善的女性声音 | 平静，支持性 |
| `Korean_CockyGuy` | Cocky Guy | 自信，有点自大的男性声音 | 喜剧，娱乐 |
| `Korean_ThoughtfulWoman` | ThoughtfulWoman | 体贴，关怀女性的深思声音 | 戏剧，支持 |
| `Korean_OptimisticYouth` | Optimistic Youth | 积极，乐观的年轻人声音 | 励志，青年 |

### 西班牙语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Spanish_SereneWoman` | Serene Woman | 平静，安详的女性声音 | 放松，冥想 |
| `Spanish_MaturePartner` | Mature Partner | 精致，成熟伴侣声音 | 浪漫，戏剧 |
| `Spanish_CaptivatingStoryteller` | Captivating Storyteller | 引人入胜，有魅力的旁白声音 | 有声书，故事讲述 |
| `Spanish_Narrator` | Narrator | 专业叙事声音 | 纪录片，旁白 |
| `Spanish_WiseScholar` | Wise Scholar | 知识渊博，睿智的学者声音 | 教育，历史 |
| `Spanish_Kind-heartedGirl` | Kind-hearted Girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 |
| `Spanish_DeterminedManager` | Determined Manager | 有野心，有冲劲的经理声音 | 商业，励志 |
| `Spanish_BossyLeader` | Bossy Leader | 发号施令，威权领导者声音 | 领导力，戏剧 |
| `Spanish_ReservedYoungMan` | Reserved Young Man | 安静，内向的年轻男性声音 | 戏剧，现实角色 |
| `Spanish_ConfidentWoman` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 |
| `Spanish_ThoughtfulMan` | ThoughtfulMan | 体贴，睿智的男性声音 | 教育，戏剧 |
| `Spanish_Strong-WilledBoy` | Strong-willed Boy | 坚定，有决心的男孩声音 | 青年，励志 |
| `Spanish_SophisticatedLady` | SophisticatedLady | 优雅，精致的女性声音 | 正式，浪漫 |
| `Spanish_RationalMan` | Rational Man | 逻辑，分析性的男性声音 | 教育，商业 |
| `Spanish_AnimeCharacter` | Anime Character | 夸张的动漫风格声音 | 动画，娱乐 |
| `Spanish_Deep-tonedMan` | Deep-toned Man | 深沉，共鸣强的男性声音 | 有魅力，指挥 |
| `Spanish_Fussyhostess` | Fussy Hostess |挑剔，要求高的女主人声音 | 喜剧，戏剧 |
| `Spanish_SincereTeen` | SincereTeen | 诚实，真挚的青少年声音 | 青年，真实 |
| `Spanish_FrankLady` | Frank Lady | 直接，坦诚的女性声音 | 喜剧，戏剧 |
| `Spanish_Comedian` | Comedian | 幽默，娱乐的声音 | 喜剧，娱乐 |
| `Spanish_Debator` | Debator | 争辩，说服的声音 | 辩论，讨论 |
| `Spanish_ToughBoss` | Tough Boss | 严厉，要求高的老板声音 | 商业，戏剧 |
| `Spanish_Wiselady` | Wise Lady | 经验丰富，睿智的女性声音 | 指导，建议 |
| `Spanish_Steadymentor` | Steady Mentor | 可靠，支持性的导师声音 | 教育，指导 |
| `Spanish_Jovialman` | Jovial Man | 快乐，友好的男性声音 | 娱乐，休闲 |
| `Spanish_SantaClaus` | Santa Claus | 节日圣诞老人声音 | 节日，儿童 |
| `Spanish_Rudolph` | Rudolph | 驯鹿声音 | 节日，儿童 |
| `Spanish_Intonategirl` | Intonate Girl | 音乐感，旋律化的女孩声音 | 音乐，歌唱 |
| `Spanish_Arnold` | Arnold | 机械，有质感的声音 | 科幻，动作 |
| `Spanish_Ghost` | Ghost | 幽灵，空灵的声音 | 恐怖，悬疑 |
| `Spanish_HumorousElder` | Humorous Elder | 搞笑，老年人声音 | 喜剧，娱乐 |
| `Spanish_EnergeticBoy` | Energetic Boy | 活跃，充满活力的男孩声音 | 青年，体育 |
| `Spanish_WhimsicalGirl` | Whimsical Girl | 俏皮，富有想象力的女孩声音 | 儿童，幻想 |
| `Spanish_StrictBoss` | Strict Boss | 严格，要求高的老板声音 | 商业，教育 |
| `Spanish_ReliableMan` | Reliable Man | 值得信赖，可依靠的男性声音 | 专业，支持 |
| `Spanish_SereneElder` | Serene Elder | 平静，安详的老年声音 | 冥想，智慧 |
| `Spanish_AngryMan` | Angry Man | 沮丧，恼怒的男性声音 | 戏剧，喜剧 |
| `Spanish_AssertiveQueen` | Assertive Queen | 自信，有命令力的女王声音 | 戏剧，幻想 |
| `Spanish_CaringGirlfriend` | Caring Girlfriend | 体贴，深情的女友声音 | 浪漫，恋爱 |
| `Spanish_PowerfulSoldier` | Powerful Soldier | 强壮，勇敢的士兵声音 | 动作，军事 |
| `Spanish_PassionateWarrior` | Passionate Warrior | 激烈，专注的战士声音 | 动作，幻想 |
| `Spanish_ChattyGirl` | Chatty Girl | 健谈，社交的女孩声音 | 喜剧，社交 |
| `Spanish_RomanticHusband` | Romantic Husband | 多情，浪漫的丈夫声音 | 浪漫，家庭 |
| `Spanish_CompellingGirl` | CompellingGirl | 有说服力，有魅力的女孩声音 | 营销，娱乐 |
| `Spanish_PowerfulVeteran` | Powerful Veteran | 经验丰富，强壮的老兵声音 | 军事，戏剧 |
| `Spanish_SensibleManager` | Sensible Manager | 务实，明理的经理声音 | 商业，指导 |
| `Spanish_ThoughtfulLady` | Thoughtful Lady | 体贴，和善的女性声音 | 支持性，建议 |

### 葡萄牙语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Portuguese_SentimentalLady` | Sentimental Lady | 情感丰富，敏感的女性声音 | 戏剧，浪漫 |
| `Portuguese_BossyLeader` | Bossy Leader | 发号施令，威权领导者声音 | 领导力，戏剧 |
| `Portuguese_Wiselady` | Wise Lady | 经验丰富，睿智的女性声音 | 指导，建议 |
| `Portuguese_Strong-WilledBoy` | Strong-willed Boy | 坚定，有决心的男孩声音 | 青年，励志 |
| `Portuguese_Deep-VoicedGentleman` | Deep-voiced Gentleman | 深沉，浑厚的男性声音 | 有魅力，指挥 |
| `Portuguese_UpsetGirl` | Upset Girl | 沮丧，情感化的女孩声音 | 戏剧，现实 |
| `Portuguese_PassionateWarrior` | Passionate Warrior | 激烈，专注的战士声音 | 动作，幻想 |
| `Portuguese_AnimeCharacter` | Anime Character | 夸张的动漫风格声音 | 动画，娱乐 |
| `Portuguese_ConfidentWoman` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 |
| `Portuguese_AngryMan` | Angry Man | 沮丧，恼怒的男性声音 | 戏剧，喜剧 |
| `Portuguese_CaptivatingStoryteller` | Captivating Storyteller | 引人入胜，有魅力的旁白声音 | 有声书，故事讲述 |
| `Portuguese_Godfather` | Godfather | 权威，有力的父亲形象声音 | 戏剧，有力 |
| `Portuguese_ReservedYoungMan` | Reserved Young Man | 安静，内向的年轻男性声音 | 戏剧，现实 |
| `Portuguese_SmartYoungGirl` | Smart Young Girl | 聪明，伶俐的女孩声音 | 教育，青年 |
| `Portuguese_Kind-heartedGirl` | Kind-hearted Girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 |
| `Portuguese_Pompouslady` | Pompous Lady | 自命不凡，傲慢的女性声音 | 喜剧，戏剧 |
| `Portuguese_Grinch` | Grinch | 爱抱怨，调皮的声音 | 喜剧，娱乐 |
| `Portuguese_Debator` | Debator | 争辩，说服的声音 | 辩论，讨论 |
| `Portuguese_SweetGirl` | Sweet Girl | 可爱，迷人的女孩声音 | 儿童内容，浪漫 |
| `Portuguese_AttractiveGirl` | Attractive Girl | 迷人，吸引人的女孩声音 | 娱乐，浪漫 |
| `Portuguese_ThoughtfulMan` | Thoughtful Man | 体贴，睿智的男性声音 | 教育，戏剧 |
| `Portuguese_PlayfulGirl` | Playful Girl | 俏皮，贪玩的女孩声音 | 喜剧，儿童内容 |
| `Portuguese_GorgeousLady` | Gorgeous Lady | 美丽，动人的女性声音 | 浪漫，娱乐 |
| `Portuguese_LovelyLady` | Lovely Lady | 甜美，可爱的女性声音 | 温暖，友好 |
| `Portuguese_SereneWoman` | Serene Woman | 平静，安详的女性声音 | 放松，冥想 |
| `Portuguese_SadTeen` | Sad Teen | 忧郁，青少年声音 | 戏剧，情感 |
| `Portuguese_MaturePartner` | Mature Partner | 精致，成熟伴侣声音 | 浪漫，戏剧 |
| `Portuguese_Comedian` | Comedian | 幽默，娱乐的声音 | 喜剧，娱乐 |
| `Portuguese_NaughtySchoolgirl` | Naughty Schoolgirl | 调皮，贪玩的学生声音 | 喜剧，学校 |
| `Portuguese_Narrator` | Narrator | 专业叙事声音 | 纪录片，旁白 |
| `Portuguese_ToughBoss` | Tough Boss | 严厉，要求高的老板声音 | 商业，戏剧 |
| `Portuguese_Fussyhostess` | Fussy Hostess | 挑剔，要求高的女主人声音 | 喜剧，戏剧 |
| `Portuguese_Dramatist` | Dramatist | 戏剧化，表现力强的声音 | 戏剧，故事讲述 |
| `Portuguese_Steadymentor` | Steady Mentor | 可靠，支持性的导师声音 | 教育，指导 |
| `Portuguese_Jovialman` | Jovial Man | 快乐，友好的男性声音 | 娱乐，休闲 |
| `Portuguese_CharmingQueen` | Charming Queen | 优雅迷人的女王声音 | 戏剧，幻想 |
| `Portuguese_SantaClaus` | Santa Claus | 节日圣诞老人声音 | 节日，儿童 |
| `Portuguese_Rudolph` | Rudolph | 驯鹿声音 | 节日，儿童 |
| `Portuguese_Arnold` | Arnold | 机械，有质感的声音 | 科幻，动作 |
| `Portuguese_CharmingSanta` | Charming Santa | 圆滑，有魅力的圣诞老人声音 | 节日，娱乐 |
| `Portuguese_CharmingLady` | Charming Lady | 优雅，精致的女性声音 | 专业，浪漫 |
| `Portuguese_Ghost` | Ghost | 幽灵，空灵的声音 | 恐怖，悬疑 |
| `Portuguese_HumorousElder` | Humorous Elder | 搞笑，老年人声音 | 喜剧，娱乐 |
| `Portuguese_CalmLeader` | Calm Leader | 沉稳，稳重的领导者声音 | 领导力，指导 |
| `Portuguese_GentleTeacher` | Gentle Teacher | 和善，耐心的教师声音 | 教育，支持性 |
| `Portuguese_EnergeticBoy` | Energetic Boy | 活跃，充满活力的男孩声音 | 青年，体育 |
| `Portuguese_ReliableMan` | Reliable Man | 值得信赖，可依靠的男性声音 | 专业，支持 |
| `Portuguese_SereneElder` | Serene Elder | 平静，安详的老年声音 | 冥想，智慧 |
| `Portuguese_GrimReaper` | Grim Reaper | 黑暗，阴沉的声音 | 恐怖，幻想 |
| `Portuguese_AssertiveQueen` | Assertive Queen | 自信，有命令力的女王声音 | 戏剧，幻想 |
| `Portuguese_WhimsicalGirl` | Whimsical Girl | 俏皮，富有想象力的女孩声音 | 儿童，幻想 |
| `Portuguese_StressedLady` | Stressed Lady | 焦虑，疲惫的女性声音 | 喜剧，现实 |
| `Portuguese_FriendlyNeighbor` | Friendly Neighbor | 温暖，乐于助人的邻居声音 | 社区，家庭 |
| `Portuguese_CaringGirlfriend` | Caring Girlfriend | 体贴，深情的女友声音 | 浪漫，恋爱 |
| `Portuguese_PowerfulSoldier` | Powerful Soldier | 强壮，勇敢的士兵声音 | 动作，军事 |
| `Portuguese_FascinatingBoy` | Fascinating Boy | 迷人，有趣的男孩声音 | 浪漫，青年 |
| `Portuguese_RomanticHusband` | Romantic Husband | 多情，浪漫的丈夫声音 | 浪漫，家庭 |
| `Portuguese_StrictBoss` | Strict Boss | 严格，要求高的老板声音 | 商业，教育 |
| `Portuguese_InspiringLady` | Inspiring Lady | 激励，鼓励的女性声音 | 励志，领导力 |
| `Portuguese_PlayfulSpirit` | Playful Spirit | 快乐，调皮的神灵声音 | 幻想，儿童 |
| `Portuguese_ElegantGirl` | Elegant Girl | 优雅，精致的女孩声音 | 正式，浪漫 |
| `Portuguese_CompellingGirl` | Compelling Girl | 有说服力，有魅力的女孩声音 | 营销，娱乐 |
| `Portuguese_PowerfulVeteran` | Powerful Veteran | 经验丰富，强壮的老兵声音 | 军事，戏剧 |
| `Portuguese_SensibleManager` | Sensible Manager | 务实，明理的经理声音 | 商业，指导 |
| `Portuguese_ThoughtfulLady` | Thoughtful Lady | 体贴，和善的女性声音 | 支持性，建议 |
| `Portuguese_TheatricalActor` | Theatrical Actor | 戏剧化，表现力强的演员声音 | 戏剧，娱乐 |
| `Portuguese_FragileBoy` | Fragile Boy | 敏感，脆弱的男孩声音 | 戏剧，情感 |
| `Portuguese_ChattyGirl` | Chatty Girl | 健谈，社交的女孩声音 | 喜剧，社交 |
| `Portuguese_Conscientiousinstructor` | Conscientious Instructor | 认真，勤勉的讲师声音 | 教育，培训 |
| `Portuguese_RationalMan` | Rational Man | 逻辑，分析性的男性声音 | 教育，商业 |
| `Portuguese_WiseScholar` | Wise Scholar | 知识渊博，睿智的学者声音 | 教育，历史 |
| `Portuguese_FrankLady` | Frank Lady | 直接，坦诚的女性声音 | 喜剧，戏剧 |
| `Portuguese_DeterminedManager` | Determined Manager | 有野心，有冲劲的经理声音 | 商业，励志 |

### 法语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `French_Male_Speech_New` | Level-Headed Man | 冷静，理性的男性声音 | 专业，叙事 |
| `French_Female_News Anchor` | Patient Female Presenter | 清晰，耐心新闻主播声音 | 新闻，广播 |
| `French_CasualMan` | Casual Man | 放松，非正式的男性声音 | 休闲，娱乐 |
| `French_MovieLeadFemale` | Movie Lead Female | 戏剧化，表现力强的女性声音 | 戏剧，娱乐 |
| `French_FemaleAnchor` | Female Anchor | 专业女主播声音 | 新闻，广播 |

### 印尼语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Indonesian_SweetGirl` | Sweet Girl | 可爱，迷人的女孩声音 | 儿童内容，友好 |
| `Indonesian_ReservedYoungMan` | Reserved Young Man | 安静，内向的年轻男性声音 | 戏剧，现实 |
| `Indonesian_CharmingGirl` | Charming Girl | 迷人，吸引人的女孩声音 | 娱乐，浪漫 |
| `Indonesian_CalmWoman` | Calm Woman | 沉稳，平静的女性声音 | 放松，冥想 |
| `Indonesian_ConfidentWoman` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 |
| `Indonesian_CaringMan` | Caring Man | 体贴，支持性的男性声音 | 支持性，家庭 |
| `Indonesian_BossyLeader` | Bossy Leader | 发号施令，威权领导者声音 | 领导力，戏剧 |
| `Indonesian_DeterminedBoy` | Determined Boy | 有野心，有决心的男孩声音 | 青年，励志 |
| `Indonesian_GentleGirl` | Gentle Girl | 轻声细语，和善的女孩声音 | 平静，支持性 |

### 德语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `German_FriendlyMan` | Friendly Man | 温暖，平易近人的男性声音 | 休闲，友好 |
| `German_SweetLady` | Sweet Lady | 宜人，和善的女性声音 | 温暖，支持性 |
| `German_PlayfulMan` | Playful Man | 爱玩，幽默的男性声音 | 喜剧，娱乐 |

### 俄语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Russian_HandsomeChildhoodFriend` | Handsome Childhood Friend | 迷人的青梅竹马声音 | 浪漫，怀旧 |
| `Russian_BrightHeroine` | Bright Queen | 活泼，有力的女主角声音 | 戏剧，动作 |
| `Russian_AmbitiousWoman` | Ambitious Woman | 有冲劲，有决心的女性声音 | 专业，励志 |
| `Russian_ReliableMan` | Reliable Man | 值得信赖，可依靠的男性声音 | 专业，支持 |
| `Russian_CrazyQueen` | Crazy Girl | 疯狂，不可预测的女性声音 | 喜剧，戏剧 |
| `Russian_PessimisticGirl` | Pessimistic Girl | 悲观，消极的女孩声音 | 喜剧，戏剧 |
| `Russian_AttractiveGuy` | Attractive Guy | 迷人，有吸引力的男性声音 | 浪漫，娱乐 |
| `Russian_Bad-temperedBoy` | Bad-tempered Boy | 易怒，暴躁的男孩声音 | 喜剧，戏剧 |

### 意大利语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Italian_BraveHeroine` | Brave Heroine | 勇敢，英雄般的女性声音 | 动作，幻想 |
| `Italian_Narrator` | Narrator | 专业叙事声音 | 纪录片，故事讲述 |
| `Italian_WanderingSorcerer` | Wandering Sorcerer | 神秘，旅行魔法师声音 | 幻想，冒险 |
| `Italian_DiligentLeader` | Diligent Leader | 勤奋，敬业的领导者声音 | 领导力，商业 |

### 阿拉伯语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Arabic_CalmWoman` | Calm Woman | 沉稳，平静的女性声音 | 放松，冥想 |
| `Arabic_FriendlyGuy` | Friendly Guy | 温暖，平易近人的男性声音 | 休闲，友好 |

### 土耳其语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Turkish_CalmWoman` | Calm Woman | 沉稳，平静的女性声音 | 放松，冥想 |
| `Turkish_Trustworthyman` | Trustworthy Man | 可靠，真诚的男性声音 | 专业，商业 |

### 乌克兰语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Ukrainian_CalmWoman` | Calm Woman | 沉稳，平静的女性声音 | 放松，冥想 |
| `Ukrainian_WiseScholar` | Wise Scholar | 知识渊博，睿智的学者声音 | 教育，历史 |

### 荷兰语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Dutch_kindhearted_girl` | Kind-hearted girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 |
| `Dutch_bossy_leader` | Bossy leader | 发号施令，威权领导者声音 | 领导力，戏剧 |

### 越南语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Vietnamese_kindhearted_girl` | Kind-hearted girl | 温暖，富有同情心的女孩声音 | 儿童内容，温暖 |

### 泰语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Thai_male_1_sample8` | Serene Man | 平静，安详的男性声音 | 放松，冥想 |
| `Thai_male_2_sample2` | Friendly Man | 温暖，平易近人的男性声音 | 休闲，友好 |
| `Thai_female_1_sample1` | Confident Woman | 自信，能干的女性声音 | 专业，赋能 |
| `Thai_female_2_sample2` | Energetic Woman | 活跃，充满活力的女性声音 | 励志，能量 |

### 波兰语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Polish_male_1_sample4` | Male Narrator | 专业男性旁白声音 | 纪录片，旁白 |
| `Polish_male_2_sample3` | Male Anchor | 专业男性主播声音 | 新闻，广播 |
| `Polish_female_1_sample1` | Calm Woman | 沉稳，平静的女性声音 | 放松，冥想 |
| `Polish_female_2_sample3` | Casual Woman | 放松，非正式的女性声音 | 休闲，娱乐 |

### 罗马尼亚语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `Romanian_male_1_sample2` | Reliable Man | 值得信赖，可依靠的男性声音 | 专业，支持 |
| `Romanian_male_2_sample1` | Energetic Youth | 活跃，充满活力的年轻人声音 | 青年，励志 |
| `Romanian_female_1_sample4` | Optimistic Youth | 积极，乐观的年轻人声音 | 励志，青年 |
| `Romanian_female_2_sample1` | Gentle Woman | 轻声细语，和善的女性声音 | 平静，支持性 |

### 希腊语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `greek_male_1a_v1` | Thoughtful Mentor | 体贴，睿智的导师声音 | 教育，指导 |
| `Greek_female_1_sample1` | Gentle Lady | 轻声细语，和善的女性声音 | 平静，支持性 |
| `Greek_female_2_sample3` | Girl Next Door | 友好，平易近人的女孩声音 | 休闲，友好 |

### 捷克语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `czech_male_1_v1` | Assured Presenter | 自信，专业的主持人声音 | 演讲，广播 |
| `czech_female_5_v7` | Steadfast Narrator | 可靠，一致的旁白声音 | 纪录片，故事讲述 |
| `czech_female_2_v2` | Elegant Lady | 优雅，精致的女性声音 | 正式，专业 |

### 芬兰语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `finnish_male_3_v1` | Upbeat Man | 开朗，精力充沛的男性声音 | 励志，娱乐 |
| `finnish_male_1_v2` | Friendly Boy | 温暖，平易近人的男孩声音 | 儿童内容，友好 |
| `finnish_female_4_v1` | Assertive Woman | 自信，坚定的女性声音 | 专业，赋能 |

### 印地语声音

| voice_id | 名称 | 描述 | 最佳用途 |
|----------|------|-------------|----------|
| `hindi_male_1_v2` | Trustworthy Advisor | 可靠，睿智的顾问声音 | 指导，建议 |
| `hindi_female_2_v1` | Tranquil Woman | 平静，安详的女性声音 | 放松，冥想 |
| `hindi_female_1_v2` | News Anchor | 专业新闻主播声音 | 新闻，广播 |

---

## 声音参数

### VoiceSetting 数据类

```python
from utils import VoiceSetting

voice = VoiceSetting(
    voice_id="male-qn-qingse",  # 必填：声音 ID
    speed=1.0,                   # 可选：0.5（较慢）到 2.0（较快），默认 1.0
    volume=1.0,                  # 可选：0.1（较轻）到 10.0（较响），默认 1.0
    pitch=0,                     # 可选：-12（较深）到 12（较高），默认 0
    emotion="calm",           # 可选：happy, sad, angry, fearful, disgusted, surprised, calm, fluent, whisper
)
```

### 参数指南

**语速 (Speed)**
- 0.75：较慢，有意放缓的语速（新闻，教程）
- 1.0：正常节奏（大多数内容）
- 1.25：稍快（活力内容）
- 1.5+：快速（时效性内容）

**音量 (Volume)**
- 0.8-1.0：正常收听水平
- 1.0-1.5：较响以吸引注意
- < 0.8：较轻，亲密感

**音调 (Pitch)**
- -6 到 -3：较深，更有权威感
- 0：自然音调
- +3 到 +6：较高，更有活力

**情绪 (Emotion)**
- `calm`：平静，中性语调
- `fluent`：流畅，自然语调
- `whisper`：低语，柔和语调
- `happy`：愉快，乐观语调
- `sad`：忧郁，沉闷语调
- `angry`：沮丧，强烈语调
- `fearful`：焦虑，紧张语调
- `disgusted`：厌恶，反感语调
- `surprised`：惊讶，赞叹语调


## 自定义声音

### 声音克隆

从音频样本创建自定义声音，以获得独特的品牌声音。

**要求：**
- 源音频：10 秒到 5 分钟
- 格式：mp3、wav、m4a
- 大小：最大 20MB
- 质量：清晰，无背景噪音，单一说话人

**最佳实践：**
- 使用 30-60 秒清晰语音
- 包含多样的语调和情绪
- 在安静环境中录制
- 全程音量一致

### 声音设计

通过文本描述生成新声音，适用于创意项目。

**使用场景：**
- 现有声音无法满足需求
- 需要独特的角色声音
- 在全面声音克隆前的原型设计

**提示词指南：**
- 包括：性别、年龄、声音特征、情绪基调、用途
- 详细说明节奏、语调和目标受众
- 示例："温暖、祖母般的声音，节奏柔和，非常适合睡前故事"