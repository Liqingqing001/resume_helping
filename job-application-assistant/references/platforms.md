# 招聘平台路径与验证边界

记录日期：2026-11-03。登录状态、页面结构和职位资格须当场核实。以下是操作经验，不包含作者个人资料，也不保证网站永久兼容。

## 通用执行

通过同一个常驻 Edge 客户端操作全部平台。每站先检查当前默认简历，备份业务字段，再更新附件和对应在线字段，保存后刷新回读。自动解析会错分栏目或漏掉字段。只点击个人简历保存，不把成功页通用“提交成功”文案视为新增岗位投递。

网站跳转导致 URL 匹配不到时，新版客户端支持 `{"action":"list"}`：复用当前连接列出页面路径，隐藏 query/hash，便于找回登录跳转页。此功能已离线测试；运行中的旧客户端不能热加载，不能为了加载功能擅自重连。

## 腾讯：附件及结构化字段更新已实测

- 入口 `https://join.qq.com/resume.html`，编辑 `/resumeedit.html`。
- 附件 `#resume-upload[type=file]`，上传后可以选择解析，但有可靠旧表单时可仅上传并单独更新条目。
- 已观察 Vue 编辑器在附件输入框祖先，组件名 `resumeedit`。只读取所需业务字段，勿导出整个 `$data`。
- 实习 `practiceList`：`employerName/practicePosition/StartEndTime/sofarChecked/workSummary`；项目 `projectList`：`projectName/projectRole/StartEndTime/sofarChecked/projectSummary`。新条目优先由页面添加控件产生 ID。
- “至今”对应结束日期空字符串和 `sofarChecked`；其他站不沿用此编码。
- `supplement` 是补充文字，别遗留旧求职意向。网站要求到岗时间时先读取用户授权，不能自行承诺。
- 保存为“提交简历”→“确认保存简历吗？”→“确认”。成功路由 `/succeed.html?type=0`；重新打开编辑页核验。
- 上传后先记录新的附件引用摘要。刷新后显示名称可能被服务器改为“姓名的简历”，不能只靠文件名判断；核对引用和业务字段持久值。

## 字节：附件及结构化字段更新已实测

- 入口 `https://jobs.bytedance.com/campus/resume/view`，编辑 `/campus/resume/edit`。
- 附件 `input[type=file][data-cy=inputUpload]`。上传后“解析并覆盖”是额外动作；已逐项维护的表单不必再覆盖。
- 模块 `.applyFormModuleWrapper-windows`，标题 `.applyFormModuleWrapper-text`；重复卡片 `.register-form-group-wrapper`。
- 输入框 `data-form-field-id`：实习 `company/title/start_end_time/desc`；项目 `name/role/start_end_time/link/desc`。自我评价以 `data-form-field-name=self_evaluation` 定位。
- 普通文本框使用原生 value setter 和冒泡 input/change 后核验；日期 UI 到月，选择真实月份和“至今”。学历按实际“本科”等标签匹配，不能跨站复用枚举数字。
- 证书名称是可输入的建议框。**看到输入文字不代表已经提交到字段模型**：2026-11-03曾保存提示“证书名称为必填”。先选建议项或提交自由输入；必要时核实该控件 React 祖先的 `suggestions`、字段名 `name` 和已绑定 `onChange`，再调用真实字段变更回调，随后正常保存和回读。不要关闭验证或只改DOM。
- 保存→预览，刷新后检查教育、公司、职位、日期、正文、证书、项目链接及附件名称。
- 预览字段标题 `.resumeViewItem-title`，值 `.resumeViewItem-content`。可以白名单读取当前组件 `resumeDetail`，勿导出身份字段。
- 后台动画空白先用 `foreground:true`。仅已知 rc-queue-anim 占位问题可运行 `scripts/recover-bytedance-render.js`；此脚本不绕过登录或表单验证。

## 京东：附件与结构化表单保存回读已实测

- 入口 `https://campus.jd.com/`。登录后用户名下拉→“我的简历”，实际路由 `/#/resume?type=present`。
- 用户名 `.ant-dropdown-trigger`，mouseover 可展开菜单；菜单动作后读实际路由，不重新搜索旧版入口。
- 模块 ID：`attachment/info/edu/experience/campus/program/skill/upoad`。附件 `#attachment input[type=file]`；照片 `#info input[type=file]`。不要按全页 input 索引上传。
- 上传会问是否自动填写；“否，仅上传附件”保留旧表单，之后需单独同步业务字段。“是，上传并解析”会覆盖原信息，须有备份并逐项纠错。
- 实测旧解析曾把真实项目放进“校园经历”，而“项目经历”为空。先备份，移到正确栏目并清除旧条目。
- 已观察 React 简历组件业务数组：`internshipInfos/schoolExpericeInfos/programExperienceInfos/skillInfos/educationInfos`。实习 `companyName/jobTitle/startDate/endDate/jobDescription`；项目 `programName/role/startDate/endDate/programDesc`；证书 `skillType/skillName`。枚举须按页面标签核实。
- 新条目组件会生成 `self_` ID，不能冒用已有服务器 ID。业务状态修改后应核对实际控件，最终走网站保存与校验。
- 删除按钮使用 **`.am-modal-wrap`** 确认框，非 `.ant-modal`。确认一条并回读数量后再删下一条，避免堆叠对话框；删除可能立即保存到服务器。
- 2026-11-03该实习起止日期要求精确日，未提供“至今”。不能擅造离职日；需与用户确定截至日说明或暂不保存该条目。项目日期优先保留该站原值，来源冲突另记。
- 页底“保存”。本次保存后返回首页；重新进入简历，核对服务器返回的附件、公司、描述、日期、项目、校园条目和证书，确认持久保存。网站可能按自身规则重排条目，按公司匹配，不依赖数组顺序。

## 阿里 / 淘天：淘天已登录并解析，部分字段保存，完整核验待补必填资料

- 阿里总入口 `https://talent.alibaba.com/`。
- 淘天（淘宝、天猫相关）校园入口 `https://talent.taotian.com/campus/home`；页面有“日常实习生”。
- 顶部“个人中心”可从 `.next-menu-item-text` 精确文字定位，点击后可能跳转单独登录域名。先完成该网站登录，再读实际简历页面。
- 不能假设集团不同业务官网共享一份简历或自动同步，也不能把面向特定毕业年份的应届批次用于所有在校生。

## Shopee 中国：Moka校招入口已验证可访问，待登录

- 中国入口 `https://careers.shopee.cn/`。2026-11-03本机 Edge 返回 `ERR_CONNECTION_CLOSED`；记录网络问题，不反复要求用户重新开启 CDP。
- 国际官网 `https://careers.shopee.sg/early-careers` 可访问，提供全年实习入口；`/students` 在本次重定向至 `/jobs`。
- 国际职位搜索入口不等同中国校招个人简历库。未找到并验证原个人简历前，不向其他职位提交代替更新。

## 美团：已登录，结构化表单保存回读已实测

- 官方校园入口 `https://zhaopin.meituan.com/web/campus`，页面区分应届校招、转正实习和日常实习。
- 官方帮助 `https://zhaopin.meituan.com/web/question/campus`；个人中心具体控件须登录后检查。

## BOSS：保留可配置平台，未验证本轮更新

- `https://www.zhipin.com/`。在线简历、附件、求职期望和聊天投递是不同动作；沟通消息须有用户对应授权。
- 页面不可用或用户要求跳过时记录停点；不要在之后的普通维护任务中自动重试或永久删除平台。


### 淘天登录后的实际路径与填写

- 个人中心 `/personal/campus-application?lang=zh` →“我的简历” `/personal/campus-resume?lang=zh`。每个 `.uxcore-card` 按 `.uxcore-card-title-text` 定位，分区保存，不必寻找全页唯一保存。
- “手动上传简历”对应 accept `.jpg,.jpeg,.png,.doc,.docx,.pdf,.txt` 的 file输入。确认框“是，覆盖掉”会解析到表单；新建空简历可用，已有资料先备份。
- 解析通常漏学院、学号、作品超链接、家庭/学校城市、语言和来源；没有GPA时解析器可能默认写“无”，**不得当成用户确认**。
- 实习与项目共用“实习/项目经历”。已观察UXCore表单 `getValues(false).values`、`setValues`；前者不进行提交验证，后者走现有字段变更。每区正常保存仍须保留网站校验。
- 教育 `educations`、`languages`、`github`；经历 `experiences` 使用 `name/responsibility/timeRange/timeRangeToPresent/description`，至今在本次为 `["Y"]`；其他 `informationSource/otherInformation`。这些键是站点实现，别跨站套用。
- `.kuma-select2-dropdown-menu-item` 按显示文字选择。城市先搜索并核对返回的全称与值，不能用籍贯替代家庭城市。校园项目日期不确定且非必填时留空，不沿用解析器凭空勾选的“至今”。
- 身份字段只按需从用户私密容器传入；不要输出表单全值或带令牌的选择框fetch URL。

### Shopee 中国站可用路径

- 学校就业平台刊登的企业招聘简章指向 `https://app.mokahr.com/campus_apply/shopee/2962`，本次 Edge 实际打开标题“Shopee 校园招聘”。来源示例：`https://job.wzu.edu.cn/campus/view/id/494923`。
- 官网“职位列表” `#/jobs`；“进度查询”实际链接 `https://app.mokahr.com/m/candidate/applications/deliver-query/shopee`。个人简历入口需登录后观察。
- 中国站连接异常时优先核对企业公布的中国Moka入口，不用国际招聘页面代替中国区简历。招聘批次与日常实习仍逐岗位区分。

### 美团填写补充

- 登录头像菜单“我的简历” → `/web/personal-center/resume-detail?type=campus&mode=view`；“编辑简历”切换 `mode=edit`，不能误入社招简历。
- `.upload_resume_edit input[type=file]` 上传PDF，确认框可选“否，仅做附件上传”，随后单独改字段。
- 区块 `.work_experience_edit/.project_experience_edit/.campus_experience_edit/.certificate_edit`，每项 `.mtd-form`。添加 `.list_add`；删除真正的点击节点为 `.delete-list > div`，点外层容器可能无效。
- MTD表单实例可观察 `getFieldsValue/setFieldsValue/handleChildOnChange`。仅调用外层 `onFieldValueChange` 可能改业务数据而不更新显示和验证状态；文本通过真实输入或 `handleChildOnChange({field:value})`。公司/工作类型的语义回调可能要求 `{name,id}`，表单显示层却是字符串，须分别核对，不能只看一层。
- 必须核对真实“至今”复选框、必填校验及页面隐私协议勾选状态；保存后回 `mode=view`，刷新后核对两段实习/项目/证书等。预览可能不显示附件名，应重新进入编辑页核对附件是否保留。
