<script lang="ts">
    import { accounts, activeAccount, currentView, atm, translations, invoiceAdmin } from '../store/stores';
    const text = (key: string) => $translations?.[key] ?? key;
    const entries = [
        {id:'transactions', icon:'fa-clock-rotate-left'},
        {id:'deposit', icon:'fa-circle-plus'},
        {id:'withdraw', icon:'fa-circle-minus'},
        {id:'transfer', icon:'fa-paper-plane'},
        {id:'invoices', icon:'fa-file-invoice-dollar'},
        {id:'accounts', icon:'fa-building-columns'},
        {id:'invoice-settings', icon:'fa-sliders', admin:true},
    ];
    $: selectedAccount = $accounts.find((account) => account.id === $activeAccount);
    const allowed = (entry:any) => {
        if (!selectedAccount || !selectedAccount.access) return true;
        if (entry.id === 'withdraw') return selectedAccount.access.withdraw;
        if (entry.id === 'transfer') return selectedAccount.access.transfer;
        if (entry.id === 'invoices') return selectedAccount.owner || selectedAccount.access.payInvoices;
        return true;
    };
</script>

<aside class="sidebar">
    <div class="account-picker">
        <span class="account-label">{text('selected_account')}</span>
        <div class="selected-account">
            <i class="fa-solid fa-building-columns"></i>
            <div><strong>{selectedAccount?.name || text('personal_account')}</strong><span>#{selectedAccount?.id || $activeAccount}</span></div>
        </div>
    </div>
    <nav>
        {#each entries as entry}
            {#if allowed(entry) && (!entry.admin || $invoiceAdmin.canManage) && !($atm && (entry.id === 'deposit' || entry.id === 'accounts' || entry.admin))}
                <button class:active={$currentView === entry.id} on:click={() => currentView.set(entry.id)}>
                    <i class={`fa-solid ${entry.icon}`}></i><span>{text('nav_' + entry.id)}</span>
                </button>
            {/if}
        {/each}
    </nav>
</aside>

<style>
    .sidebar{flex:0 0 270px;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:12px;padding:1.25rem;display:flex;flex-direction:column;gap:1.25rem;box-shadow:inset 0 1px rgba(255,255,255,.035)}
    .account-picker{display:flex;flex-direction:column;gap:.55rem;padding-bottom:1rem;border-bottom:1px solid var(--clr-border)}
    .account-label{font-size:.72rem;text-transform:uppercase;color:var(--clr-text-muted);font-weight:700;letter-spacing:.06em}
    .selected-account{width:100%;box-sizing:border-box;background:var(--clr-primary-dark);border:1px solid var(--clr-border);border-radius:10px;color:var(--clr-text-bright);padding:.8rem .9rem;display:flex;align-items:center;gap:.75rem}
    .selected-account>i{color:var(--clr-green)}
    .selected-account div{min-width:0;display:flex;flex-direction:column;gap:.15rem}.selected-account strong{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.selected-account span{font-size:.72rem;color:var(--clr-text-muted)}
    nav{display:flex;flex-direction:column;gap:.45rem}
    button{border:1px solid transparent;background:transparent;color:var(--clr-text);border-radius:11px;padding:.9rem 1rem;display:flex;align-items:center;gap:.85rem;text-align:left;cursor:pointer;font-weight:600}
    button:hover{background:var(--clr-primary-light);color:var(--clr-text-bright)}
    button.active{background:color-mix(in srgb,var(--clr-green) 15%,transparent);border-color:var(--clr-green);color:var(--clr-green)}
    i{width:18px;text-align:center}
</style>
