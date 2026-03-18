# Database OPA Schema (`database.rego`)

ဒီ `database.rego` ဖိုင်ဟာ **Open Policy Agent (OPA)** ရဲ့ Rego language နဲ့ ရေးသားထားတဲ့ Infrastructure စည်းမျဉ်း (Rule) ဖိုင်တစ်ခု ဖြစ်ပါတယ်။ အဓိက ရည်ရွယ်ချက်ကတော့ **Production Environment အတွက် လိုအပ်ချက်တွေ ပြည့်စုံမှသာ Database ကို ဆောက်လုပ်ခွင့်ပေးဖို့** ထိန်းချုပ်ထားတာပါ။

## ဘယ်လို လုပ်ဆောင်သလဲ? (How it works)

Rego ဖိုင်ထဲက အလုပ်လုပ်ပုံ အဆင့်ဆင့်ကို အောက်ပါအတိုင်း နားလည်နိုင်ပါတယ်။

### ၁။ `package` နဲ့ `default` သတ်မှတ်ခြင်း
```rego
package atmos.validation

default valid = false

valid {
    count(errors) == 0
}
```
* **အဓိပ္ပါယ်:** စံသတ်မှတ်ချက်အရ Atmos က `atmos.validation` ဆိုတဲ့ package name ကို ရှာပါတယ်။ အစပိုင်းမှာ `valid = false` (မှားယွင်းနေတယ်) လို့ ပုံသေ သတ်မှတ်ထားပါတယ်။ `errors` (အမှား) အရေအတွက် `0` ဖြစ်သွားမှသာ (ဆိုလိုတာက Rule တွေ အားလုံးနဲ့ ကိုက်ညီမှသာ) `valid = true` (မှန်ကန်တယ်/ခွင့်ပြုတယ်) လို့ ပြောင်းလဲ သတ်မှတ်ပေးပါတယ်။

### ၂။ High Availability (HA) စည်းမျဉ်း
```rego
errors[msg] {
    input.vars.environment == "production"
    input.vars.multi_az != true
    msg := "Validation Failed: Production database must have multi_az set to true for High Availability."
}
```
* **အဓိပ္ပါယ်:** ဒီ Code block က အောက်ပါ အခြေအနေ ၂ ခုစလုံး တိုက်ဆိုင်ရင် `errors` စာရင်းထဲကို `msg` (Message) တစ်ခု ထည့်လိုက်ပါတယ်။
  1. `environment` က `production` ဖြစ်နေရမယ်။
  2. `multi_az` က `true` မဟုတ်ဘူး (ဥပမာ - `false` ဖြစ်နေတယ်) ဆိုရင်။
* **ရလဒ်:** Production မှာ Database ဆောက်ရင် `multi_az` (Data ကို Data Center ၂ ခုမှာ ပွားထားတဲ့ စနစ်) ကို `true` လို့ မဖြစ်မနေ ထည့်ရပါမယ်။ မထည့်ရင် Deploy လုပ်ခွင့် မပေးဘဲ Error ပြပါလိမ့်မယ်။ ဒါက Production Data တွေ လုံခြုံရေးအတွက် မရှိမဖြစ် လိုအပ်လို့ပါ။

### ၃။ Storage ပမာဏ စည်းမျဉ်း
```rego
errors[msg] {
    input.vars.environment == "production"
    input.vars.max_allocated_storage < 100
    msg := "Validation Failed: Production database must have max_allocated_storage >= 100 GB."
}
```
* **အဓိပ္ပါယ်:** ဒီ Code block ကလည်း အခြေအနေ ၂ ခု တိုက်ဆိုင်ရင် Error ထုတ်ပေးပါတယ်။
  1. `environment` က `production` ဖြစ်နေရမယ်။
  2. `max_allocated_storage` ပမာဏက `100` GB ထက် ငယ်နေမယ် ဆိုရင်။
* **ရလဒ်:** Production Database တွေဟာ အချက်အလက် အများကြီး သိမ်းရမှာဖြစ်လို့ Storage ပြည့်သွားတဲ့ ပြဿနာ (Storage Full Downtime) မဖြစ်အောင် `max_allocated_storage` ကို အနည်းဆုံး 100 GB ထက် ပိုပေးထားဖို့ အလိုအလျောက် တားဆီး စစ်ဆေးပေးတာ ဖြစ်ပါတယ်။

---

**အနှစ်ချုပ်:** 
Development (Dev) ဒါမှမဟုတ် UAT ပတ်ဝန်းကျင်တွေမှာ `multi_az` ကို `false` ထားတာ၊ `max_allocated_storage` ကို `20` GB ဘဲ ထားတာတွေကို ဒီ OPA Policy က လျစ်လျူရှု (Ignore) ပေးပါတယ်။ တကယ်လို့ **Production** ကိုသာ Deploy လုပ်မယ်ဆိုရင်တော့ ဒီအရေးကြီးတဲ့ လိုအပ်ချက် ၂ ခု မပါရင် လုံးဝ (လုံးဝ) ခွင့်မပြုပါဘူး။ Human Error ကြောင့် Production Database တွေမှာ ပြဿနာ မတက်အောင် Guardrail လိုမျိုး ကာကွယ်ပေးထားတာ ဖြစ်ပါတယ်။
