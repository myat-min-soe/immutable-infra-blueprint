# Atmos Component Catalog (`stacks/catalog/`)

ဒီ Folder (`stacks/catalog/`) ဟာ ကိုယ့်ရဲ့ Infrastructure တွေမှာ ပါဝင်တဲ့ **Component တွေ (ဥပမာ - `base`, `compute`, `database`) ရဲ့ အခြေခံ သတ်မှတ်ချက် (Default Configurations) တွေကို စုစည်း သိမ်းဆည်းထားတဲ့ နေရာ (Library)** ဖြစ်ပါတယ်။

## ဘာကြောင့် သုံးရသလဲ? (Why use a Catalog?)

`develop`, `uat`, `preprod`, `production` စတဲ့ Environment တွေအကုန်လုံးမှာ `compute` component ကို သုံးတဲ့အခါ **S3 Backend ဘယ်လိုချိတ်မလဲ**, **Workspace Key Prefix က ဘာပါလဲ**, **Schema Validation ကို ဘယ်ဖိုင်နဲ့ စစ်မလဲ** ဆိုတဲ့ အချက်တွေက အမြဲတမ်း တူညီနေမှာ ဖြစ်ပါတယ်။

ဒါတွေကို Environment ဖိုင် ၄ ခုလုံးမှာ လိုက်ရေးနေမယ့် အစား:
1. `catalog/compute/defaults.yaml` ထဲမှာ တစ်ခါတည်း သတ်မှတ်လိုက်ပါတယ်။
2. နောက်ပြီး Environment ဖိုင်တွေကနေ `import: - catalog/compute/defaults` ဆိုပြီး လှမ်းခေါ်သုံးလိုက်ပါတယ်။

ဒါကြောင့် Component အသစ်တစ်ခု တိုးလာတိုင်း Catalog ထဲမှာ အရင်စ ဆောက်ပြီးမှ Environment တွေက ဆွဲယူ သုံးစွဲတဲ့ စနစ် (Component-driven architecture) ဖြစ်ပါတယ်။

## Mixins နဲ့ ဘာကွာသလဲ?

- **Mixins (`stacks/mixins/`):** သီးသန့် Variable လေးတွေ (ဥပမာ - `region`, `stage` name) ကိုသာ သိမ်းဆည်းဖို့ သုံးပါတယ်။
- **Catalog (`stacks/catalog/`):** Component တစ်ခုလုံးရဲ့ ဖွဲ့စည်းပုံ အကြီးကြီးတွ (ဥပမာ - `backend` သတ်မှတ်ချက်တွေ၊ `validation` rules တွေ၊ Default Variables တွေ) ကို သိမ်းဆည်းဖို့ သုံးပါတယ်။

## ဘယ်လို အလုပ်လုပ်သလဲ?

`catalog/compute/defaults.yaml` မှာ အောက်ပါအတိုင်း Component တစ်ခုလုံးကို တည်ဆောက်ထားပါတယ်။

```yaml
components:
  terraform:
    compute:
      settings:
        validation:
          jsonschema:
            schema_path: "compute.json"
      backend_type: s3
      backend:
        s3:
          bucket: "terraform-backend-storage"
          # ...
```

ဒီလို ရေးထားတဲ့အတွက် Environment ဖိုင်တွေ (e.g. `develop.yaml`) ထဲမှာ ကိုယ်ပြောင်းလဲချင်တဲ့ အချက်လေးတွေ (ဥပမာ - `vpc_id`, `frontend_domain_name`) လောက်ပဲ သီးသန့် ခွဲရေးဖို့ ကျန်ပါတော့တယ်။ ကျန်တဲ့ လုံခြုံရေးဆိုင်ရာ Backend တွေ၊ Schema တွေကို Catalog ကနေ အလိုအလျောက် ရယူ (Inherit လုပ်) သွားမှာ ဖြစ်ပါတယ်။
