# Overleaf 更新与 PDF 交付

项目地址从用户自己的配置读取。先确认项目、当前选中文件、主编译入口及用户已确认正文，不复用作者项目ID或上次生成的旧源码。

1. 保留当前本地编辑器，原地修订其 `.tex`。在线编辑前备份完整当前文档和源码ZIP。CodeMirror的可见DOM可能虚拟化，不能把 `.cm-content.innerText` 当完整源码。
2. 仅在实际观察到 `.cm-content.cmView.view.state.doc` 后，用 `state.doc.toString()` 读取全文。写入前比较刚备份的文本，若已被修改就先核对差异；用已观察的 `view.dispatch({changes:{from:0,to:view.state.doc.length,insert:desired}})` 更新，并读回验证。CRLF/LF差异可规范化比较，不能掩盖正文差异。
3. 原模板、字体和XeLaTeX配置已经可用时沿用，别每次重建工程。用户当前本地编辑器支持内置编译工具时，也在保存后编译原项目检查。
4. 在线通过“Recompile”正常编译。核对错误、警告、页数和实时“Download as PDF”链接；旧构建地址不代表新版本成功。
5. 从真实页面下载链接同源fetch，检查HTTP状态、ZIP的PK及PDF的 `%PDF-` 文件头。再次下载源码ZIP，对比其中主文件，证明修改已同步云端。
6. PDF按配置命名，版本信息可放目录；不要仅重命名旧文件。检查正文、中文字形/提取、嵌入字体、作品超链接，并逐页渲染检查裁切、拥挤、重叠。
7. Fandol等CJK字体的原始PDF可能缺失 `/ToUnicode`。仅在确认采用Adobe/GB1标准CID、Identity-H且确实缺映射时，可对交付副本补标准Adobe-GB1-UCS2映射。保留原件，比较内容流及渲染前后像素；不得对未知编码盲补。

只在上述结果通过后将PDF标记可投递，并以该确切文件同步平台。记录哈希、源码版本、编译与版面检查结果。在线显示离线时先备份，再刷新同一项目页恢复；不要因此重连Edge。
