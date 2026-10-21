<script lang="ts">
	import Trader from "$lib/Trader.svelte";
	import VisibilityProvider from "$lib/providers/VisibilityProvider.svelte";
</script>

<VisibilityProvider>
	<Trader />
</VisibilityProvider>
