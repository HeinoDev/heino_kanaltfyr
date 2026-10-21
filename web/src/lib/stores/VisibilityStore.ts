import { writable, get } from "svelte/store";
import { isEnvBrowser } from "$lib/utils/misc";
import { fetchNui } from "$lib/utils/fetchNui";

const visibility = writable(isEnvBrowser());

export const visibilityStore = {
	subscribe: visibility.subscribe,
	show: () => visibility.set(true),
	hide: () => visibility.set(false),
	toggle: (value?: boolean) =>
		visibility.update((v) => (value !== undefined ? value : !v)),
};

export type TraderItem = {
	Item: string;
	Label: string;
	Price: number;
	Time: number;
	Trend?: string;
	Hot?: boolean;
};

export type TraderData = {
	Name: string;
	Label: string;
	Currency: { Type: string; Value: string };
	Items: TraderItem[];
	RefreshIn?: number;
};

export type ConfigData = {
	ImageUrl: string;
	Currency: { Symbol: string; Position: string; Separator: string };
};

export const Trader = writable<TraderData>({
	Name: "",
	Label: "",
	Currency: { Type: "", Value: "" },
	Items: [],
});
export const Config = writable<ConfigData>({
	ImageUrl: "",
	Currency: { Symbol: "", Position: "after", Separator: "," },
});
export const Locale = writable<Record<string, string>>({});

export const Closing = writable(false);

export const CLOSE_DURATION = 150;

export function CloseTrader() {
	if (get(Closing) || !get(visibility)) return;

	Closing.set(true);
	setTimeout(() => {
		fetchNui("HideUI");
		visibilityStore.hide();
		Closing.set(false);
	}, CLOSE_DURATION);
}
