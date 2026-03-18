# Atmos Mixins (`stacks/mixins/`)

ဒီ Folder (`stacks/mixins/`) ဟာ ကိုယ့်ရဲ့ Infrastructure Configurations (YAML ဖိုင်တွေ) မှာ **ထပ်ခါတလဲလဲ သုံးရမယ့် Variables လေးတွေကို သီးခြားစီ ခွဲထုတ်ပြီး သိမ်းဆည်းထားတဲ့ နေရာ (Reusable Configuration Fragments)** ဖြစ်ပါတယ်။ 

Programming မှာ Functions တွေ ခွဲရေးပြီး ပြန်ခေါ်သုံး (Reuse) သလိုမျိုး၊ Atmos YAML ဖိုင်တွေမှာ ခွဲထုတ်ရေးတဲ့ စနစ်ပါ။

## ဘာကြောင့် သုံးရသလဲ? (Why use Mixins?)

ဥပမာ - သင့်မှာ `develop`, `uat`, `preprod`, `production` ဆိုပြီး Environment ၄ ခု ရှိတယ် ဆိုပါစို့။ အားလုံးက `ap-southeast-1` (Singapore Region) မှာပဲ ဆောက်မှာ ဖြစ်တယ်။
Mixin မသုံးဘူးဆိုရင် ဒီ Region name ကို YAML ဖိုင် ၄ ခုလုံးထဲ လိုက်ရေးနေရမှာပါ။ 

Mixin ကို သုံးလိုက်တဲ့အခါ:
1. `stacks/mixins/region/ap-southeast-1.yaml` ဆိုပြီး ဖိုင်တစ်ဖိုင်တည်းမှာ `region: ap-southeast-1` လို့ တစ်ခါတည်း သတ်မှတ်လိုက်ပါတယ်။
2. ကျန်တဲ့ ဖိုင်တွေ (ဥပမာ - `develop.yaml`) ကနေ `import: - mixins/region/ap-southeast-1` ဆိုပြီး လှမ်းခေါ် (Import) သုံးလိုက်ရုံပါပဲ။
3. နောက်ပိုင်း Region ပြောင်းချင်ရင် ဖိုင်တစ်နေရာတည်းမှာပဲ ပြင်လိုက်ရုံနဲ့ အားလုံးကို အလိုအလျောက် သက်ရောက်သွားမှာ ဖြစ်ပါတယ်။ (Don't Repeat Yourself - DRY Principle)

## လက်ရှိ Mixins ဖွဲ့စည်းပုံ

1. **`mixins/region/`** 
   - AWS Region သတ်မှတ်ချက်တွေ သိမ်းဖို့ပါ။
   - ဥပမာ - `ap-southeast-1.yaml`
2. **`mixins/stage/`** 
   - Environment (Stage) နာမည်တွေ သတ်မှတ်ဖို့ပါ။
   - ဥပမာ - `develop.yaml` ထဲမှာ `stage: develop` နဲ့ `environment: develop` လို့ သတ်မှတ်ထားပါတယ်။

## ဘယ်လို အလုပ်လုပ်သလဲ?

ပင်မ Environment ဖိုင် (ဥပမာ - `stacks/develop.yaml`) ရဲ့ အပေါ်ဆုံးမှာ `import` သုံးပြီး Mixins တွေကို လှမ်းခေါ်ထားပါတယ်။

```yaml
import:
  - catalog/base/defaults
  - mixins/region/ap-southeast-1
  - mixins/stage/develop

vars:
  aws_id: "118955426917"
```

ဒီလိုရေးထားတဲ့အတွက် `develop.yaml` ဖိုင်ဟာ ရှင်းလင်းသွားပြီး သီးသန့်ဖြစ်တဲ့ `aws_id` လိုမျိုး Variable လောက်ပဲ ကျန်ခဲ့ပါတယ်။ ကျန်တာတွေအားလုံးကို Mixins နဲ့ Catalog ထဲကနေ ဆွဲယူ (Inherit) သွားတာ ဖြစ်ပါတယ်။
