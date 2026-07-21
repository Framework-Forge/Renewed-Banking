<script lang="ts">
    import AccountsList from "./Accounts/AccountsList.svelte";
    import AccountTransactionsList from "./Accounts/AccountTransactionsList.svelte";
    import { accounts } from '../store/stores';
    import { formatMoney } from "../utils/misc";
</script>

<div class="main">
    <section>
        <AccountsList />
        <AccountTransactionsList />
    </section>
    <h5><i class="fa-solid fa-wallet fa-fw"></i>{formatMoney($accounts[0].cash)}</h5>
</div>

<style>
    .main {
        overflow: hidden;
        width: 90%;
        height: 90%;
        bottom: 5%;
        left: 5%;
        padding: 1.6rem;
        position: absolute;
        background-color: var(--surface-1);
        border-radius: var(--radius);
        border: 1px solid var(--border);
        box-shadow: 0 0 0 1px rgba(255,255,255,0.03),
                    0 25px 50px -12px rgba(0,0,0,0.60);
        animation: fadeSlideUp 0.25s ease both;
    }

    section {
        display: flex;
        gap: 2.4rem;
        height: calc(100% - 3.2rem);
    }

    h5 {
        font-family: var(--font-heading);
        font-size: 1.3rem;
        font-weight: 600;
        color: var(--brand-bright);
        display: flex;
        align-items: center;
        gap: 0.6rem;
        margin-top: 0.8rem;
        padding-top: 0.8rem;
        border-top: 1px solid var(--border);
    }

    h5 i {
        color: var(--brand-bright);
        font-size: 1.2rem;
    }
</style>
