# Packer တည်ဆောက်မှု လုပ်ငန်းစဉ် အသေးစိတ် (Low-level Deployment Process)

ဤဖိုင်သည် `atmos packer build ami -s develop` ဟု Run လိုက်သည့်အခါ နောက်ကွယ်တွင် Packer မှ အဆင့်ဆင့် အလုပ်လုပ်သွားပုံ (Low-level process) ကို အသေးစိတ် ရှင်းလင်းထားခြင်း ဖြစ်ပါသည်။

## အဆင့် (၁) - ပြင်ဆင်ခြင်းနှင့် စစ်ဆေးခြင်း (Initialization & Prevalidation)
```text
==> -ami.amazon-ebs.ubuntu: Prevalidating any provided VPC information   
==> -ami.amazon-ebs.ubuntu: Prevalidating AMI Name: base-develop-...
==> -ami.amazon-ebs.ubuntu: Found Image ID: ami-xxxxxxxxxxxxxxxxxx 
```
Packer သည် ပထမဆုံးအနေဖြင့် `build.pkr.hcl` တွင် သတ်မှတ်ထားသော Base Image (ဥပမာ - Ubuntu 24.04 ၏ မူလ `ami-xxxxxxxxxxxxxxxxxx...`) ကို AWS ပေါ်တွင် ရှာဖွေပါသည်။ ထို့နောက် တည်ဆောက်မည့် AMI အမည်အသစ် (-base-develop) နှင့် VPC အချက်အလက်များကို မှန်ကန်မှုရှိမရှိ ကြိုတင်စစ်ဆေးပါသည်။ ကျွန်ုပ်တို့၏ config တွင် VPC သီးသန့် မသတ်မှတ်ထားသောကြောင့် AWS Account ၏ **Default VPC** ကို အလိုအလျောက် ရွေးချယ်အသုံးပြုမည်ဖြစ်ပါသည်။

## အဆင့် (၂) - ယာယီကွန်ရက်နှင့် လုံခြုံရေးများ တည်ဆောက်ခြင်း (Temporary Security setup)
```text
==> -ami.amazon-ebs.ubuntu: Creating temporary keypair: packer_xxxxxxxx...
==> -ami.amazon-ebs.ubuntu: Creating temporary security group for this instance: packer_xxxxxxxx...
==> -ami.amazon-ebs.ubuntu: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
```
Image ကို ပြင်ဆင်ရန် အသုံးပြုမည့် ယာယီ EC2 ထဲသို့ ဝင်ရောက်နိုင်ရန် Packer သည် **Temporary Keypair** နှင့် **Temporary Security Group** အသစ်များကို အလိုအလျောက် တည်ဆောက်ပါသည်။ ထို Security Group တွင် SSH သုံးရန် Port 22 ကို ဖွင့်ပေးထားပါသည်။

## အဆင့် (၃) - ယာယီ EC2 အသစ်ဖွင့်ခြင်းနှင့် ဆက်သွယ်ခြင်း (Launch Instance & SSH)
```text
==> -ami.amazon-ebs.ubuntu: Launching a source AWS instance...
==> -ami.amazon-ebs.ubuntu: Instance ID: i-xxxxxxxxxxxxxxxxx
==> -ami.amazon-ebs.ubuntu: Waiting for instance (i-xxxxxxxxxxxxxxxxx) to become ready...
==> -ami.amazon-ebs.ubuntu: Using SSH communicator to connect: xxx.xxx.xxx.xxx
==> -ami.amazon-ebs.ubuntu: Connected to SSH!
```
AWS ၏  Default VPC ပေါ်တွင် ယာယီ (Source) EC2 Instance တစ်ခု (ဉပမာ `  i-xxxxxxxxxxxxxxxxx`) ကို စတင် Run ပါသည်။ Instance လည်ပတ်မှုအသင့်ဖြစ်သွားသည်နှင့် ၎င်း၏ Public IP (`xxx.xxx.xxx.xxx`) ကို ရှာဖွေပြီး အဆင့် (၂) တွင် ဆောက်ထားသော Keypair ကိုသုံး၍ အဆိုပါ IP ထံသို့ SSH ဖြင့် ချိတ်ဆက်ပါသည်။

## အဆင့် (၄) - လိုအပ်သော ဆော့ဖ်ဝဲလ်များ သွင်းခြင်း (Provisioning with Shell Script)
```text
==> -ami.amazon-ebs.ubuntu: Provisioning with shell script: ./install_packages.sh
==> -ami.amazon-ebs.ubuntu: Hit:1 http://ap-southeast-1.ec2.archive.ubuntu.com/ubuntu noble InRelease
...
==> -ami.amazon-ebs.ubuntu: Installing Nginx...
...
==> -ami.amazon-ebs.ubuntu: Installing Docker Engine...
==> -ami.amazon-ebs.ubuntu: Installing Docker Compose Plugin...
...
==> -ami.amazon-ebs.ubuntu: Installing MySQL Server...
==> -ami.amazon-ebs.ubuntu: Installing MySQL Client...
...
==> -ami.amazon-ebs.ubuntu: Package installation complete!
```
SSH ချိတ်ဆက်မိသွားပြီးနောက် ကျွန်ုပ်တို့ ရေးသားထားသော `install_packages.sh` ကို ထို EC2 ထဲသို့ လှမ်းပို့ကာ Run ပါသည်။ ဤနေရာတွင် လုပ်ဆောင်သွားသည်များမှာ-
* `apt-get update` များလုပ်ကာ လိုအပ်သော library အသစ်များ (ca-certificates, curl စသည်) ကို သွင်းပါသည်။
* Nginx ကို သွင်းပြီး Service ကို Enable လုပ်ပါသည်။
* Docker ရဲ့ Official GPG Key နှင့် Repo များကို ချိတ်ဆက်ပြီး Docker Engine (docker-ce) နှင့် Docker Compose Plugin များကို Install လုပ်ပါသည်။ `ubuntu` user ကို `docker` group ထဲသို့ ထည့်ပေးပါသည်။
* MySQL Server နှင့် Client များကို သွင်းပြီး လိုအပ်သော မှီခို (Dependencies) များကို အလိုအလျောက် သွင်းပေးပါသည်။
* Software များအားလုံး သွင်းပြီးလျှင် `Package installation complete!` ဆိုသော message ပြကာ Provisioning အဆင့် ပြီးဆုံးပါသည်။

## အဆင့် (၅) - AMI အသစ်ထုတ်ယူခြင်း (Creating AMI & Tagging)
```text
==> -ami.amazon-ebs.ubuntu: Stopping the source instance...
==> -ami.amazon-ebs.ubuntu: Waiting for the instance to stop...
==> -ami.amazon-ebs.ubuntu: Creating AMI -base-develop-20260316035745 from instance i-xxxxxxxxxxxxxxxxx
...
==> -ami.amazon-ebs.ubuntu: Adding tag: "ManagedBy": "Atmos/Packer"      
==> -ami.amazon-ebs.ubuntu: Adding tag: "Name": "base-develop"       
==> -ami.amazon-ebs.ubuntu: Adding tag: "Environment": "develop"
```
Software များသွင်းပြီးသော ယာယီ EC2 ကို Packer က Stop လုပ် (ပိတ်) လိုက်ပါသည်။ ၎င်းပိတ်သွားပြီးနောက် ထို EC2 အပေါ်မူတည်၍ AMI အသစ်တစ်ခု (`ami-xxxxxxxxxxxxxxxxx`) ကို စတင်တည်ဆောက် (Bake) ပါသည်။ ထို့နောက် ကျွန်ုပ်တို့ သတ်မှတ်ထားသော Tags များကို ထို AMI နှင့် ၎င်း၏ Snapshot ပေါ်သို့ တွဲချိတ် (Assign) ပေးပါသည်။

## အဆင့် (၆) - ရှင်းလင်းခြင်း (Cleanup & Final Result)
```text
==> -ami.amazon-ebs.ubuntu: Terminating the source AWS instance...
==> -ami.amazon-ebs.ubuntu: Deleting temporary security group...
==> -ami.amazon-ebs.ubuntu: Deleting temporary keypair...
Build '-ami.amazon-ebs.ubuntu' finished after 8 minutes 1 second.

==> Builds finished. The artifacts of successful builds are:
--> -ami.amazon-ebs.ubuntu: AMIs were created:
ap-southeast-1: ami-xxxxxxxxxxxxxxxxx
```
AMI အသစ်ထုတ်ယူခြင်း အောင်မြင်သွားပါက၊ အဆင့် (၁) နှင့် (၂) တို့တွင် ယာယီဖွင့်ထားခဲ့သော EC2 Instance, Keypair နှင့် Security Group အားလုံးကို Packer မှ အလိုအလျောက် ဖျက်သိမ်း (Terminate/Delete) ပေးပါသည်။ နောက်ဆုံးအနေဖြင့် ၈ မိနစ်ခန့်အကြာတွင် အသစ်ရရှိလာသော **AMI ID (`ami-xxxxxxxxxxxxxxxxx`)** ကို ဖော်ပြပေးပြီး အလုပ်ပြီးဆုံးပါသည်။
