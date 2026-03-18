# JSON Schema (`compute.json`)

ဒီ `compute.json` ဖိုင်ဟာ **JSON Schema** စံနှုန်းကို အသုံးပြုပြီး `compute` component ရဲ့ Configuration (YAML ဖိုင်) တွေ မှန်ကန်မှု ရှိ/မရှိ စစ်ဆေးပေးတဲ့ Validation ဖိုင်တစ်ခု ဖြစ်ပါတယ်။

## ဘယ်လို လုပ်ဆောင်သလဲ? (How it works)

### ၁။ `instance_type` ကို ကန့်သတ်ခြင်း (Enum Validation)
```json
"instance_type": {
  "type": "string",
  "enum": [
    "t2.micro",
    "t3.micro",
    "t3a.small",
    "t3.small",
    "t3a.medium",
    "t3.medium",
    "t3a.large"
  ]
}
```
* **အဓိပ္ပါယ်:** ကိုယ့်ရဲ့ `develop.yaml` ဒါမှမဟုတ် `production.yaml` ထဲမှာ `compute` component ကို သုံးတဲ့အခါ EC2 `instance_type` ကို ဒီ List (Enum) ထဲမှာ ပါတဲ့ အမျိုးအစားတွေကိုပဲ သုံးစွဲခွင့် ပေးထားပါတယ်။
* **ရလဒ်:** ဥပမာ - လူတစ်ယောက်က မှားယွင်းပြီး `instance_type: c5.4xlarge` လိုမျိုး ဈေးအရမ်းကြီးတဲ့ Server ကြီးကို Deploy လုပ်ဖို့ ကြိုးစားခဲ့ရင်၊ Terraform မစခင်မှာတင် Atmos က "Invalid instance_type" ဆိုပြီး ချက်ချင်း တားဆီး (Block) ပေးမှာ ဖြစ်ပါတယ်။

### ၂။ မဖြစ်မနေ ပါဝင်ရမည့် အချက် (Required Field)
```json
"required": ["instance_type"]
```
* **အဓိပ္ပါယ်:** `compute` component ကို သုံးပြီဆိုတာနဲ့ `instance_type` ဆိုတဲ့ Variable ကို မဖြစ်မနေ (Required) ထည့်သွင်းရပါမယ်။ လုံးဝ မေ့ကျန်ခဲ့လို့ မရပါဘူး။

---

**အနှစ်ချုပ်:** 
JSON Schema ဟာ ကိုယ့်ရဲ့ Infrastructure Code တွေမှာ **Data Type မှန်ကန်မှု (String လား၊ Number လား)** နဲ့ **ခွင့်ပြုထားတဲ့ တန်ဖိုး (Allowed Values)** တွေကို တိတ်တဆိတ် စောင့်ကြည့် ထိန်းချုပ်ပေးပါတယ်။ ငွေကုန်ကြေးကျ များစေမယ့် အမှားတွေ (Costly Mistakes) နဲ့ စာလုံးပေါင်း အမှား (Typos) တွေကို ကာကွယ်ဖို့အတွက် အလွန် အသုံးဝင်တဲ့ စနစ်ဖြစ်ပါတယ်။
