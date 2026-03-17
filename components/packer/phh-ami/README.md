# Demo AMI with Packer & Atmos

ဤ Directory သည် Atmos နှင့် Packer ကို အသုံးပြုပြီး Demo (Pun Hlaing Hospitals) ပရောဂျက်အတွက် လိုအပ်သော Amazon Machine Image (AMI) ဖန်တီးရန် တည်ဆောက်ထားခြင်းဖြစ်ပါသည်။

## ဘာကြောင့် Packer ကို သုံးရတာလဲ? (Why)

၁။ **အချိန်ကုန်သက်သာခြင်း (Faster Deployment)** - EC2 Instance အသစ်တစ်ခု တက်လာတိုင်း လိုအပ်သော Nginx, Docker, Docker Compose နှင့် MySQL တို့ကို အစကနေ ပြန်သွင်းစရာမလိုဘဲ ကြိုတင်သွင်းထားပြီးသား (Pre-baked) AMI ကို အသုံးပြုခြင်းဖြင့် Boot Time ကို သိသိသာသာ လျှော့ချပေးနိုင်ပါသည်။
၂။ **Immutable Infrastructure** - ပြောင်းလဲမှုတစ်ခုခုလုပ်လိုပါက လက်ရှိ run နေသော Server ပေါ်တွင် တိုက်ရိုက်မလုပ်ဘဲ Image (AMI) အသစ်တစ်ခု ပြန်လည်တည်ဆောက်ပြီး အသုံးပြုသည့် စနစ်ကို ကျင့်သုံးနိုင်ရန်ဖြစ်ပါသည်။
၃။ **မပြောင်းလဲသောစနစ် (Consistency)** - Server အသစ်ဘယ်နှစ်လုံးပဲဖွင့်ဖွင့် တူညီသော Software Version များနှင့် တူညီသော Configuration များကို အမြဲတမ်း ရရှိစေရန်ဖြစ်ပါသည်။

## ဘယ်လိုအလုပ်လုပ်လဲ? (How)

၁။ **Packer Builder** - `build.pkr.hcl` တွင် အခြေခံ OS (Base OS) အနေဖြင့် Ubuntu 24.04 ကို အသုံးပြုထားပြီး AWS AMI အသစ်တစ်ခု တည်ဆောက်ရန် သတ်မှတ်ထားပါသည်။
၂။ **Shell Provisioner** - Packer သည် AMI ကို အပြီးသတ် မသိမ်းဆည်းမီ ယာယီ EC2 instance တစ်ခုပေါ်တွင် `install_packages.sh` (Shell Script) ကို Run ပေးပါသည်။ ဤ Script သည် Nginx, Docker, Docker Compose နှင့် MySQL တို့ကို တိုက်ရိုက် Install လုပ်သွားမည်ဖြစ်ပါသည်။
၃။ **Atmos Integration** - Atmos မှတစ်ဆင့် `stacks/deploy/<env>.yaml` အတွင်းရှိ `packer` configuration များကို ဖတ်ကာ Packer သို့ Variable (ဥပမာ - region, environment, install_nginx=true စသည်ဖြင့်) ထည့်သွင်းပေးပါသည်။ ထို Variable များအပေါ်မူတည်၍ Script က လိုအပ်သော Software များကို ရွေးချယ် Install လုပ်သွားပါသည်။

## အသုံးမပြုမီ လိုအပ်ချက်များ (Prerequisites)

Packer တွင် AWS နှင့် ချိတ်ဆက်အလုပ်လုပ်နိုင်ရန် (ဥပမာ - EC2 ဖွင့်ခြင်း၊ AMI မှတ်တမ်းတင်ခြင်း) Core Packer အပြင် သီးသန့် "Amazon Plugin" တစ်ခု လိုအပ်ပါသည်။ `build.pkr.hcl` ဖိုင်ထဲတွင် ကျွန်ုပ်တို့က ထို Plugin ကို သုံးမည်ဟု ကြေညာထားသောကြောင့် Packer ကို ပထမဆုံးအကြိမ် စတင်အသုံးပြုမည်ဆိုပါက ထို Plugin ကို အရင်ဆုံး Download ဆွဲရန် `init` လုပ်ပေးရပါမည်။

ထို့ကြောင့် အောက်ပါ command ကို **ပထမဆုံး တစ်ကြိမ်** မဖြစ်မနေ Run ပေးရပါမည်။

```bash
# လိုအပ်သော Plugin များ (ဥပမာ amazon-ebs plugin) ကို အရင်သွင်းရန်
atmos packer init Demo-ami -s packer
```

## ဘယ်လို Build လုပ်မလဲ? (Usage)

AMI အသစ်တစ်ခု တည်ဆောက်ရန် Project ၏ ဗဟို (Root folder) မှနေ၍ အောက်ပါ command ကို Run ပါ။

```bash
# Base AMI ကို Unified Image အဖြစ် ဆောက်ရန် (Environment အားလုံးအတွက်)
atmos packer build Demo-ami -s packer
```

ဤသို့ Run လိုက်ပါက အလုပ်လုပ်ဆောင်မှု ပြီးဆုံးသည့်အခါ သင်၏ AWS account အတွင်းသို့ `Demo-base-image-<timestamp>` အမည်ဖြင့် အသင့်သုံးနိုင်သော AMI အသစ်တစ်ခု ရောက်ရှိလာမည်ဖြစ်ပါသည်။

## မဆောက်ခင် ကြိုတင်စစ်ဆေးလိုလျှင် (Dry Run / Validation)

အမှန်တကယ် AWS ပေါ်တွင် AMI မဆောက်ခင် ကုတ် (Code) များ မှန်မမှန်ကို ကြိုတင်စစ်ဆေး (Dry Run အနေဖြင့် Validate လုပ်) လိုပါက အောက်ပါ command ကို အသုံးပြုနိုင်ပါသည်။

```bash
atmos packer validate Demo-ami -s packer
```

## Terraform တွင် ဘယ်လို ပြန်လည်အသုံးပြုမလဲ? (Using the AMI in Terraform)

Packer ဖြင့် AMI ကို တည်ဆောက်ပြီးသောအခါ အဆိုပါ AMI ၏ ID (ဥပမာ `ami-0a1b2c...`) သည် ပြောင်းလဲတတ်ပါသည်။ ထို့ကြောင့် Terraform တွင် AMI ID ကို Hardcode အသေမရေးဘဲ **Data Source** ကို အသုံးပြု၍ အလိုအလျောက် ရှာဖွေနိုင်ပါသည်။

ကျွန်ုပ်တို့၏ `build.pkr.hcl` တွင် `tags` များ သတ်မှတ်ပေးထားသောကြောင့် Terraform တွင် အောက်ပါကဲ့သို့ `aws_ami` ကို အသုံးပြု၍ ဆွဲယူနိုင်ပါသည်။

```hcl
data "aws_ami" "Demo_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["Demo-base-image"] # AMI ပေါ်ရှိ Tag Name နှင့် ကိုက်ညီရမည်
  }

  filter {
    name   = "tag:ManagedBy"
    values = ["Atmos/Packer"]
  }
}

# EC2 Instance ဆောက်ရာတွင် အသုံးပြုခြင်း
resource "aws_instance" "app" {
  ami           = data.aws_ami.Demo_ami.id
  instance_type = "t3a.small"
  # ...
}
```

အထက်ပါနည်းလမ်းဖြင့် Packer သည် AMI အသစ်တစ်ခု ဆောက်လိုက်တိုင်း Terraform က နောက်ဆုံးဆောက်ထားသော AMI အသစ်ကို အလိုအလျောက် ရွေးချယ်အသုံးပြုသွားမည် ဖြစ်ပါသည်။

## Packer တွင် Terraform ကဲ့သို့ Backend State ရှိပါသလား? (State Management)
**မရှိပါ။** Packer သည် Terraform ကဲ့သို့ `.tfstate` ဖိုင်ဖြင့် မိမိဘာတွေဆောက်ခဲ့သည်ဆိုသည့် မှတ်တမ်း (State) ကို သိမ်းဆည်းထားလေ့မရှိပါ။ Packer ၏ အလုပ်မှာ "သတ်မှတ်ချက်အတိုင်း Image ကို ဆောက်ပြီး AWS ပေါ်တင်ပေးလိုက်ခြင်း" သီးသန့်သာ ဖြစ်ပါသည်။ သို့သော် မိမိဆောက်ခဲ့သော လတ်တလော AMI ID များကို မှတ်တမ်းတင်ထားချင်ပါက Packer ၏ `manifest` post-processor ကိုသုံး၍ JSON ဖိုင် အဖြစ် ထုတ်ယူသိမ်းဆည်းထားနိုင်ပါသည်။ (သို့သော် AWS Console/Tags မှတစ်ဆင့် ပြန်လည်ရှာရခြင်းက ပို၍ လက်တွေ့ကျပါသည်။)

## AMI ၏ Version နှင့် ပါဝင်သော Packages များကို ဘယ်လို မှတ်သား/စီမံမလဲ? (Versioning & Tracking)

AMI အသစ်တစ်ခု ဆောက်လိုက်တိုင်း မည်သည့် Package အသစ်များ ပါသွားသည်၊ မည်သည့်အကြောင်းကြောင့် Release လုပ်လိုက်သည် ဆိုသည်ကို Packer ကိုယ်တိုင်က Dashboard ဖြင့် ပြသမပေးနိုင်ပါ။ ထို့ကြောင့် အောက်ပါ **Best Practices (၃) ခု** ကို ပေါင်းစပ်အသုံးပြုရပါမည်။

### ၁။ AMI Tags များကို အပြည့်အဝအသုံးချခြင်း (AWS tagging)
`build.pkr.hcl` ဖိုင်ထဲရှိ `tags` ကို အသုံးပြု၍ AMI ပေါ်တွင် တိုက်ရိုက်မှတ်သားထားနိုင်ပါသည်။
```hcl
tags = {
  Name          = "${var.ami_prefix}-image"
  ManagedBy     = "Atmos/Packer"
  Version       = "v1.2.0" # Version သတ်မှတ်ချက်
  Packages      = "Nginx, Docker, MySQL" # သိသာသော အပြောင်းအလဲများ
  BuildCommitID = "abc123d" # Git Commit Hash
}
```
ဤသို့ Tag များတပ်ထားခြင်းဖြင့် AWS Console ထဲသို့ဝင်ကြည့်လိုက်သည်နှင့် ဤ AMI သည် ဘာအတွက်ဆောက်ထားသည်ကို အလွယ်တကူ သိနိုင်ပါသည်။

### ၂။ CI/CD Pipeline တွင် မှတ်တမ်းတင်ခြင်း (GitLab/GitHub Releases)
အကောင်းဆုံးနည်းလမ်းမှာ Packer build လုပ်သည့်ဖြစ်စဉ်ကို GitLab CI/CD (သို့) GitHub Actions ထဲတွင် ထည့်ရေးထားခြင်းဖြစ်ပါသည်။ 
ကုဒ်အပြောင်းအလဲ (ဥပမာ - `install_packages.sh` ထဲသို့ Redis အသစ်ထည့်လိုက်ခြင်း) ကို Git တွင် Commit လုပ်သည်နှင့် CI/CD က အလိုအလျောက် Packer ကို Run ပေးပြီး ထွက်လာသော AMI ID ကို `GitLab Release Note` တွင် မှတ်တမ်းတင်ပေးခဲ့ခြင်းသဘော ဖြစ်ပါသည်။ ဤနည်းအားဖြင့် Code Change နှင့် AMI အသစ်သည် တစ်ထပ်တည်းကျနေမည်ဖြစ်ပါသည်။

### ၃။ AWS Systems Manager (Parameter Store) တွင် သိမ်းထားခြင်း
AMI အသစ်ထွက်လာတိုင်း ထို AMI ID နှင့် Version ကို AWS SSM Parameter Store သို့ အလိုအလျောက် လှမ်းရေး (Write) ခိုင်းထားနိုင်ပါသည်။ (ဥပမာ - `/Demo/develop/latest_ami_id` သို့ `ami-0a1b2c...` ကို သိမ်းခြင်း)။ နောက်ပိုင်းတွင် ထို Parameter Store ထဲဝင်ကြည့်ရုံဖြင့် မှတ်တမ်းများကို သေသေချာချာ စီမံနိုင်ပါသည်။

## ပတ်ဝန်းကျင်အမျိုးမျိုးအတွက် ဘယ်လို (Build) သင့်သလဲ? (Environment Parity)

မေးခွန်း - *"Develop အတွက် မတ်လ မှာ AMI ခဲ့ပြီး၊ Prod အတွက် ဧပြီလမှ ထပ်ဆောက်ပါက `apt-get` ကြောင့် Nginx/Docker version များ ကွဲလွဲသွားနိုင်သလား?"* 

အဖြေ - **ကွဲလွဲသွားနိုင်ပါသည်။** ထို့ကြောင့် Infrastructure စည်းမျဉ်းအရ ပတ်ဝန်းကျင်အသီးသီး (dev, uat, prod) အတွက် **AMI များကို သီးခြားစီ မဆောက်သင့်ပါ။** အကောင်းဆုံး Best Practice (Immutable Infrastructure Pattern) မှာ **"Build Once, Deploy Everywhere"** (တစ်ခါပဲဆောက်၊ နောက်ကနေ ကူးယူသုံး) ဖြစ်ပါသည်။

**အကောင်းဆုံး လုပ်ဆောင်သင့်သည့် အဆင့်များ:**
၁။ **Base Image ထုတ်ခြင်း**: Packer ဖြင့် `packer.yaml` ကို အသုံးချကာ `Demo-base-image` ဆိုသည့် သီးသန့် Unified AMI တစ်ခုတည်းကိုသာ (Environment မခွဲဘဲ) ပုံသေ တည်ဆောက်ပါ။
၂။ **Develop တွင် စမ်းသပ်ခြင်း**: Terraform က ထို `Demo-base-v1.0.0` AMI အသစ်ကို ယူပြီး Dev Environment တွင် အရင် Deployment လုပ်ပါသည်။
၃။ **Ansible ဖြင့် ပုံသွင်းခြင်း**: ထို AMI ပေါ်သို့ Ansible က `dev` အတွက် Nginx Config လာရောက် ပုံသွင်းပါသည်။
၄။ **Prod သို့ Promote လုပ်ခြင်း**: Dev တွင် စမ်းသပ်ပြီး အဆင်ပြေသွားပါက ဧပြီလတွင် Prod Deploy လုပ်သည့်အခါ၊ Prod Terraform က **AMI အသစ်ထပ်မဆောက်ဘဲ** မတ်လက စမ်းသပ်အောင်မြင်ခဲ့သည့် `Demo-base-v1.0.0` (AMI ID အဟောင်း) ကိုပင် ပြန်လည်အသုံးပြုပါသည်။
၅။ **Prod ကို ပုံသွင်းခြင်း**: ထို့နောက် Ansible က Prod အတွက် သီးသန့် Nginx Config ကို အဆိုပါ AMI ပေါ်သို့ လာရောက် ပုံသွင်းပေးပါသည်။

**ကွင်ချက်**: အကယ်၍ သက်ဆိုင်ရာ Environment-specific package များ (dev အတွက် သီးသန့် tools များ) လိုအပ်ပါက၊ ၎င်းဖြစ်စဉ်များကို Packer Base Image ထဲတွင် မထည့်ဘဲ နောက်ဆုံးအဆင့်တွင် Ansible ဖြင့်သာ လာရောက်သွင်းသင့်ပါသည်။

## AMI အဟောင်းများကို ဘယ်လိုဖျက်မလဲ? (Deleting AMIs)

Packer သည် လိုအပ်သော Software များ ပေါင်းထည့်ကာ AMI အသစ်ထုတ်ပေးရန်သာ တာဝန်ယူပါသည်။ **အဟောင်းများကို အလိုအလျောက် ဖျက်ပေးမည့် (Auto-cleanup / Manage) စနစ် Packer တွင် မပါဝင်ပါ။** ထို့ကြောင့် တဖြည်းဖြည်း များပြားလာမည့် AMI အဟောင်းများကို ရှင်းလင်းရန် အောက်ပါနည်းလမ်း (၃) ခုထဲမှ တစ်ခုကို အသုံးပြုနိုင်ပါသည်။

### နည်းလမ်း (၁) - AWS Data Lifecycle Manager (DLM) ကို အသုံးပြုခြင်း (အကောင်းဆုံးနည်းလမ်း)
AWS ၏ DLM ကို အသုံးပြု၍ သတ်မှတ်ထားသော Tag (ဥပမာ - `ManagedBy: Atmos/Packer`) ပါသည့် AMI များကို (ဥပမာ - နောက်ဆုံး ၃ ခုသာထားပြီး ကျန်တာဖျက်ရန်) အလိုအလျောက် သတ်မှတ်ပေးထားနိုင်ပါသည်။ ၎င်းသည် အလွယ်ကူဆုံးနှင့် အထိရောက်ဆုံး နည်းလမ်းဖြစ်ပါသည်။

### နည်းလမ်း (၂) - Terraform ဖြင့် ရှင်းလင်းခြင်း
Terraform တွင် `aws_ami` resource ထံ တိုက်ရိုက်ချိတ်ဆက်၍ မရသော်လည်း၊ ကြိုတင်သတ်မှတ်ထားသော Script များကို `null_resource` (သို့မဟုတ်) `aws_lambda_function` များမှတစ်ဆင့် Run ကာ အဟောင်းများကို ရှင်းလင်းခိုင်းနိုင်ပါသည်။

### နည်းလမ်း (၃) - AWS CLI ဖြင့် Manual ဖျက်ခြင်း
တစ်ခါတစ်ရံမှသာ မိမိဘာသာ Manual ဖျက်လိုပါက အောက်ပါ command များကို အသုံးပြုနိုင်ပါသည်။

၁။ AMI ကို Deregister လုပ်ရန်:
```bash
aws ec2 deregister-image --image-id ami-0123456789abcdef0 --region ap-southeast-1
```

၂။ ၎င်းနှင့်ချိတ်ဆက်ထားသော Snapshot ကို ဖျက်ရန်:
```bash
aws ec2 delete-snapshot --snapshot-id snap-0123456789abcdef0 --region ap-southeast-1
```
