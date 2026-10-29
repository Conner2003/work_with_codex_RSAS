# RenderDoc 1.46 — RSAS D3D12 Selective Replay

**Experimental graphics replay research / 實驗性圖形重播研究**

[繁體中文](#繁體中文) · [English](#english)

> **Research status / 研究狀態：** This repository contains an RSAS-specific extension to the RenderDoc 1.46 source tree. The selective-replay code is present, but this README does **not** claim that the project has passed a Windows build, end-to-end GPU-splitting, image-composition, or arbitrary-game transparency test.  
> 本專案包含 RenderDoc 1.46 的 RSAS 專用修改原始碼；可確認選擇性重播程式路徑存在，但**不能據此宣稱**已通過 Windows 實際建置、跨 GPU 分工、畫面合成或任意遊戲透明資源共享測試。

---

## 繁體中文

### 專案介紹

這是一份以 **RenderDoc 1.46** 為基礎的研究性修改版，目標是探索如何在 **Direct3D 12 (D3D12)** 擷取檔案中，依照 **RenderDoc Event ID** 指定要執行的繪圖／運算指令，作為 RSAS 分散式 GPU 研究的基礎元件。

本專案不會讓未修改的 Windows 應用程式直接將另一台電腦的 GPU 視為本機顯示卡，也不提供已完成的透明 CPU／GPU／RAM 資源合併。它目前是**基於 `.rdc` 擷取資料的重播後端研究**，不是可直接安裝的完整 RSAS 系統。

> **與原始 RenderDoc 的關係：** 本專案以開源 [RenderDoc](https://github.com/baldurk/renderdoc) 的 1.46 版原始碼為基礎，並非 RenderDoc 官方發行版本或官方認證功能。原始 RenderDoc 的使用範圍、著作權及授權資訊請參閱 [LICENSE.md](LICENSE.md) 與上游專案。

### 使用技術

| 技術／元件 | 用途 | 適用範圍 |
| --- | --- | --- |
| **C++14** | 主要原生程式碼、Replay Controller 與 D3D12 驅動層修改 | 研究擴充及上游核心 |
| **Direct3D 12 / DXGI** | Windows GPU 擷取與重播基礎 | RSAS 選擇性重播僅針對 D3D12 |
| **RenderDoc 1.46** | `.rdc` 擷取檔案、Event ID、Replay Controller、GPU 重播基礎設施 | 上游框架 |
| **D3D12 command-list wrappers** | 依 Event ID 決定是否發出指定 Draw／Dispatch 等 shader-work 指令 | RSAS 核心修改 |
| **Visual Studio／MSBuild、Windows SDK** | Windows x64 Release 建置 `renderdoccmd.exe` 與 `renderdoc.dll` | 此版本提供的 RSAS 建置流程 |
| **PowerShell** | 自動建置、Probe 檢查、複製及封裝輸出 | `build-rsas-selective.ps1` |
| **Qt、Python、CMake** | RenderDoc 上游的 UI、腳本／測試及跨平台建置基礎 | **不代表** RSAS 擴充已支援所有平台／API |
| **JSON／命令列介面** | 回報執行狀態、迴圈數、起訖時間等資料 | `renderdoccmd` 擴充輸出 |

### 研究性功能與程式路徑

- 新增 `renderdoccmd rsas-selective-replay` 命令，接收 `.rdc` 擷取檔與一組 Event ID。
- 在 D3D12 重播期間，透過指定的 Event ID 選擇執行 `DrawInstanced`、`DrawIndexedInstanced`、`Dispatch`、`ExecuteIndirect` 的 Draw／Dispatch 子動作，以及 `DispatchRays`、`DispatchMesh` 的相關分支。
- **重播至所選事件的最後一個 Event ID**，保留捕捉到的狀態設定、複製及資源 Barrier 等非選取性 shader-work 指令；不是只重播指定事件的完全獨立片段。
- 可使用 `--gpu-name` 偏好選擇目前可用的重播 GPU；這**不是**跨網路連接遠端 GPU 的選項。
- 支援重複執行、最短執行時間及指定 Unix 奈秒時間戳開始；時間戳控制本身**不保證**跨電腦時鐘同步。
- 支援 `--probe` 識別研究擴充版本，並以 JSON 格式輸出完成資訊。

**技術邊界：** `--probe` 成功只代表編譯出的命令列程式具有該擴充識別能力；JSON 回報成功也不能單獨證明跨機 GPU 分工的實際效能、同步正確性或最終畫面一致性。不同 Event ID 可能存在資源讀寫相依性，仍需另行驗證。

### 專案目錄

```text
.
├── BUILD_RSAS_RENDERDOC.md          # RSAS 專用研究與建置說明
├── build-rsas-selective.ps1        # Windows 建置、Probe 與封裝腳本
├── renderdoccmd/
│   └── renderdoccmd.cpp             # rsas-selective-replay CLI
├── renderdoc/
│   ├── api/replay/                  # Replay API 及版本資訊
│   ├── replay/                      # Replay Controller / Driver
│   └── driver/d3d12/               # D3D12 Selective Replay 實作
├── qrenderdoc/                      # 原始 RenderDoc Qt GUI
├── docs/                            # 原始 RenderDoc 文件
├── util/                            # 建置、測試及其他工具
└── LICENSE.md                       # 原始 RenderDoc MIT 授權條款
```

### Windows 編譯需求

- Windows 10／11 x64（以 Windows 研究建置路徑為目標；未在本次 README 製作流程中實測）。
- Visual Studio 2022 或 Build Tools，包含 **Desktop development with C++**。
- Windows 10 或 Windows 11 SDK。
- PowerShell 與 MSBuild（腳本會嘗試由 `PATH` 或 `vswhere.exe` 尋找 MSBuild）。
- 專案內完整的 RenderDoc 原始碼及相關建置相依項。

進入專案根目錄，執行：

```powershell
# 在原始碼根目錄執行 / Run at repository root
.\build-rsas-selective.ps1
```

若受到 PowerShell 執行政策限制，可**只針對當前 PowerShell 處理程序**設定：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build-rsas-selective.ps1
```

腳本設計上會使用 MSBuild 建置 `renderdoccmd\renderdoccmd.vcxproj`（Release / x64），檢查輸出中的 `renderdoccmd.exe` 與 `renderdoc.dll`，再執行 Probe。**這是腳本定義的流程，不代表本次已在 Windows 成功執行。**

預期的成功訊息：

```text
Probe PASS: RSAS_SELECTIVE_REPLAY_V1
BUILD PASS
```

預期輸出：

```text
x64/Release/renderdoccmd.exe
x64/Release/renderdoc.dll
rsas-build-output/PROBE.txt
RenderDoc-1.46-RSAS-Selective-x64.zip
```

### 執行方式（D3D12 Capture）

先以適當且獲授權的程式建立 D3D12 `.rdc` 擷取檔，從 RenderDoc 事件清單找出實際要測試的 Event ID（下例 `101,205` **僅為範例**，不是已驗證有效的事件編號）。

```powershell
# 確認擴充存在（不需擷取檔）
.\x64\Release\renderdoccmd.exe rsas-selective-replay --probe

# 示範對 D3D12 capture 中指定的事件執行研究性選擇重播
.\x64\Release\renderdoccmd.exe rsas-selective-replay `
  --events 101,205 `
  --loops 1 `
  "C:\Captures\example.rdc"

# 偏好可用的本機重播 GPU，並控制研究執行時間
.\x64\Release\renderdoccmd.exe rsas-selective-replay `
  --events 101,205 `
  --gpu-name "NVIDIA" `
  --loops 2 `
  --min-runtime-ms 1000 `
  "C:\Captures\example.rdc"
```

| 選項 | 說明 |
| --- | --- |
| `--probe` | 輸出 `RSAS_SELECTIVE_REPLAY_V1`，不開啟擷取檔 |
| `--events`, `-e` | 以逗號分隔的正整數 RenderDoc Event ID；一般執行時必填 |
| `--gpu-name` | 依 GPU 名稱的一部分選擇可用重播裝置 |
| `--loops`, `-l` | 最少執行迴圈數，預設 1 |
| `--min-runtime-ms` | 最短執行的牆鐘時間，預設 0 |
| `--start-unix-ns` | 指定不早於某個 Unix 奈秒時間戳啟動 |

成功執行的程式路徑會輸出 `RSAS_JSON_BEGIN` 與 `RSAS_JSON_END` 標記之間的 JSON，包含 `requested_count`、`loops`、`started_unix_nano`、`completed_unix_nano`、`duration_ms` 等欄位。此為**程式回報資料**，不是獨立的 GPU 分工驗證報告。

### 與 RSAS 主專案整合（選用）

若已有符合腳本預期結構的 **RSAS RD7.3** 目錄，可使用：

```powershell
.\build-rsas-selective.ps1 -RSASRoot "D:\path\to\RSAS-Distributed-Fabric-RD7.3-D3D12-SelectiveTrueSplit"
```

腳本會複製編譯產物到 `tools\renderdoc\1.46\x64`，**可能覆寫該目錄中的 `renderdoccmd.exe`、`renderdoc.dll`**；請先備份。RD7.3 不是此來源封裝提供的完整系統，這項選用整合並不代表已完成跨機分工。

### 驗證狀態與已知限制

| 項目 | 狀態 |
| --- | --- |
| RenderDoc 版本與 RSAS CLI／D3D12 篩選程式碼 | **已從上傳原始碼確認存在** |
| Windows Release x64 編譯 | **本次未實測** |
| `--probe` 實際執行 | **本次未實測** |
| D3D12 `.rdc` 在指定 GPU 上的實際選擇重播 | **本次未實測** |
| 跨主機工作分配／資源同步／最終影像合成 | **未由本來源驗證** |
| 任意未修改 Windows 應用程式／Steam 遊戲透明共享 GPU | **未實現／未由本來源提供** |
| 跨平台 RSAS 擴充（Vulkan、D3D11、Linux、Android 等） | **未由本 D3D12 擴充提供** |

這份程式是研究原型，不是建議直接用於正式服務的穩定產品。若要宣稱真正的雙 GPU 分工，至少還需要不同主機各自執行的事件集合證據、GPU 硬體執行紀錄、同步與資源相依性驗證，以及最終畫面正確性測試。

### 授權與來源致謝

- 上游專案：**RenderDoc** — https://github.com/baldurk/renderdoc
- 此來源封裝包含上游 RenderDoc 1.46 程式碼及 RSAS 研究修改。
- RenderDoc 根目錄採 **MIT License**，詳見 [LICENSE.md](LICENSE.md)。發佈修改版時，請保留原有著作權及授權聲明。
- 封裝包含第三方元件；請一併遵守各自的授權與告知義務，參閱 `renderdoc/3rdparty/`、`qrenderdoc/3rdparty/`、`docs/credits_acknowledgements.rst` 等。
- **非 RenderDoc 官方產品，也不代表上游作者或 OpenAI 的認可。**

**公開發布前：** 請人工檢查是否包含金鑰、Token、私密擷取檔、使用者資料、受限授權的第三方檔案或不應重新散布的二進位資產；README 與成功建置腳本不能取代程式碼審查和授權審查。

---

## English

### Overview

This repository is an **experimental modification of the RenderDoc 1.46 source tree** for RSAS research. It explores **event-ID-based selective execution of shader-work commands** when replaying **Direct3D 12 (D3D12)** captures (`.rdc`).

The work is a **capture-derived replay backend**, not a complete distributed rendering system. It does **not** expose a GPU on another computer as a local adapter to an unmodified Windows application, nor does it implement transparent aggregation of CPU, GPU, and RAM across machines.

> **Upstream attribution:** Based on the open-source [RenderDoc](https://github.com/baldurk/renderdoc) project, version 1.46, with an RSAS-specific research extension. This is **not** an official RenderDoc release or an endorsed feature. See [LICENSE.md](LICENSE.md) for the upstream license.

### Technology stack

| Technology | Role | Scope |
| --- | --- | --- |
| **C++14** | Native implementation, replay controller, D3D12 driver-layer changes | Research extension and upstream core |
| **Direct3D 12 / DXGI** | Windows graphics API capture and replay foundations | Selective-replay extension targets D3D12 only |
| **RenderDoc 1.46** | Capture files, event IDs, replay interfaces and infrastructure | Upstream framework |
| **D3D12 command-list wrappers** | Conditional execution of Draw/Dispatch shader actions selected by event ID | Main RSAS change |
| **Visual Studio / MSBuild / Windows SDK** | Windows x64 Release build of `renderdoccmd.exe` and `renderdoc.dll` | RSAS build workflow |
| **PowerShell** | Build automation, probe, binary installation and packaging | `build-rsas-selective.ps1` |
| **Qt, Python, CMake** | Existing upstream UI, scripting/testing and cross-platform build infrastructure | **Not** proof of cross-platform support for this RSAS extension |
| **CLI / JSON output** | Event selection, GPU selection, timing and execution reports | `renderdoccmd` extension |

### Implementation highlights

- Introduces the `renderdoccmd rsas-selective-replay` CLI command.
- Accepts an `.rdc` capture and a comma-separated set of RenderDoc event IDs.
- Includes D3D12 event-selection checks for `DrawInstanced`, `DrawIndexedInstanced`, `Dispatch`, `ExecuteIndirect` Draw/Dispatch children, and code paths for `DispatchRays` and `DispatchMesh`.
- Replays the captured prefix through the highest selected event ID, retaining captured non-selected state, copy and barrier operations; only selected shader-work actions are intended to execute.
- Supports selecting an **available replay GPU** by name, multiple loops, a minimum runtime, and a scheduled wall-clock start timestamp.
- Provides an extension probe and machine-readable JSON output.

**Important:** `--gpu-name` is not a remote-GPU connector, and `--start-unix-ns` does not by itself provide inter-host clock synchronization. Dependencies between rendering events, final image equivalence, workload distribution and performance gains require separate validation. A successful probe or self-reported JSON result is not independent evidence of correct distributed GPU execution.

### Repository layout

```text
.
├── BUILD_RSAS_RENDERDOC.md          # Project-specific research/build notes
├── build-rsas-selective.ps1        # Windows build and probe script
├── renderdoccmd/renderdoccmd.cpp   # Extended command-line interface
├── renderdoc/api/replay/           # RenderDoc replay API
├── renderdoc/replay/               # Replay controller/driver
├── renderdoc/driver/d3d12/        # D3D12 selective action logic
├── qrenderdoc/                    # Upstream Qt UI
├── docs/                          # Upstream documentation
├── util/                          # Upstream tools/tests
└── LICENSE.md                     # Upstream MIT license
```

### Requirements and building on Windows

- Windows 10/11 x64 is the intended build environment for this extension (not independently tested while preparing this README).
- Visual Studio 2022 or Build Tools with **Desktop development with C++**.
- Windows 10 or Windows 11 SDK.
- MSBuild, PowerShell, and the required source-tree dependencies.

From the repository root:

```powershell
.\build-rsas-selective.ps1
```

If PowerShell execution policy blocks the script, you may temporarily allow it for the current process:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build-rsas-selective.ps1
```

The script targets `renderdoccmd\renderdoccmd.vcxproj` in **Release / x64**, checks for both compiled binaries, runs `rsas-selective-replay --probe`, and packages the outputs. **These are source-defined build steps; a successful Windows build has not been verified for this README.**

Expected success indicators:

```text
Probe PASS: RSAS_SELECTIVE_REPLAY_V1
BUILD PASS
```

Expected outputs:

```text
x64/Release/renderdoccmd.exe
x64/Release/renderdoc.dll
rsas-build-output/PROBE.txt
RenderDoc-1.46-RSAS-Selective-x64.zip
```

### Usage

Capture a **D3D12 application that you own or are authorized to debug**, then obtain the relevant event IDs from RenderDoc's event list. The IDs below are **illustrative placeholders**, not tested events.

```powershell
# Probe the extension without opening a capture
.\x64\Release\renderdoccmd.exe rsas-selective-replay --probe

# Selective replay by RenderDoc event ID
.\x64\Release\renderdoccmd.exe rsas-selective-replay `
  --events 101,205 `
  --loops 1 `
  "C:\Captures\example.rdc"

# Optional local GPU preference and timing controls
.\x64\Release\renderdoccmd.exe rsas-selective-replay `
  --events 101,205 `
  --gpu-name "NVIDIA" `
  --loops 2 `
  --min-runtime-ms 1000 `
  "C:\Captures\example.rdc"
```

| Option | Meaning |
| --- | --- |
| `--probe` | Prints `RSAS_SELECTIVE_REPLAY_V1`; capture file not required |
| `--events`, `-e` | Required comma-separated positive RenderDoc event IDs for replay |
| `--gpu-name` | Selects a matching **available** replay device by partial name |
| `--loops`, `-l` | Minimum replay loop count; default 1 |
| `--min-runtime-ms` | Minimum wall-clock runtime; default 0 |
| `--start-unix-ns` | Do not start before the specified Unix nanosecond timestamp |

The code emits a JSON object between `RSAS_JSON_BEGIN` and `RSAS_JSON_END` with fields including `requested_count`, `loops`, `started_unix_nano`, `completed_unix_nano`, and `duration_ms`. These are **process-reported diagnostics**, not an independent GPU-splitting correctness certificate.

### Optional RSAS RD7.3 integration

For an **existing** RSAS RD7.3 tree with the expected directory layout:

```powershell
.\build-rsas-selective.ps1 -RSASRoot "D:\path\to\RSAS-Distributed-Fabric-RD7.3-D3D12-SelectiveTrueSplit"
```

This copies generated `renderdoccmd.exe` and `renderdoc.dll` into `tools\renderdoc\1.46\x64`. **Back up existing binaries first**: the script may overwrite them. RD7.3 itself is not provided as a complete system by this source package, and this step does not establish cross-host correctness.

### Verification status and limitations

| Claim | Status |
| --- | --- |
| RenderDoc 1.46 sources and RSAS CLI/D3D12 selection paths exist | **Confirmed by source inspection** |
| Windows x64 Release build succeeds | **Not tested here** |
| Compiled binary returns the probe string | **Not tested here** |
| A real D3D12 `.rdc` capture selectively replays correctly | **Not tested here** |
| Cross-host GPU execution, synchronization and final-image composition | **Not established by this source** |
| Transparent GPU sharing for arbitrary unmodified Windows apps/games | **Not provided by this extension** |
| RSAS selective replay on D3D11, Vulkan, Linux or Android | **Not implemented by this D3D12-specific extension** |

This code should be treated as a research prototype. Claims of actual multi-GPU workload separation require independently measured event allocation, hardware execution evidence, resource-dependency checks, synchronization tests, and final-image validation.

### License, attribution and responsible publication

- Upstream: [RenderDoc](https://github.com/baldurk/renderdoc).
- The source bundle contains upstream RenderDoc 1.46 code with RSAS research changes.
- The root project license is **MIT**; preserve the copyright and license notices in [LICENSE.md](LICENSE.md).
- Bundled third-party components have their own license terms. Review `renderdoc/3rdparty/`, `qrenderdoc/3rdparty/`, and `docs/credits_acknowledgements.rst` before redistributing source or binaries.
- This work is **unofficial** and is not presented as endorsed by RenderDoc maintainers or OpenAI.

Before making the repository public, review it for secrets, API keys, access tokens, private captures, personal data, third-party licensing restrictions and redistributable binary assets. Documentation and build scripts are not substitutes for code, security and license review.
