# RSAS RenderDoc 1.46 selective D3D12 replay build

This tree is RenderDoc v1.46 with an **RSAS-specific research extension**.

## What changed

The extension adds `renderdoccmd rsas-selective-replay` for D3D12 captures. During a replay pass it preserves the captured state/copy/barrier stream, but only emits D3D12 shader-work actions whose RenderDoc event IDs are in the assigned set:

- DrawInstanced / DrawIndexedInstanced
- Dispatch
- ExecuteIndirect Draw/Dispatch children
- DispatchRays
- DispatchMesh

This replaces RD7.2's repeated `ReplayController.SetFrameEvent()` loop. The old loop repeatedly rebuilt a frame prefix and was **not valid evidence of a disjoint GPU split**.

## Scope

This is a capture-derived selective replay research backend. It does **not** make an unmodified live game process see a GPU in another PC as a local D3D12 adapter. Non-shader state/copy/barrier work is replayed on both peers. Final image/composition correctness is still Gate 4 and is not implied by Gate 3.

## Windows build requirement

RenderDoc's supplied build documentation says Windows builds require Visual Studio and a Windows SDK; the core source checkout contains its other build dependencies.

Install Visual Studio 2022 or Build Tools with:

- Desktop development with C++
- Windows 10 or Windows 11 SDK

Then from PowerShell in this source directory run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build-rsas-selective.ps1
```

To install the two custom binaries directly into an extracted RD7.3 directory:

```powershell
.\build-rsas-selective.ps1 -RSASRoot "D:\path\to\RSAS-Distributed-Fabric-RD7.3-D3D12-SelectiveTrueSplit"
```

A successful build must print:

```text
Probe PASS: RSAS_SELECTIVE_REPLAY_V1
BUILD PASS
```

It also creates:

```text
RenderDoc-1.46-RSAS-Selective-x64.zip
```

containing `renderdoccmd.exe`, `renderdoc.dll`, and `PROBE.txt`.

RD7.3 deliberately reports **BLOCKED** for D3D12 Gate 2/3 if `renderdoccmd rsas-selective-replay --probe` does not return `RSAS_SELECTIVE_REPLAY_V1`.
