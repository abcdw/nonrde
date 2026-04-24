/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Andrew Tropin <andrew@trop.in>
 *
 * OpenAI Codex subscription status extension.
 *
 * - Adds /ostatus command
 * - Updates footer status with current Codex usage snapshots
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const AUTH_PATH = join(homedir(), ".pi", "agent", "auth.json");
const USAGE_ENDPOINT = "https://chatgpt.com/backend-api/wham/usage";
const JWT_CLAIM_PATH = "https://api.openai.com/auth";
const PERIODIC_REFRESH_MS = 5 * 60 * 1000;
const MIN_REFRESH_GAP_MS = 60 * 1000;

interface RateLimitWindowSnapshot {
	used_percent?: number | null;
	limit_window_seconds?: number | null;
	reset_after_seconds?: number | null;
	reset_at?: number | null;
}

interface RateLimitStatusDetails {
	allowed?: boolean;
	limit_reached?: boolean;
	primary_window?: RateLimitWindowSnapshot | null;
	secondary_window?: RateLimitWindowSnapshot | null;
}

interface AdditionalRateLimitDetails {
	limit_name?: string;
	metered_feature?: string;
	rate_limit?: RateLimitStatusDetails | null;
}

interface CreditStatusDetails {
	has_credits?: boolean;
	unlimited?: boolean;
	balance?: string | null;
}

interface UsagePayload {
	plan_type?: string;
	rate_limit?: RateLimitStatusDetails | null;
	credits?: CreditStatusDetails | null;
	additional_rate_limits?: AdditionalRateLimitDetails[] | null;
}

interface AccessData {
	token: string;
	accountId: string;
}

interface UsageOk {
	ok: true;
	payload: UsagePayload;
}

interface UsageErr {
	ok: false;
	message: string;
	status?: number;
}

type UsageResult = UsageOk | UsageErr;



function readOpenAICodexAccessData(): AccessData | UsageErr {
	try {
		const raw = readFileSync(AUTH_PATH, "utf-8");
		const auth = JSON.parse(raw) as Record<string, unknown>;
		const entry = auth?.["openai-codex"] as Record<string, unknown> | undefined;

		if (!entry) {
			return {
				ok: false,
				message: `No openai-codex entry in ${AUTH_PATH}. Run /login first.`,
			};
		}

		const token = typeof entry.access === "string" ? entry.access : "";
		if (!token) {
			return {
				ok: false,
				message:
					"openai-codex token is missing. This extension requires ChatGPT OAuth login for openai-codex.",
			};
		}

		const accountId = extractAccountId(token);
		if (!accountId) {
			return {
				ok: false,
				message:
					"Could not extract chatgpt_account_id from token. Try /logout openai-codex and /login again.",
			};
		}

		return { token, accountId };
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		return { ok: false, message: `Failed to read ${AUTH_PATH}: ${msg}` };
	}
}

function extractAccountId(token: string): string | null {
	try {
		const parts = token.split(".");
		if (parts.length !== 3) {
			return null;
		}

		const payloadBase64Url = parts[1];
		const payloadBase64 = payloadBase64Url.replace(/-/g, "+").replace(/_/g, "/");
		const padding = "=".repeat((4 - (payloadBase64.length % 4)) % 4);
		const payloadJson = Buffer.from(payloadBase64 + padding, "base64").toString("utf-8");
		const payload = JSON.parse(payloadJson) as Record<string, unknown>;
		const auth = payload[JWT_CLAIM_PATH] as Record<string, unknown> | undefined;
		const accountId = auth?.chatgpt_account_id;
		if (typeof accountId !== "string" || accountId.length === 0) {
			return null;
		}
		return accountId;
	} catch {
		return null;
	}
}

async function fetchUsage(signal?: AbortSignal): Promise<UsageResult> {
	const access = readOpenAICodexAccessData();
	if ("ok" in access && !access.ok) {
		return access;
	}

	try {
		const response = await fetch(USAGE_ENDPOINT, {
			method: "GET",
			headers: {
				Authorization: `Bearer ${access.token}`,
				"ChatGPT-Account-Id": access.accountId,
				"Content-Type": "application/json",
			},
			signal,
		});

		if (!response.ok) {
			const body = await response.text().catch(() => "");
			const detail = parseApiErrorBody(body);
			return {
				ok: false,
				status: response.status,
				message: detail ?? `API ${response.status}`,
			};
		}

		const payload = (await response.json()) as UsagePayload;
		return { ok: true, payload };
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		return { ok: false, message: `Failed to fetch usage: ${msg}` };
	}
}

function parseApiErrorBody(body: string): string | null {
	if (!body.trim()) {
		return null;
	}

	try {
		const parsed = JSON.parse(body) as Record<string, unknown>;
		const error = parsed.error as Record<string, unknown> | undefined;
		if (!error) {
			return body.slice(0, 300);
		}

		const type = typeof error.type === "string" ? error.type : "error";
		const message = typeof error.message === "string" ? error.message : "request failed";
		const resetsAt = typeof error.resets_at === "number" ? error.resets_at : null;

		if (resetsAt) {
			return `${type}: ${message} (try again in ${formatCountdown(resetsAt)})`;
		}

		return `${type}: ${message}`;
	} catch {
		return body.slice(0, 300);
	}
}



function toPercent(value: number | null | undefined): string {
	if (typeof value !== "number" || !Number.isFinite(value)) {
		return "n/a";
	}
	return `${Math.max(0, Math.round(value))}%`;
}

function formatCountdown(resetAt: number | null | undefined): string {
	if (typeof resetAt !== "number") {
		return "unknown";
	}

	const diffMs = resetAt * 1000 - Date.now();
	if (diffMs <= 0) {
		return "now";
	}

	const totalMin = Math.ceil(diffMs / 60000);
	const days = Math.floor(totalMin / (24 * 60));
	const hours = Math.floor((totalMin % (24 * 60)) / 60);
	const mins = totalMin % 60;

	if (days > 0) {
		return `${days}d ${hours}h`;
	}
	if (hours > 0) {
		return `${hours}h ${mins}m`;
	}
	return `${mins}m`;
}

function formatLocalTime(resetAt: number | null | undefined): string {
	if (typeof resetAt !== "number") {
		return "unknown";
	}
	return new Date(resetAt * 1000).toLocaleString(undefined, {
		hour: "2-digit",
		minute: "2-digit",
		month: "short",
		day: "numeric",
	});
}

function compactStatus(payload: UsagePayload): string {
	const primary = payload.rate_limit?.primary_window ?? null;
	const secondary = payload.rate_limit?.secondary_window ?? null;
	return `5h:${toPercent(primary?.used_percent)} 7d:${toPercent(secondary?.used_percent)}`;
}

function formatWindowLine(label: string, window: RateLimitWindowSnapshot | null | undefined): string {
	if (!window) {
		return `${label}: n/a`;
	}

	const used = toPercent(window.used_percent);
	const resetsAt = formatLocalTime(window.reset_at);
	const inText = formatCountdown(window.reset_at);
	const durationSec = typeof window.limit_window_seconds === "number" ? window.limit_window_seconds : null;
	const durationMin = durationSec ? Math.round(durationSec / 60) : null;
	const duration = durationMin ? `${durationMin}m` : "unknown";

	return `${label}: ${used}, window ${duration}, resets ${resetsAt} (in ${inText})`;
}

function formatUsageReport(payload: UsagePayload): string {
	const lines: string[] = [];
	lines.push("OpenAI Codex usage");
	lines.push("");
	lines.push(`Plan: ${payload.plan_type ?? "unknown"}`);
	lines.push(`Allowed: ${String(payload.rate_limit?.allowed ?? "unknown")}`);
	lines.push(`Limit reached: ${String(payload.rate_limit?.limit_reached ?? "unknown")}`);
	lines.push("");
	lines.push(formatWindowLine("Primary", payload.rate_limit?.primary_window));
	lines.push(formatWindowLine("Secondary", payload.rate_limit?.secondary_window));

	if (payload.credits) {
		lines.push("");
		lines.push("Credits");
		lines.push(`- has_credits: ${String(payload.credits.has_credits ?? false)}`);
		lines.push(`- unlimited: ${String(payload.credits.unlimited ?? false)}`);
		if (payload.credits.balance) {
			lines.push(`- balance: ${payload.credits.balance}`);
		}
	}

	const additional = Array.isArray(payload.additional_rate_limits) ? payload.additional_rate_limits : [];
	if (additional.length > 0) {
		lines.push("");
		lines.push("Additional limits");
		for (const item of additional) {
			const name = item.limit_name ?? item.metered_feature ?? "unknown";
			lines.push(`- ${name}`);
			lines.push(`  ${formatWindowLine("Primary", item.rate_limit?.primary_window)}`);
			if (item.rate_limit?.secondary_window) {
				lines.push(`  ${formatWindowLine("Secondary", item.rate_limit.secondary_window)}`);
			}
		}
	}

	return lines.join("\n");
}



function sanitizeStatusText(text: string): string {
	return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function formatTokens(count: number): string {
	if (count < 1000) {
		return count.toString();
	}
	if (count < 10000) {
		return `${(count / 1000).toFixed(1)}k`;
	}
	if (count < 1000000) {
		return `${Math.round(count / 1000)}k`;
	}
	if (count < 10000000) {
		return `${(count / 1000000).toFixed(1)}M`;
	}
	return `${Math.round(count / 1000000)}M`;
}

function padLeftRight(left: string, right: string, width: number, ellipsis: string): string {
	if (!right) {
		return truncateToWidth(left, width, ellipsis);
	}

	const leftWidth = visibleWidth(left);
	const rightWidth = visibleWidth(right);
	const minGap = 2;
	const total = leftWidth + minGap + rightWidth;

	if (total <= width) {
		return left + " ".repeat(width - leftWidth - rightWidth) + right;
	}

	const leftAvailable = width - minGap - rightWidth;
	if (leftAvailable > 0) {
		const leftTruncated = truncateToWidth(left, leftAvailable, ellipsis);
		const leftTruncatedWidth = visibleWidth(leftTruncated);
		return leftTruncated + " ".repeat(width - leftTruncatedWidth - rightWidth) + right;
	}

	return truncateToWidth(right, width, ellipsis);
}

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | null = null;
	let lastRefreshAt = 0;
	let refreshInFlight: Promise<void> | null = null;
	let usageInline: string | null = null;
	let footerRerender: (() => void) | null = null;

	const stopTimer = () => {
		if (timer) {
			clearInterval(timer);
			timer = null;
		}
	};

	const requestFooterRender = () => {
		footerRerender?.();
	};

	const refreshUsage = async (ctx: ExtensionContext, force: boolean = false): Promise<void> => {
		const now = Date.now();
		if (!force && now - lastRefreshAt < MIN_REFRESH_GAP_MS) {
			return;
		}

		if (ctx.model?.provider !== "openai-codex") {
			usageInline = null;
			lastRefreshAt = Date.now();
			requestFooterRender();
			return;
		}

		if (refreshInFlight) {
			if (!force) {
				return;
			}
			await refreshInFlight;
			return;
		}

		refreshInFlight = (async () => {
			const result = await fetchUsage();
			lastRefreshAt = Date.now();
			usageInline = result.ok ? compactStatus(result.payload) : null;
			requestFooterRender();
		})().finally(() => {
			refreshInFlight = null;
		});

		await refreshInFlight;
	};

	pi.registerCommand("ostatus", {
		description: "Show OpenAI Codex subscription usage from ChatGPT backend",
		handler: async (args, ctx) => {
			const result = await fetchUsage(ctx.signal);
			if (!result.ok) {
				usageInline = null;
				requestFooterRender();
				ctx.ui.notify(result.message, "error");
				return;
			}

			usageInline = compactStatus(result.payload);
			requestFooterRender();

			if (args.trim() === "json") {
				ctx.ui.notify(JSON.stringify(result.payload, null, 2), "info");
				return;
			}

			ctx.ui.notify(formatUsageReport(result.payload), "info");
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		stopTimer();
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unwatchBranch = footerData.onBranchChange(() => tui.requestRender());
			const rerender = () => tui.requestRender();
			footerRerender = rerender;

			return {
				render(width: number): string[] {
					const entries = ctx.sessionManager.getEntries();
					let totalInput = 0;
					let totalOutput = 0;
					let totalCacheRead = 0;
					let totalCacheWrite = 0;
					let totalCost = 0;

					for (const entry of entries) {
						if (entry.type === "message" && entry.message.role === "assistant") {
							totalInput += entry.message.usage.input;
							totalOutput += entry.message.usage.output;
							totalCacheRead += entry.message.usage.cacheRead;
							totalCacheWrite += entry.message.usage.cacheWrite;
							totalCost += entry.message.usage.cost.total;
						}
					}

					const contextUsage = ctx.getContextUsage();
					const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					const contextPercentValue = contextUsage?.percent ?? 0;
					const contextPercent =
						contextUsage?.percent !== undefined && contextUsage?.percent !== null
							? contextUsage.percent.toFixed(1)
							: "?";

					let cwd = ctx.sessionManager.getCwd();
					const home = process.env.HOME || process.env.USERPROFILE;
					if (home && cwd.startsWith(home)) {
						cwd = `~${cwd.slice(home.length)}`;
					}
					const sessionName = pi.getSessionName();
					if (sessionName) {
						cwd = `${cwd} | ${sessionName}`;
					}

					const showUsageRight = ctx.model?.provider === "openai-codex" && usageInline;
					const leftTop = theme.fg("dim", cwd);
					const rightTop = showUsageRight ? theme.fg("dim", usageInline) : "";
					const firstLine = padLeftRight(leftTop, rightTop, width, theme.fg("dim", "..."));

					const statsParts: string[] = [];
					if (totalInput) statsParts.push(`↑${formatTokens(totalInput)}`);
					if (totalOutput) statsParts.push(`↓${formatTokens(totalOutput)}`);
					if (totalCacheRead) statsParts.push(`R${formatTokens(totalCacheRead)}`);
					if (totalCacheWrite) statsParts.push(`W${formatTokens(totalCacheWrite)}`);
					if (totalCost) statsParts.push(`$${totalCost.toFixed(3)}`);

					const contextDisplay =
						contextPercent === "?"
							? `?/${formatTokens(contextWindow)}`
							: `${contextPercent}%/${formatTokens(contextWindow)}`;
					if (contextPercentValue > 90) {
						statsParts.push(theme.fg("error", contextDisplay));
					} else if (contextPercentValue > 70) {
						statsParts.push(theme.fg("warning", contextDisplay));
					} else {
						statsParts.push(contextDisplay);
					}

					let leftBottom = statsParts.join(" ");
					if (!leftBottom) {
						leftBottom = "0";
					}

					let rightBottom = ctx.model?.id || "no-model";
					if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
						rightBottom = `(${ctx.model.provider}) ${rightBottom}`;
					}

					const thinkingCompactMap: Record<string, string> = {
						off: "off",
						minimal: "min",
						low: "low",
						medium: "med",
						high: "hi",
						xhigh: "xhi",
					};
					const thinking = pi.getThinkingLevel();
					rightBottom = `${rightBottom} · T:${thinkingCompactMap[thinking] ?? thinking}`;

					const secondLine = padLeftRight(
						theme.fg("dim", leftBottom),
						theme.fg("dim", rightBottom),
						width,
						theme.fg("dim", "..."),
					);

					const lines = [firstLine, secondLine];
					const extensionStatuses = footerData.getExtensionStatuses();
					if (extensionStatuses.size > 0) {
						const statusLine = Array.from(extensionStatuses.entries())
							.sort(([a], [b]) => a.localeCompare(b))
							.map(([, text]) => sanitizeStatusText(text))
							.join(" ");
						lines.push(truncateToWidth(statusLine, width, theme.fg("dim", "...")));
					}

					return lines;
				},
				invalidate() {},
				dispose() {
					unwatchBranch();
					if (footerRerender === rerender) {
						footerRerender = null;
					}
				},
			};
		});

		timer = setInterval(() => {
			void refreshUsage(ctx, false);
		}, PERIODIC_REFRESH_MS);

		await refreshUsage(ctx, true);
	});

	pi.on("model_select", async (_event, ctx) => {
		await refreshUsage(ctx, true);
	});

	pi.on("turn_end", async (_event, ctx) => {
		await refreshUsage(ctx, false);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		stopTimer();
		usageInline = null;
		footerRerender = null;
		ctx.ui.setFooter(undefined);
	});
}
