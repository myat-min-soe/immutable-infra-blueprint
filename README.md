# 🚀 Modern Infrastructure: Atmos, Packer, Terraform, နှင့် Ansible ကိုအသုံးပြု၍ “Immutable Infrastructure” တည်ဆောက်ခြင်း။

> *(Note: This article is written based on this code flow / ဤ Article ကို အောက်ပါ Code Flow အပေါ် အခြေခံ၍ ရေးသားထားခြင်း ဖြစ်ပါသည်။)*
> 🔗 **[https://github.com/myat-min-soe/immutable-infra-blueprint](https://github.com/myat-min-soe/immutable-infra-blueprint)**

လက်ရှိ ခေတ်သစ် Software Ecosystem တွေမှာ CI/CD pipeline ကနေတစ်ဆင့် Infrastructure ကို Code အနေနဲ့ (**Infrastructure as Code — IaC**) Manage လုပ်တာက Standard တစ်ခုဖြစ်လာပါပြီ။ ဒါပေမယ့် Technical အားဖြင့် ဒီလို Automation လုပ်တဲ့အခါ **“ဘယ် Tool ကို ဘယ်အချိန်မှာ သုံးမလဲ (Separation of Concerns)”** ဆိုတာက အလွန်အရေးကြီးပါတယ်။

ဒီ Article မှာတော့ Live Server တွေပေါ်မှာ Script တွေ တိုက်ရိုက် run တဲ့ (Mutable) စနစ် ကနေ၊ **“Build Once, Deploy Everywhere”** လို့ခေါ်တဲ့ **“Immutable Infrastructure”** ပုံစံကို Atmos, Packer, Terraform, Ansible နှင့် GitLab CI တို့ ပေါင်းစပ်ပြီး ဘယ်လို Low-Level အလုပ်လုပ်သွားလဲဆိုတာကို DevOps တစ်ယောက်ရဲ့ အမြင်ကနေ Deep Dive ရှင်းပြပေးသွားမှာပါ။

---

## 🧐 ဘာကြောင့် ဒီ Architecture ကို ပြောင်းလဲအသုံးပြုသင့်တာလဲ? (Why Should We Use This?)

ရိုးရိုး Terraform နဲ့ Ansible သုံးနေတာပဲ၊ ဘာလို့ Packer တွေ၊ Atmos တွေ၊ Parent-Child CI တွေပါ ထပ်ပေါင်းထည့်ရတာလဲ? အကြောင်းရင်းကတော့ ရေရှည် (Scale) လုပ်တဲ့အခါ ကြုံရမယ့် ပြဿနာတွေကို ကြိုတင်ဖြေရှင်းထားလို့ပါပဲ။

* ❄️ **Snowflake Servers ပြဿနာကို အမြစ်ပြတ်ရှင်းလင်းခြင်း**
  Server တွေကို လူကိုယ်တိုင် ဝင်ပြင်ခြင်း၊ Runtime မှာ Script တွေ Error တက်ခြင်းကြောင့် ဖြစ်ပေါ်လာတဲ့ “ငါ့စက်မှာတော့ အလုပ်လုပ်တယ်” (Configuration Drift) ပြဿနာကို ရာခိုင်နှုန်းပြည့် ကာကွယ်ပေးပါတယ်။
* ⚡ **Ultra-Fast Auto-Scaling**
  Traffic တက်လာလို့ Server အသစ်တွေ အရေးပေါ်ပွားတဲ့အခါ (Auto-scaling) မှာ Software တွေလိုက်သွင်းနေရင် မိနစ်ချီ ကြာပါတယ်။ Golden Image (AMI) ကြိုထုတ်ထားတဲ့အတွက် စက္ကန့်ပိုင်းအတွင်း Server တက်လာပြီး ချက်ချင်း အလုပ်လုပ်နိုင်ပါတယ်။
* ♻️ **DRY (Don’t Repeat Yourself) Codebase**
  Environment (Dev, UAT, Prod) တစ်ခုတိုးလာတိုင်း Terraform Code တွေ ခဏခဏ Copy-Paste လုပ်စရာမလိုတော့ဘဲ Atmos ရဲ့ Wrapper စနစ်ကြောင့် YAML ဖိုင်လေးတစ်ခုတိုးရုံနဲ့ ပြီးစီးပါတယ်။
* 🛡️ **Zero-Trust Security Model**
  Bastion Hosts တွေ၊ SSH Public Key တွေ၊ Port 22 တွေကို လုံးဝမသုံးတော့ဘဲ AWS Systems Manager (SSM) ဖြင့် HTTPS API ကနေ ချိတ်ဆက်တဲ့အတွက် လုံခြုံရေးအမြင့်ဆုံး စနစ်ကို ရရှိပါတယ်။

---

## 🏗️ AWS Service-by-Service Deep Dive (Infrastructure Topology)

System ကြီးတစ်ခုလုံးကို စီမံခန့်ခွဲရ လွယ်ကူစေဖို့အတွက် Terraform Codebase တွေဖြစ်တဲ့ `components/terraform/` အောက်မှာ Layers (၃) ခု ခွဲခြားပြီး တည်ဆောက်ထားပါတယ်။ အောက်ပါအတိုင်း အသေးစိတ် လေ့လာနိုင်ပါတယ်:

### 🌐 ၁. Network & Security Layer (`components/terraform/base`)
App Server တွေ၊ Database တွေအတွက် လုံခြုံတဲ့ (Foundation) တည်ဆောက်ပေးတဲ့ အပိုင်းဖြစ်ပါတယ်။

* **Amazon VPC (Virtual Private Cloud)**: Network ကြီးတစ်ခုလုံးရဲ့ အခွံကြီးဖြစ်ပါတယ်။ Public Subnets (Internet ထွက်ခွင့်ရှိ) နှင့် Private Subnets (Internet ကနေ တိုက်ရိုက်ဝင်လို့မရ) ဆိုပြီး ခွဲခြားထားပါတယ်။
* **NAT Gateway**: Private Subnet ထဲက Server တွေပြင်ပ Internet ကို အန္တရာယ်ကင်းကင်းနဲ့ ထွက်နိုင်ဖို့ (ဥပမာ- Package တွေ ဒေါင်းလုဒ်ဆွဲဖို့) NAT Gateway က တစ်ဆင့်ခံပေးပါတယ်။
* **Logical Security Groups**: ALB (Load Balancer) အတွက်သီးသန့် `alb-sg`, App Server တွေအတွက်သီးသန့် `app-sg`၊ နဲ့ Database အတွက်သီးသန့် `db-sg` ဆိုပြီး လုံခြုံရေးအလွှာ ၃ ထပ် (3-Tier Security Group) ကို စနစ်တကျ ချိတ်ဆက်ထားပေးပါတယ်။
* **Application Load Balancer (ALB)**: Internet ကနေ ဝင်လာတဲ့ Request တွေကို လက်ခံပေးဖို့ Public Subnet အပေါ်မှာ Load Balancer တစ်ခုကို ကြိုတင်နေရာချထားပါတယ်။

### 💻 ၂. Compute & Application Layer (`components/terraform/compute`)
Application ကို Run မယ့် အဓိက အပိုင်းဖြစ်ပါတယ်။

* **Amazon EC2**: Docker containers တွေက ဒီ Private EC2 တွေပေါ်မှာ Run ပါတယ်။ (Packer နဲ့ Bake လုပ်ထားတဲ့ Golden AMI ကို သုံးပါတယ်)
* **Application Load Balancer (ALB) & Listeners**: Internet ကဝင်လာတဲ့ HTTPS Request တွေကို SSL/TLS (Offload) ပြီး Private Subnet ထဲက EC2 တွေဆီ (Target Group မှတစ်ဆင့်) မျှဝေပေးပါတယ်။
* **AWS IAM (Identity and Access Management)**:
  * EC2 အတွက် Instance Profile ဖန်တီးပေးထားလို့ S3 နဲ့ ECR တွေကို ခွင့်ပြုချက်တောင်းစရာမလိုဘဲ Access ရပါတယ်။
  * GitLab CI အတွက်လည်း လိုအပ်တဲ့ Role တွေ ဖန်တီးပေးထားပါတယ်။
* **Amazon S3 Bucket**: Data တွေသိမ်းဖို့နဲ့၊ Deployment Artifacts (ZIP ဖိုင်တွေ) ထားရှိဖို့ သုံးပါတယ်။
* **AWS CodeDeploy**: Application Code အသစ် (သို့) Docker Image Update ဖြစ်တိုင်း Server တွေပေါ်ကို Zero-Downtime Deployment ချပေးမယ့် Agent-based Orchestrator ပါ။
* **Amazon ECR (Elastic Container Registry)**: ကိုယ်ပိုင် Docker Image တွေကို လုံခြုံစွာ သိမ်းဆည်းဖို့ Private Registry ကိုလည်း ဆောက်ပေးထားပါတယ်။

### 💾 ၃. Data & State Layer (`components/terraform/database` & Backend)
* **Amazon RDS (PostgreSQL/MySQL)**: Database ကို Server ထဲမှာ တွဲမတည်ဆောက်ဘဲ AWS ရဲ့ Managed Service ဖြစ်တဲ့ RDS ကို သီးသန့် ခွဲထုတ်ထားပါတယ်။ Multi-AZ ပါဝင်လို့ Database တစ်လုံးကျသွားရင်တောင် နောက်ထပ် AZ တစ်ခုကနေ အလိုအလျောက် အစားထိုး အလုပ်လုပ်ပေးမှာပါ။

---

## 🛠️ The Core Technologies (What, Why & Codebase Deep Dive)

System တစ်ခုလုံးရဲ့ တည်ငြိမ်မှု (Stability) ရဖို့အတွက် နည်းပညာတစ်ခုချင်းစီကို သူ့တာဝန်နဲ့သူ တိတိကျကျ ခွဲခြား (Separation of Concerns) ပေးထားပါတယ်။ အဓိက အသုံးပြုထားတဲ့ Tool အသီးသီးက ဘာလုပ်လဲ၊ ဘာကြောင့်သုံးလဲနဲ့ ဘယ်လိုအလုပ်လုပ်လဲဆိုတာကို လေ့လာကြည့်ပါမယ်။

### 📦 1. Packer (The Golden Image Baker)
* **What it is:** HashiCorp ကနေ ထုတ်လုပ်ထားတဲ့ Open-source tool တစ်ခုဖြစ်ပြီး၊ Machine Image တွေ (AWS အတွက်ဆိုရင် AMI — Amazon Machine Image) ကို Code ကနေတစ်ဆင့် အလိုအလျောက် တည်ဆောက်ပေးပါတယ်။
* **Why we use it:** ပုံမှန်အားဖြင့် user data script နဲ့ဖြစ်စေ Server တက်လာမှ packages လိုက်သွင်းပါတယ်။ (Run-time Provisioning)ဟာ အချိန်ကြာသလို၊ Package Version ပြောင်းသွားရင် Error တက်နိုင်လို့ Production အတွက် အန္တရာယ်များပါတယ်။ Packer ကိုသုံးပြီး Software အားလုံး ကြိုတင်ထည့်သွင်းထားတဲ့ (Pre-baked) “Golden Image” တစ်ခု ရယူခြင်းဖြင့် Server တက်တာနဲ့ ချက်ချင်း အလုပ်လုပ်နိုင်ပါတယ်။
* **How it works (Native Atmos Component Deep Dive):**
  * **Atmos Component Integration (Latest Feature):** အရင်လို `packer build` သက်သက် သွားမခေါ်တော့ဘဲ Packer ကို Atmos ရဲ့ Native Component အဖြစ် အပြည့်အဝ ပေါင်းစပ်ထားပါတယ်။ (`stacks/packer.yaml` ထဲမှာ Component အနေနဲ့ တရားဝင် သတ်မှတ်ထားတာပါ)။
  * **Builder (`build.pkr.hcl`):** Packer က Ubuntu 24.04 ကို အခြေခံအဖြစ် ယူကာ AWS ebs builder ကိုအသုံးပြုပါတယ်။
  * **Contextual Provisioner (`install_packages.sh`):** ယာယီ EC2 instance ထဲမှာ Shell script ရိုက်ပါတယ်။ စိတ်ဝင်စားစရာကောင်းတာက `INSTALL_NGINX`, `INSTALL_MYSQL_SERVER` နှင့် `AWS_REGION` တွေကို အပြင်ကနေမပို့ဘဲ Atmos Stack ထဲကနေတစ်ဆင့် Environment Vars အနေနဲ့ Script ဆီ တိုက်ရိုက် လှမ်းပို့ပေးတာပါပဲ။
  * **Baked-in Dependencies:** Script က Nginx, Docker, Docker Compose နှင့် MySQL ကို သွင်းပေးရုံသာမက၊ AWS CodeDeploy Agent ကိုပါ တစ်ပါတည်း စနစ်တကျ သွင်းပေးလိုက်ပါတယ်။
  * **Build Once, Deploy Anywhere (AMI Copy Strategy):** Packer ဟာ `develop` ပတ်ဝန်းကျင်မှာ တစ်ကြိမ်တည်းသာ (Only Once) Image ကို Bake ပါတယ်။ ကျန်တဲ့ `uat`, `preprod`, `prod` တွေအတွက် ထပ်မံ Build စရာမလိုပါဘူး။ ယင်းအစား GitLab CI Pipeline ထဲကနေတစ်ဆင့် `develop` မှာ အောင်မြင်စွာ စမ်းသပ်ပြီးသား AMI အတိအကျကို အခြား Environment တွေနဲ့ AWS Accounts တွေဆီကို AMI Copy Strategy သုံးပြီး တိုက်ရိုက် ကူးယူသွားပါတယ်။
  * **Result:** ဒါကြောင့် Environment တိုင်းမှာရှိတဲ့ Docker နှင့် Nginx ဗားရှင်းတွေဟာ ၁၀၀% ထပ်တူညီသွားပါတယ်။ ထို့အပြင် Server တက်လာတာနဲ့ Application Deploy ချဖို့ အဆင်သင့်ဖြစ်နေပြီး၊ လက်ရှိ Github က code မှာ Auto Scaling Group (ASG) ကို ထည့်မထား သော်လည်း ASG နဲ့ တွဲဖက်အသုံးပြုဖို့ရာ အပြည့်အဝ အသင့်ဖြစ်နေသော (ASG-Compatible) Architecture တစ်ခုဖြစ်ပါတယ်။

### 🧠 2. Atmos (The Infrastructure Configuration Wrapper)
* **What it is:** Cloud Posse က ဖန်တီးထားတဲ့ Open-source CLI Tool တစ်ခုဖြစ်ပြီး၊ Terraform ကိုသာမက Packer နှင့် Ansible ကိုပါ Native Component များအနေဖြင့် Environment ပေါင်းများစွာ (Multi-environment) မှာ တပြေးညီ လွယ်ကူစနစ်တကျ Manage လုပ်ပေးတဲ့ Wrapper သို့မဟုတ် Orchestrator ဖြစ်ပါတယ်။
* **Why we use it:** သာမန်အားဖြင့် Packer တစ်မျိုး၊ Terraform တစ်မျိုး၊ Ansible တစ်မျိုးစီအတွက် Variable တွေ (ဥပမာ- Region, Environment Name, Tags) ကို သီးခြားစီ ခွဲရေးရပါတယ်။ Atmos ဟာ ဒီလို Duplicate ဖြစ်နေမယ့် Code တွေကို ဖယ်ရှားပေးပြီး Tools (၃) မျိုးလုံးအတွက် Universal Source of Truth (DRY Principle) အဖြစ် အပြည့်အဝရပ်တည်ပေးပါတယ်။
* **How it works (Advanced Directory Structure & Features Deep Dive):** Atmos ရဲ့ အမိုက်ဆုံး အချက်က Component Inheritance နဲ့ တိကျတဲ့ Directory ဖွဲ့စည်းပုံပါ။ ၎င်းတို့အားလုံးကို `stacks/` အောက်က YAML တွေနဲ့ ဗဟိုကနေ လှမ်းပြီး ထိန်းချုပ်ပါတယ်။
  * **Catalog (`stacks/catalog/`) — The Baseline:** Component တစ်ခုချင်းစီအတွက် အခြေခံအကျဆုံး Default တန်ဖိုးတွေကို ဒီထဲမှာ သတ်မှတ်ပါတယ်။ ဥပမာ (`stacks/catalog/base/defaults.yaml`):
    ```yaml
    components:
      terraform:
        base:
          vars:
            create_nat: true
            azs: ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    ```
  * **Mixins (`stacks/mixins/`) — Reusable Fragments:** Programming မှာ Function တွေ ခွဲရေးပြီး ပြန်ခေါ်သုံး (Reuse) သလိုမျိုး၊ YAML ထဲမှာ ထပ်ခါတလဲလဲ ရေးရမယ့် `region` တွေ၊ `stage` တွေကို သီးခြားစီ ခွဲထုတ်ထားပါတယ်။ Mixins ကို သုံးလိုက်တဲ့အတွက် Environment ဖိုင်တွေ (ဥပမာ `develop.yaml`) ရဲ့ အပေါ်ဆုံးမှာ အောက်ပါအတိုင်း ရှင်းလင်းစွာ ခေါ်သုံး (Import) လိုက်ရုံပါပဲ:
    ```yaml
    import:
    - catalog/base/defaults # (၁) Baseline ကို ယူမယ်
    - mixins/region/ap-southeast-1 # (၂) Region Mixin ကို ယူမယ်
    - mixins/stage/develop # (၃) Stage Mixin ကို ယူမယ်
    ```
    ဒီလို `import:` ခေါ်လိုက်ရုံနဲ့ အရာအားလုံးကို Inherit အမွေဆက်ခံလိုက်ပြီး၊ `develop` လိုအပ်တဲ့ သီးသန့် `vpc_cidr` နှင့် `env: START_MYSQL_SERVER: “true”` လို Variable တွေကိုသာ ထပ်မံ Inject (ပေါင်းထည့်) ပေးသွားပါတယ်။
  * **Schemas (`stacks/schemas/`) — Pre-flight Validation:** သာမန်အားဖြင့် DevOps တစ်ယောက်က `instance_type` အမှားရေးမိရင် Terraform (သို့) AWS ဆီရောက်မှ Error တက်ပါတယ်။ Schema တွေက ဒီလို အမှားတွေ (Human Errors) ကို ကြိုတင်ကာကွယ်ပေးပါတယ်။
    * **JSON Schema:** Variable တွေရဲ့ Data Type မှန်/မမှန် နဲ့ ခွင့်ပြုထားတဲ့ တန်ဖိုး (ဥပမာ- `t3a.small` သာ ခွင့်ပြုမယ်) ကို စစ်ဆေးပါတယ်။
    * **OPA Schema (Open Policy Agent):** ပိုမို ရှုပ်ထွေးတဲ့ Logic တွေ၊ ဥပမာ — “Environment က `production` ဆိုရင် Database ဟာ `multi_az: true` ဖြစ်ကိုဖြစ်ရမယ်” ဆိုတဲ့ Security/Compliance စည်းမျဉ်းတွေကို Rego language နဲ့ ထိန်းချုပ်ထားပါတယ်။
    * **Result:** လိုအပ်ချက်နဲ့ မကိုက်ညီရင် **Terraform အဆင့်ကိုတောင် ရောက်ခွင့်မပေးဘဲ Atmos ဆီမှာတင် Error ပြပြီး Block လုပ်ပေးမှာ** ဖြစ်ပါတယ်။

### 🏗️ 3. Terraform (The State Master)
* **Why we use it:** AWS Resource တွေကို Manual (ClickOps) ဆောက်ရင် ခြေရာခံဖို့ ခက်ခဲပါတယ်။ Infrastructure As Code အဖြစ် တိကျသေချာစွာ တည်ဆောက်နိုင်ဖို့ Terraform ကို အဓိက သုံးထားပါတယ်။
* **How it works (Deep Dive):**
  * **Native S3 State Locking (Goodbye DynamoDB!):** Terraform 1.10+ ရဲ့ အမိုက်စား feature အသစ်ဖြစ်တဲ့ Native S3 Locking ကိုသုံးထားလို့ `use_lockfile: true` လို့ ထည့်လိုက်ရုံနဲ့ S3 ပေါ်မှာတင် State locking ရရှိပါတယ်။
  * **Dynamic AMI Data Source:** Terraform Code ထဲမှာ AMI ID တွေကို Hardcode လုံးဝ မရေးပါဘူး။ Packer က Image အသစ် Bake ပြီးသွားတိုင်း Terraform Run ပြီး Latest AMI အသစ်ကို ယူကာ Server ကို Update လုပ်ပေးနိုင်ပါတယ်။

### 🤖 4. Ansible (The Configuration Tuner)
* **What it is:** Red Hat က ပိုင်ဆိုင်တဲ့ နာမည်ကြီး Configuration Management Tool ပါ။ Server တွေကို SSH ကနေလှမ်းချိတ်ပြီး လိုအပ်တဲ့ Setting တွေ၊ Software တွေ သွင်းပေးပါတယ်။
* **Why we use it:** Packer က Software အကြမ်းထည်တွေ သွင်းပေးခဲ့ပေမယ့်၊ ပတ်ဝန်းကျင်အလိုက် ကွဲလွဲနေတဲ့ Configuration (Environment-specific settings) တွေကို Ansible နဲ့ setting ချနိုင်ပါတယ်။
* **How it works (Zero-Trust SSM & Atmos Integration Deep Dive):**
  * **Atmos Native Component:** `atmos ansible playbook provisioning -s develop` လို့ ခေါ်လိုက်တာနဲ့ သက်ဆိုင်ရာ Environment ရဲ့ Context တွေ၊ Variable တွေကို အလိုအလျောက် ရရှိပြီး terraform နဲ့ create ထားတဲ့ instance ကို ဝင် run နိုင်ပါတယ်။
  * **Dynamic Tag Discovery:** Inventory မှာ IP တွေ လိုက်မရေးပါဘူး။ AWS ထဲကနေ အလိုအလျောက် ရှာဖွေပေးပါတယ်။
  * **Zero-Trust Connection:** Private Subnet ထဲက EC2 တွေကို ဝင်ချိတ်ဖို့ SSH Port 22 လုံးဝ မသုံးပါဘူး။ AWS Systems Manager (SSM) ဖြင့် ဝင်ရောက်လုပ်ဆောင်ပါတယ်။
  * **Idempotency & Dynamic State Control:** ဥပမာ- `develop` ရောက်ရင် `systemctl start mysql` လုပ်ဖို့ ညွှန်ကြားပြီး၊ AWS RDS သုံးတဲ့ `production` ရောက်ရင် `systemctl stop mysql` လို့ပိတ်ပစ်ဖို့ကို Atmos ကနေတစ်ဆင့် အလိုအလျောက် ဆုံးဖြတ်သွားပါတယ်။

### 🛡️ 5. tfsec (The Shift-Left Security Concept)
* **What it is:** Terraform Infrastructure Code အပေါ်မှာ လုံခြုံရေး အားနည်းချက် (Security Vulnerability) တွေရှိမရှိ ကြိုတင်စစ်ဆေးပေးတဲ့ (Static Code Analysis) Security Tool ပါ။
* **Why we use it:** လူအမှားကြောင့် Security Group မှာ Port 22 ကို Public (0.0.0.0/0) ဖွင့်မိတာမျိုး၊ Database တွေ Encrypt မလုပ်ထားတာမျိုး၊ S3 Bucket တွေကို Public Read ဖွင့်ထားမိတာမျိုးကို တားဆီးဖို့ CI Pipeline ရဲ့ ရှေ့ဆုံးမှာ အသုံးပြုပါတယ်။
* **How it works (Deep Dive):** Pipeline ထဲမှာ `terraform plan` မလုပ်ခင် `tfsec` ကို အရင် Run ပါတယ်။ ရေးထားတဲ့ Terraform Code (HCL) တွေကို Abstract Syntax Tree (AST) ပုံစံပြောင်းပြီး Scan ဖတ်ပါတယ်။
  * **Fast Detection:** ကိုယ်ရေးလိုက်တဲ့ လုံခြုံရေး အားနည်းချက်ကို Cloud မရောက်ခင် စက္ကန့်ပိုင်းအတွင်း သိနိုင်ပါတယ်။ (Cloud ထဲဝင်မစစ်လို့ AWS Access Keys ပေးထားစရာ မလိုပါဘူး။)
  * **Handling False Positives:** တမင်တကာ ပြင်ပလောကကို ပေးဝင်ရမယ့် Application Load Balancer လိုမျိုးတွေအတွက် Error မပြအောင် Terraform Code အပေါ်မှာ Ignore Comment လေးတပ်ပြီး ထိန်းချုပ်နိုင်ပါတယ်။
    ```hcl
    #tfsec:ignore:aws-vpc-no-public-ingress-sg
    resource "aws_security_group_rule" "alb_http_ingress" {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
    ```
  ဒါကို **“Shift-Left Security”** (လုံခြုံရေးကို နောက်ဆုံးမှ မစစ်ဘဲ၊ Code ရေးတဲ့ CI အဆင့်မှာတင် ဖမ်းယူစစ်ဆေးခြင်း) လို့ ခေါ်ပါတယ်။

### 🔄 6. GitLab CI (The Parent-Child Orchestrator)
* **What it is:** Tools အားလုံး အစီအစဉ်တကျ အလိုအလျောက် အလုပ်လုပ်သွားအောင် အစအဆုံး ထိန်းကျောင်းပေးတဲ့ Continuous Integration (CI) Engine ဖြစ်ပါတယ်။
* **Why we use it:** Monolithic ဖိုင်ကြီးတစ်ခုလုံးမှာ မရေးဘဲ Parent-Child Pipeline Architecture ကို အသုံးပြုထားလို့ အရမ်းမြန်ဆန်ပါတယ်။
* **How it works (Deep Dive):**
  * **Parent Router (`.gitlab-ci.yml`):** အဓိက Root ဖိုင်က Trigger Role တွေကိုပဲ တာဝန်ယူပြိး User တွေကို UI ခလုတ် တွေပဲ ပြပေးပါတယ်။ အသေးစိတ်ကို `.gitlab/ci/` အောက်မှာ ခွဲထုတ်ထားပါတယ်။
  * **Child Pipelines:**
    * **Packer (`packer.yml`):** `components/packer/` အောက်က Code တွေပြင်မှသာလျှင် Packer Build ကို CI မှာ ပေါ်လာအောင် (Conditional Trigger) ပေးပါတယ်။
    * **Terraform (`terraform.yml`):** `tfsec` ကို အရင်စစ်ပါတယ်။ `terraform plan` ထွက်လာတဲ့ Binary `.tfplan` ဖိုင်ကို GitLab Artifact အနေနဲ့ သိမ်းပါတယ်။ အဲ့ဒီ **သိမ်းထားတဲ့ Artifact အတိအကျကိုပဲ `terraform apply` က ပြန်ခေါ်သုံးပါတယ်**။ ဒါကြောင့် Plan နဲ့ Apply ကြားမှာ Code တွေ ပြောင်းသွားနိုင်တဲ့ Race Condition ပြဿနာကို လုံးဝ ကာကွယ်ပေးထားပါတယ်။
    * **Ansible (`ansible.yml`):** Running ဖြစ်လာတဲ့ Server တွေကို SSM ကနေ Config ပုံသွင်းပါတယ်။

---

## 🎮 7. Day-to-Day Operations: Atmos Workflows

Infrastructure အကြီးကြီးတစ်ခု ဆောက်ပြီးသွားတဲ့အခါ “ဘယ်လို ပြုပြင်ထိန်းသိမ်း (Operate) မလဲ” ဆိုတာက အင်မတန် အရေးကြီးတဲ့ မေးခွန်းပါ။ Terraform နဲ့ချည်းဆိုရင် အဆင့်ဆင့် လူကိုယ်တိုင် လိုက်လုပ်နေရပါတယ်။

ဒီ Project မှာ ဒါကိုဖြေရှင်းဖို့ Atmos Workflows တွေကို စိတ်ကြိုက်ရေးသား (Custom build) ပေးထားပါတယ်။ Command တစ်ကြောင်းတည်းနဲ့ လိုအပ်တဲ့ Layer အားလုံးကို Dependency Order အတိုင်း အလိုအလျောက် သွားပေးပါတယ်။

ဥပမာ လက်တွေ့အသုံးချနိုင်သော Workflows များ:
* **deploy-stateless**: Database မပါဝင်တဲ့ ရိုးရိုး Web Server သက်သက် Deploy လုပ်ချင်တဲ့အခါ: 👉 `atmos workflow deploy-stateless -s develop` (base -> compute -> ansible)
* **deploy-stateful**: RDS Database ပါဝင်တဲ့ အပြည့်အစုံ Deploy ချင်တဲ့အခါ: 👉 `atmos workflow deploy-stateful -s preprod` (base -> database -> compute -> ansible)
* **destroy-stateful**: Infrastructure တစ်ခုလုံးကို ပြန်ဖျက်သိမ်း (Teardown) ချင်ရင် နောက်ပြန်အတိုင်း (Reverse Order) အလိုအလျောက် လုံခြုံစွာ ဖျက်သိမ်းပေးပါတယ်။

ဒီလို Workflow တွေ ဖန်တီးထားခြင်းအားဖြင့် DevOps အသစ်ရောက်လာရင်တောင် Documentation အထူကြီး ဖတ်စရာမလိုဘဲ Command တစ်ကြောင်းတည်းနဲ့ Production-ready Infrastructure ကို ယုံကြည်မှုအပြည့်နဲ့ ကိုင်တွယ်နိုင်သွားပါပြီ။

---

## 💡 The Verdict (နိဂုံးချုပ် သုံးသပ်ချက်)

> ဒီ Architecture ဟာ ခေတ်သစ် Cloud-Native ကုမ္ပဏီကြီးတွေသုံးတဲ့ Cloud Architecture Design Pattern ကို တိုက်ရိုက်အသုံးချထားခြင်းဖြစ်ပါတယ်။
>
> State (Configuration) ကို Run-time ရောက်မှ မတွက်ခိုင်းဘဲ၊ Build-time (Packer) ကတည်းက အတိအကျ Freeze လုပ်လိုက်တဲ့စနစ် ဟာ Infrastructure ကို “Predictable” အဖြစ်ဆုံး၊ မြန်ဆန်ဆုံးနဲ့ လုံခြုံမှုအရှိဆုံး ဖြစ်စေတဲ့ Best Practice တစ်ခုဖြစ်ကြောင်း မျှဝေလိုက်ရပါတယ်။ 🚀