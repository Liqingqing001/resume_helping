# 日常实习平台入口与续接（2026-11-10实测）

本页覆盖19个平台。入口可访问、账户已登录、附件已上传、在线字段已保存、刷新核验成功是不同状态；不能互相替代。当前账户的完成情况和附件版本只写个人台账，不写进公开技能。

## 先走这条路径

1. 读取当前资料索引的可投递版本。项目数量、日期和职位名称可能已更新，不能沿用旧站点文案或旧临时脚本中的常量。
2. 复用当前常驻Edge客户端。`list`找回真实页面，原标签进入登录域名后按新URL匹配；不要重新打开同一站。一个站未登录不代表浏览器连接失败。
3. 有已保存简历先备份业务字段白名单；附件上传选择仅替换，随后逐项更新在线字段。新条目由页面添加动作生成。
4. 保存后重新进入，按公司名和项目名匹配，检查条数、全文、年月、至今、链接、学历、证书和附件。网站可能重排数组；不能仅核对数量或文件名。
5. 未登录站只记录入口与停点。登录后再探索编辑与保存，不把公开首页探索写成全流程验证。只维护简历时不选岗位、不发招聘者消息、不点击岗位申请。

## 19个平台导航

|平台|已实测入口/最快续接|已验证边界与注意事项|
|---|---|---|
|百度|`https://talent.baidu.com/jobs/center` → 现有“编辑”链接 → `/jobs/resume/edit?id=…`|附件及在线字段保存、返回个人中心、重开核验已实测。选择“实习生简历（全部在校生）”，不是2027校招；不要硬编码个人简历ID。日常入口 `/jobs/list?recruitType=INTERN`。|
|京东|`https://campus.jd.com/#/resume?type=present`|附件和表单保存回读已实测；首页用户名悬停→我的简历为备用导航。日期与文本控件细节见下文。|
|阿里|`https://campus-talent.alibaba.com/campus/index`|由 `talent.alibaba.com` 的校园入口进入；有面向全体在校生的研究型/日常实习。未登录时先登录/个人中心；登录后表单待实测。|
|淘天|`https://talent.taotian.com/personal/campus-resume?lang=zh`|失效时跳 `mozi-login.alibaba-inc.com/ssoLogin.htm`。既有分区填写方法见 platforms-expanded.md；不要把旧的部分保存记录当当前完成。|
|蚂蚁|`https://talent.antgroup.com/campus`；已打开 `/campus/home`|公开页面及登录入口已查。招聘AI助手的上传入口不等于个人简历库；登录后确认实际简历管理入口。|
|美团|`https://zhaopin.meituan.com/web/personal-center/resume-detail?type=campus&mode=view`|附件、在线字段、刷新核验已实测。编辑为 `mode=edit`；控件细节见下文。|
|快手|`https://campus.kuaishou.cn/#/campus/index` → 实习招聘 `#/campus/jobs`|公开页和登录弹窗已查；职位列表仍需核对筛选条件。个人简历保存待登录实测。|
|小红书|`https://job.xiaohongshu.com/campus/intern`|校园页实际链接“实习生”；Ace为独立项目 `/campus/landing/top_intern`，不能混用资格。登录弹窗已查，编辑待实测。|
|B站|`https://jobs.bilibili.com/campus`|首页校园招聘→该页；导航另有“实习生招聘”。登录入口已查，编辑和实习列表路由待登录实测。|
|滴滴|`https://app.mokahr.com/apply/didiglobal/6222#/`|从 `talent.didiglobal.com/campus/` 的“日常实习生招聘”进入，标题“滴滴 -实习生招聘”。“简历招聘进展”指向 `/candidate/applications/deliver-query/didiglobal`。独立应届校招96064入口不能替代此入口；登录后编辑待实测。|
|携程|`https://careers.ctrip.com/#/campus`|登录跳 `https://passport.ctrip.com/user/login`。校招页显示2027应届与留用实习，不能直接套用全部日常实习。登录后个人简历、日常实习渠道待核。|
|PDD|`https://careers.pddglobalhr.com/campus/`|当前官网从根路径跳该页，提供面向在校生的实习信息；登录/注册入口已查，编辑待实测。|
|华为|`https://career.huawei.com/cn/campus-recruitment`|根路径重定向 `/cn`，登录入口已查；实习项目毕业届别需逐项核对。编辑待登录实测。|
|OPPO|`https://career.oppo.com/official/oppo/recruitment/post?recruitType=OFFEN-RECRUITMENT`|此单数career域名已实测显示“日常实习生招聘”。复数careers域名的 `/university/oppo/campus` 是另一个校招入口；个人中心悬停→校招登录会新开 `/university/oppo/login`，勿重复开。日常渠道账号/简历归属待登录核对。|
|vivo|`https://hr.vivo.com/home` → 个人中心 `/personal-home`|点击会另开标签，未登录跳 `/login`，用list找回。校园外链 `https://hr-campus.vivo.com/`，日常渠道和编辑待登录核对。|
|智联|`https://www.zhaopin.com/`|公开首页显示求职登录；账号简历、附件和求职期望是不同模块，待登录后逐项核验。|
|牛客|`https://www.nowcoder.com/jobs/recommend/campus`；实习 `/jobs/intern/center`|`/jobs`本次404，不再从该地址重试。顶部“简历”可能跳外部zhiyeapp.com简历制作服务，不当作牛客已存求职简历。登录弹窗已查。|
|实习僧|`https://www.shixiseng.com/`|首页学生登录提供扫码/验证码；个人简历待登录实测，勿进入企业端。|
|24365|`https://www.ncss.cn/student/signin.html`；实习 `/student/shixi.html`|从国家大学生就业服务平台“求职者登录/注册”进入；不要选用人单位或管理用户登录。个人简历待登录实测。|

## 百度：表单与持久核验

- 页面有社招、校招、实习生三种简历，先核对激活标签。个人中心编辑链接带账户自己的ID，必须从当前页面读取。
- PDF输入为 `#resume-upload-info input[accept*=pdf]`。页面重复使用 `resume-upload-info` ID，作品集输入不能只靠该ID定位。上传弹窗“仅替换简历”保留已有表单；“覆盖”会重新解析。
- 添加工作经历为 `.add-one__…` 文本“添加工作经历”。字段：`companyNameN/departmentN/positionNameN/workDescN/industryTypeN`；项目 `subjectNameN/positionN/subjectDescN/positionDescN`，另有 `portfolioDesc/portfolioAddress`。
- 已观察 React Final Form `change/batch/getState` 与业务模型 `resumeEmployeeDTOS/resumeSubjectDTOS/setProps`。仅 `form.change` 可能改验证值而不更新实际文本框/业务模型。优先真实控件事件；确需组件适配时使用当前节点绑定的变更回调，并核对两层值。不能仅改DOM、关闭校验或给所有React站套同一模型。
- 日期组件 `InnerDatePicker` 的 `onChange` 会同步业务条目的 `startDate/endDate` 与表单日期字段；月份格式 `YYYY-MM`。持续经历遇到无至今选项，使用已获授权的截至时间解释，不擅造离职日；授权缺失时询问或保留待填。
- 下拉选项点击后必须检查回显。`Select` 有实际 `options` 与 `onChange`；读取标签和值后通过控件回调选择，不能猜枚举。可实习时长“6-12个月”对应 `Six to twelve months`，应按当前用户真实条件选，不能默认承诺超过12个月。
- 强制应聘字段包括城市、职位类别、到岗日、时长。若无“不限”，不要擅改成新求职意向；保留已确认旧值或问用户。“综合”是本次看到的既有宽泛类别，不是新增岗位申请。到岗日只在用户授权下选最近可用日期。
- 正常“保存”成功返回 `/jobs/center`，从现有编辑链接重开，核对服务器持久值、附件与日期；条目可能按时间自动排序。发现旧项目应删除或替换为当前有效项目，不能只在后面追加造成过时经历残留。

## 美团：两个容易误判的控件

- `handleChildOnChange({field:value})` **逐字段调用**。一次对象里放职位和描述，本次只更新了第一个字段；编辑页一层值和最后服务器描述可能不一致。每字段更新后要检查刷新后的全文。
- 新项目先填普通字段，再点真实“至今”。本次错误地在勾选后写 `endDate:0`，使后台拒绝“项目结束时间不能为空”；不能把0视为通用至今。真实勾选会生成业务层特殊结束值，预览显示“至今”，表单显示层仍可能为0。
- 点保存没有跳转不能视为成功。页面无常驻错误时，可仅观察网站正常保存响应的状态和错误提示，不记录请求体、证件值或完整返回数据。本次后台返回HTTP200仍含业务错误，必须看业务成功及回读。
- 成功后为 `mode=view`，刷新检查全文、链接和日期；再进编辑页核验PDF附件。确认成功后可以回预览，不重复上传。

## 京东：模型、文本框与年月

- `setState` 更新业务数组后，旧文本框可能仍显示旧描述，新条目文本框为空；保存可报“请填写项目描述”。调用实际文本控件的当前变更事件，使可见输入、业务数据和校验一致，再正常保存。
- 新项目先点击 `#program a` 中“添加”，保留生成的self ID；项目内容按名称匹配，勿依赖保存后的数组顺序。
- 强制精确日、无至今时，只按用户已授权的截至日规则填，文字明确仍在进行；PDF/正文通常按月展示。不能把截至日误报为真实结束时间。

## 登录与续接规则

公开首页有“登录”就记录待登录，不要求用户重开调试。用户可分批完成登录，报告平台名后只核对这些页面，再继续表单更新。运行中的唯一客户端和标签保持开放；会话ID只放本地运行记录，不进入公开仓库。网站登录不是永久保证，下一次先读实际状态。
