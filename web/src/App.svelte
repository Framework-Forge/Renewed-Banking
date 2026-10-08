<script lang="ts">
    import VisibilityProvider from "./providers/VisibilityProvider.svelte";
    import { debugData } from "./utils/debugData";
    import AccountsContainer from "./components/AccountsContainer.svelte";
    import Loading from "./components/Loading.svelte";
    import Notification from "./components/Notification.svelte";
    import { loading, notify, theme, uiOpacity } from "./store/stores";

    debugData([
        {
            action: "setVisible",
            data: true,
        },
    ]);

    $: {
        if ($theme) {
            const root = document.documentElement;
            root.style.setProperty('--clr-green', $theme.primary);
            root.style.setProperty('--clr-orange', $theme.primaryDark);
            root.style.setProperty('--clr-accent-text', $theme.primaryText);
            root.style.setProperty('--clr-primary-dark', $theme.background);
            root.style.setProperty('--clr-primary', $theme.surface);
            root.style.setProperty('--clr-primary-light', $theme.card);
            root.style.setProperty('--clr-border', $theme.border);
            root.style.setProperty('--clr-text', $theme.text);
            root.style.setProperty('--clr-text-bright', $theme.text);
            root.style.setProperty('--clr-text-muted', $theme.textMuted);
            root.style.setProperty('--clr-accent-glow', $theme.primary + '40');
            root.style.setProperty('--ui-opacity', String($uiOpacity));
        }
    }
</script>

<svelte:head>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.2/css/all.min.css" integrity="sha512-1sCRPdkRXhBV2PBLUdRb4tMg1w2YPf37qatUFeS7zlBy7jJI8Lf4VHwWfZZfpXtYSLy85pkm9GaYVYMfw5BC1A==" crossorigin="anonymous" referrerpolicy="no-referrer" />
</svelte:head>
<VisibilityProvider>
    <AccountsContainer />
    {#if $notify !== ""}
        <Notification />
    {/if}
</VisibilityProvider>
{#if $loading}
    <Loading />
{/if}
