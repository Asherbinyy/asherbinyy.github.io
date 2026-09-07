# Arabic content — for review

Every Arabic string on the site, beside its English, so a correction is a
glance down a column rather than a hunt through five JSON files.

**These were written by an agent, not by the owner.** `AGENTS.md` §3 forbids
fabricating translations; the owner waived that on 2026-09-07 — *"just do it
and ship all and later i will tell u if smth is wrong"* — so they shipped
without waiting for review. This file is the review surface that waiver
implies, not a substitute for it.

## How to correct one

Find the row, then edit the `ar` value at that path in
`assets/content/<document>.json`. Nothing else needs touching: no code reads
these strings by name, and `test/unit/content/arabic_coverage_test.dart` will
fail if one is emptied rather than replaced.

## Conventions used

- **Western numerals** (25, 50%, 2024) rather than Arabic-Indic. The type scale puts tabular figures on every numeric style and mixes Latin technology names into Arabic sentences throughout; switching numeral systems mid-line would break both.
- **Product, company and technology names stay in Latin** — Flutter, Apple Pay, STC Pay, City Loom, Mokaf. Transliterating them would make them unsearchable and is not what an Arabic-speaking engineer would write.
- **Institutions are translated**, because they have established Arabic names: جامعة سالفورد, جامعة المنصورة.
- **`Sherbini` renders as `الشربيني`**, and the legal name as `أحمد الشربيني`.

---

## `profile.json`

| Path | English | Arabic |
|---|---|---|
| `name` | Ahmed Elsherbini | أحمد الشربيني |
| `displayName` | Sherbini | الشربيني |
| `positioning` | Mobile engineer. 25+ applications shipped across six countries. | مهندس تطبيقات موبايل. أكثر من 25 تطبيقًا أُطلقت في ست دول. |
| `location` | Manchester, United Kingdom | مانشستر، المملكة المتحدة |
| `status` | MSc Managing Innovation & IT, University of Salford — Distinction | ماجستير إدارة الابتكار وتقنية المعلومات، جامعة سالفورد — بامتياز |
| `venture.label` | Co-founder, City Loom (early stage) | شريك مؤسس في City Loom (مرحلة مبكرة) |
| `stats[0].label` | shipped | تطبيق مُطلق |
| `stats[1].label` | countries | دول |
| `stats[2].label` | years commercial | سنوات احترافية |

## `fallback.json`

| Path | English | Arabic |
|---|---|---|
| `name` | Ahmed Elsherbini | أحمد الشربيني |
| `positioning` | Mobile engineer. 25+ applications shipped across six countries. | مهندس تطبيقات موبايل. أكثر من 25 تطبيقًا أُطلقت في ست دول. |

## `career.json`

| Path | English | Arabic |
|---|---|---|
| `roles[0].title` | BEng Communications & Electronics Engineering | بكالوريوس هندسة الاتصالات والإلكترونيات |
| `roles[1].title` | Flutter Developer & Team Leader | مطوّر Flutter وقائد فريق |
| `roles[1].summary` | Led development of 16+ Flutter applications. Mentored a team of three. | قاد تطوير أكثر من 16 تطبيقًا بـ Flutter، وأشرف على فريق من ثلاثة مطوّرين. |
| `roles[2].title` | Mobile Application Developer | مطوّر تطبيقات موبايل |
| `roles[2].summary` | Led end-to-end design and delivery of mobile and web applications, owning architecture, Flutter development, API integration and user experience. Full time to January 2024, part time from April 2025. | قاد تصميم وتسليم تطبيقات الموبايل والويب من البداية إلى النهاية، وتولّى البنية البرمجية وتطوير Flutter وتكامل واجهات البرمجة وتجربة المستخدم. بدوام كامل حتى يناير 2024، وبدوام جزئي من أبريل 2025. |
| `roles[3].title` | Mobile Application Developer | مطوّر تطبيقات موبايل |
| `roles[3].summary` | Led Flutter development and implemented CI/CD workflows, reducing development time by 50% and delivery time by a further 20%. | قاد تطوير Flutter ونفّذ مسارات التكامل والنشر المستمر، فخفّض زمن التطوير بنسبة 50% وزمن التسليم بنسبة 20% إضافية. |
| `roles[4].title` | Mobile Application Developer | مطوّر تطبيقات موبايل |
| `roles[4].summary` | Migrated a legacy Android application to Flutter, improving performance by 20%. Added unit, integration and widget testing, reducing bug rates by 30%. | نقل تطبيق أندرويد قديمًا إلى Flutter، فحسّن الأداء بنسبة 20%. وأضاف اختبارات الوحدة والتكامل والواجهات، فخفّض معدّل الأخطاء بنسبة 30%. |
| `roles[5].title` | Mobile Application Developer | مطوّر تطبيقات موبايل |
| `roles[5].summary` | Built Mokaf, a Flutter smart-parking application with real-time maps, QR scanning and Google Maps navigation, integrating TAP, Apple Pay and STC Pay. MVP delivered in under eight weeks. | طوّر Mokaf لمواقف السيارات الذكية بـ Flutter، بخرائط لحظية ومسح رمز QR وملاحة عبر خرائط جوجل، مع دمج TAP وApple Pay وSTC Pay. سُلّم النموذج الأولي في أقل من ثمانية أسابيع. |
| `roles[6].title` | MSc Managing Innovation & Information Technology | ماجستير إدارة الابتكار وتقنية المعلومات |
| `roles[6].summary` | Graduated with Distinction. | تخرّج بتقدير امتياز. |

## `apps.json`

| Path | English | Arabic |
|---|---|---|
| `apps[0].role` | Legacy Android to Flutter migration | نقل تطبيق أندرويد قديم إلى Flutter |
| `apps[1].role` | Smart parking — real-time maps, QR, TAP / Apple Pay / STC Pay | مواقف ذكية — خرائط لحظية ورمز QR ومدفوعات TAP وApple Pay وSTC Pay |
| `apps[2].role` | Redesign and rebuild — video, PDF, audio delivery | إعادة تصميم وبناء — بثّ الفيديو وملفات PDF والتسجيلات الصوتية |
| `apps[3].role` | E-scooter rental — BLE QR unlock, in-app navigation | تأجير السكوتر الكهربائي — فتح عبر BLE ورمز QR، وملاحة داخل التطبيق |
| `apps[5].role` | Showcase and shop features, cloud functions, structural and UI improvements, and bug fixes | إضافة واجهتَي العرض والمتجر، ودوالّ سحابية، وتحسينات بنيوية وواجهات، وإصلاح أخطاء |
| `apps[6].role` | Freelance build with one other developer | عمل حرّ بالتعاون مع مطوّر آخر |

## `education.json`

| Path | English | Arabic |
|---|---|---|
| `entries[0].institution` | University of Salford | جامعة سالفورد |
| `entries[0].award` | MSc Managing Innovation & Information Technology | ماجستير إدارة الابتكار وتقنية المعلومات |
| `entries[0].status` | Distinction | امتياز |
| `entries[0].modules[0].name` | Business Data Insights & Analytics | تحليلات ورؤى بيانات الأعمال |
| `entries[0].modules[1].name` | Managing Information Systems & Transformation | إدارة نظم المعلومات والتحوّل |
| `entries[0].modules[2].name` | Cybersecurity & Information Management | الأمن السيبراني وإدارة المعلومات |
| `entries[0].modules[3].name` | Responsible Technologies | التقنيات المسؤولة |
| `entries[0].modules[4].name` | Managing Project Deployment & Delivery | إدارة تنفيذ المشاريع وتسليمها |
| `entries[0].modules[5].name` | Research Methods for Managers | مناهج البحث للمديرين |
| `entries[0].modules[6].name` | Managing Innovation & Creativity | إدارة الابتكار والإبداع |
| `entries[0].highlights[0]` | Dissertation: human oversight and accountability in generative AI adoption within Big Four consulting firms | رسالة الماجستير: الإشراف البشري والمساءلة في تبنّي الذكاء الاصطناعي التوليدي داخل شركات الاستشارات الأربع الكبرى |
| `entries[0].highlights[1]` | Led a smartphone manufacturer in the Edumundo strategy simulation — 2nd of cohort | قاد شركة هواتف ذكية في محاكاة Edumundo الاستراتيجية — المركز الثاني على الدفعة |
| `entries[1].institution` | Mansoura University | جامعة المنصورة |
| `entries[1].award` | BEng Communications & Electronics Engineering | بكالوريوس هندسة الاتصالات والإلكترونيات |


---

44 strings, all translated. Generated 2026-09-07.
