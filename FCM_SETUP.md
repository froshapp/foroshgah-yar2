# راهنمای فعال‌سازی اعلان پوش (FCM)

## ۱) ساخت پروژه Firebase
1. برو به https://console.firebase.google.com
2. Add project → نام دلخواه (مثلا foroshgah-yar)
3. Android app اضافه کن:
   - Package name دقیقاً: `ir.apadanasleep.foroshgah_yar`
   - App nickname: فروشگاه‌یار
4. فایل `google-services.json` را دانلود کن

## ۲) قرار دادن فایل در ریپو
فایل دانلودشده را بگذار اینجا:

```
android_templates/google-services.json
```

(جای فایل نمونه را بگیر)

## ۳) Server Key برای افزونه وردپرس
Firebase Console → Project settings → Cloud Messaging
- اگر **Cloud Messaging API (Legacy)** دیدی: Server key را کپی کن
- اگر فقط HTTP v1 بود: از Google Cloud Console برای همان پروژه یک API key بساز یا Legacy را فعال کن

در اپ: **بیشتر → اعلان پوش FCM → ذخیره کلید**

## ۴) بیلد
GitHub Actions → Build APK → Run workflow
APK را نصب کن، وارد شو، مجوز اعلان را بده.
با ثبت سفارش تستی باید پوش برسد.
