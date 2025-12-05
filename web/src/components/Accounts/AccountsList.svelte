<script lang="ts">
    import { accounts, translations } from "../../store/stores";
    import AccountListItem from "./AccountListItem.svelte";

    const FILTERS = ["all", "personal", "business", "organization"] as const;
    let accSearch = "";
    let activeFilter: typeof FILTERS[number] = "all";

    const normalizeCategory = (account: any) => account?.category ?? "organization";

    const matchesSearch = (account: any, searchTerm: string) => {
        if (!searchTerm) return true;
        const lowered = searchTerm.toLowerCase();
        const nameMatch = (account?.name ?? "").toLowerCase().includes(lowered);
        const idMatch = (account?.id ?? "").toLowerCase().includes(lowered);
        return nameMatch || idMatch;
    };

    $: filteredAccounts = $accounts.filter((account: any) => {
        const category = normalizeCategory(account);
        const typePass = activeFilter === "all" ? true : category === activeFilter;
        return typePass && matchesSearch(account, accSearch);
    });
</script>

<aside>
    <h3 class="heading">{$translations.accounts}</h3>
    <div class="filters">
        {#each FILTERS as filterKey}
            <button
                type="button"
                class:selected={activeFilter === filterKey}
                on:click={() => activeFilter = filterKey}>
                {#if filterKey === "all"}
                    {$translations.accounts}
                {:else if filterKey === "personal"}
                    {$translations.personal}
                {:else if filterKey === "business"}
                    {$translations.business}
                {:else}
                    {$translations.org}
                {/if}
            </button>
        {/each}
    </div>
    <input type="text" class="acc-search" placeholder={$translations.account_search} bind:value={accSearch} />
    <section class="scroller">
        {#if filteredAccounts.length > 0}
            {#each filteredAccounts as account (account.id)}
                <AccountListItem {account} />
            {/each}
        {:else}
            <h3 style="text-align: left; color: #F3F4F5; margin-top: 1rem;">{$translations.account_not_found}</h3>
        {/if}
    </section>
</aside>

<style>
    aside {
        flex: 0 0 25%;
        padding-left: 1rem;
        padding-top: 0.4rem;
    }
    .filters {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 0.75rem;
        flex-wrap: wrap;
    }
    .filters button {
        background-color: #2a333b;
        color: #fff;
        border: none;
        border-radius: 5px;
        padding: 0.5rem 0.75rem;
        cursor: pointer;
        font-size: 0.85rem;
        transition: background-color 0.15s ease;
    }
    .filters button.selected {
        background-color: #3ecf8e;
        color: #121417;
    }
    .acc-search {
        width: 100%;
        border-radius: 5px;
        border: none;
        padding: 1.4rem;
        margin-bottom: 1rem;
        background-color: var(--clr-primary-light);
        color: #fff;
    }
</style>
