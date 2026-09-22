# MATLAB 远程医疗患者信息可逆嵌入与医学图像加密原型

本实现采用“先嵌入、后加密”。医学图像是载体，患者 TXT/JSON 是附加信息，不再进行“图像藏图像”。

## 融合流程

```text
患者TXT/JSON附加信息
    ↓ UTF-8/原始字节序列P
固定差分-LZW10编码
    ↓ 一维差分 + 符号位置图 + LZW10
实际嵌入码流
    ↓
XORP + 哈夫曼写入医学载体图像的高位空闲空间
    ↓
单通道旋转置乱
    ↓
Fibonacci Q^9矩阵扩散
    ↓
DNA编码 + 中心扩散（二维Salomon映射提供混沌矩阵）
    ↓
密文医学图像
```

这里的差分方法是论文 3 二维医学图像差分思想向一维附加信息字节流的适配。发送端固定执行一维差分、符号位图生成和LZW10编码，不再选择raw或直接LZW10。解码器同时兼容历史LZW12结果。

## 主要文件

- `additional_info_diff_lzw_compress.m`：患者附加信息固定差分-LZW10编码。
- `additional_info_diff_lzw_decompress.m`：患者信息无损重建。
- `xorp_huffman_embed.m`：论文 2 的 2×2 XORP 与哈夫曼标签链嵌入。
- `rotation_scramble.m`：论文 1 的单通道顺时针环遍历置乱。
- `fibonacci_q_diffuse.m`：论文 5 的 Fibonacci Q^9 矩阵扩散。
- `dna_center_diffuse.m`：论文 5 的 DNA 累加、互补和中心扩散。
- `salomon_sequence.m`：在论文6二维Salomon映射上加入指数增益内正弦交叉反馈。
- `salomon_material.m`：v4数据包从一条改进二维Salomon轨道生成四路DNA掩码：
  `X1=x(1:2:end)`、`X2=x(2:2:end)`、`X3=y(1:2:end)`、`X4=y(2:2:end)`；
  新参数`c、d`由SHA-512派生到`[0.5,1.5)`；直接替换后不再兼容旧v2/v3密文。
- `telemedicine_send.m`：不含验证逻辑的底层发送算法。
- `telemedicine_send_verification.m`：验证流程挑战—响应通过后的发送入口。
- `verify_package.m`：使用接收端预先保存的可信公钥，验证挑战签名、完整记录签名、密文绑定关系及 Logo 参数。
- `telemedicine_receive.m`：授权通过后的底层恢复算法。
- `telemedicine_receive_verification.m`：验证通过后才调用的接收入口。
- `verification_generate_verifier_keys.m`：生成验证方RSA-3072公私钥。
- `verification_public_key_fingerprint.m`：计算可信验证方公钥指纹。
- `verification_record_digest.m`、`verification_finalize_record.m`：生成并签署完整验证记录。
- `verification_generate_logo.m`、`verification_analyze_logo.m`：字符Logo生成与识别。
- `main.m`：统一入口。

## 输入要求

- 医学载体：8 位单通道 PNG/TIFF/BMP。
- 患者附加信息：TXT、JSON 或其他二进制文件，程序逐字节读取，不改变编码。
- 恢复信息文件与原文件逐字节一致。

## 运行

发送：

```matlab
main('send', ...
    'data/medical_carrier.png', ...
    'data/patient_info_example.json', ...
    'output/cipher.png', ...
    'output/package.json', ...
    'your-password');
```

### 验证流程

首先生成验证方RSA-3072密钥：

```matlab
keys=main('verification_keygen','data/verification_verifier_keys');
```

执行挑战—响应，并在`R=r`后生成密文、Logo和发送方正确验证参数：

```matlab
[package,record]=main('send_verification', ...
    'data/medical_carrier.png', ...
    'data/patient_info_example.json', ...
    'output/verification/cipher.png', ...
    'output/verification/package.json', ...
    'output/verification/logo.png', ...
    'output/verification/verification_record.json', ...
    'your-password', ...
    keys.privateKeyPath, ...
    keys.publicKeyPath);
```

接收方根据收到的Logo独立生成字符、文字比例、Logo哈希和指定字符局部哈希：

```matlab
request=main('verification_request','output/verification/logo.png',[1 3]);
verification_write_json('output/verification/receiver_request.json',request);
```

验证方不接收算法口令，按验证流程逐项比较：

```matlab
[isValid,detail]=main('verify_verification', ...
    'output/verification/cipher.png', ...
    'output/verification/package.json', ...
    'output/verification/logo.png', ...
    'output/verification/verification_record.json', ...
    'output/verification/receiver_request.json', ...
    keys.publicKeyPath);
```

验证全部通过后，在同一MATLAB调用中授权算法口令并执行恢复：

```matlab
[carrier,patientInfo]=main('receive_verification', ...
    'output/verification/cipher.png', ...
    'output/verification/package.json', ...
    'output/verification/logo.png', ...
    'output/verification/verification_record.json', ...
    'output/verification/receiver_request.json', ...
    'output/verification/recovered_medical_image.png', ...
    'output/verification/recovered_patient_info.json', ...
    'your-password', ...
    keys.publicKeyPath);
```

当前验证协议为`verification-v2`。接收端必须从本地可信来源指定验证方公钥，不能直接信任验证记录中携带的公钥信息。当前代码已删除旧的密文HMAC认证；验证记录签名负责保护挑战值、密文摘要、患者信息摘要及Logo参数之间的绑定关系。Logo及验证JSON均为外部认证开销，因此不会改变容量、PSNR、SSIM、熵、NPCR/UACI或Salomon混沌指标。

## 容量指标

- `usableCapacityBits`：XORP＋哈夫曼扣除标签、参考像素 MSB 等块内辅助信息后的可用位数。
- `NetSecretCapacityBpp`：继续扣除45字节图内头部、B2恢复位，以及解密、提取和无损恢复所需的紧凑外部旁信息后，再除以载体总像素数所得的严格净容量。Logo、RSA签名、挑战值等认证通信开销不计入像素嵌入辅助信息。
- `payloadBits`：选中码流连同嵌入头部和B2恢复位实际占用的位数。
- `OriginalPatientBytes`：原始患者信息字节数。
- `CompressedPatientBytes`：实际交给XORP-Huffman嵌入的选中码流字节数。
- `EncodingMode`：当前实现固定为`diff-lzw10`；解码器仍兼容历史`diff-lzw12`结果。
- 原始信息有效嵌入率可计算为：

```matlab
effectiveER = 8 * originalPatientBytes / numel(carrierImage);
```

- 实际码流嵌入率可计算为：

```matlab
encodedER = 8 * compressedPatientBytes / numel(carrierImage);
```

编码器始终采用差分-LZW10。`CompressionRatio`小于1表示压缩有效，大于1表示压缩膨胀；程序不再自动回退到raw。

默认患者样例保留 3,072 字符的去标识化 Base64 监测片段。真实负载写入后，剩余可用位仍由 SHA-256 伪随机位填满；“满载”指所有可用嵌入位均被使用，不表示全部位都属于患者数据。

> 本代码用于论文算法研究。真实医疗系统仍应采用标准认证加密、正式密钥管理、权限控制和审计机制。
