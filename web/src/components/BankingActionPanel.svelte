<script lang="ts">
    import { accounts, activeAccount, loading, translations, currentView } from '../store/stores';
    import { fetchNui } from '../utils/fetchNui';
    export let action: string;
    let amount = 0, comment = '', stateid = '', message = '';
    $: account = $accounts.find((item:any) => item.id === $activeAccount);
    const text = (key: string) => $translations?.[key] ?? key;
    async function submit(){
        if(!account || amount < 1) return;
        loading.set(true); message='';
        const result:any = await fetchNui(action,{fromAccount:account.id,amount,comment,stateid});
        if(Array.isArray(result)){ accounts.set(result); message=text('operation_success'); amount=0; comment=''; stateid=''; }
        else message=text('operation_failed');
        loading.set(false);
    }
</script>
<section class="panel">
    <header><i class={`fa-solid ${action==='deposit'?'fa-circle-plus':action==='withdraw'?'fa-circle-minus':'fa-paper-plane'}`}></i><div><h3>{text(action+'_but')}</h3><span>{account ? `${account.name} · #${account.id}` : text('select_account')}</span></div></header>
    {#if account}<form on:submit|preventDefault={submit}>
        <label>{text('amount')}<input type="number" min="1" bind:value={amount} required /></label>
        {#if action === 'transfer'}<label>{text('transfer')}<input bind:value={stateid} required /></label>{/if}
        <label>{text('comment')}<input bind:value={comment} /></label>
        {#if message}<p>{message}</p>{/if}
        <button type="submit">{text('confirm_but')}</button>
    </form>{/if}
</section>
<style>
    .panel{flex:1;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:20px;padding:2rem;overflow:auto}header{display:flex;gap:1rem;align-items:center;border-bottom:1px solid var(--clr-border);padding-bottom:1.5rem}header>i{font-size:1.7rem;color:var(--clr-green)}h3{margin:0;color:var(--clr-text-bright);font-size:1.35rem}header span{color:var(--clr-text-muted);font-size:.85rem}form{max-width:650px;margin:2rem auto;display:flex;flex-direction:column;gap:1.25rem}label{display:flex;flex-direction:column;gap:.55rem;color:var(--clr-text-muted);font-size:.8rem;font-weight:700;text-transform:uppercase}input{background:var(--clr-primary-dark);border:1px solid var(--clr-border);border-radius:12px;padding:1rem;color:var(--clr-text-bright);font-size:1rem}input:focus{border-color:var(--clr-green)}button{padding:1rem;border:0;border-radius:12px;background:var(--clr-green);color:var(--clr-accent-text);font-weight:800;cursor:pointer}p{color:var(--clr-green)}
    .panel{border-radius:12px;box-shadow:inset 0 1px rgba(255,255,255,.035)}
</style>
