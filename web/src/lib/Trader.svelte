<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { Trader, Config, Locale, Closing, CloseTrader, type TraderItem } from "$lib/stores/VisibilityStore";
    import { fetchNui } from "$lib/utils/fetchNui";

    // Credit to AI for the Typescript and some of the html

    let SellingItem: string | undefined;
    let SellingProgress = 0;
    let Counts: Record<string, number> = {};
    let Busy = false;
    let OnlyOwned = false;
    let Destroyed = false;
    let Remaining: number | null = null;
    let Countdown: ReturnType<typeof setInterval> | undefined;
    let SaleProgressTimer: ReturnType<typeof setInterval> | undefined;

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
        clearInterval(SaleProgressTimer);
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
        const Data = await fetchNui<{ Success: boolean; Amount: number }>('HaveItem', Item);
        if (!Data.Success || Destroyed || $Closing) return;

        SellingItem = Item.Item;
        SellingProgress = 0;
        const StartTime = performance.now();
        const Duration = Math.max(1, Item.Time * Data.Amount);
        SaleProgressTimer = setInterval(() => {
            SellingProgress = Math.min(100, ((performance.now() - StartTime) / Duration) * 100);
        }, 16);

        try {
            await fetchNui('SellItem', { Item, Amount: Data.Amount, Trader: $Trader.Name });
        } finally {
            clearInterval(SaleProgressTimer);
            SellingItem = undefined;
        }
    }

    async function SellItem(Item: TraderItem) {
        if (Busy || !Counts[Item.Item]) return;

        Busy = true;
        try {
            await RunSale(Item);
        } finally {
            Busy = false;
            if (!Destroyed && !$Closing) LoadCounts();
        }
    }

    async function SellAll() {
        if (Busy || TotalValue <= 0) return;

        Busy = true;
        try {
            for (const Item of $Trader.Items) {
                if (Destroyed || $Closing) break;
                await RunSale(Item);
            }
        } finally {
            Busy = false;
            if (!Destroyed && !$Closing) LoadCounts();
        }
    }
</script>
<div class="anim-backdrop fixed inset-0 flex items-center justify-center bg-black/[.28] p-5 select-none" class:closing={$Closing}>
    <div class="anim-window trader-window w-full max-w-[560px] h-full max-h-[600px] flex flex-col overflow-hidden" class:closing={$Closing}>
        <header class="trader-header min-h-[55px] shrink-0 border-b border-[var(--border)] px-4 flex justify-between items-center gap-2">
            <h1 class="text-base font-[650] truncate">{$Trader.Label}</h1>
            <div class="flex shrink-0 items-center gap-2">
                {#if Remaining !== null && Remaining > 0}
                    <span class="bg-[#252525] border border-[var(--border)] rounded-[3px] px-2 py-0.5 text-xs text-[var(--muted)]">
                        {$Locale.PricesChangeIn} <span class="text-[var(--blue)] tabular-nums">{FormatTime(Remaining)}</span>
                    </span>
                {/if}
                <button onclick={CloseTrader} aria-label="Close" class="trader-close grid h-8 w-8 place-items-center rounded-[3px] transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>
        </header>

        <div class="trader-field border-b border-[var(--border)] px-4 py-2 flex items-center justify-between text-xs">
            <div>
                <span class="text-[var(--muted)]">{$Locale.TotalValue}:</span>
                <span class="text-[var(--green)] font-medium tabular-nums">{FormatCurrency(TotalValue)}</span>
            </div>
            <button
                onclick={() => (OnlyOwned = !OnlyOwned)}
                aria-pressed={OnlyOwned}
                class="trader-filter border border-[var(--border)] rounded-[3px] px-2 py-1 text-[var(--muted)] transition-colors hover:border-[var(--blue)]"
            >
                {$Locale.OnlyOwned}
            </button>
        </div>

        <div class="trader-items flex-1 min-h-0 overflow-y-auto p-4">
            {#if VisibleItems.length === 0}
                <p class="text-[var(--muted)] text-sm text-center mt-8">{$Locale.NothingToSell}</p>
            {:else}
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                    {#each VisibleItems as Item (Item.Item)}
                        <div class="trader-field border border-[var(--border)] rounded-[3px] p-2 flex flex-col gap-2 relative overflow-hidden">
                            <div class="h-20 bg-[#252525] rounded-[3px] flex items-center justify-center relative">
                                {#if Item.Hot}
                                    <span class="absolute top-1 left-1 trader-field border border-[var(--border)] rounded-[3px] px-1.5 py-0.5 text-xs text-[var(--blue)]">{$Locale.Hot}</span>
                                {/if}
                                {#if $Config.ImageUrl}
                                    <img
                                        src={$Config.ImageUrl + Item.Item + '.webp'}
                                        alt={Item.Label}
                                        onerror={(event) => {
                                            const image = event.currentTarget;
                                            if (image instanceof HTMLImageElement && image.src.endsWith('.webp')) {
                                                image.src = $Config.ImageUrl + Item.Item + '.png';
                                            }
                                        }}
                                        class="max-w-[60%] max-h-[60%] object-contain"
                                    />
                                {/if}
                            </div>
                            <div class="flex items-center justify-between gap-2">
                                <p class="text-[var(--ink)] text-sm font-medium truncate min-w-0">{Item.Label}</p>
                                <div class="flex items-center gap-1 flex-shrink-0">
                                    {#if Item.Trend === 'up'}
                                        <svg class="text-[var(--green)]" xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 5l8 12H4z"></path></svg>
                                    {:else if Item.Trend === 'down'}
                                        <svg class="text-[var(--red)]" xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 19L4 7h16z"></path></svg>
                                    {/if}
                                    <p class="{Item.Trend === 'down' ? 'text-[var(--red)]' : 'text-[var(--green)]'} text-xs font-medium tabular-nums">{FormatCurrency(Item.Price)}</p>
                                </div>
                            </div>
                            <div class="flex items-center justify-between gap-2">
                                <span class="text-xs tabular-nums {Counts[Item.Item] ? 'text-[var(--blue)]' : 'text-[var(--muted)]'}">x{Counts[Item.Item] ?? 0}</span>
                                <button
                                    onclick={() => SellItem(Item)}
                                    disabled={Busy || !Counts[Item.Item]}
                                    class="trader-action px-3 py-1 rounded-[3px] text-xs font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                                >
                                    {$Locale.Sell}
                                </button>
                            </div>
                            {#if SellingItem === Item.Item}
                                <div class="absolute bottom-0 left-0 w-full h-1 bg-[var(--border)]">
                                    <div class="bg-[var(--primary)] h-1" style="width: {SellingProgress}%"></div>
                                </div>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>

        <div class="trader-field px-4 py-3 border-t border-[var(--border)]">
            <button
                onclick={SellAll}
                disabled={Busy || TotalValue <= 0}
                class="w-full trader-action py-2 rounded-[3px] text-sm font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
                {$Locale.SellEverything}
            </button>
        </div>
    </div>
</div>
