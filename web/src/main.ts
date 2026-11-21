import { mount } from "svelte";
import "./app.css";
import App from "./App.svelte";
import { isEnvBrowser } from "$lib/utils/misc";

const app = mount(App, {
	target: document.getElementById("app")!,
});

if (import.meta.env.DEV && isEnvBrowser()) {
	void import("$lib/utils/debugData").then(({ showDebugTrader }) => showDebugTrader());
}

export default app;
