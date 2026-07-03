#!/usr/bin/env bash
# Claude Code status line: model · effort · git branch · context tokens · subscription usage
# Quiet by default: healthy segments use the terminal's default foreground (readable on light
# or dark themes); meters turn yellow/red only past a warning threshold. Model = the one accent.
# Reads the session JSON from stdin. See https://code.claude.com/docs/en/statusline

input=$(cat)

# ESC byte for ANSI colors, defined here (not as an invisible literal in the jq) so the script
# stays editable — a raw ESC is non-printing and gets silently dropped when the file is rewritten.
ESC=$'\033'

# Current working dir from the session JSON, then the git branch for whatever repo it
# sits in (short SHA when detached). Empty if the dir isn't inside a git repo.
cwd=$(jq -rn --argjson d "$input" '$d.workspace.current_dir // $d.cwd // ""')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

jq -rn --argjson d "$input" --arg branch "$branch" --arg E "$ESC" '
  def color(c; s): $E + "[" + c + "m" + s + $E + "[0m";
  def k: if . >= 1000 then ((./1000)|floor|tostring) + "k" else (.|tostring) end;
  # quiet meter: neutral (default fg) while healthy, yellow >=70%, red >=90%
  def meter(p; s):
    if   p >= 90 then color("31"; s)
    elif p >= 70 then color("33"; s)
    else s end;

  # --- model + effort ---
  ($d.model.display_name // "?")                              as $model |
  ($d.effort.level // "")                                     as $eff |

  # --- context (tokens) ---
  ($d.context_window.total_input_tokens // 0)                as $used |
  ($d.context_window.context_window_size // 0)               as $max |
  ($d.context_window.used_percentage // 0)                   as $pct |

  # --- subscription usage (color by whichever window is closer to its cap) ---
  ($d.rate_limits.five_hour.used_percentage // null)         as $h5 |
  ($d.rate_limits.seven_day.used_percentage // null)         as $d7 |
  (if ($h5 != null or $d7 != null)
     then ([($h5 // 0), ($d7 // 0)] | max) else null end)    as $umax |

  # --- assemble: identity (calm) on the left, meters on the right ---
  [
    # model is the one accent; effort + branch stay neutral
    color("36"; $model)
      + (if $eff != "" then color("90"; " · " + $eff) else "" end),

    (if $branch != "" then ("⎇ " + $branch) else empty end),

    (if $max > 0
      then meter($pct; "⛁ " + ($used|k) + "/" + ($max|k))
      else empty end),

    (if $umax != null
      then meter($umax;
        "▮ "
        + (if $h5 != null then "5h:" + (($h5|floor)|tostring) + "%" else "" end)
        + (if ($h5 != null and $d7 != null) then " " else "" end)
        + (if $d7 != null then "7d:" + (($d7|floor)|tostring) + "%" else "" end))
      else empty end)
  ]
  | map(select(. != "" and . != null))
  | join(color("90"; "  ·  "))
'
