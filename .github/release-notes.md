## 附魔破解器 iOS 版（未签名 IPA）

[Earthcomputer/EnchantmentCracker](https://github.com/Earthcomputer/EnchantmentCracker) 的原生 iOS 移植：
全部算法用 Swift 重写，界面用 SwiftUI 重写，由 GitHub Actions 的 macOS 运行器自动编译打包。

- 要求：**iOS 16.0 及以上**，arm64 设备（iPhone / iPad）
- 支持 Minecraft **1.8 ~ 1.21.11** 的附魔台规则
- 功能：XP 种子破解（2³² 全量扫描，多线程）→ 玩家种子反推 → 附魔计算器（算出还要丢几件物品）

### 安装（未签名，需要自己签名）

1. **Sideloadly**（Windows / macOS）：连上 iPhone，把本 IPA 拖进 Sideloadly，填 Apple ID，Start。
   免费 Apple ID 签名 7 天后过期，到期重装即可。
2. **AltStore / SideStore**：同样用 Apple ID 自签，可自动续签。
3. **TrollStore**（iOS 14.0 ~ 17.0）：直接安装未签名 IPA，不过期、不需要 Apple ID。
4. 其他国产助手（爱思助手等）的 "IPA 签名" 功能同理。

> 自签只是本机签名，不会上传任何东西，也不需要 688 元的开发者账号。

### 使用步骤

1. 附魔台（不要放物品）记录 **书架数量** + **三个附魔格的经验等级**，填进 App 点「检查」。
2. 换一个书架数量再看一次，重复 2~3 次，直到「可能的种子数」变成 1 个（约 10~40 秒/次，有进度条）。
3. 再打开一次附魔台，把两次的 XP 种子填进「XP种子 1/2」，点「计算种子」得到玩家种子。
4. 切到「附魔计算器」，选物品、书架数、玩家等级、目标附魔，点「计算」得到「丢几件物品 / 用多少书架 / 第几格」。
5. 按提示丢物品、附魔，点「完成」，种子和等级会自动推进。

本构建完全由源码自动生成，源码与验证工具同在本仓库。GPL-3.0。
