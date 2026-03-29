المجهود اللي بذلته في كتابة الـ **Documentation** دي ينم عن عقلية مبرمج فاهم "Architecture" صح. التقسيمة واضحة، الـ JSON Structure نظيفة جداً، وفكرة الـ `EnergyState` كـ Object موحد عبقرية لأنها بتسهل عليك الـ UI Binding في فلاتر.

لكن، لو سألتني كـ **Senior Architect**: "هل ده كفاية؟" .. الإجابة هي: **للمرحلة الأولى (MVP) أيوة، لكن لمنتج احترافى أو مشروع تخرج مبهر، لسه فيه "تكات" ناقصة.**

إليك ما ينقص الـ API ليكون متكاملاً:

### ١. الأمان والخصوصية (Auth Layer)
حالياً الـ API بيعتمد على الـ `userId` فقط في الـ URL أو الـ Body. ده خطر تقنياً (Insecure).
* **تحتاج إضافة:** `POST /api/auth/login` أو `register`.
* **الـ Token:** استخدم **JWT (JSON Web Token)**. كل الـ Endpoints اللي تحت لازم تطلب الـ Token ده في الـ `Authorization` Header.

### ٢. تعديل بيانات المستخدم (Update Profile)
أنت أضفت `Create` و `Get` لكن نسيت الـ **Update**.
* **السيناريو:** اليوزر بدأ بـ `Sensitivity: Normal` وبعد أسبوع لقى إنه بيهبط بسرعة وعاوز يخليها `Sensitive`.
* **Endpoint مقترح:** `PATCH /api/users/:id` لتحديث الـ `targetGoal` أو الـ `sensitivityLevel`.

### ٣. البيانات التاريخية والرسوم البيانية (History & Analytics)
عشان فلاتر ترسم Graph لشكل "البالونة" أو استهلاك الطاقة على مدار الـ ٢٤ ساعة اللي فاتوا، الـ `Sync State` لوحدها مش كفاية.
* **Endpoint مقترح:** `GET /api/energy/history/:userId?period=24h`
* **الرد:** Array من الـ `volumeRemaining` مع `timestamps` كل ١٥ دقيقة مثلاً.

### ٤. التعامل مع الأخطاء (Error Specification)
الأجنت (أو أنت وأنت شغال في فلاتر) محتاج يعرف الـ API هيرد بإيه لو حصلت مشكلة.
* **أضف قسم للـ Status Codes:**
    * `400 Bad Request`: لو الداتا ناقصة.
    * `401 Unauthorized`: لو الـ Token خلص أو مش موجود.
    * `413 Payload Too Large`: لو صورة الأكل حجمها أكبر من ١٠ ميجا.
    * `422 Unprocessable Entity`: لو الـ AI معرفش يتعرف على صورة الأكل.

### ٥. إدارة التنبيهات (Push Notifications vs Local)
أنت ذكرت الـ `alertTime` للـ Local Notifications، وده ممتاز. لكن لو الموبايل "قتل" الأبلكيشن في الخلفية (وده بيحصل كتير في أندرويد)، الـ Local Notification ممكن متشتغلش.
* **نصيحة:** يفضل ربط الـ Backend بـ **FCM (Firebase Cloud Messaging)**. السيرفر (Node.js) هو اللي يبعت التنبيه في الوقت المحسوب عشان يضمن وصوله لليوزر حتى لو قافل التطبيق.

---

### ٦. تعديلات تقنية بسيطة (For Better Dev Experience):

* **Multipart Upload:** في الـ `POST /api/meals/snap` يفضل الـ `userId` يتبعت في الـ Header أو يكون مستخرج من الـ JWT Token بدل ما يكون في الـ Body مع الصورة، ده بيبقى "Cleaner".
* **Constants Sync:** فكرة الـ `GET /api/energy/constants` ممتازة جداً (Smart Move!)، دي هتخليك لو عدلت الـ Multipliers في الداتابيز، الأبلكيشن يتحدث عند كل الناس فوراً من غير ما تنزل Update على الـ Store.

### ملخص الـ "Missing Endpoints" اللي محتاجها:
| Method | Endpoint | Purpose |
| :--- | :--- | :--- |
| **PATCH** | `/api/users/:id` | Update sensitivity or goal. |
| **GET** | `/api/energy/history/:userId` | Get data for the 24h graph. |
| **POST** | `/api/auth/login` | Secure access. |
| **DELETE** | `/api/meals/:id` | In case the user logged a meal by mistake. |

---

**هل تحب أساعدك في كتابة الـ `ApiService` بـ Flutter (باستخدام Dio) اللي بيتعامل مع الـ Endpoints دي، ولا حابب نركز على كود الـ Node.js اللي بيحسب الـ `etcMinutes` بدقة؟**
