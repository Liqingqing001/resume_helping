# Edge 常驻会话

适用于用户已授权通过已登录 Edge 操作招聘网站。开始前先看本次工具是否仍能访问已有执行会话；磁盘旧 ID 不是进程存活证明。

确实没有客户端时，在个人工作区启动一次 `node <技能路径>/scripts/cdp-inspect.cjs`，使用可持续 stdin 的执行会话，例如 `exec_command` 的 `tty:true`。保留 session_id，通过同一 `write_stdin` 发送以换行结束的 JSON；不能每站另开进程。

```json
{"id":"pages","action":"list"}
{"id":"resume","action":"inspect","url":"https://join.qq.com/resume.html","open":true,"foreground":true}
{"id":"check","action":"evaluate","url":"https://join.qq.com/resumeedit.html","expressionFile":"tmp/check.js","foreground":true}
```

默认本机 WebSocket 为 `ws://localhost:9222/devtools/browser`。实际地址不同可在启动前设置 `EDGE_CDP_URL`；不要循环切换地址。首次连接核实 Edg/ 浏览器版本；`ready` 事件只表示脚本待命，`connected` 才表示连接成功。HTTP调试列表404并不证明WebSocket不可用。

- `open:true` 仅在没有匹配页面时创建标签。页面加载后再次只读核实，不自动再开一个。
- `list` 返回页面路径，去掉 query/hash；登录跨域跳转后用它找回页面。它不新建连接或附加会话。检查结果中可能有与任务无关的页面，不继续读取那些页面。
- `foreground:true` 使用同一连接激活当前标签，避免后台动画/计时器延迟。刷新网页与重连CDP不同；确有需要才刷新，先保存未提交业务草稿。
- `inspect` 输出正文，含隐私的简历页不要用它。改用 `evaluate` 仅返回必要字段、数量或布尔结果。
- `expressionFile` 必须是当前工作区内已审核JS。异步脚本用 `(async()=>{...return JSON.stringify(result)})()`；不要对未完成的 Promise 调用 JSON.stringify。
- `saveResultTo` 只接受字符串。`encoding:base64` 将字符串解码为二进制保存；文件仍必须在工作区。敏感值不得因此写进同步目录。
- 超时先查结果，不重复上传/保存。连接真正断开后脚本不自动重连，报告明确原因再处理。
- 一个任务结束前保持客户端，不主动解除标签附加。必须释放时发送 `{"action":"quit"}`。旧工具会话不保证跨新聊天可访问。

脚本修改不会热加载到已运行进程。先完成当前任务，再在下次启动使用新版；不能为了新功能擅自重新触发调试确认。
