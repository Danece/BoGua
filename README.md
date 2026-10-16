# 道標（BoGua）

易經八卦轉盤占卜 App，使用 Flutter 開發，支援 Android、iOS、Web。

- 轉動八卦轉盤起卦，顯示本卦、之卦（變卦）、占法與判斷依據
- 占卜紀錄存在本機 SQLite（Web 版用 sqflite_common_ffi_web），可查看、刪除、清空
- 架構：`lib/core`（路由、主題）／`data`（資料來源、模型、Repository）／
  `domain`（起卦、解爻邏輯）／`presentation`（各頁面），狀態管理用 Riverpod、
  路由用 go_router

| 項目 | 值 |
| --- | --- |
| 顯示名稱 | 道標 |
| Android applicationId／iOS Bundle ID | `com.bogua.app` |
| 版本 | 見 `pubspec.yaml` 的 `version` |

## 開發

```sh
flutter pub get
flutter run            # 或 flutter run -d chrome
flutter test           # 單元／Widget 測試
```

效能量測見 `integration_test/performance_test.dart`。

## App 圖示

原圖由程式繪製（太極＋先天八卦），改圖示時：

```sh
flutter test tool/generate_app_icon.dart   # 輸出 assets/icon/*.png
dart run flutter_launcher_icons            # 產生各平台尺寸
```

## 發佈

### Android

Release 簽章讀取 `android/key.properties`（已列入 `.gitignore`，**不要提交**）：

```properties
storePassword=<密碼>
keyPassword=<密碼>
keyAlias=upload
storeFile=<keystore 的絕對路徑>
```

沒有這個檔案時 release 會退回 debug 簽章，只能自己測試，無法上傳 Play Console。
keystore 與密碼遺失就無法再更新同一個 App（除非已啟用 Play App Signing 並申請重設上傳金鑰），請另外備份。

```sh
flutter build appbundle --release   # 產出 build/app/outputs/bundle/release/app-release.aab
```

### iOS

需在 macOS 上用 Xcode 開啟 `ios/Runner.xcworkspace`，在 Signing & Capabilities 設定
Apple Developer Team 後執行 `flutter build ipa`。

### 發版前

每次上架前調高 `pubspec.yaml` 的 `version`（`x.y.z+build`，build 號必須遞增）。
