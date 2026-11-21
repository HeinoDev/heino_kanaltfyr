import locale from "../../../../locales/da.json";
import type { ConfigData, TraderData, TraderItem } from "../stores/VisibilityStore";

const counts: Record<string, number> = {
	gold_watch: 3,
	gold_necklace: 2,
	diamond_ring: 1,
	emerald_earrings: 0,
	amethyst_necklace: 4,
	diamond_bracelet: 0,
};

const trader: TraderData = {
	Name: "debug",
	Label: "Kanaltfyren",
	Currency: { Type: "item", Value: "cash" },
	RefreshIn: 120,
	Items: [
		{ Item: "gold_watch", Label: "Guldur", Price: 850, Time: 350, Trend: "up", Hot: true },
		{ Item: "gold_necklace", Label: "Guldhalskæde", Price: 570, Time: 400 },
		{ Item: "diamond_ring", Label: "Diamantring", Price: 1_250, Time: 700, Trend: "up" },
		{ Item: "emerald_earrings", Label: "Smaragdøreringe", Price: 710, Time: 500, Trend: "down" },
		{ Item: "amethyst_necklace", Label: "Ametysthalskæde", Price: 430, Time: 300, Trend: "down" },
		{ Item: "diamond_bracelet", Label: "Diamantarmbånd", Price: 1_480, Time: 700 },
	],
};

export function showDebugTrader() {
	const config: ConfigData = {
		ImageUrl: "",
		Currency: { Symbol: "kr.", Position: "after", Separator: "," },
	};

	document.body.style.background = 'center / cover no-repeat fixed #181818 url("./background/day.png")';
	window.postMessage({ action: "InitializeConfig", data: { Config: config, Locale: locale } }, window.location.origin);
	window.postMessage({ action: "OpenTrader", data: trader }, window.location.origin);
}

export async function mockNui(event: string, data?: { Item: string | TraderItem; Amount?: number }) {
	switch (event) {
		case "GetCounts":
			return { ...counts };
		case "HaveItem": {
			const amount = typeof data?.Item === "string" ? counts[data.Item] ?? 0 : 0;
			return { Success: amount > 0, Amount: amount };
		}
		case "SellItem": {
			const item = data?.Item;
			const amount = data?.Amount;
			if (!item || typeof item === "string" || !amount) return { Success: false };
			await new Promise((resolve) => setTimeout(resolve, item.Time * amount));
			counts[item.Item] = Math.max(0, (counts[item.Item] ?? 0) - amount);
			return { Success: true };
		}
	}
}
