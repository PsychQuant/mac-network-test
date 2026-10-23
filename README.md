# Mac Network Test — Mac 網路瓶頸診斷

> 狀態：診斷方法已整理完成，命令列工具開發中。
> Status: the diagnosis method is written down; the CLI is in development.

---

## 中文

在旅館、會場、共用空間連上網路，覺得「怪怪的慢」時，用這套方法回答三個問題：

1. 慢在哪一段：Wi-Fi、本地閘道，還是上游線路？
2. 是被限速，還是被塞住？
3. 對要做的事（瀏覽、大檔下載、視訊、VPN）有什麼影響？

### 診斷步驟

| 步驟 | 量什麼 | 怎麼判讀 |
|------|--------|----------|
| 1. Wi-Fi 連線 | 訊號、雜訊、連線速率 | 訊號強於 -67 dBm、連線速率遠高於實測頻寬 → 瓶頸不在 Wi-Fi |
| 2. 分層 ping | 閘道、外網各 30–50 次 | 掉包從哪一跳開始，問題就在那一跳；連閘道都掉包，代表本地網路擁擠 |
| 3. 上下行同時跑 vs 分開跑 | `networkQuality` 與 `networkQuality -s` | Wi-Fi 同一時間只能往一個方向傳：同時跑時兩個方向互相分掉頻寬 → Wi-Fi 是瓶頸；互不影響 → 瓶頸在後面的有線段 |
| 4. 連線數對照 | 1、4、8 條連線的每秒下載速度 | 每條連線卡在同一個值、隨連線數成倍增加、曲線是平的 → 每條連線限速；單條連線忽高忽低、慢慢爬升 → 被掉包拖慢 |
| 5. MTU | 不分段 ping，從 1472 bytes 往下 | 大封包無聲消失 → MTU 黑洞。TCP 通常不受影響，VPN 與視訊（UDP）會卡 |
| 6. 本機背景流量 | 網路介面的流量計數 | 排除是這台 Mac 自己在同步或備份 |
| 7. 有線對照 | 接上網路線，步驟 2–4 再跑一次 | 有線的掉包與延遲明顯改善 → 問題有一部分在 Wi-Fi 那一段；有線一樣慢 → 問題在閘道之後。先比對兩邊的閘道與上游路由：不同的話可能是兩條不同的線路，改善不一定來自避開了 Wi-Fi |

### 限速還是壅塞

單次量測常常分不出「每台裝置被限速」和「共用線路晚上塞住」，兩者都會讓速度卡在某個值。分辨方法：

- 換時段重量：清晨明顯變快、晚上變慢且波動大 → 壅塞；不論何時都是同一條平線 → 限速。
- 同一時間用手機熱點對照，確認問題不在這台 Mac。

### 量測陷阱

- ping 不能和測速同時跑：那樣量到的是滿載延遲，不是閒置延遲。
- `networkQuality` 預設上下行同時跑；要分開看，加 `-s`。
- Cloudflare 測速端點（`speed.cloudflare.com/__down`）單次超過 25 MB 會回 403。
- `networksetup -getMTU` 顯示的可能只是執行期的值，不代表有寫進設定。
- ping 閘道沒回不一定是掉包：路由器常會壓低回應自己 ping 的優先順序。同時 ping 外網，若穿過閘道的封包 0% 掉包，閘道的轉送就沒有問題。

### 隱私

診斷輸出會透露位置：BSSID 在公開的 Wi-Fi 資料庫裡查得到接近確切的地點，SSID、路由器名稱、閘道 IP、ISP 路由也能拼出使用者在哪裡。工具的輸出預設會遮掉這些欄位；分享結果前請再看一次。

這個 repo 是公開的，只放診斷方法與工具。量測結果預設寫在 `results/`，這個資料夾不進 git；要保存自己的量測紀錄，請放在另一個私人 repo 或只留在本機。

---

## English

When a hotel, venue, or co-working network feels slow, this method answers three questions:

1. Where is the bottleneck: Wi-Fi, the local gateway, or the upstream line?
2. Is the network throttled, or congested?
3. What does that mean for browsing, large downloads, video calls, and VPN?

### Steps

| Step | Measures | How to read it |
|------|----------|----------------|
| 1. Wi-Fi link | Signal, noise, link rate | Signal stronger than -67 dBm and a link rate far above measured throughput → Wi-Fi is not the bottleneck |
| 2. Hop-by-hop ping | 30–50 pings each to the gateway and the internet | Loss starts at the hop where the problem is; loss at the gateway means the local network is congested |
| 3. Concurrent vs sequential up/down | `networkQuality` and `networkQuality -s` | Wi-Fi transmits in one direction at a time: if the two directions split capacity when run together, Wi-Fi is the bottleneck; if they don't, the bottleneck is on the wired side |
| 4. Stream scaling | Per-second download rate with 1, 4, and 8 streams | Each stream pinned at the same rate, total scaling with stream count, flat curve → per-connection throttling; a single stream that ramps and collapses → loss-limited TCP |
| 5. MTU | Don't-fragment pings from 1472 bytes down | Large packets silently dropped → MTU black hole. TCP usually survives; VPN and video (UDP) stall |
| 6. Local background traffic | Interface byte counters | Rules out this Mac syncing or backing up |
| 7. Wired comparison | Plug in Ethernet and rerun steps 2–4 | Loss and latency clearly improve on wired → part of the problem is the Wi-Fi hop; wired is just as slow → the problem is past the gateway. Compare the gateway and upstream route first: if they differ, the two may be separate lines, and the improvement need not come from leaving Wi-Fi |

### Throttled or congested

One measurement often cannot separate a per-device cap from a shared line congested in the evening; both pin throughput at some ceiling. To tell them apart:

- Re-measure at another time: much faster early in the morning, slower and noisier at night → congestion; the same flat line at any hour → a cap.
- Compare against a phone hotspot at the same moment to rule out this Mac.

### Measurement traps

- Never ping while a throughput test is running: you measure loaded latency, not idle latency.
- `networkQuality` runs uplink and downlink concurrently by default; use `-s` to separate them.
- Cloudflare's speed endpoint (`speed.cloudflare.com/__down`) returns 403 above 25 MB per request.
- `networksetup -getMTU` may show a runtime value that was never written to the configuration.
- Unanswered pings to the gateway are not necessarily loss: routers often deprioritize replies to pings addressed to themselves. Ping the internet at the same time; if packets crossing the gateway see 0% loss, its forwarding is fine.

### Privacy

Diagnostic output reveals location: a BSSID can be looked up in public Wi-Fi databases to a near-exact position, and SSIDs, router names, gateway IPs, and ISP routes narrow it down further. The tool redacts these fields by default; review results before sharing them.

This repository is public and holds only the method and the tool. Results are written to `results/`, which git ignores; keep your own measurement records in a separate private repository, or only on your machine.
