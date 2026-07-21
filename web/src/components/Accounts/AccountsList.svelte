<script lang="ts">
    import { accounts, translations } from "../../store/stores";
    import AccountListItem from "./AccountListItem.svelte";
    let accSearch = "";
</script>

<aside>
    <h3 class="heading">{$translations.accounts}</h3>
    <input type="text" class="acc-search" placeholder={$translations.account_search} bind:value={accSearch} />
    <section class="scroller">
        {#if $accounts.filter(item => item.name.toLowerCase().includes(accSearch.toLowerCase())).length > 0}
            {#each $accounts.filter(item => item.name.toLowerCase().includes(accSearch.toLowerCase())) as account (account.id)}
                <AccountListItem {account} />
            {/each}
        {:else}
            <h3 style="text-align: left; color: #F3F4F5; margin-top: 1rem;">{$translations.account_not_found}</h3>
        {/if}
    </section>
</aside>

<style>
    aside {
        flex: 0 0 27%;
        padding-left: 0.4rem;
        padding-top: 0.4rem;
        display: flex;
        flex-direction: column;
        border-right: 1px solid var(--border);
        padding-right: 2rem;
    }

    .acc-search {
        width: 100%;
        border-radius: 8px;
        border: 1px solid var(--border);
        padding: 1.1rem 1.4rem;
        margin-bottom: 1.2rem;
        background-color: var(--surface-3);
        color: var(--text);
        font-family: var(--font-family);
        font-size: 1.2rem;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    .acc-search::placeholder {
        color: var(--text-muted);
    }
    .acc-search:focus {
        border-color: var(--border-active);
        box-shadow: 0 0 0 3px var(--glow);
    }
</style>
