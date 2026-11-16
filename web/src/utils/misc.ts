import { currency, uiLocale } from "../store/stores";

export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

let activeCurrency: string;
let activeLocale: string;
uiLocale.subscribe((value: string) => { activeLocale = value; });

currency.subscribe((value: string) => {
    activeCurrency = value;
});

export function formatMoney(number: number) {
    return number.toLocaleString(activeLocale, { style: 'currency', currency: activeCurrency });
}
