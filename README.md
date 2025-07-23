# mkcert

程式會快速自動產生自簽的 Certificate Authority Certificate 以及 Server Certificate，有效期限預設都是 10 年

## 快速開始

### 1. 編輯設定檔

設定要產生憑證的內容

```
nano ./mkcert/config
```

修改 DOMAIN_NAME 變數的值

```
...
# Server 相關設定
DOMAIN_NAME="example.com"
....
```

### 2. 產生自簽憑證

```
./mkcert/certctl
```

### 3. 檢視製作好的憑證

```
DOMAIN_NAME="example.com"
ls -l ${DOMAIN_NAME}
```

執行結果：

```
total 20
-rw-rw-r-- 1 bigred bigred 2057 Jul 23 11:09 ca.crt
-rw------- 1 bigred bigred 3272 Jul 23 11:09 ca.key
-rw-rw-r-- 1 bigred bigred 2147 Jul 23 11:09 example.com.crt
-rw------- 1 bigred bigred 3272 Jul 23 11:09 example.com.key
```

### 4. 故障排除

```
cat /tmp/.certctl.log
```
