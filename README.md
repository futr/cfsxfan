# cfsxfan
LinuxでLet' note CF-SX1のCPUファンを制御します。

## 注意
以下の方法は実験的なもので動作する保証はりません。また、PCを破壊する可能性があります。

現存のCF-SX1は、グリスが固形化している可能性があります。その場合CPUファンを制御しても放熱問題を解決できません。グリスの塗り直しが必要となる可能性があります。

以下の内容は`kubuntu 22.04`を想定しています。

## 概要
Let's note CF-SX1上でLinux(Ubuntu)を利用する際、CPUファンの回転数が負荷に応じて上昇しないため、放熱できずに電源が落ちることがあります。

[DSDTの解析方法](https://github.com/hirschmann/nbfc/wiki/Analyze-your-notebook%27s-DSDT)を参考に`nbfc-linux`などのECのレジスタ値を変更して制御する方法を検討しましたが、直接レジスタ値を変更してもファンの回転数は制御できませんでした。

しかし、解析して見ると以下のコードが見つかりました。
```
    Device (TFN1)
        {
            Name (_HID, EisaId ("INT3404"))  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _CID: Compatible ID
            Name (_UID, 0x00)  // _UID: Unique ID
            Name (_STR, Unicode ("Fan 1"))  // _STR: Description String
            Name (FSPD, 0x00)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Method (SSPD, 1, Serialized)
            {
                If ((Arg0 != \_SB.PCI0.LPCB.TFN1.FSPD))
                {
                    \_SB.PCI0.LPCB.TFN1.FSPD = Arg0
                    Notify (\_SB.DPPM, 0x83) // Device-Specific Change
                    \_SB.PCI0.LPCB.EC0.EC44 (0x77, Arg0, 0x00)
                }
                Else
                {
                }
            }
        }
```
内容はよくわかりませんが、`SSPD`というメソッドはいかにもファンの回転数を制御できそうです。

`acpi_call`というモジュールを利用すると、ACPIのメソッドが呼び出せるようなので、`acpi-call-dkms`をインストールしてロードします。

そして、以下を実行するとファンの回転数を制御できました。
```
echo '\_SB.PCI0.LPCB.TFN1.SSPD 0x70' | sudo tee /proc/acpi/call
```

いろんな値を試してみて、値の範囲は`0x00`から`0x70`であることがわかりました。また、`0x00`でもファンは停止せず低速で回転します。

このリポジトリには、これらを利用してCPU温度に応じてファンの回転数を制御するbashスクリプトとsystemdのユニットが含まれています。

## インストール
### acpi_call
以下のパッケージをインストールします。
```
sudo apt install acpi-call-dkms
```
自動的にロードされるようにします。
```
echo "acpi_call" | sudo tee /etc/modules-load.d/acpi_call.conf
```
### cfsxfan.service
リポジトリをクローンし、`install.sh`を実行します。
```
git clone https://github.com/futr/cfsxfan.git
cd cfsxfan
./install.sh
```
bashスクリプトとsystemdのユニットがインストールされ、起動されます。

bashスクリプトは`/usr/local/cfsxfan/`にインストールされます。
### 設定
回転数と温度の関係の設定は、`/usr/local/cfsxfan/cfsxfan-unit.sh`を直接編集してください。
```
# 温度データを取得するファイル
TEMPPATH=/sys/devices/platform/coretemp.0/hwmon/hwmon3/temp1_input
SLEEPTIME=3          # 何秒ごとに回転数を制御するか
LOWTEMP=50.0         # 最低回転数の温度
HIGHTEMP=70.0        # 最高回転数の温度
LOWSPEED=$((16#00))  # 最低回転数設定値（16進数）
HIGHSPEED=$((16#70)) # 最高回転数設定値（16進数）
```
