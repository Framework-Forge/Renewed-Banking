<script lang="ts">
  import { fetchNui } from '../utils/fetchNui';
  import { onMount } from 'svelte';
  import { 
    visibility,
    accounts,
    activeAccount,
    loading,
    notify,
    popupDetails,
    atm,
    translations,
    currency,
    uiLocale,
    theme,
    bankName,
    bankSubtitle,
    applyAppearance,
    currentView,
    invoices,
    invoiceAdmin
  } from '../store/stores';
  import { useNuiEvent } from '../utils/useNuiEvent';
  let isVisible: boolean;

  visibility.subscribe(visible => {
    isVisible = visible;
  });

  useNuiEvent<any>('setVisible', data => {
    accounts.set(data.accounts);
    activeAccount.update(() => data.accounts[0].id)
    currentView.set('transactions');
    fetchNui<any>('getInvoices', {accountId:data.accounts[0].id}).then(data => {
      invoices.set(Array.isArray(data) ? data : (data && data.entries) || []);
      invoiceAdmin.set({canManage:!!(data && data.canManage),settings:(data && data.settings)||{}});
      if (data && data.settings) applyAppearance(data.settings);
    });
    visibility.set(data.status);
    loading.set(data.loading);
    atm.set(data.atm);
    if (data.theme) theme.set(data.theme);
    if (data.bankName) bankName.set(data.bankName);
    if (data.bankSubtitle) bankSubtitle.set(data.bankSubtitle);
    if (data.appearance) applyAppearance({...data.appearance, bankName:data.bankName, bankSubtitle:data.bankSubtitle});
  })

  useNuiEvent<any>('setLoading', data => {
    loading.set(data.status);
    if (data.theme) theme.set(data.theme);
    if (data.bankName) bankName.set(data.bankName);
    if (data.bankSubtitle) bankSubtitle.set(data.bankSubtitle);
    if (data.appearance) applyAppearance({...data.appearance, bankName:data.bankName, bankSubtitle:data.bankSubtitle});
  })

  useNuiEvent<any>('notify', data => {
    notify.set(data.status);
    setTimeout(() => {
      notify.set("");
    }, 3500);
  })

  useNuiEvent<any>('updateLocale', data => {
    translations.set(data.translations || {});
    currency.set(data.currency);
    const language = String(data.locale || 'en').replace(/_/g, '-');
    try {
      const canonical = new Intl.DateTimeFormat(language).resolvedOptions().locale;
      uiLocale.set(canonical);
      document.documentElement.lang = canonical;
    } catch (_) {
      uiLocale.set('en');
      document.documentElement.lang = 'en';
    }
  })
  
  onMount(() => {
    const keyHandler = (e: KeyboardEvent) => {
      if (isVisible && ['Escape'].includes(e.code)) {
        fetchNui('closeInterface');
        visibility.set(false);
        popupDetails.update((val) => ({
          ...val,
          actionType: "",
        }));
      }
    };

    window.addEventListener('keydown', keyHandler);
    return () => window.removeEventListener('keydown', keyHandler);
  });
</script>

{#if isVisible}
  <slot />
{/if}
