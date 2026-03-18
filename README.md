# 💌 SoulSeal (靈魂封緘) - 基於 LLM 與生成式 AI 之沉浸式日記系統

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white) ![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white) ![Deno](https://img.shields.io/badge/Deno-000000?style=for-the-badge&logo=deno&logoColor=white)

### 📖 專案概述

在快節奏的現代生活中，自我覺察與情緒紀錄往往因為「缺乏回饋感」而難以持續。本專案開發了一個自動化的「AI 靈魂知己」，透過大語言模型 (LLM) 與圖像生成技術，將使用者瑣碎的日常低語，精準轉化為具備文學美感的「隱喻故事」與專屬的「視覺藝術郵票」。

本系統實現了從 **語意解析 (Prompt Engineering)**、**跨平台前端 (Flutter App)**、**遊戲化機制 (Gamification)** 到 **無縫雲端邊緣計算 (Edge Functions)** 的全流程閉環。

---

### 📈 核心價值與 UX 突破

* **情感具象化與留存 (Retention)：** 獨創 54 項多維度「靈魂里程碑」（涵蓋時間、頻率、節慶彩蛋），結合虛擬經濟系統（旅幣與靈魂雜貨舖），大幅降低傳統日記產品的流失率 (Churn Rate)。
* **零摩擦體驗 (Zero-Friction UX)：** 實作本地端快取機制 (`cached_network_image` & `shared_preferences`)，降低 API 重複請求成本，圖片加載速度提升。
* **高轉換率架構 (High Conversion)：** 支援「無痛訪客模式」，並透過雲端腳本實現訪客數據到正式帳號的毫秒級無縫遷移，確保使用者體驗 Aha Moment 後的極致轉換。

---

### 🛠️ 技術架構與核心模組

#### 1. AI 雙引擎架構 (LLM & Text-to-Image)
系統採用雙層 AI 處理架構，兼顧文本深度與視覺純粹性：
* **第一層 (Text-to-Text - GPT-4o-mini)：** 邏輯推理中樞。透過嚴謹的 System Prompt 限制，穩定解析使用者日記，輸出標準化的「三段式結構」（隱喻故事、金句、DALL-E 繪圖精確指令）。
* **第二層 (Text-to-Image - DALL-E 3)：** 視覺生成器。注入嚴格的負面提示詞 (Negative Prompts)，強制過濾圖片中的雜訊與文字符號，生成純粹的意境郵票，並自動轉存至 Supabase CDN。

#### 2. 雲端原生架構與邊緣計算 (Supabase BaaS)
* **關聯式資料與資安 (PostgreSQL & RLS)：** 透過 Row Level Security (RLS) 確保每一篇靈魂日記的絕對隱私，實現用戶資料的租戶隔離。
* **無縫數據遷移 (Deno Edge Functions)：** 撰寫 `migrate-guest-data` 腳本部署於邊緣節點。透過 Server-side 繞過 RLS，安全且具備原子性 (Atomicity) 地合併訪客金幣與歷史日記至全新 Google 帳戶。

#### 3. 模組化前端架構 (Modular UI Architecture)
* **職責分離 (Separation of Concerns)：** 揚棄單一神怪物件 (God Object)，將系統拆分為 `screens` (視圖層)、`services` (業務邏輯層) 與 `constants` (全域配置)，確保程式碼的高可維護性與擴展性。

---

### 📂 目錄結構

```text
├── lib/
│   ├── main.dart                  # 程式進入點與主題路由設定
│   ├── constants_example.dart     # 環境變數與 API Keys 配置範本 (防呆機制)
│   ├── screens/                   # 核心 UI 視圖層 (MVC - View)
│   │   ├── achievement_page.dart  # 靈魂里程碑 (成就系統)
│   │   ├── detail_page.dart       # 日記詳情頁
│   │   ├── diary_page.dart        # 核心：LLM 對接與日記撰寫邏輯
│   │   ├── history_page.dart      # 雲端數據流讀取與快取展示
│   │   ├── login_page.dart        # 登入與訪客驗證邏輯
│   │   ├── profile_page.dart      # 用戶檔案與數據統計
│   │   ├── shop_page.dart         # 靈魂雜貨舖 (虛擬商城)
│   │   └── sip_with_sage_page.dart# 智者對話 (AI 延伸互動)
│   ├── services/                  # 業務邏輯與第三方 API 串接 (MVC - Controller)
│   │   └── notification_service.dart # 本地推播通知管理
│   └── widgets/                   # 高頻複用 UI 元件庫
│       ├── soul_loading.dart      # 客製化全局載入動畫
│       └── story_card.dart        # 封裝後的卡片展示元件
