<script lang="ts">
	import { onMount } from "svelte";
	import { visibilityStore as visibility, Trader, Config, Locale, CloseTrader, type TraderData } from "$lib/stores/VisibilityStore";
	import { useNuiEvent } from "$lib/hooks/useNuiEvent";
	
	onMount(() => {
		const keyHandler = (e: KeyboardEvent) => {
			if ($visibility && e.code === "Escape") {
				CloseTrader();
			}
		};

		window.addEventListener("keydown", keyHandler);
		return () => window.removeEventListener("keydown", keyHandler);
	});

	useNuiEvent("OpenTrader", (Data: TraderData) => {
		visibility.show();
		Trader.set(Data)
	});

	useNuiEvent("InitializeConfig", (Data: { Config: any; Locale: any }) => {
		Config.set(Data.Config)
		Locale.set(Data.Locale)
	});

	useNuiEvent("HideUI", () => {
		CloseTrader();
	});
</script>

{#if $visibility}
	<slot />
{/if}
