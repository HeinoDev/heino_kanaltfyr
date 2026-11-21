import { isEnvBrowser } from "./misc";

export async function fetchNui<T = any>(eventName: string, data?: any): Promise<T> {
	if (import.meta.env.DEV && isEnvBrowser()) {
		const { mockNui } = await import("./debugData");
		return (await mockNui(eventName, data)) as T;
	}

	const options = {
		method: "post",
		headers: {
			"Content-Type": "application/json; charset=UTF-8",
		},
		body: JSON.stringify(data),
	};

	// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
	const resourceName = (window as any).GetParentResourceName
		? // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-call
			(window as any).GetParentResourceName()
		: "nui-frame-app";

	const resp = await fetch(`https://${resourceName}/${eventName}`, options);

	// eslint-disable-next-line @typescript-eslint/no-unsafe-return
	return await resp.json();
}
