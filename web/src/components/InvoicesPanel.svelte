<script lang="ts">
    import { onMount } from 'svelte';
    import { invoices, translations, accounts, activeAccount, uiLocale } from '../store/stores';
    import { fetchNui } from '../utils/fetchNui';
    import { formatMoney } from '../utils/misc';
    let filter='active', message='', payingId:number|null=null, refreshing=false;
    const text = (key: string) => $translations?.[key] ?? key;
    const date=(stamp:number)=>new Date(stamp*1000).toLocaleString($uiLocale);
    $: shown=$invoices.filter((item:any)=>filter==='all'||filter==='overdue'?(filter==='all'||(item.status==='active'&&item.overduePeriods>0)):item.status===filter);
    async function refresh(){
        refreshing=true;
        try {
            const data:any=await fetchNui('getInvoices',{accountId:$activeAccount});
            invoices.set(Array.isArray(data)?data:(data&&data.entries)||[]);
        } catch (_) {
            message=text('invoice_refresh_failed');
        } finally {
            refreshing=false;
        }
    }
    async function pay(id:number){
        if(payingId!==null) return;
        payingId=id;
        message='';
        try {
            const result:any=await Promise.race([
                fetchNui('payInvoice',{id,accountId:$activeAccount}),
                new Promise((_,reject)=>setTimeout(()=>reject(new Error('payment_timeout')),15000))
            ]);
            if(result && result.success){
                invoices.set(result.invoices||[]);
                if(Array.isArray(result.accounts)) accounts.set(result.accounts);
                message=text('invoice_paid');
            } else {
                message=result?.reason==='not_enough_money'
                    ? text('invoice_insufficient_funds')
                    : text('invoice_payment_failed');
                await refresh();
            }
        } catch (_) {
            message=text('invoice_payment_timeout');
            await refresh();
        } finally {
            payingId=null;
        }
    }
    onMount(refresh);
</script>
<section class="panel">
    <header><div><h3>{text('invoices_title')}</h3><span>{text('invoices_subtitle')}</span></div><button on:click={refresh} disabled={refreshing}><i class:fa-spin={refreshing} class="fa-solid fa-rotate"></i> {text('refresh')}</button></header>
    <div class="filters"><button class:active={filter==='active'} on:click={()=>filter='active'}>{text('invoice_pending')}</button><button class:active={filter==='overdue'} on:click={()=>filter='overdue'}>{text('invoice_overdue_plural')}</button><button class:active={filter==='paid'} on:click={()=>filter='paid'}>{text('invoice_paid_plural')}</button><button class:active={filter==='cancelled'} on:click={()=>filter='cancelled'}>{text('invoice_cancelled_plural')}</button><button class:active={filter==='all'} on:click={()=>filter='all'}>{text('all')}</button></div>
    {#if message}<p class="message">{message}</p>{/if}
    <div class="scroller"><div class="invoice-list">{#each shown as invoice (invoice.id)}
        <article class:overdue={invoice.status==='active' && invoice.overduePeriods>0}>
            <div class="icon"><i class="fa-solid fa-file-invoice-dollar"></i></div>
            <div class="info"><div class="title"><strong>{invoice.title}</strong><span>#{invoice.id}</span></div><p>{invoice.description}</p><div class="meta"><span>{text('invoice_issuer')}: {invoice.issuer}</span><span>{text('invoice_due')}: {date(invoice.dueAt)}</span><span>{text('invoice_interest')}: {invoice.interestRate}% {text(invoice.interestInterval==='hour'?'per_hour':'per_day')}</span></div></div>
            <div class="amount"><small>{text('invoice_principal')}: {formatMoney(invoice.principal)}</small><strong>{formatMoney(invoice.total)}</strong><span class:late={(invoice.status==='active' && invoice.overduePeriods>0)}>{(invoice.status==='active' && invoice.overduePeriods>0)?text('invoice_overdue'):invoice.status==='paid'?text('invoice_paid_status'):invoice.status==='cancelled'?text('invoice_cancelled'):text('invoice_open')}</span>{#if invoice.status==='active'}<button on:click={()=>pay(invoice.id)} disabled={payingId!==null}>{#if payingId===invoice.id}<i class="fa-solid fa-circle-notch fa-spin"></i> {text('invoice_processing')}{:else}{text('pay_invoice')}{/if}</button>{/if}</div>
        </article>
    {:else}<div class="empty"><i class="fa-solid fa-receipt"></i><span>{text('no_invoices')}</span></div>{/each}</div></div>
</section>
<style>
    .panel{flex:1;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:20px;padding:1.5rem;overflow:hidden;display:flex;flex-direction:column}header{display:flex;justify-content:space-between;align-items:center}h3{margin:0;color:var(--clr-text-bright);font-size:1.3rem}header span{color:var(--clr-text-muted);font-size:.85rem}button{background:var(--clr-primary-light);border:1px solid var(--clr-border);color:var(--clr-text-bright);padding:.7rem 1rem;border-radius:10px;cursor:pointer;transition:opacity .18s ease,border-color .18s ease}button:disabled{cursor:not-allowed;opacity:.55}.filters{display:flex;gap:.5rem;margin:1.4rem 0}.filters button.active{border-color:var(--clr-green);color:var(--clr-green)}.scroller{flex:1;overflow-y:auto;padding-right:.5rem}.invoice-list{display:flex;flex-direction:column;gap:.8rem;min-height:100%}article{display:flex;gap:1rem;padding:1.1rem;background:var(--clr-primary-dark);border:1px solid var(--clr-border);border-radius:14px}article.overdue{border-color:#ef4444}.icon{width:42px;height:42px;border-radius:10px;background:color-mix(in srgb,var(--clr-green) 15%,transparent);display:grid;place-items:center;color:var(--clr-green)}.info{flex:1;min-width:0}.title{display:flex;gap:.7rem;align-items:center}.title strong{color:var(--clr-text-bright)}.title span,.meta,p{color:var(--clr-text-muted);font-size:.8rem}.info p{margin:.45rem 0}.meta{display:flex;gap:1rem;flex-wrap:wrap}.amount{display:flex;flex-direction:column;align-items:flex-end;gap:.35rem}.amount strong{font-size:1.25rem;color:var(--clr-text-bright)}.amount span{font-size:.75rem;color:var(--clr-green)}.amount span.late{color:#ef4444}.amount button{background:var(--clr-green);color:var(--clr-accent-text);font-weight:800;min-width:9.2rem}.empty{margin:auto;display:flex;flex-direction:column;gap:1rem;align-items:center;color:var(--clr-text-muted);font-size:1rem}.empty i{font-size:2.5rem}.message{color:var(--clr-green)}
    .panel{border-radius:12px;box-shadow:inset 0 1px rgba(255,255,255,.035)}
</style>
