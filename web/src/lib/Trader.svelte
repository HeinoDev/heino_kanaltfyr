<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { Trader, Config, Locale, Closing, CloseTrader, type TraderItem } from "$lib/stores/VisibilityStore";
    import { fetchNui } from "$lib/utils/fetchNui";

    // Credit to AI for the Typescript and some of the html

    let SellingProgress: Record<string, number> = {};
    let Counts: Record<string, number> = {};
    let Busy = false;
    let OnlyOwned = false;
    let Destroyed = false;
    let Remaining: number | null = null;
    let Countdown: ReturnType<typeof setInterval> | undefined;

    $: TotalValue = ($Trader.Items ?? []).reduce((Sum: number, Item: TraderItem) => Sum + Item.Price * (Counts[Item.Item] ?? 0), 0);

    $: VisibleItems = ($Trader.Items ?? []).filter((Item: TraderItem) => !OnlyOwned || Counts[Item.Item]);

    onMount(() => {
        LoadCounts();

        Remaining = $Trader.RefreshIn ?? null;
        Countdown = setInterval(() => {
            if (Remaining !== null && Remaining > 0) Remaining -= 1;
        }, 1000);
    });

    onDestroy(() => {
        Destroyed = true;
        clearInterval(Countdown);
    });

    async function LoadCounts() {
        const Items = ($Trader.Items ?? []).map((Item: TraderItem) => Item.Item);
        const Result = await fetchNui('GetCounts', { Items });
        if (!Destroyed && Result) Counts = Result;
    }

    function FormatCurrency(value: number): string {
        const { Symbol, Position, Separator } = $Config.Currency;
        const formattedValue = Separator ? value.toLocaleString() : value.toString();
        const symbol = Symbol.trim();

        return Position === 'before'
            ? `${symbol} ${formattedValue}`
            : `${formattedValue} ${symbol}`;
    }

    function FormatTime(Seconds: number): string {
        const Minutes = Math.floor(Seconds / 60);
        return `${Minutes}:${String(Seconds % 60).padStart(2, '0')}`;
    }

    async function RunSale(Item: TraderItem) {
        const Data = await fetchNui('HaveItem', Item);
        if (!Data.Success || Destroyed) return;

        SellingProgress[Item.Item] = 0;
        const StartTime = Date.now();
        const Duration = Item.Time * Data.Amount;

        await new Promise<void>((resolve) => {
            const Interval = setInterval(() => {
                const Progress = ((Date.now() - StartTime) / Duration) * 100;
                SellingProgress[Item.Item] = Math.min(Progress, 100);

                if (Destroyed) {
                    clearInterval(Interval);
                    resolve();
                    return;
                }

                if (Progress >= 100) {
                    clearInterval(Interval);
                    delete SellingProgress[Item.Item];
                    fetchNui('SellItem', { Item: Item, Amount: Data.Amount, Trader: $Trader.Name }).then(() => resolve());
                }
            }, 16);
        });
    }

    async function SellItem(Item: TraderItem) {
        if (Busy || !Counts[Item.Item]) return;

        Busy = true;
        await RunSale(Item);
        Busy = false;

        if (!Destroyed) LoadCounts();
    }

    async function SellAll() {
        if (Busy || TotalValue <= 0) return;

        Busy = true;
        for (const Item of $Trader.Items) {
            if (Destroyed) break;
            await RunSale(Item);
        }
        Busy = false;

        if (!Destroyed) LoadCounts();
    }
</script>
<div class="anim-backdrop fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 select-none" class:closing={$Closing}>
    <div class="anim-window w-[560px] h-[600px] bg-[#121212] rounded-[3px] shadow-2xl flex flex-col overflow-hidden border border-[#333333]" class:closing={$Closing}>
        <header class="bg-[#1a1a1a] border-b border-[#333333] px-4 py-3 flex justify-between items-center">
            <h1 class="text-white font-medium tracking-tight">{$Trader.Label}</h1>
            <div class="flex items-center gap-2">
                {#if Remaining !== null && Remaining > 0}
                    <span class="bg-[#252525] border border-[#333333] rounded-[3px] px-2 py-0.5 text-xs text-gray-400">
                        {$Locale.PricesChangeIn} <span class="text-blue-400 tabular-nums">{FormatTime(Remaining)}</span>
                    </span>
                {/if}
                <button onclick={CloseTrader} aria-label="Close" class="text-gray-400 hover:text-white ml-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>
        </header>

        <div class="bg-[#1e1e1e] border-b border-[#333333] px-4 py-2 flex items-center justify-between text-xs">
            <div>
                <span class="text-gray-400">{$Locale.TotalValue}:</span>
                <span class="text-green-400 font-medium tabular-nums">{FormatCurrency(TotalValue)}</span>
            </div>
            <button
                onclick={() => (OnlyOwned = !OnlyOwned)}
                class="border rounded-[3px] px-2 py-1 transition-colors {OnlyOwned ? 'border-blue-500 text-blue-400 bg-[#252525]' : 'border-[#333333] text-gray-400 hover:border-blue-400'}"
            >
                {$Locale.OnlyOwned}
            </button>
        </div>

        <div class="flex-1 min-h-0 overflow-y-auto p-4 hide-scrollbar">
            {#if VisibleItems.length === 0}
                <p class="text-gray-400 text-sm text-center mt-8">{$Locale.NothingToSell}</p>
            {:else}
                <div class="grid grid-cols-3 gap-2">
                    {#each VisibleItems as Item (Item.Item)}
                        <div class="bg-[#1e1e1e] border border-[#333333] rounded-[3px] p-2 flex flex-col gap-2 relative overflow-hidden">
                            <div class="h-20 bg-[#252525] rounded-[3px] flex items-center justify-center relative">
                                {#if Item.Hot}
                                    <span class="absolute top-1 left-1 bg-[#1e1e1e] border border-[#333333] rounded-[3px] px-1.5 py-0.5 text-xs text-blue-400">{$Locale.Hot}</span>
                                {/if}
                                <img src={$Config.ImageUrl + Item.Item + '.webp'} alt={Item.Label} class="max-w-[60%] max-h-[60%] object-contain" />
                            </div>
                            <div class="flex items-center justify-between gap-2">
                                <p class="text-white text-sm font-medium truncate min-w-0">{Item.Label}</p>
                                <div class="flex items-center gap-1 flex-shrink-0">
                                    {#if Item.Trend === 'up'}
                                        <svg class="text-green-400" xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 5l8 12H4z"></path></svg>
                                    {:else if Item.Trend === 'down'}
                                        <svg class="text-red-400" xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 19L4 7h16z"></path></svg>
                                    {/if}
                                    <p class="text-green-400 text-xs font-medium tabular-nums">{FormatCurrency(Item.Price)}</p>
                                </div>
                            </div>
                            <div class="flex items-center justify-between gap-2">
                                <span class="text-xs tabular-nums {Counts[Item.Item] ? 'text-blue-400' : 'text-gray-500'}">x{Counts[Item.Item] ?? 0}</span>
                                <button
                                    onclick={() => SellItem(Item)}
                                    disabled={Busy || !Counts[Item.Item]}
                                    class="bg-blue-500 hover:bg-blue-400 text-white px-3 py-1 rounded-[3px] text-xs font-medium transition-colors disabled:opacity-40 disabled:hover:bg-blue-500 disabled:cursor-not-allowed"
                                >
                                    {$Locale.Sell}
                                </button>
                            </div>
                            {#if SellingProgress[Item.Item] !== undefined}
                                <div class="absolute bottom-0 left-0 w-full h-1 bg-[#333333]">
                                    <div class="bg-blue-500 h-1" style="width: {SellingProgress[Item.Item]}%"></div>
                                </div>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>

        <div class="bg-[#1e1e1e] px-4 py-3 border-t border-[#333333]">
            <button
                onclick={SellAll}
                disabled={Busy || TotalValue <= 0}
                class="w-full bg-blue-500 hover:bg-blue-400 text-white py-2 rounded-[3px] text-sm font-medium transition-colors disabled:opacity-40 disabled:hover:bg-blue-500 disabled:cursor-not-allowed"
            >
                {$Locale.SellEverything}
            </button>
        </div>
    </div>
</div>

<style>
    .hide-scrollbar::-webkit-scrollbar {
        display: none;
    }

    .hide-scrollbar {
        -ms-overflow-style: none;
        scrollbar-width: none;
    }

    .percentage-text {
        transition: all 0.5s ease-out;
    }

    * {
        user-select: none;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
    }
</style>
