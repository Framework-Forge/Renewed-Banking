import { writable } from "svelte/store";

export const visibility = writable(false);
export const loading = writable(false);
export const notify = writable("");
export let activeAccount = writable<string | null>(null);
export const atm = writable(false);
export const currency = writable("USD");
export const uiLocale = writable('en');
export const currentView = writable("transactions");
export const invoices = writable<any[]>([]);
export const invoiceAdmin = writable<any>({canManage:false, settings:{}});

export let popupDetails = writable<{account: any; actionType: string}>({
    account: {},
    actionType: "",
});

export const theme = writable({
    primary: '#ff7a1a',
    primaryDark: '#ff8c2a',
    primaryText: '#ffffff',
    background: '#0a0a0c',
    surface: '#121214',
    card: '#18181c',
    border: '#2d2d35',
    text: '#ffffff',
    textMuted: '#8e8e9f'
});

export const bankName = writable('RENEWED');
export const bankSubtitle = writable('');
export const bankLogo = writable('img/bank.png');
export const overviewTitle = writable('');
export const overviewSubtitle = writable('');
export const uiOpacity = writable(0.98);

export function applyAppearance(settings: any = {}) {
    if (settings.bankName) bankName.set(settings.bankName);
    if (settings.bankSubtitle) bankSubtitle.set(settings.bankSubtitle);
    if (typeof settings.logoUrl === 'string') bankLogo.set(settings.logoUrl);
    if (typeof settings.overviewTitle === 'string') overviewTitle.set(settings.overviewTitle);
    if (typeof settings.overviewSubtitle === 'string') overviewSubtitle.set(settings.overviewSubtitle);
    if (Number.isFinite(Number(settings.uiOpacity))) uiOpacity.set(Number(settings.uiOpacity));
    theme.update(current => ({
        ...current,
        primary: settings.primaryColor || current.primary,
        primaryDark: settings.primaryHoverColor || current.primaryDark,
        primaryText: settings.accentTextColor || current.primaryText,
        background: settings.backgroundColor || current.background,
        surface: settings.surfaceColor || current.surface,
        card: settings.cardColor || current.card,
        border: settings.borderColor || current.border,
        text: settings.textColor || current.text,
        textMuted: settings.mutedTextColor || current.textMuted
    }));
}

export const accounts = writable<any[]>([

]);

export const translations = writable<Record<string, string>>({});
