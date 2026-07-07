import 'models.dart';

/// Mock campus knowledge base
class MockKnowledgeBase {
  static final List<KnowledgeArticle> articles = [
    KnowledgeArticle(
      id: 'KB001',
      title: '校园卡挂失流程',
      category: '校园卡服务',
      content: '''发现校园卡丢失后，请立即通过以下方式进行挂失：

1. **线上挂失**：登录"中南民族大学"微信公众号 → 校园服务 → 校园卡 → 挂失
2. **电话挂失**：拨打校园卡服务中心电话 027-6784****（工作日 8:30-17:00）
3. **现场挂失**：前往校园卡服务中心（学生事务中心1楼）

挂失后，原卡立即冻结，余额将转移至新卡。补办新卡需携带学生证和身份证到校园卡服务中心办理，补卡工本费 20 元。

**注意**：挂失前的消费无法追回，请尽快办理。挂失后7天内未补办，系统将自动注销原卡。''',
      tags: ['校园卡', '挂失', '补办', '服务中心'],
      lastUpdated: DateTime(2026, 6, 15),
    ),
    KnowledgeArticle(
      id: 'KB002',
      title: '图书馆开放时间与借阅规则',
      category: '图书馆',
      content: '''**开放时间**
- 周一至周五：8:00 - 22:00
- 周六、周日：9:00 - 21:00
- 寒暑假：另行通知

**借阅规则**
- 本科生：最多借阅 10 册，借期 30 天，可续借 1 次（30天）
- 研究生：最多借阅 20 册，借期 60 天，可续借 2 次（每次30天）
- 续借需在到期前 7 天办理

**逾期处理**
- 逾期 1-7 天：暂停借阅权限 7 天
- 逾期 7-30 天：暂停借阅权限 30 天
- 逾期超过 30 天：暂停借阅权限至归还并缴清罚款

**电子资源**
校园网内可免费访问中国知网、万方数据、Web of Science 等数据库。校外可通过 VPN 访问。''',
      tags: ['图书馆', '借阅', '开放时间', '续借', '电子资源'],
      lastUpdated: DateTime(2026, 3, 1),
    ),
    KnowledgeArticle(
      id: 'KB003',
      title: '教务系统选课指南',
      category: '教务系统',
      content: '''**选课时间**
- 预选课：每学期第 16 周（具体时间以教务处通知为准）
- 正选课：每学期第 1-2 周
- 补退选：每学期第 3 周

**选课步骤**
1. 登录教务系统 jwxt.scuec.edu.cn
2. 进入"选课管理" → "自主选课"
3. 按课程号或课程名称搜索
4. 确认选课信息后提交

**注意事项**
- 每学期最少修读 15 学分，最多 30 学分
- 必修课自动预置，无需手动选课
- 体育课、公选课需手动选课
- 选课结束后不再接受补选申请
- 如遇系统问题，请联系教务处 027-6784****''',
      tags: ['选课', '教务系统', '学分', '必修课', '公选课'],
      lastUpdated: DateTime(2026, 5, 20),
    ),
    KnowledgeArticle(
      id: 'KB004',
      title: '学生宿舍管理规定',
      category: '宿舍管理',
      content: '''**作息时间**
- 宿舍开门：6:00
- 宿舍关门：23:00（周五、周六延长至 23:30）
- 熄灯时间：23:30（考试周延长至 24:00）

**用电安全**
- 禁止使用大功率电器（电热毯、电热锅、电吹风超过1000W等）
- 禁止私拉电线
- 发现违规电器将予以没收并通报批评

**报修流程**
1. 登录"中南民族大学"微信公众号 → 校园服务 → 宿舍报修
2. 选择报修类型（水电、家具、网络、门锁等）
3. 填写具体问题描述
4. 维修人员将在 24 小时内上门

**访客管理**
- 访客需在宿管处登记
- 访客时间：8:00 - 21:00
- 异性不得进入宿舍楼层''',
      tags: ['宿舍', '作息', '报修', '用电安全', '访客'],
      lastUpdated: DateTime(2026, 2, 28),
    ),
    KnowledgeArticle(
      id: 'KB005',
      title: '心理咨询中心服务',
      category: '学生服务',
      content: '''**服务内容**
- 个体心理咨询（免费）
- 团体心理辅导
- 心理危机干预
- 心理健康测评

**预约方式**
1. 线上预约：登录"中南民族大学"微信公众号 → 学生服务 → 心理咨询
2. 电话预约：027-6784****
3. 现场预约：心理健康教育中心（学生活动中心3楼）

**咨询时间**
- 周一至周五：9:00 - 17:00
- 紧急情况：24小时心理热线 400-161-9995

**隐私保护**
所有咨询内容严格保密，不会出现在学籍档案中。仅在涉及自伤或伤人风险时，为保护生命安全可能会通知相关人员。''',
      tags: ['心理咨询', '心理健康', '预约', '危机干预'],
      lastUpdated: DateTime(2026, 4, 10),
    ),
    KnowledgeArticle(
      id: 'KB006',
      title: '校园网使用指南',
      category: '网络服务',
      content: '''**连接方式**
- SSID：SCUEC-WiFi
- 认证方式：学号 + 密码（初始密码为身份证后6位）
- 认证页面：10.10.10.10

**流量套餐**
- 基础套餐：每月 30GB 免费流量
- 加油包：10GB / 5元，可通过微信公众号购买
- 有线网络：宿舍网口，10元/月不限流量

**常见问题**
1. 无法连接：检查是否欠费，尝试重新认证
2. 网速慢：避免高峰期（20:00-23:00）下载大文件
3. 忘记密码：携带学生证到网络中心（图书馆1楼）重置

**网络中心服务时间**
- 周一至周五：8:30 - 17:30
- 报修电话：027-6784****''',
      tags: ['校园网', 'WiFi', '流量', '网络中心'],
      lastUpdated: DateTime(2026, 1, 15),
    ),
    KnowledgeArticle(
      id: 'KB007',
      title: '校医院就诊指南',
      category: '医疗服务',
      content: '''**就诊时间**
- 周一至周五：8:00 - 17:30
- 急诊：24小时

**就诊流程**
1. 携带校园卡到校医院挂号
2. 到相应科室候诊
3. 就诊后到药房取药

**费用说明**
- 校医院就诊：挂号费 1 元，药品按医保价
- 转诊：需校医院医生开具转诊单，到指定医院就诊
- 医保报销：在校医院就诊可报销 80%，转诊报销 60%

**疫苗接种**
校医院定期组织流感疫苗、HPV疫苗等接种，关注微信公众号获取通知。

**地址**：校医院位于校园东区，靠近东门。''',
      tags: ['校医院', '就诊', '医保', '疫苗', '急诊'],
      lastUpdated: DateTime(2026, 6, 1),
    ),
    KnowledgeArticle(
      id: 'KB008',
      title: '食堂分布与营业时间',
      category: '生活服务',
      content: '''**第一食堂（北区）**
- 早餐：6:30 - 9:00
- 午餐：11:00 - 13:30
- 晚餐：17:00 - 19:30
- 特色：清真窗口、地方特色小吃

**第二食堂（南区）**
- 早餐：7:00 - 9:00
- 午餐：11:00 - 13:00
- 晚餐：17:00 - 19:00
- 特色：自助餐、面食

**第三食堂（东区）**
- 早餐：6:30 - 9:00
- 午餐：10:30 - 13:30
- 晚餐：16:30 - 19:30
- 特色：经济实惠套餐

**支付方式**
支持校园卡、微信支付、支付宝。校园卡消费享受食堂补贴，比移动支付便宜约 10%。''',
      tags: ['食堂', '营业时间', '餐饮', '支付'],
      lastUpdated: DateTime(2026, 3, 20),
    ),
  ];

  /// Search knowledge base by query
  static List<KnowledgeArticle> search(String query, {double threshold = 0.3}) {
    final q = query.toLowerCase();
    final results = <KnowledgeArticle>[];

    for (final article in articles) {
      double score = 0;

      // Title match (high weight)
      if (article.title.toLowerCase().contains(q)) {
        score += 0.5;
      }

      // Category match (medium weight)
      if (article.category.toLowerCase().contains(q)) {
        score += 0.3;
      }

      // Tag match (medium weight)
      for (final tag in article.tags) {
        if (tag.toLowerCase().contains(q) || q.contains(tag.toLowerCase())) {
          score += 0.2;
          break;
        }
      }

      // Content match (low weight)
      if (article.content.toLowerCase().contains(q)) {
        score += 0.15;
      }

      // Keyword expansion for common queries
      final expandedKeywords = _expandKeywords(q);
      for (final kw in expandedKeywords) {
        if (article.title.toLowerCase().contains(kw) ||
            article.content.toLowerCase().contains(kw) ||
            article.tags.any((t) => t.toLowerCase().contains(kw))) {
          score += 0.1;
        }
      }

      if (score >= threshold) {
        results.add(KnowledgeArticle(
          id: article.id,
          title: article.title,
          category: article.category,
          content: article.content,
          tags: article.tags,
          lastUpdated: article.lastUpdated,
          relevanceScore: score.clamp(0, 1),
        ));
      }
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  static List<String> _expandKeywords(String query) {
    final expansions = <String>[];
    final map = {
      '丢卡': ['挂失', '校园卡'],
      '丢': ['挂失', '丢失'],
      '借书': ['图书馆', '借阅'],
      '看书': ['图书馆', '阅读'],
      '上网': ['校园网', 'WiFi', '网络'],
      'wifi': ['校园网', '网络'],
      '网': ['校园网', '网络'],
      '吃饭': ['食堂', '餐饮'],
      '饭': ['食堂'],
      '看病': ['校医院', '就诊'],
      '生病': ['校医院', '就诊'],
      '心理': ['心理咨询', '心理'],
      '选课': ['教务系统', '选课'],
      '睡觉': ['宿舍', '作息'],
      '住': ['宿舍'],
      '报修': ['宿舍', '报修'],
    };

    for (final entry in map.entries) {
      if (query.contains(entry.key)) {
        expansions.addAll(entry.value);
      }
    }

    return expansions;
  }
}
