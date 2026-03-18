# Atmos Workflows 🚀

ဒီ `stacks/workflows/` Directory ထဲမှာတော့ Project တစ်ခုလုံးရဲ့ Infrastructure တွေကို လွယ်ကူမြန်ဆန်စွာ အလိုအလျောက် တည်ဆောက် (Deploy) နိုင်ဖို့၊ ဒါမှမဟုတ် ပြန်လည်ဖျက်သိမ်း (Destroy) နိုင်ဖို့အတွက် **Atmos Workflows** တွေကို စုစည်းရေးသားထားပါတယ်။

## 🌟 ဘာကြောင့် Workflows တွေကို သုံးတာလဲ?

ပုံမှန်ဆိုရင် Infrastructure တစ်ခုတည်ဆောက်ဖို့ `validate`, `plan`, `apply` အစရှိတဲ့ command တွေကို `base`, `database`, `compute` စတဲ့ အဆင့် (Layers) တွေအလိုက် တစ်ခုပြီးတစ်ခု လိုက် Run နေရပါတယ်။ 

Workflow တွေကို သုံးလိုက်တဲ့အခါ Command တစ်ကြောင်းတည်း Run ရုံနဲ့ လိုအပ်တဲ့ Layer အားလုံးကို အစီအစဉ်တကျ (Dependencies order အတိုင်း) အလိုအလျောက် တည်ဆောက်ပေးသွားမှာ ဖြစ်ပါတယ်။

---

## 📂 ရရှိနိုင်သော Workflows များ

လက်ရှိမှာ အဓိက Workflow (၄) ခု ရှိပါတယ်။

### ၁။ `deploy-stateless`
Database မပါဝင်တဲ့ ရိုးရိုး Web Server တွေ၊ Application တွေကို ချည်းပဲ Deploy လုပ်ချင်တဲ့အခါ သုံးပါတယ်။
- **လုပ်ဆောင်မည့် အဆင့်များ:**
  1. Base Layer ကို Validate လုပ်ပါမယ်။
  2. Networking တွေပါတဲ့ `base` ကို အရင်တည်ဆောက်ပါမယ်။
  3. ပြီးရင် `compute` (EC2, ALB, ECR) ကို တည်ဆောက်ပါမယ်။
  4. နောက်ဆုံးမှာ Ansible Playbook ကို ခေါ်ပြီး Server Provisioning လုပ်သွားပါမယ်။
- **အသုံးပြုပုံ:**
  ```bash
  atmos workflow deploy-stateless -s <environment>
  # ဥပမာ: atmos workflow deploy-stateless -s develop
  ```

### ၂။ `deploy-stateful`
Database, RDS တွေပါဝင်တဲ့ ပြည့်စုံတဲ့ Infrastructure တစ်ခုလုံးကို Deploy လုပ်ချင်တဲ့အခါ သုံးပါတယ်။
- **လုပ်ဆောင်မည့် အဆင့်များ:**
  1. Base Layer ကို Validate လုပ်ပါမယ်။
  2. Networking တွေပါတဲ့ `base` ကို အရင်တည်ဆောက်ပါမယ်။
  3. ပြီးရင် `database` ကို လုံခြုံစွာ တည်ဆောက်ပါမယ်။
  4. ပြီးမှသာ Application တွေ run မယ့် `compute` ကို တည်ဆောက်ပါမယ်။
  5. နောက်ဆုံးမှာ Ansible Playbook ကို ခေါ်ပြီး Server Provisioning လုပ်သွားပါမယ်။
- **အသုံးပြုပုံ:**
  ```bash
  atmos workflow deploy-stateful -s <environment>
  # ဥပမာ: atmos workflow deploy-stateful -s preprod
  ```

### ၃။ `destroy-stateless`
`deploy-stateless` နဲ့ တည်ဆောက်ထားတဲ့ Infrastructure အားလုံးကို အစီအစဉ်တကျ ပြန်လည်ဖျက်သိမ်းချင်တဲ့အခါ သုံးပါတယ်။
- **ပြန်ဖျက်မည့် အဆင့်များ (နောက်ကို အရင်ဖျက်ပါသည်):**
  1. `compute` Layer ကို အရင်ဖျက်ပါမယ်။
  2. ပြီးမှ `base` Layer ကို ဖျက်သိမ်းပါမယ်။
- **အသုံးပြုပုံ:**
  ```bash
  atmos workflow destroy-stateless -s <environment>
  ```

### ၄။ `destroy-stateful`
`deploy-stateful` နဲ့ တည်ဆောက်ထားတဲ့ Infrastructure တစ်ခုလုံး (Database အပါအဝင်) ကို အစီအစဉ်တကျ ပြန်လည်ဖျက်သိမ်းချင်တဲ့အခါ သုံးပါတယ်။ Database ပါ ပျက်သွားမှာမို့ အထူးသတိထားပြီး သုံးသင့်ပါတယ်။
- **ပြန်ဖျက်မည့် အဆင့်များ:**
  1. Application `compute` Layer ကို အရင်ဖျက်ပါမယ်။
  2. ပြီးရင် `database` ကို ဖျက်ပါမယ်။
  3. နောက်ဆုံးမှ အခြေခံ Networking `base` Layer ကို ဖျက်သိမ်းပါမယ်။
- **အသုံးပြုပုံ:**
  ```bash
  atmos workflow destroy-stateful -s <environment>
  ```

---

## 🛠️ Options နှင့် Command အပိုများ

Workflow တစ်ခုလုံးကို အစအဆုံး မ Run ချင်ဘူး၊ ပြတ်သွားတဲ့ အဆင့် (Step) တစ်ခုကနေပဲ ဆက်ပြီး (Resume) လုပ်ချင်တယ်ဆိုရင် `--from-step` ကို သုံးနိုင်ပါတယ်။

ဥပမာ - `compute` အဆင့်မှာ Error တက်ပြီး ရပ်သွားတယ်ဆိုပါစို့။ အစကနေ `base` ကို ပြန်မသွားဘဲ `compute` အဆင့်ကနေပဲ ပြန်စချင်တဲ့အခါ-

```bash
atmos workflow deploy-stateless -f deploy-stateless --from-step 'Applying the stateless compute layer' -s develop
```

> **မှတ်ချက်:** `-s <environment>` နေရာတွင် မိမိတည်ဆောက်လိုသော Stack (ဥပမာ - `develop`, `uat`, `preprod`, `production`) ကို ထည့်သွင်းအသုံးပြုရမည် ဖြစ်ပါသည်။
