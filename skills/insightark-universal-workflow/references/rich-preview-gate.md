# Rich Preview Gate

## When preview is required

A message batch is **preview-required** when:

- any message `contentType` is not `text/plain`, or
- the batch includes quick replies.

Otherwise (text-only, no quick replies): obtain normal write confirmation; **do not** call `messaging_message_preview`.

## Required flow (preview-required)

1. Build the canonical message payload for the step/batch.
2. Disclose the preview credit cost (**2 credits** for `messaging_message_preview`) before calling it.
3. Upload any required **local** media via `media_upload_url`, then PUT to the returned presigned URL; patch HTTPS asset URLs into the payload.
4. Call `messaging_message_preview` with the canonical payload.
5. Present the preview URL to the customer.
6. For **MA** rich steps, also present the step’s place in the journey schedule (ordered relative timing). The preview tool does not render graph delays.
7. Wait for explicit approval before send, `broadcast_create`, `ma_procedure_validate`, or `ma_procedure_create` for that content.

## Skip

Skip preview only after an **explicit** user instruction to skip. Still obtain confirmation for the subsequent write.

## Invalidation

After approval, any change to content, media, CTA, quick replies, platform, or timing **invalidates** the prior preview. Generate a new preview (and re-disclose credit cost) before proceeding.

## MA multi-step

Preview each **changed** preview-required step. Unchanged text-only steps do not need a preview.
