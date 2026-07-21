<script lang="ts">
    import { accounts, activeAccount, popupDetails, atm, translations } from "../../store/stores";
    import { formatMoney } from "../../utils/misc";
    export let account:any;

    function handleAccountClick(id: any) {
        activeAccount.update(() => id);
    };

    let isAtm: boolean;
    function handleButton(id:string, type:string) {
        let account = $accounts.find((accountItem: any) => id === accountItem.id);
        popupDetails.update(() => ({ actionType: type, account }));
    }

    atm.subscribe((usingAtm: boolean) => {
        isAtm = usingAtm;
    });
</script>

<section class="account" on:click={()=>handleAccountClick(account.id)} on:keydown={()=>{}}>
    <h4>
        {account.type}{$translations.account}/ {account.id}
    </h4>
    <h5>
        {account.type}{$translations.account}<br />
        <span>{account.name}</span>
    </h5>

    <div class="price">
        <strong>{formatMoney(account.amount)}</strong> <br />
        <span>{$translations.balance}</span>
    </div>

    <div class="btns-group">
        {#if !account.isFrozen}
            {#if !isAtm}
                <button class="btn btn-green" on:click={() => handleButton(account.id, "deposit")}>{$translations.deposit_but}</button>
            {/if}
            <button class="btn btn-orange" on:click={() => handleButton(account.id, "withdraw")}>{$translations.withdraw_but}</button>
            <button class="btn btn-grey" on:click={() => handleButton(account.id, "transfer")}>{$translations.transfer_but}</button>
        {:else}
            {$translations.frozen}
        {/if}
    </div>
</section>

<style>
    .account {
        background-color: var(--surface-2);
        padding: 1.2rem 1.4rem;
        border-radius: var(--radius-sm);
        border: 1px solid var(--border);
        cursor: pointer;
        transition: border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;
    }
    .account:not(:last-child) {
        margin-bottom: 1rem;
    }
    .account:hover {
        border-color: var(--border-active);
        box-shadow: 0 0 0 3px var(--glow);
        background-color: var(--surface-3);
    }

    h4 {
        font-family: var(--font-heading);
        font-size: 1rem;
        font-weight: 500;
        color: var(--text-muted);
        letter-spacing: 0.06em;
        text-transform: uppercase;
        margin-bottom: 0.5rem;
    }
    h5 {
        font-family: var(--font-heading);
        font-size: 1.3rem;
        font-weight: 600;
        color: var(--text);
        margin-bottom: 1rem;
        line-height: 1.4;
    }
    h5 span {
        font-family: var(--font-family);
        font-size: 1.1rem;
        font-weight: 400;
        color: var(--text-sec);
        display: block;
        margin-top: 0.2rem;
    }

    .price {
        text-align: right;
        margin-bottom: 1.2rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--border);
    }
    .price strong {
        font-family: var(--font-heading);
        font-size: 1.9rem;
        font-weight: 700;
        color: var(--brand-bright);
        letter-spacing: -0.02em;
        display: block;
    }
    .price span {
        font-size: 1rem;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    /* make first btn in btn-group take up the whole first row */
    .btns-group > :first-child {
        grid-column: 1 / -1;
    }
    .btns-group {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 0.6rem;
    }
</style>
