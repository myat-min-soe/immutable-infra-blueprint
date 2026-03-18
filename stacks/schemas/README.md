# Atmos Schemas (`stacks/schemas/`)

ဒီ Folder (`stacks/schemas`) ကတော့ **Atmos Stack Configurations တွေကို Validate (အမှားအယွင်း စစ်ဆေးပေးခြင်း)** အတွက် သုံးတဲ့ Rules တွေ သိမ်းဆည်းတဲ့ နေရာ ဖြစ်ပါတယ်။

သင့်ရဲ့ Infrastructure (YAML ဖိုင်တွေ) ကို မမှန်ကန်တဲ့ တန်ဖိုးတွေ၊ လိုအပ်ချက်တွေ မပါဘဲ Deploy လုပ်မိတာမျိုး (Human Errors) တွေကနေ ကြိုတင် တားဆီးပေးပါတယ်။

## Schema အမျိုးအစား (၂) မျိုး

Atmos မှာ လက်ရှိ အသုံးပြုထားတဲ့ Validation နည်းလမ်း (၂) မျိုး ရှိပါတယ်။

### ၁။ JSON Schema (`jsonschema/`)
* **အသုံးပြုပုံ:** Variable တွေရဲ့ Data Type (e.g. String, Number) မှန်/မမှန် နဲ့ ခွင့်ပြုထားတဲ့ တန်ဖိုး (e.g. `instance_type` ကို `t3a.small` သာ ခွင့်ပြုမယ်) ဆိုတာမျိုးတွေကို လွယ်ကူရိုးရှင်းစွာ စစ်ဆေးနိုင်ပါတယ်။
* **ပိုမိုသိရှိရန်:** [jsonschema/README.md](jsonschema/README.md) ကို ဖတ်ရှုပါ။

### ၂။ OPA Schema (`opa/`)
* **အသုံးပြုပုံ:** ပိုမို ရှုပ်ထွေးတဲ့ Logic တွေ၊ ဥပမာ - "Environment က Production ဆိုရင် Database ဟာ Multi-AZ ဖြစ်ကိုဖြစ်ရမယ်၊ Storage က အနည်းဆုံး 100GB ရှိရမယ်" ဆိုတဲ့ Security နဲ့ Compliance ပိုင်းဆိုင်ရာ စည်းမျဉ်းတွေကို Open Policy Agent (Rego) နဲ့ ရေးသား ထိန်းချုပ်နိုင်ပါတယ်။
* **ပိုမိုသိရှိရန်:** [opa/README.md](opa/README.md) ကို ဖတ်ရှုပါ။

---

## ဘယ်လို အလုပ်လုပ်သလဲ?

ဒီ Schemas တွေကို Component တွေကနေ `settings.validation` block သုံးပြီး သွားချိတ်ထားပါတယ်။ (ဥပမာ - `catalog/compute/defaults.yaml` မှာ သွားကြည့်နိုင်ပါတယ်)။

အကယ်၍ လူတစ်ယောက်ယောက်က Developer တစ်ယောက်က လိုအပ်ချက်နဲ့ မကိုက်ညီတဲ့ စာကြောင်းကို YAML ဖိုင်ထဲ ထည့်ရေးပြီး Deploy (သို့) Plan လုပ်ဖို့ ကြိုးစားရင်၊ **Terraform အဆင့်ကိုတောင် ရောက်ခွင့်မပေးဘဲ Atmos ဆီမှာတင် Error ပြပြီး Block လုပ်ပေးမှာ** ဖြစ်ပါတယ်။ ဒါကြောင့် ငွေကုန်ကြေးကျ များစေမယ့် အမှားတွေ (Costly Mistakes) ကို အသေအချာ ကာကွယ်ပေးနိုင်ပါတယ်။
