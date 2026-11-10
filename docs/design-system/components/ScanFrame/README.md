# ScanFrame

The box the number must sit in. Only text inside it is read, which keeps stray numbers on the paper out.

- 300 × 180 dp centred slightly above the middle, corners 6px thick, 44px long, bent at `radius-md`.
- Searching: `scan` amber corners and a scan line that drifts up and down (1.6 s, ease-in-out). With "Remove animations" on, the line stays still.
- Locked: corners turn `signal` lime, the line disappears, the camera freezes for 300 ms, then the result sheet rises.
- Outside the box the camera is dimmed with `scrim` so the box reads first.
