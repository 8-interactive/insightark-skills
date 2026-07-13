# Local structural checks for outbound message payloads (Tier 1).
# Mirrors server/lib/logic/business/message_preview.js validateRichOutboundMessages (subset).
# Full validation still runs on API (preview / send / broadcast).

def err($path; $message):
  {path: $path, message: $message};

def supported_content_types:
  ["text/plain", "application/x-image", "application/x-video", "application/x-file", "application/x-template"];

def supported_template_types:
  ["card", "confirm", "carousel", "imagemap", "richvideo", "image"];

def line_only_template_types:
  ["carousel", "imagemap"];

def carousel_like_template_types:
  ["carousel", "image"];

def normalize_aspect_ratio($v):
  if ($v | type) == "string" and ($v | length) > 0 then $v else "1:1" end;

def is_nonempty_string($v):
  ($v | type) == "string" and ($v | length) > 0;

def validate_carousel_like_elements($elements; $msgIdx; $tt):
  if ($elements | type) != "array" or ($elements | length) == 0 then
    [err("messages[\($msgIdx)].data.elements"; "must be a non-empty array for templateType \"\($tt)\"")]
  else
    [range(0; $elements | length) as $ei
      | ($elements[$ei] // null) as $el
      | if ($el | type) != "object" then
          err("messages[\($msgIdx)].data.elements[\($ei)]"; "must be an object")
        elif is_nonempty_string($el.imageUrl) | not then
          err("messages[\($msgIdx)].data.elements[\($ei)].imageUrl"; "must be a non-empty string")
        else empty end
    ]
    + (if ([$elements[] | normalize_aspect_ratio(.aspectRatio)] | unique | length) > 1 then
        [err("messages[\($msgIdx)].data"; "carousel slides must use the same aspectRatio on every element")]
      else [] end)
  end;

def validate_card_elements($elements; $msgIdx):
  if ($elements | type) != "array" or ($elements | length) == 0 then
    [err("messages[\($msgIdx)].data.elements"; "must be a non-empty array for templateType \"card\"")]
  else
    [range(0; $elements | length) as $ei
      | ($elements[$ei] // null) as $el
      | if ($el | type) != "object" then
          err("messages[\($msgIdx)].data.elements[\($ei)]"; "must be an object")
        elif ($el.imageType // "") == "hidden" then
          empty
        elif is_nonempty_string($el.imageUrl) and (is_nonempty_string($el.aspectRatio) | not) then
          err("messages[\($msgIdx)].data.elements[\($ei)].aspectRatio"; "must be set when imageUrl is present (e.g. 1:1 for square art)")
        else empty end
    ]
  end;

def validate_message($msg; $idx; $platform):
  if ($msg | type) != "object" then
    [err("messages[\($idx)]"; "must be an object")]
  else
    ($msg.contentType // "") as $ct
    | ($msg.data // null) as $data
    | if (supported_content_types | index($ct)) == null then
        [err("messages[\($idx)].contentType"; "is not supported")]
      elif ($data | type) != "object" then
        [err("messages[\($idx)].data"; "must be an object")]
      elif $ct == "text/plain" then
        if is_nonempty_string($data.content) then [] else [err("messages[\($idx)].data.content"; "must be a non-empty string")] end
      elif $ct == "application/x-image" or $ct == "application/x-video" or $ct == "application/x-file" then
        if is_nonempty_string($data.url) then [] else [err("messages[\($idx)].data.url"; "must be a non-empty string")] end
      elif $ct == "application/x-template" then
        (($data.templateType // $msg.templateType) // "") as $tt
        | if (supported_template_types | index($tt)) == null then
            [err("messages[\($idx)]"; "templateType is not supported")]
          elif ($platform | length) > 0 and (line_only_template_types | index($tt)) != null and $platform != "line" then
            [err("messages[\($idx)]"; "templateType \"\($tt)\" is only supported on LINE platform")]
          elif (carousel_like_template_types | index($tt)) != null then
            validate_carousel_like_elements($data.elements; $idx; $tt)
          elif $tt == "card" then
            validate_card_elements($data.elements; $idx)
          else
            []
          end
      else
        []
      end
  end;

def is_https_url($v):
  is_nonempty_string($v) and ($v | startswith("https://"));

def validate_quick_reply_item($item; $idx; $platform):
  if ($item | type) != "object" then
    [err("quickReply[\($idx)]"; "must be an object")]
  else
    ($item.action // "") as $action
    | (if is_nonempty_string($item.label) then [] else [err("quickReply[\($idx)].label"; "must be a non-empty string")] end)
    + (if is_nonempty_string($item.label) and ($item.label | length) > 20 then [err("quickReply[\($idx)].label"; "must not exceed 20 characters")] else [] end)
    + (if ($action | IN("message", "uri", "postback")) then [] else [err("quickReply[\($idx)].action"; "must be \"message\", \"uri\", or \"postback\"")] end)
    + (if $action == "message" and (is_nonempty_string($item.text) | not) then [err("quickReply[\($idx)].text"; "must be a non-empty string for action \"message\"")] else [] end)
    + (if $action == "uri" and $platform != "line" and ($platform | length) > 0 then [err("quickReply[\($idx)].action"; "uri is only supported on LINE platform")] else [] end)
    + (if $action == "uri" and (is_https_url($item.url) | not) then [err("quickReply[\($idx)].url"; "must be an https URL for action \"uri\"")] else [] end)
    + (if $action == "uri" and is_nonempty_string($item.url) and ($item.url | length) > 1000 then [err("quickReply[\($idx)].url"; "must not exceed 1000 characters")] else [] end)
    + (if $action == "postback" and (is_nonempty_string($item.postback) | not) then [err("quickReply[\($idx)].postback"; "must be a non-empty string for action \"postback\"")] else [] end)
    + (if $action == "postback" and ($item.tg != null) and (($item.tg | type) != "string") then [err("quickReply[\($idx)].tg"; "must be a string when provided")] else [] end)
    + (if $action == "postback" and ($item.imageUrl != null) and (($item.imageUrl | type) != "string") then [err("quickReply[\($idx)].imageUrl"; "must be a string when provided")] else [] end)
    + (if $action == "postback" and ($item.imageUrl != null) and (($item.imageUrl | type) == "string") and (is_https_url($item.imageUrl) | not) then [err("quickReply[\($idx)].imageUrl"; "must be an https URL")] else [] end)
  end;

def validate_quick_reply($qr; $platform):
  if $qr == null then
    []
  elif ($qr | type) != "array" then
    [err("quickReply"; "must be an array when provided")]
  elif ($qr | length) == 0 then
    [err("quickReply"; "must be a non-empty array when provided")]
  elif ($qr | length) > 13 then
    [err("quickReply"; "must not exceed 13 items")]
  else
    [range(0; $qr | length) as $i | validate_quick_reply_item($qr[$i]; $i; $platform)] | add // []
  end;

($platform_arg // "") as $platform_arg
| . as $root
| ($root.platform // $platform_arg // "line") as $platform
| ($max_messages // "") as $max_messages
| (.messages // null) as $messages
| (if ($messages | type) != "array" then
    [err("messages"; "must be an array")]
  elif ($messages | length) == 0 then
    [err("messages"; "must be a non-empty array")]
  elif ($max_messages | length) > 0 and ($messages | length) > ($max_messages | tonumber) then
    [err("messages"; "must not exceed \($max_messages) items")]
  else
    [range(0; $messages | length) as $i | validate_message($messages[$i]; $i; $platform)] | add // []
  end) as $message_errors
| validate_quick_reply($root.quickReply; $platform) as $qr_errors
| $message_errors + $qr_errors
