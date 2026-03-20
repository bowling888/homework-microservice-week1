## โครงสร้างแต่ละภาษา

### 1. Rust
- Source Code: `src/main.rs`
- Package Manager: `cargo`
- Dependency File: `Cargo.toml`, `Cargo.lock`
- Runtime / Executable:
  - build → ได้ binary (`target/release/...`)
  - ใช้ `Dockerfile` รัน binary

---

### 2. Java
- Source Code: `src/main/java/...`
- Package Manager: `Maven`
- Dependency File: `pom.xml`
- Runtime / Executable:
  - build → `.jar`
  - run ด้วย `java -jar`
  - หรือผ่าน `Dockerfile`

---

### 3. Go
- Source Code: `main.go`
- Package Manager: `go mod`
- Dependency File: `go.mod`, `go.sum`
- Runtime / Executable:
  - build → binary (`app`)
  - run ได้เลย (ไม่ต้องติด runtime เพิ่ม)

---

### 4. Bash
- Source Code: `server.sh`
- Package Manager: ไม่มี
- Dependency File: ไม่มี
- Runtime / Executable:
  - run script ตรง (`bash server.sh`)
  - ใช้ `Dockerfile` + tools เช่น `socat`

---

### 5. Dart
- Source Code: `bin/server.dart`
- Package Manager: `pub`
- Dependency File: `pubspec.yaml`
- Runtime / Executable:
  - `dart run`
  - หรือ compile เป็น native ได้
  - ใช้ `Dockerfile`

---

### 6. JavaScript (Node.js)
- Source Code: `src/server.js`
- Package Manager: `npm` / `yarn`
- Dependency File: `package.json`
- Runtime / Executable:
  - run ด้วย `node server.js`
  - ใช้ `Dockerfile`

---

### 7. Python
- Source Code: `app.py`
- Package Manager: `pip`
- Dependency File: `requirements.txt`
- Runtime / Executable:
  - run ด้วย `python app.py`
  - ใช้ `Dockerfile`

---

### 8. PHP
- Source Code: `public/index.php`
- Package Manager: `composer`
- Dependency File: `composer.json`
- Runtime / Executable:
  - run ด้วย `php -S`
  - หรือ `Apache / Nginx + PHP-FPM`
  - ใช้ `Dockerfile`

---

### 9. C# (.NET)
- Source Code: `Program.cs` (หรือ `Controllers/*.cs`)
- Package Manager: `NuGet` (ผ่าน `dotnet` CLI)
- Dependency File: `*.csproj`
- Runtime / Executable:
  - run ด้วย `dotnet run`
  - หรือ `dotnet <project>.dll`
  - หรือ build เป็น `.exe` (self-contained)
  - ใช้ `Dockerfile` (`dotnet sdk + aspnet runtime`)

###########################################################################
###########################################################################
###########################################################################

# Microservice (หลายภาษา) - GET `/`

โปรเจ็คขนาดเล็ก **9 ภาษา** ผ่าน `docker compose` โดยทุก service จะมี endpoint:

- `GET /` -> คืนค่า JSON:

```json
{"first_name":"นิฤมล","last_name":"ทดสอบ","nick_name":"Test","language":"<language>"}
```

ทุกครั้งที่มี request จะถูกบันทึกลงไฟล์ไว้ที่ `./logs/<language>.log`


## ตั้งค่า Environment Variables

ตัวแปรร่วม:
- `FIRST_NAME`
- `LAST_NAME`
- `NICK_NAME`

ตัวแปรแยกตามภาษา:
- `LANGUAGE_<LANG>`
- `LOG_FILE_<LANG>` (เช่น `LOG_FILE_RUST=/logs/rust.log`)

## วิธีรัน

รันทุก service:

```bash
docker compose up -d --build
```

รีสตาร์ทเฉพาะ service เดียว (ตัวอย่าง `csharp`):

```bash
docker compose up -d --build csharp
```

## Endpoint และ Port

- `rust`: `http://localhost:8001/`
- `java`: `http://localhost:8002/`
- `go`: `http://localhost:8003/`
- `bash`: `http://localhost:8004/`
- `dart`: `http://localhost:8005/`
- `javascript`: `http://localhost:8006/`
- `python`: `http://localhost:8007/`
- `php`: `http://localhost:8008/`
- `csharp`: `http://localhost:8009/`

## Logs

ไฟล์ log จะถูกเก็บตาม Path นี้

ตัวอย่าง:
- `logs/rust.log`
- `logs/java.log`
- `logs/go.log`
- `logs/bash.log`
- `logs/dart.log`
- `logs/javascript.log`
- `logs/python.log`
- `logs/php.log`
- `logs/csharp.log`


ไฟล์ `docker-compose.yml` จะใช้ `Dockerfile` ภายในโฟลเดอร์นั้นเพื่อ build image (ยกเว้น PHP ที่ใช้ runtime image แล้ว mount โฟลเดอร์ `public/` เข้าไป)

