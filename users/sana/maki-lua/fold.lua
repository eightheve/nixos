-- fold.lua — transcript folding for maki
--
-- Port of gopherbone/al-jaffee (pi) to maki: set a tag before a tangent,
-- work the tangent, then fold(summary) collapses everything after the tag
-- into the tag's result — only the summary stays in context. The folded
-- transcript is archived by maki's session-log shrink rewrite and comes back
-- whole with return_to_tag(prompt).
--
-- Requires a maki build with the fold-tag Rust patch (maki.session.fold_tag
-- and maki.session.restore_tag). On an unpatched build the tools queue
-- normally and the commit reports the missing API instead of touching
-- anything.
--
-- Model-facing semantics, kept from al-jaffee:
-- - The fold receipt is written in second person with excision metadata,
--   composed in the patched host where the entry counts live: a model
--   resuming from the folded context must be able to tell "I did this work
--   and it was spliced out" apart from "this never happened".
-- - fold sweeps EVERYTHING after the tag, user messages included; the
--   queue-time text warns so the summary can cover them.
-- - All model-directed traffic goes through observations
--   (maki.session.notify), never fake user turns.
-- - One fold/unfold commits per turn. The commit runs at TurnEnd with a
--   bounded poll for idle, and every failure reaches the model.

local TAG_TOOL = "set_tag"
local FOLD_TOOL = "fold"
local IDLE_POLL_MS = 250
local IDLE_POLL_MAX = 60

-- Per-session bookkeeping. tags: active (unfolded) tag tasks, newest last.
-- folds: completed folds, newest first, each with its archive sequence.
local state = {}
local pending = {}

local function session_state(sid)
  local s = state[sid]
  if not s then
    s = { tags = {}, folds = {} }
    state[sid] = s
  end
  return s
end

local function short(s, max)
  max = max or 48
  s = (tostring(s or ""):gsub("%s+", " "))
  if #s > max then
    return s:sub(1, max - 1) .. "…"
  end
  return s
end

-- Fold records survive /reload (the Lua host rebuilds and drops `state`)
-- through a file in the config dir, keyed by session id. Best-effort: losing
-- it only costs precise archive targeting, restore falls back to a scan.
local function state_path()
  local dir, err = maki.env.config_dir()
  if not dir then
    return nil, err
  end
  return dir .. "/fold-state.json"
end

local function save_state()
  local path, err = state_path()
  if not path then
    maki.log.debug("fold: no state path: " .. tostring(err))
    return
  end
  local out = {}
  for sid, s in pairs(state) do
    out[sid] = { tags = s.tags, folds = s.folds }
  end
  local ok, werr = maki.fs.write(path, maki.json.encode(out))
  if not ok then
    maki.log.debug("fold: could not persist state: " .. tostring(werr))
  end
end

local function load_state()
  local path = state_path()
  if not path then
    return
  end
  local text = maki.fs.read(path)
  if not text then
    return
  end
  local ok, decoded = pcall(maki.json.decode, text)
  if not ok or type(decoded) ~= "table" then
    return
  end
  for sid, s in pairs(decoded) do
    if type(s) == "table" and type(s.tags) == "table" and type(s.folds) == "table" then
      state[sid] = { tags = s.tags, folds = s.folds }
    end
  end
end

local function notify_model(sid, text)
  local ok, err = maki.session.notify(text, { session = sid, wake = true })
  if not ok then
    maki.log.warn("fold: could not reach session " .. tostring(sid) .. ": " .. tostring(err))
  end
end

-- Deferred: the init.lua load context cannot yield, so the async fs read
-- runs as its own task once the plugin host is up.
maki.async.run(load_state)

-- Tools -------------------------------------------------------------------

maki.api.register_tool({
  name = TAG_TOOL,
  kind = "fold",
  audiences = { "main" },
  description = [[Set a fold tag at the current point in the conversation. Do this right BEFORE starting a self-contained tangent or subtask (research detour, deep exploration, mechanical multi-step work) whose intermediate steps the main conversation will not need afterward. Then run the tangent normally. When it is done, call fold(summary): the whole tangent collapses into this tag's result, replaced by your summary, and you continue from this point with the tangent's tokens no longer in context. The full tangent stays archived; return_to_tag restores it. Nested tags are allowed; fold applies to the most recent one.]],
  schema = {
    type = "object",
    properties = {
      task = {
        type = "string",
        description = "Short label for the tangent you are about to do (the fold's name).",
      },
    },
    required = { "task" },
  },
  handler = function(input)
    local task = (tostring(input.task or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if task == "" then
      return { llm_output = "error: task is required", is_error = true }
    end
    local sid, err = maki.session.current()
    if not sid then
      return { llm_output = "error: " .. tostring(err), is_error = true }
    end
    local s = session_state(sid)
    table.insert(s.tags, task)
    save_state()
    return string.format(
      'Tag set: "%s". Work on this tangent now. When it is done, call fold with a '
        .. "self-contained summary of what you did, tried, decided, and produced — "
        .. "after the fold that summary is the only part of the tangent left in context.",
      task
    )
  end,
})

maki.api.register_tool({
  name = FOLD_TOOL,
  kind = "fold",
  audiences = { "main" },
  description = [[Complete the tangent started by your most recent set_tag call, collapsing it into the tag. Write the summary for future-you: after the fold, that summary at the tag is the ONLY part of the tangent that remains in the conversation — include what you did, tried, decided, and produced (file paths, key findings, conclusions). Call fold in the same turn, right when the tangent is done. The fold commits at the end of this turn if the conversation stays quiet: the tangent's full transcript leaves the context, your summary replaces the tag's result, and you continue the main conversation from there. You will not remember the folded work — the fold receipt will say so explicitly. If the fold cannot commit, you get a correction message and NOTHING is folded — the tangent stays in context and you can call fold again. Note: everything after the tag call is folded, so if anything significant happened past the tangent (including user messages), make sure the summary covers it. The folded transcript stays recoverable via return_to_tag.]],
  schema = {
    type = "object",
    properties = {
      summary = {
        type = "string",
        description = "Self-contained writeup of the completed tangent: what was done, tried, decided, produced. Include file paths and key findings worth keeping.",
      },
    },
    required = { "summary" },
  },
  handler = function(input)
    local summary = (tostring(input.summary or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if summary == "" then
      return { llm_output = "error: summary is required — after the fold it is the only part of the tangent left in context", is_error = true }
    end
    local sid, err = maki.session.current()
    if not sid then
      return { llm_output = "error: " .. tostring(err), is_error = true }
    end
    local s = session_state(sid)
    local queued = pending[sid]
    if queued and queued.kind == "return" then
      return {
        llm_output = "error: a return_to_tag is already queued for this turn — only one fold/unfold can commit per turn. This fold was NOT queued. Call fold again after the restore commits (next turn).",
        is_error = true,
      }
    end
    local task = s.tags[#s.tags]
    if not task then
      return {
        llm_output = "error: no active tag to fold. Call set_tag(task) before starting the tangent, then fold(summary) when it is done.",
        is_error = true,
      }
    end
    local snap, rerr = maki.session.read({ session = sid })
    if not snap then
      return {
        llm_output = "error: fold needs an interactive session (" .. tostring(rerr) .. ")",
        is_error = true,
      }
    end
    pending[sid] = { kind = "fold", task = task, summary = summary }
    return string.format(
      'Fold queued: "%s" will collapse into its tag at the end of this turn if the '
        .. "conversation stays quiet, with your summary recorded as the tag's result. "
        .. "Everything after the tag is folded — the tangent plus anything that happened "
        .. "past it, user messages included — so make sure the summary covers anything "
        .. "important from that span. Do not continue the tangent; continue the main "
        .. "line; the fold happens automatically. If it cannot commit, you will get a "
        .. "correction and nothing will be folded. The folded transcript stays "
        .. "restorable via return_to_tag.%s",
      task,
      queued and " (Supersedes the fold you queued earlier this turn.)" or ""
    )
  end,
})

maki.api.register_tool({
  name = "return_to_tag",
  kind = "fold",
  audiences = { "main" },
  description = [[Restore the full conversation of a completed fold. Use it when you need details from a tangent that was folded away (instead of re-doing the work). At the end of this turn the session goes back to the unfolded tangent: the full detailed conversation returns to context (fast when the provider prompt cache is still warm), and your prompt is re-sent there as a labeled fold observation (it does not impersonate the user) so you can mine it. Target the fold with fold (a case-insensitive substring of the fold's task label) or depth (1 = latest fold); without either, the latest fold is restored. After returning, name the fold explicitly if you return again — an unnamed restore picks the newest archive holding that tag, which after a restore is the branch the restore replaced.]],
  schema = {
    type = "object",
    properties = {
      prompt = {
        type = "string",
        description = "What you need from the unfolded conversation. Re-sent after the restore as a labeled fold observation.",
      },
      fold = {
        type = "string",
        description = "Which fold to restore: case-insensitive substring of the fold's task label. Defaults to the latest fold.",
      },
      depth = {
        type = "number",
        description = "Restore the depth-th newest fold (1 = latest). Takes precedence over fold when both are given.",
      },
    },
    required = { "prompt" },
  },
  handler = function(input)
    local prompt = (tostring(input.prompt or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if prompt == "" then
      return { llm_output = "error: prompt is required — say exactly what you need from the unfolded conversation", is_error = true }
    end
    local sid, err = maki.session.current()
    if not sid then
      return { llm_output = "error: " .. tostring(err), is_error = true }
    end
    local s = session_state(sid)
    local queued = pending[sid]
    if queued and queued.kind == "fold" then
      return {
        llm_output = "error: a fold is already queued for this turn — only one fold/unfold can commit per turn. This restore was NOT queued. Call return_to_tag after the fold commits (next turn).",
        is_error = true,
      }
    end
    local which = (tostring(input.fold or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    local depth = input.depth and math.floor(tonumber(input.depth) or 0) or nil
    local rec
    if depth and depth > 0 then
      rec = s.folds[depth]
    elseif which ~= "" then
      local lower = which:lower()
      for _, f in ipairs(s.folds) do
        if f.task:lower():find(lower, 1, true) then
          rec = f
          break
        end
      end
      if not rec then
        -- Records lost (e.g. after /reload): let the host scan the archives
        -- for a tag call matching the name.
        rec = { task = which, archived = nil }
      end
    else
      rec = s.folds[1]
      if not rec and #s.tags > 0 then
        rec = { task = s.tags[#s.tags], archived = nil }
      end
    end
    if not rec then
      local names = {}
      for i, f in ipairs(s.folds) do
        if i > 5 then
          names[#names + 1] = ("… +%d older"):format(#s.folds - 5)
          break
        end
        names[#names + 1] = '"' .. short(f.task, 40) .. '"'
      end
      return {
        llm_output = "error: nothing to restore — no completed fold on record."
          .. (#names > 0 and (" Folds on record (newest first): " .. table.concat(names, ", ") .. ".") or "")
          .. " Set a tag with set_tag, do the tangent, and fold(summary) to create one.",
        is_error = true,
      }
    end
    local snap, rerr = maki.session.read({ session = sid })
    if not snap then
      return {
        llm_output = "error: restore needs an interactive session (" .. tostring(rerr) .. ")",
        is_error = true,
      }
    end
    pending[sid] = { kind = "return", task = rec.task, archived = rec.archived, prompt = prompt }
    return string.format(
      "Restore queued: at the end of this turn, if the conversation stays quiet, the "
        .. 'full "%s" conversation returns to context and your prompt is re-sent there '
        .. "as a labeled fold observation. Do not continue here — continue from the "
        .. "restored conversation automatically. If the restore cannot commit, you will "
        .. "get a correction and nothing will change.%s",
      short(rec.task, 60),
      queued and " (Supersedes the restore you queued earlier this turn.)" or ""
    )
  end,
})

-- Commit at turn end -------------------------------------------------------

local function wait_idle(sid)
  for _ = 1, IDLE_POLL_MAX do
    local snap, err = maki.session.read({ session = sid })
    if not snap then
      return false, err
    end
    if snap.status == "idle" then
      return true, nil
    end
    maki.async.sleep(IDLE_POLL_MS)
  end
  return false, string.format("session did not go idle within %.1fs", IDLE_POLL_MAX * IDLE_POLL_MS / 1000)
end

local function commit_fold(sid, job)
  local s = session_state(sid)
  local idle, werr = wait_idle(sid)
  if not idle then
    notify_model(
      sid,
      string.format(
        '[fold] FAILED, nothing was folded (%s): the tangent is still fully in your context — do not refer to it as folded. You may call fold(summary) again.',
        tostring(werr)
      )
    )
    return
  end
  local reply, ferr = maki.session.fold_tag({
    tool_name = TAG_TOOL,
    task = job.task,
    receipt = job.summary,
  })
  if reply then
    table.insert(s.folds, 1, {
      task = job.task,
      summary = job.summary,
      archived = reply.archived,
    })
    for i = #s.tags, 1, -1 do
      if s.tags[i] == job.task then
        table.remove(s.tags, i)
        break
      end
    end
    save_state()
    notify_model(
      sid,
      string.format(
        '[fold] committed: "%s" is folded into set_tag; its receipt replaced the tag result. '
          .. "Continue the main conversation.",
        short(job.task, 60)
      )
    )
  else
    notify_model(
      sid,
      string.format(
        "[fold] FAILED, nothing was folded (%s): the tangent is still fully in your "
          .. "context — do not refer to it as folded. You may call fold(summary) again.",
        tostring(ferr)
      )
    )
  end
end

local function commit_return(sid, job)
  local s = session_state(sid)
  local idle, werr = wait_idle(sid)
  if not idle then
    notify_model(
      sid,
      string.format(
        "[return_to_tag] FAILED, nothing changed (%s): the folded summary is still in "
          .. "context. You may call return_to_tag again.",
        tostring(werr)
      )
    )
    return
  end
  local reply, rerr = maki.session.restore_tag({
    archive = job.archived,
    tool_name = TAG_TOOL,
    task = job.task,
    fold_tool_name = FOLD_TOOL,
  })
  if reply then
    -- The restored fold (and any folded after it) is undone: drop its record
    -- and everything newer, and make the restored tag active again.
    for i, f in ipairs(s.folds) do
      if f.task == job.task and (job.archived == nil or f.archived == job.archived) then
        for _ = 1, i do
          table.remove(s.folds, 1)
        end
        break
      end
    end
    table.insert(s.tags, job.task)
    save_state()
    notify_model(
      sid,
      string.format(
        '[return_to_tag] Restored "%s": the full conversation of the folded task is back '
        .. "in context.\n\n%s",
        short(job.task, 60),
        job.prompt
      )
    )
  else
    notify_model(
      sid,
      string.format(
        "[return_to_tag] FAILED, nothing changed (%s): the folded summary is still in "
          .. "context. You may call return_to_tag again.",
        tostring(rerr)
      )
    )
  end
end

maki.api.create_autocmd("TurnEnd", {
  callback = function(ev)
    local data = ev.data or {}
    local sid = data.session_id
    local job = sid and pending[sid]
    if not job then
      return
    end
    if data.reason == "cancelled" then
      pending[sid] = nil
      notify_model(
        sid,
        job.kind == "fold"
          and "[fold] your fold did not commit: the turn was cancelled; nothing was "
            .. "folded. Call fold(summary) again if you still want it."
          or "[return_to_tag] your restore did not commit: the turn was cancelled; "
            .. "nothing changed. Call return_to_tag again if you still want it."
      )
      return
    end
    if data.reason ~= "finished" then
      return
    end
    pending[sid] = nil
    maki.async.run(function()
      if job.kind == "fold" then
        commit_fold(sid, job)
      else
        commit_return(sid, job)
      end
    end)
  end,
})

-- Status -------------------------------------------------------------------

maki.api.register_command({
  name = "/fold-status",
  description = "Show fold state: active tags, folds on record, pending surgery",
  handler = function()
    local sid, err = maki.session.current()
    if not sid then
      maki.ui.flash("fold: " .. tostring(err))
      return
    end
    local s = session_state(sid)
    local lines = {}
    if #s.tags == 0 then
      lines[#lines + 1] = "active tags: none"
    else
      local parts = {}
      for _, t in ipairs(s.tags) do
        parts[#parts + 1] = '"' .. short(t, 32) .. '"'
      end
      lines[#lines + 1] = "active tags (newest last): " .. table.concat(parts, ", ")
    end
    if #s.folds == 0 then
      lines[#lines + 1] = "folds on record: none"
    else
      local parts = {}
      for i, f in ipairs(s.folds) do
        if i > 5 then
          parts[#parts + 1] = ("… +%d older"):format(#s.folds - 5)
          break
        end
        parts[#parts + 1] = ('%d. "%s"'):format(i, short(f.task, 32))
      end
      lines[#lines + 1] = "folds on record (newest first): " .. table.concat(parts, ", ")
    end
    local p = pending[sid]
    lines[#lines + 1] = "pending: " .. (p and p.kind or "none")
    maki.notify(table.concat(lines, "\n"), "info")
  end,
})
