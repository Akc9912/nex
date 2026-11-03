/**
 * nex OpenCode V2 plugin.
 *
 * Registers the same shared Bash hooks that Claude Code uses:
 *   - session context injection (once per session)
 *   - destructive-command and pre-commit permission checks
 *   - post-edit checks (logged; OpenCode's formatter still runs)
 *   - session-end handoff + usage record
 *
 * This is intentionally small. It does not implement an orchestrator.
 */
import { Plugin } from "@opencode/plugin";
import { spawn } from "node:child_process";
import { mkdir, appendFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const NEX_ROOT = process.env.NEX_ROOT || join(homedir(), "nex");
const HOOKS = join(NEX_ROOT, "shared", "hooks");
const STATE = join(process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "nex");
const LOG = join(STATE, "opencode-plugin.log");

type HookResult = { code: number; stdout: string; stderr: string };

function runHook(name: string, payload: unknown, timeoutMs = 20_000): Promise<HookResult> {
  return new Promise((resolve) => {
    let stdout = "";
    let stderr = "";
    let settled = false;
    const child = spawn(join(HOOKS, name), [], {
      env: {
        ...process.env,
        NEX_HOOK_TOOL: "opencode",
        NEX_CWD: (payload as { cwd?: string })?.cwd || process.cwd(),
      },
      stdio: ["pipe", "pipe", "pipe"],
    });
    const finish = (result: HookResult) => {
      if (settled) return;
      settled = true;
      resolve(result);
    };
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      finish({ code: 124, stdout, stderr: `${stderr}\nnex: hook ${name} timed out` });
    }, timeoutMs);
    child.stdout.on("data", (chunk) => { stdout += String(chunk); });
    child.stderr.on("data", (chunk) => { stderr += String(chunk); });
    child.on("error", (error) => {
      clearTimeout(timer);
      finish({ code: 127, stdout, stderr: `${stderr}\nnex: ${error.message}` });
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      finish({ code: code ?? 1, stdout, stderr });
    });
    child.stdin.on("error", () => { /* the child may exit before reading */ });
    child.stdin.end(JSON.stringify(payload ?? {}));
  });
}

async function note(message: string): Promise<void> {
  try {
    await appendFile(LOG, `${new Date().toISOString()}\t${message}\n`, { mode: 0o600 });
  } catch {
    // Logging must never break a session.
  }
}

export default Plugin.define({
  id: "nex.hooks",
  async setup(ctx: any) {
    await mkdir(STATE, { recursive: true, mode: 0o700 }).catch(() => {});
    const started = new Set<string>();
    const lastEnd = new Map<string, number>();

    const sessionCwd = async (sessionID: string): Promise<string> => {
      let cwd = ctx.location?.directory || process.cwd();
      try {
        const session = await ctx.session.get({ sessionID });
        if (session?.directory) cwd = session.directory;
      } catch {
        // Fall back to the plugin location.
      }
      return cwd;
    };

    // Inject a compact project snapshot once per session.
    await ctx.session.hook("context", async (event: any) => {
      const sessionID = event.sessionID;
      if (!sessionID || started.has(sessionID)) return;
      started.add(sessionID);
      const cwd = await sessionCwd(sessionID);
      const result = await runHook("session-start.sh", { cwd, tool: "opencode" }, 6_000);
      if (result.stdout.trim()) {
        event.system.push({ type: "text", text: result.stdout.trim() });
      }
      if (result.code !== 0) await note(`session-start ${sessionID} exit=${result.code} ${result.stderr.slice(0, 500)}`);
    });

    // Guard shell commands and verify commits before they run.
    await ctx.permission.hook("evaluate", async (event: any) => {
      if (event.action !== "shell") return;
      const cwd = event.sessionID ? await sessionCwd(event.sessionID) : (ctx.location?.directory || process.cwd());
      for (const command of event.resources || []) {
        if (typeof command !== "string" || !command.trim()) continue;
        const guard = await runHook("guard-destructive.sh", { command, tool_input: { command }, cwd }, 8_000);
        if (guard.code === 2) {
          event.effect = "deny";
          event.message = guard.stderr.trim() || "Blocked by the nex destructive-command guard.";
          await note(`guard denied: ${command.slice(0, 200)}`);
          return;
        }
        if (/\bgit\s+commit\b/.test(command)) {
          const check = await runHook("pre-commit.sh", { cwd, tool_input: { command } }, 120_000);
          if (check.code !== 0) {
            event.effect = "deny";
            event.message = check.stderr.trim() || "Blocked by the nex pre-commit checks.";
            await note(`pre-commit denied: ${command.slice(0, 200)}`);
            return;
          }
        }
      }
    });

    // Post-edit checks: log the result so a failure is discoverable without
    // interrupting the tool call. OpenCode's formatter handles formatting.
    await ctx.tool.hook("execute.after", async (event: any) => {
      if (event.status !== "completed") return;
      if (!["edit", "write", "patch", "multiedit"].includes(event.tool)) return;
      const input = event.input || {};
      const file = input.filePath || input.path || input.file_path;
      if (!file) return;
      const cwd = ctx.location?.directory || process.cwd();
      const check = await runHook("post-edit.sh", { tool_input: { file_path: file }, cwd }, 20_000);
      if (check.code === 2) {
        await note(`post-edit ${file}: ${check.stderr.slice(0, 1000)}`);
        try {
          if (event.result && typeof event.result === "object") {
            event.result.metadata = {
              ...(event.result.metadata || {}),
              nex_post_edit: check.stderr.slice(0, 2000),
            };
          }
        } catch {
          // Never let observability break the tool result.
        }
      }
    });

    // Session end: write a deterministic handoff and a usage record.
    const controller = new AbortController();
    void (async () => {
      try {
        for await (const raw of ctx.event.subscribe({ signal: controller.signal })) {
          const event: any = raw;
          if (event.type !== "session.idle" && event.type !== "session.deleted") continue;
          const sessionID = event.data?.sessionID || event.properties?.sessionID || event.sessionID;
          if (!sessionID) continue;
          if (event.type === "session.deleted") {
            started.delete(sessionID);
            lastEnd.delete(sessionID);
            continue;
          }
          const now = Date.now();
          if (now - (lastEnd.get(sessionID) || 0) < 10_000) continue;
          lastEnd.set(sessionID, now);
          const cwd = await sessionCwd(sessionID);
          const result = await runHook(
            "session-end.sh",
            { tool: "opencode", session_id: sessionID, cwd, reason: "session.idle" },
            20_000,
          );
          if (result.code !== 0) await note(`session-end ${sessionID} exit=${result.code} ${result.stderr.slice(0, 500)}`);
        }
      } catch (error) {
        if (!controller.signal.aborted) await note(`event loop: ${String(error).slice(0, 500)}`);
      }
    })();

    return () => controller.abort();
  },
});
