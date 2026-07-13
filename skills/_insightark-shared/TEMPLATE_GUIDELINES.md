# Super 8 Studio — LINE template message guidelines

Agents **must** follow these shapes when authoring `application/x-template` messages. Copy from `examples/messages/*.json` and edit — do not invent fields from other chat platforms.

Run `messages_validate.sh --messages-file PATH --platform line` before preview or send. The API enforces the same rules (mixed carousel ratios → `400 error/invalid-carousel-aspect-ratio`).

## General

| Rule | Detail |
|------|--------|
| Wrapper | `{ "platform": "line", "messages": [ ... ], "quickReply": [...] }` |
| Template message | `contentType: "application/x-template"`, `data.templateType` required |
| Media URLs | Prefer `https://assets.no8.io/...` from `media_upload_url.sh`; external HTTPS URLs may work but are not guaranteed |
| Variables | Customer display name in `text/plain` `content` or template `altText`: use EJS `<%= name %>` (same as Super 8 Console). **Do not use `{{name}}`** — it is sent literally. Preview: set `sampleCustomer.displayName` or `originalDisplayName`. Send/broadcast: uses each recipient's `originalDisplayName` (falls back to `displayName`). |
| LINE-only types | `carousel`, `imagemap` — rejected on facebook / instagram / whatsapp |

---

## `card` — 多頁卡片（標題 + 副標 + 圖 + 按鈕）

**Use when:** product options, service info with readable title/subtitle and labeled buttons.

```json
{
  "contentType": "application/x-template",
  "data": {
    "templateType": "card",
    "altText": "通知列表文字",
    "elements": [
      {
        "title": "標題",
        "subtitle": "副標題或說明",
        "imageType": "upload",
        "imageUrl": "https://assets.no8.io/.../960x960.jpg",
        "aspectRatio": "1:1",
        "buttons": [
          { "type": "url", "title": "按鈕文字", "data": "https://...", "tags": [] }
        ]
      }
    ]
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `elements[].title` | Yes | Shown on the card |
| `elements[].subtitle` | Recommended | Body copy under title |
| `elements[].imageUrl` | Recommended | Hero image; use uploaded asset |
| `elements[].imageType` | When using upload | Set `"upload"` for Console-compatible cards |
| `elements[].aspectRatio` | **Yes when `imageUrl` is set** | Controls LINE hero crop. `1:1` (960×960 square), `1.92:1` (960×500 wide), `1:1.618` (960×1553 tall). **If omitted, LINE defaults to `320:213` and crops square/portrait art.** |
| `elements[].buttons` | Yes | `type`: `url`, `postback`, `phone` |

**Do not** put carousel-only overlay fields (`x`, `y`, `width`, `height` as `%`) on card buttons unless mirroring an existing working payload.

**Preview vs LINE:** Preview now crops the hero image using the same `aspectRatio` (or the `320:213` default) as the send pipeline. Set `aspectRatio` to match your uploaded image dimensions before preview.

---

## `carousel` — 輪播大圖（整圖 + 透明熱區）

**Use when:** swipeable full-bleed slides where the **image is the UI** (buttons are invisible tap areas).

```json
{
  "contentType": "application/x-template",
  "data": {
    "templateType": "carousel",
    "altText": "通知列表文字",
    "elements": [
      {
        "imageUrl": "https://assets.no8.io/.../1040x1040.jpg",
        "aspectRatio": "1:1",
        "size": { "width": 1040, "height": 1040 },
        "buttons": [
          {
            "type": "url",
            "title": "了解更多",
            "data": "https://...",
            "tags": [],
            "x": "0%",
            "y": "0%",
            "width": "100%",
            "height": "100%"
          }
        ]
      }
    ]
  }
}
```

| Rule | Detail |
|------|--------|
| **Same `aspectRatio` on every slide** | Required. Mixing `16:9` and `1:1` breaks LINE layout (white gaps). API rejects mixed ratios. |
| Recommended ratio | **`1:1`** with images **1040×1040** (Console default) |
| Other supported ratios | `1:1.618`, `1.92:1`, `16:9`, `4:3` — use **one ratio for all slides** |
| `size` | Strongly recommended `{ width, height }` per slide (matches image pixels) |
| `title` / `subtitle` | **Not shown** on carousel — do not expect card-style text |
| `buttons` | Overlay on image; use `%` for `x`, `y`, `width`, `height` |
| Slides | 2–10 typical; each slide needs `imageUrl` |

**Agent mistakes to avoid**

- Mixing landscape (`16:9`) and square (`1:1`) in one carousel
- Omitting `imageUrl` on a slide
- Using card-shaped JSON (title/subtitle) inside carousel elements
- Expecting visible button labels (carousel uses full-image tap targets)

---

## `imagemap` — 單張大圖多區塊

**Use when:** one image with multiple rectangular tap regions (menu, map-style layout).

See `examples/messages/imagemap-line.json`. Typically **one** element with `size`, `aspectRatio`, `messageTemplateType`, and multiple `buttons` with `%` coordinates.

| Rule | Detail |
|------|--------|
| LINE only | Yes |
| `size` | Required (`width` / `height`, often 1040×1040) |
| `buttons` | Each needs `x`, `y`, `width`, `height` as percentages |

---

## `confirm` — 確認型（標題 + 兩個按鈕）

See `examples/messages/confirm-line.json`. One element, `title`, exactly two `postback` or `url` buttons.

---

## `richvideo` — 影片訊息

See `examples/messages/richvideo-line.json`. One element with `videoUrl`, `previewImageUrl`, `aspectRatio`, optional `buttons`.

---

## `image` — 多頁大圖輪播

Same **uniform `aspectRatio`** rule as `carousel`. Each element is a full-image slide with one primary button.

---

## Workflow checklist (agents)

1. Pick the template type from this doc — do not blend card and carousel shapes.
2. Start from the matching file in `examples/messages/`.
3. Upload local images via `media_upload_url.sh`; patch URLs into the scratch JSON.
4. `messages_validate.sh --messages-file ... --platform line`
5. `preview_create.sh` → user confirms (~4h link, 2 credits)
6. `customer_send_message.sh` or `broadcast_create.sh` with the **same file**
