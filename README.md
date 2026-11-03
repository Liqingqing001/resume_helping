# Resume Helping

供 Codex 使用的求职助手 Skill：维护本地个人资料与简历版本，通过用户已登录的 Microsoft Edge 更新招聘官网的 **PDF附件和在线表单**，并沉淀各网站操作。

这是由真实操作整理的工作流和辅助脚本，不是一键群投机器人。腾讯、字节、京东、美团的附件与表单更新已有实测；其他平台的状态以 `job-application-assistant/references/platforms.md` 为准。网页变化后需要重新检查控件。

## 安装与准备

1. 下载或克隆本仓库。将 `job-application-assistant` 文件夹复制到 `%USERPROFILE%\.codex\skills\`。如已有同名技能，先备份并合并自己的配置。
2. 在自己的求职工作区复制 `profile.example.json` 为 `profile.local.json`，填写自己的资料路径、Overleaf项目和输出位置；不要把真实资料写进本仓库的示例或技能文件。
3. 准备自己的简历、已确认经历和证书、可选照片。普通资料可放本地工作区，身份证等敏感信息建议放同步目录之外。提供空值或待确认标记，不让助手猜测。
4. 使用已登录的 Edge，按浏览器提供的方式启用本机远程调试。首次连接若出现允许提示，由用户处理。不要开放公网端口，也不要复制登录Cookie。
5. 告诉 Codex 工作区位置，调用 `$job-application-assistant`，指定本次要更新的平台和范围。例如：

> 读取我的 profile.local.json，用最新简历更新腾讯和字节的附件及在线表单。简历正文和文件名不写求职意向。先备份，保存后刷新核对，不投递岗位。

## 如何运行同一条 Edge 连接

需要 Node.js，且 `node -p "typeof WebSocket"` 返回 `function`。脚本没有npm依赖。Windows使用PowerShell；需要Python时用 `py`。

在工作区内启动一次，保持进程的标准输入打开：

```powershell
node .\job-application-assistant\scripts\cdp-inspect.cjs
```

通过这个进程的stdin发送JSON行，所有网站复用同一进程。示例：

```json
{"id":"inspect-1","action":"inspect","url":"https://join.qq.com/resume.html","foreground":true}
{"id":"inspect-2","action":"inspect","url":"https://jobs.bytedance.com/campus/resume/view","foreground":true}
```

默认入口为 `ws://localhost:9222/devtools/browser`；若浏览器实际入口不同，启动前设置 `EDGE_CDP_URL`。脚本仅接受本机WebSocket，并核实连接的是Edge。`open:true`仅在没有匹配标签时新开一个；重复标签需指定更精确URL。`foreground:true`激活已匹配标签。

`evaluate`从工作区内的`expressionFile`执行JavaScript，可按`saveResultTo`保存字符串；`encoding:"base64"`解码二进制下载。只能运行自己审核过、且属于当前授权任务的代码。**inspect会返回可见正文：身份证等私密表单应使用只返回必要字段/布尔结果的evaluate，避免全文进入日志。**

不要用短命管道每站启动一次。不要因为HTTP `/json/version` 404就判定调试不可用。连接失败后脚本不会自动重连；确认原因与浏览器状态，再决定恢复。运行中的旧脚本不会热加载修改。

## 正常工作流程

读取资料与本次展示规则 → 备份当前版本/在线业务字段 → 修订并编译检查PDF → 更新附件和对应在线条目 → 检查解析结果、日期、学历、职位、链接及字数 → 正常保存 → 刷新回读核验 → 更新站点操作记录和个人同步台账。

PDF、照片与证件路径由用户自己的配置决定。文件名可用“姓名_简历.pdf”，版本号放在目录中。实习正文一般只写年月；如果官网强制精确日期，以已知真实日期和控件精度处理。到岗时间是求职承诺，只有用户明确授权时才选最近可用日期，不能把个别用户的选择当所有人的默认值。

删除求职意向不等于删除真实实习职位。公司集团背景要有依据，不能替换实际雇主。更新个人简历也不等于修改历史申请，更不等于授权新投递或给招聘者发消息。

## 文件与隐私

- `SKILL.md`：任务入口和授权范围。
- `references/workflow.md`：字段匹配、版本、保存核验。
- `references/platforms.md`：平台路径及实测状态。
- `references/browser-session.md`：同一条 Edge 连接、登录跳转和恢复。
- `references/overleaf.md`：在线 LaTeX 修订、编译与 PDF 交付。
- `scripts/cdp-inspect.cjs`：常驻CDP客户端。
- `scripts/recover-bytedance-render.js`：严格限定字节简历页的已知动画占位恢复。
- `scripts/private-profile.ps1`：Windows DPAPI资料摘要与面向指定HTTPS页面的加密传输。它不负责首次导入；已有容器必须由本机同一Windows用户使用相同entropy加密。不得把原始证件写进命令行或同步目录。

DPAPI容器约定entropy为`job-application-assistant/profile/v1`，UTF-8 JSON包含`canonical_fields`、`source_url`、`review_notes`。首次导入时由助手在内存中接收已授权来源、用`ProtectedData.Protect(..., CurrentUser)`密封后写文件；仓库不提供真实资料或通用密钥。更换系统用户通常无法解密原容器。

## 检查与限制

```powershell
node --check .\job-application-assistant\scripts\cdp-inspect.cjs
node .\job-application-assistant\scripts\test-cdp-session.cjs
```

测试使用假WebSocket，不连接浏览器；验证单连接、页面会话复用、同连接前台激活以及不自动重连。它不证明所有网站都能自动填写。验证码、短信验证和账号登录由用户处理。网页模型/DOM接口是局部恢复手段，需检查实际结构，不保证长期稳定。

本仓库不包含作者的简历、照片、证件、联系方式、私有Overleaf项目地址、Cookie、投递记录或会话文件。发布前应再次扫描目录，且只提交明确允许的技能文件。

### 登录跳转查找

新版客户端还支持 `{"action":"list"}`，在同一连接中返回打开页面的路径（省略查询参数和片段），用于找回跳到登录域名的标签页。该动作不重新附加页面，不新建连接。运行中的旧客户端不会热加载；不要为了新功能在任务中重启连接。

