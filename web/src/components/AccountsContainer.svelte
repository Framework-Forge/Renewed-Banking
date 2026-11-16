<script lang="ts">
    import AccountTransactionsList from "./Accounts/AccountTransactionsList.svelte";
    import AccountsList from "./Accounts/AccountsList.svelte";
    import BankingSidebar from "./BankingSidebar.svelte";
    import BankingActionPanel from "./BankingActionPanel.svelte";
    import InvoicesPanel from "./InvoicesPanel.svelte";
    import InvoiceSettingsPanel from "./InvoiceSettingsPanel.svelte";
    import AccountDependentsPanel from "./Accounts/AccountDependentsPanel.svelte";
    import { accounts, bankName, bankSubtitle, bankLogo, overviewTitle, overviewSubtitle, translations, currentView } from "../store/stores";
    import { formatMoney } from "../utils/misc";
    let logoFailed = false;
    $: if ($bankLogo) logoFailed = false;
</script>

<div class="bank-wrapper">
    <header class="top-bar">
        <div class="brand">
            <div class="brand-icon">
                {#if $bankLogo && !logoFailed}
                    <img src={$bankLogo} alt={$bankName} on:error={() => logoFailed = true} />
                {:else}
                    <i class="fa-solid fa-shield-halved"></i>
                {/if}
            </div>
            <div class="brand-text">
                <h1>{$bankName}</h1>
                <span>{$bankSubtitle || $translations.bank_default_subtitle}</span>
            </div>
        </div>

        <div class="top-bar-title">
            <h2>{$overviewTitle || $translations.overview_title}</h2>
            <span>{$overviewSubtitle || $translations.overview_subtitle}</span>
        </div>

        <div class="header-stats">
            <div class="wallet-stat">
                <div class="stat-label">
                    <i class="fa-solid fa-wallet"></i>
                    <span>{$translations.cash_on_hand}</span>
                </div>
                <div class="stat-value">{formatMoney($accounts.length ? $accounts[0].cash : 0)}</div>
            </div>
        </div>
    </header>

    <main class="main-content">
        <section class="dashboard-grid">
            <BankingSidebar />
            <div class="workspace">
                {#if $currentView === 'transactions'}
                    <AccountTransactionsList />
                {:else if $currentView === 'invoices'}
                    <InvoicesPanel />
                {:else if $currentView === 'accounts'}
                    <div class="accounts-management"><AccountsList /><AccountDependentsPanel /></div>
                {:else if $currentView === 'invoice-settings'}
                    <InvoiceSettingsPanel />
                {:else}
                    <BankingActionPanel action={$currentView} />
                {/if}
            </div>
        </section>
    </main>
</div>

<style>
    .bank-wrapper {
        position: fixed;
        left: 50%;
        top: 50%;
        transform: translate(-50%, -50%);
        width: min(1480px, 94vw);
        height: min(880px, 90vh);
        background: var(--clr-primary-dark);
        border-radius: 14px;
        border: 1px solid color-mix(in srgb, var(--clr-green) 28%, var(--clr-border));
        display: flex;
        flex-direction: column;
        overflow: hidden;
        font-family: var(--font-family);
        color: var(--clr-text);
        box-shadow: 0 28px 80px rgba(0,0,0,.72),0 0 0 1px color-mix(in srgb,var(--clr-green) 8%,transparent),inset 0 1px rgba(255,255,255,.05);
        opacity: var(--ui-opacity, .98);
        animation: forge-bank-in .24s cubic-bezier(.1,.8,.25,1);
    }

    .top-bar {
        padding: 1.25rem 2rem;
        background: var(--clr-primary);
        border-bottom: 1px solid var(--clr-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .brand {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .brand-icon {
        width: 46px;
        height: 46px;
        background: color-mix(in srgb,var(--clr-green) 12%,var(--clr-primary-dark));
        color: var(--clr-accent-text);
        border-radius: 9px;
        border:1px solid color-mix(in srgb,var(--clr-green) 42%,transparent);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
    }
    .brand-icon img{width:100%;height:100%;object-fit:contain;padding:5px;filter:drop-shadow(0 4px 8px rgba(0,0,0,.45))}

    .brand-text h1 {
        font-size: 1.1rem;
        font-weight: 800;
        margin: 0;
        color: var(--clr-text-bright);
        letter-spacing: 0.5px;
    }

    .brand-text span {
        font-size: 0.7rem;
        color: var(--clr-text-muted);
        text-transform: uppercase;
    }

    .top-bar-title {
        text-align: center;
    }

    .top-bar-title h2 {
        font-size: 1.4rem;
        font-weight: 700;
        color: var(--clr-text-bright);
        margin: 0;
    }

    .top-bar-title span {
        font-size: 0.85rem;
        color: var(--clr-text-muted);
    }

    .header-stats {
        display: flex;
        align-items: center;
        gap: 2rem;
    }

    .wallet-stat {
        text-align: right;
    }

    .stat-label {
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 0.5rem;
        color: var(--clr-text-muted);
        font-size: 0.75rem;
        margin-bottom: 0.25rem;
    }

    .stat-value {
        font-size: 1.25rem;
        font-weight: 700;
        color: var(--clr-green);
    }

    .main-content {
        flex: 1;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .dashboard-grid {
        flex: 1;
        display: flex;
        gap: 2rem;
        padding: 2rem;
        overflow: hidden;
    }

    .workspace {
        flex: 1;
        min-width: 0;
        height: 100%;
        display: flex;
    }
    .accounts-management{display:flex;gap:1.5rem;flex:1;min-width:0;height:100%}
    @keyframes forge-bank-in{from{opacity:0;transform:translate(-50%,-48%) scale(.97)}to{opacity:var(--ui-opacity,.98);transform:translate(-50%,-50%) scale(1)}}
</style>
