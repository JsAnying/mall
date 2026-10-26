---
name: 拾光闲置
description: 浅绿灰底与白色内容面上的中文闲置商品界面
colors:
  ground: "#f3f5f4"
  surface: "#ffffff"
  raised: "#f6f8f7"
  active: "#e8eeeb"
  text: "#202923"
  text-secondary: "#5d6861"
  line: "#e3e8e5"
  control-border: "#b8c3bc"
  accent: "#275c45"
  accent-soft: "#edf3ef"
  primary: "#253d30"
  danger: "#a32d32"
  danger-soft: "#fff2f2"
typography:
  headline:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "28px"
    fontWeight: 650
    lineHeight: 1.4
    letterSpacing: "-0.02em"
  title:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.6
  product-title:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.7
  label:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.6
  price:
    fontFamily: '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif'
    fontSize: "24px"
    fontWeight: 650
    lineHeight: 1.3
    letterSpacing: "-0.02em"
rounded:
  badge: "4px"
  chip: "6px"
  control: "8px"
  image: "12px"
  surface: "16px"
spacing:
  compact: "4px"
  small: "8px"
  control-gap: "12px"
  inset: "16px"
  medium: "20px"
  gap: "24px"
  large: "32px"
  section: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    padding: "10px 20px"
  button-primary-hover:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
  button-text:
    textColor: "{colors.accent}"
  input-search:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.control}"
    padding: "4px 4px 4px 16px"
  navigation-current:
    textColor: "{colors.text}"
  chip-filter:
    backgroundColor: "{colors.active}"
    textColor: "{colors.text}"
    rounded: "{rounded.chip}"
    padding: "6px 10px"
  workspace-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.surface}"
    padding: "32px"
  availability-note:
    backgroundColor: "{colors.raised}"
    textColor: "{colors.text}"
    rounded: "{rounded.control}"
    padding: "16px"
---

# Design System: 拾光闲置

## Overview

**Creative North Star: "绿灰纸框中的白色集市"**

浅绿灰地面包住白色内容面，深绿承载价格、链接和当前操作。中文系统字体、细边线与真实商品素材构成安静、清楚、方便比较的界面；主内容区有明确边界，商品卡本身保持轻量。

保留“拾光闲置”名称、既有 SVG 标志及本地素材。示例商品、未开放服务、请求失败等信息使用可读的正文与状态面表达。此文档从已实现代码提取；首页的 framed-sheet 方向和 seed 1103829787 记录在 `.impeccable/surfaces/storefront.md`，不约束所有未来页面必须采用首页构图。

**Key Characteristics:**

- 浅绿灰背景与白面分层。
- 中文系统字体、清晰的价格和商品信息层级。
- 大内容面、轻商品卡、细边线和适度圆角。
- 源顺序网格与可见的键盘焦点。
- 既有图片、明确的缺图回退和服务状态。

## Colors

低饱和绿灰组成中性底色，深绿用于主要操作和信息强调，错误状态独立使用暗红。

### Primary

- **深林绿（primary）**：发布与主要提交动作的实色底；悬停改为 accent。
- **松叶绿（accent）**：商品价格、文字链接、当前导航下划线和焦点轮廓。
- **浅绿提示面（accent-soft）**：撤销提示与 Element Plus 浅色强调面。

### Neutral

- **绿灰地面（ground）**：整页背景与页头。
- **白色纸面（surface）**：商品主区、工作区、账号表单与浮层。
- **雾白面（raised）**：图片底、可用性说明、次要状态面。
- **灰绿选中面（active）**：已选分类、筛选标签和账号介绍面。
- **墨绿正文（text）**：标题、正文和选中项。
- **苔灰副文（text-secondary）**：说明、地点、原价与辅助导航；源码中的 muted 与其同值。
- **浅灰绿线（line）**：内容面边框、分隔线。
- **灰绿控件线（control-border）**：搜索和原生排序控件边框。

错误信息使用 **暗红（danger）** 与 **浅红面（danger-soft）**。Element Plus 的既有主色阶梯与禁用状态保留在 `src/assets/main.css`，本规范不另造第二套调色来源。

**The Role Color Rule.** 价格、主要操作、当前状态沿用现有深绿分工；错误信息使用错误色，并同时提供文字说明。

## Typography

**Body Font:** 前置令牌所列的中文系统字体栈；标题、标签、数字共用此栈，未下载字体，也未建立独立展示字体。

**Character:** 中文正文紧凑而清楚，层级依赖字号、字重与留白。价格使用等宽数字特性，商品标题允许两行，不通过大段宣传文字压住商品信息。

### Hierarchy

- **Headline**：首页标题角色；窄屏（600px 以下）改为 24px。
- **Title**：商品区标题角色；窄屏首页为 17px。账号表单标题为 24px，详情标题为 26px，随各自断点收缩。
- **Body**：正文与输入角色；说明段落在详情中使用 1.9 行高。
- **Product title**：商品卡两行标题，最小内容高度 48px。
- **Label**：导航、商品地点等辅助信息；表单标签为 14px、550 字重。
- **Price**：商品卡强调价格；450px 以下为 22px。详情价格为 36px，700px 以下为 32px。

现有 11–12px 品牌副行、数量、说明和手机辅助行是局部实现；手机辅助字号偏多的审查提示仍保留，不将其定为未来正文或交互标签的推荐下限。

**The Shared Chinese Type Rule.** 沿用同一中文字体栈和语义层级；价格保持 `tabular-nums`，不新增仅用于装饰的展示字体。

## Layout

页头、主体与页尾共享最大内容宽度（1280px），使用 `min(1280px, calc(100% - gutter * 2))` 居中。外侧 gutter 为桌面 32px、1100px 以下 24px、600px 以下 16px。主要间隔为 24px，手机为 16px；4/8/12/16/20/24/32/48px 均已在实现中复用，属于实用步阶而非严格等比比例。

首页桌面使用 184px 分类侧栏与剩余商品主区，1100px 以下侧栏为 172px；800px 以下分类变为横向可滚动入口，主区单列排列。商品网格直接按数据源顺序生成：1200px 以上四列，1200px 以下三列，600px 以下两列。网格间距依次为行/列 32/24px、800px 以下 24/16px、600px 以下 24/12px；不使用脚本按列重新排列商品。

白色商品主区内边距为 24px，1100px 以下 20px，600px 以下 16px。工作区使用主栏与 280px 辅栏，900px 以下为单栏；主栏内边距为 32px，手机为 20px。账号页最大宽 1040px，650px 以下由双栏转单栏；详情页在700px 以下由双栏转单栏。这些是各自已实现页面的响应式行为，不是新页面只能采用的构图。

**The Source Order Rule.** 商品的视觉、DOM 与键盘浏览顺序保持一致；响应式只改变网格列数。

## Elevation & Depth

内容面和商品卡静态时使用背景色、边框与间距区分层次，不为卡片增加投影。自定义 CSS 投影仅用于搜索建议和分类浮层；现有 SVG 缺图示意素材内部的投影属于插画内容，不是界面表面的层级令牌。Element Plus 组件继续保留自身必要状态样式。

### Shadow Vocabulary

- **搜索建议浮层**：`0 12px 36px #182c1f24`，定位在搜索框下方，z-index 为 50。
- **分类浮层**：`0 12px 40px #182c1f24`，分类面板 z-index 为 20；桌面侧向展开，手机在入口下方展开。

**The Flat Surface Rule.** 主内容与商品卡保持平面；已有浮层投影用于表达菜单与页面的覆盖关系。

商品照片悬停以 300ms 和既有缓动轻微放大至 1.035，图片内箭头以 160ms 显现；搜索边框为 160ms，分类底色为 150ms。加载图片使用 1.4s 透明度动画。减少动态效果偏好会关闭过渡、动画和平滑滚动。

## Shapes

大内容面使用 surface 圆角，图片和搜索建议使用 image 圆角，按钮与输入使用 control 圆角；小筛选标签使用 chip 圆角，成色标签使用 badge 圆角。商品头像与图片内箭头为正圆。内容面和控件使用细实线边框，图片按容器裁切，商品卡本体没有额外包边。

## Components

### Buttons

主要动作稳重、次要动作轻量。主要链接使用白字深林绿底、control 圆角与 10px 20px 内边距，最小高度 44px；页头发布入口使用相同颜色与圆角，水平内边距为 16px。Element Plus 提交按钮复用主要底色，悬停使用 accent。

文字链接使用 accent，悬停加下划线；返回链接使用副文色。全局可聚焦控件的键盘焦点为 2px accent 轮廓、4px 偏移。禁用态保留明确文字与不可用鼠标指针；加载提交显示动作进度，账号表单提供停止等待入口。

### Chips

已应用筛选使用 active 底、chip 圆角与 6px 10px 内边距，并附移除图标和可访问名称。桌面最小高度 36px，800px 以下为 44px。分类类型按钮使用 control 圆角；悬停或已选时使用 active 底与 accent 字色。筛选改变写入 URL，移除支持撤销。

### Cards / Containers

白面大容器使用细 line 边框和 surface 圆角；工作区、账号、详情与商品区按内容选择各自内边距。商品卡为整张可聚焦链接：图片长宽比 1.1、image 圆角；成色位于图片左上，价格优先于原价与地点，卖家位于底部。标题限制两行；悬停标题变绿，图片内箭头在悬停和键盘聚焦时出现。

继续使用已有本地商品素材。图片等待时显示 active 底的加载面；失败时显示已有 SVG 示意图并明确标记“图片暂不可用 · 示意图”。不把示例数据包装成已验证真实交易。

### Inputs / Fields

页头搜索框使用白面、control-border 边框、control 圆角，最小高度 48px；内部输入为 14px，聚焦区域使用 accent 边线与 1px 外轮廓。搜索建议显示近期搜索，支持清空与撤销、Enter 搜索、Esc 关闭；`/` 和 Ctrl/Cmd+K 可聚焦搜索。

账号及工作区沿用 Element Plus 输入、选择器、表单验证；输入和选择器最小高度 44px，标签与提示明确关联。错误面使用 danger 色文字、danger-soft 背景和文字重试入口，表单输入保留；未开放服务使用 raised 状态面和解释文案。

### Navigation

页头当前入口、商品分类页签与账号页签以正文色、较高字重和 2px accent 下划线表示当前项。侧栏分类选中使用 active 底；鼠标精细指针可悬停展开，也可点击或键盘 Enter 展开。Esc 关闭分类浮层并恢复触发按钮焦点；移出焦点后关闭。手机分类横向滚动，浮层宽度随容器、最大高度 65vh，内容可滚动。

800px 以下页头搜索移到第二行，次导航隐藏；手机分类仍提供完整类型。共享跳过导航链接在聚焦时出现。辅助功能快捷入口位于页面流中的页尾，不覆盖手机商品。

## Do's and Don'ts

### Do:

- **Do** 复用 `src/assets/main.css` 的颜色变量和中文字体栈，让标题、表单和商品保持一致。
- **Do** 保持商品源顺序、可见焦点和窄屏可操作的分类入口。
- **Do** 在商品图片旁保留价格、成色和地点，并清楚标记示例与未开放服务。
- **Do** 保留图片失败回退、撤销提示以及减少动态效果偏好。

### Don't:

- **Don't** 将首页构图、framed-sheet 名称或随机种子变成所有未来页面的唯一版式。
- **Don't** 为静态商品卡添加菜单式阴影，或把插画内部投影当作界面投影令牌。
- **Don't** 将当前局部 11–12px 辅助文字当作未来正文和交互标签的推荐字号。
- **Don't** 依靠颜色独自传达错误、当前筛选或服务是否可用。
