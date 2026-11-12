# Al Baraka Bank Assistant & RAGLab — حزمة التشغيل الجاهزة (`albaraka-demo`)

حزمة تشغيل مستقلة للمنصة بالكامل عبر **Docker** فقط (بدون الحاجة إلى الكود المصدري أو تثبيت Java / Node.js / Python)، تسحب الصور الجاهزة مباشرة من حساب **Ayari Farah** (`elayarifarah`) على Docker Hub:

- `elayarifarah/albaraka-raglab:latest`
- `elayarifarah/albaraka-backend:latest`
- `elayarifarah/albaraka-frontend:latest`

---

## 1. المتطلبات
- تثبيت وتشغيل **Docker Desktop** (على Windows / macOS) أو **Docker Engine + Compose** (على Linux).
- توفير المنفذ `8080` على الجهاز.

---

## 2. خطوات التشغيل السريع

### الخطوة 1 — مفاتيح الـ API (اختياري قبل التشغيل أو من الواجهة بعده)
افتح ملف `config/api-keys.env` وضع مفاتيح المزوّدين:
```env
NVIDIA_API_KEY=nvapi-...
XKIRO_API_KEY=sk-...
```
> **ملاحظة:** يمكنك ترك الملف فارغًا الآن وإدخال المفاتيح مباشرة من لوحة التحكم بعد فتح المتصفح.

### الخطوة 2 — تشغيل المنصة
افتح الطرفية (Terminal / PowerShell) داخل مجلد `albaraka-demo` ونفّذ:
```bash
docker compose pull
docker compose up -d
```
*(أو شغّل `start.bat` على Windows / `./start.sh` على Linux & macOS).*

انتظر حوالي 30–60 ثانية حتى تكتمل جاهزية الحاويات (`docker compose ps`)، ثم افتح المتصفح على:
- **الرابط:** `http://localhost:8080`

---

## 3. حسابات الدخول التجريبية

| الدور | البريد الإلكتروني | كلمة المرور |
| :--- | :--- | :--- |
| مدير المنصة (Admin) | `admin@albaraka.tn` | `postgres` |
| واجهة العميل (Client) | `client@albaraka.tn` | `client123` |

---

## 4. تهيئة الفهرس لأول مرة (مرّة واحدة فقط)
1. سجّل الدخول بحساب المدير (`admin@albaraka.tn` / `postgres`).
2. إذا لم تكن قد وضعت مفاتيح الـ API في `config/api-keys.env`، ادخل إلى:
   **Administration → RAGLab → Paramètres → Clés API (`.env`)** واحفظ مفاتيحك.
3. ادخل إلى **Administration → RAGLab → Corpus / Statut** واضغط على زر الفهرسة لبناء فهرس المتجهات فوق الوثائق المدمجة (تستغرق حوالي دقيقة واحدة أول مرة فقط، وتبقى محفوظة تلقائيًا في وحدة التخزين الدائمة).

---

## 5. أوامر مفيدة
```bash
# متابعة حالة الحاويات
docker compose ps

# عرض السجلات الحية
docker compose logs -f

# إيقاف المنصة مع الاحتفاظ بقاعدة البيانات والفهرس
docker compose down

# إيقاف المنصة وحذف جميع البيانات (إعادة ضبط كاملة)
docker compose down -v
```
