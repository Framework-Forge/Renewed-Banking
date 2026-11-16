<script lang="ts">
    import { accounts, activeAccount, translations } from '../../store/stores';
    import { fetchNui } from '../../utils/fetchNui';

    let playerId = '';
    let permissions = { withdraw:false, transfer:false, payInvoices:true };
    let members:any[] = [];
    let loading = false;
    let saving = '';
    let message = '';
    let loadedAccount = '';
    const text = (key: string) => $translations?.[key] ?? key;
    $: account = $accounts.find((item:any) => item.id === $activeAccount);
    $: if (account && account.id !== loadedAccount) {
        loadedAccount = account.id;
        members = [];
        message = '';
        if (account.owner) loadMembers(account.id);
    }

    async function loadMembers(accountId = account?.id) {
        if (!accountId || !account?.owner) return;
        loading = true;
        const result:any = await fetchNui('getAccountMembers', {accountId});
        members = result?.success && Array.isArray(result.members) ? result.members : [];
        if (!result?.success) message = text('dependents_load_failed');
        loading = false;
    }

    async function addDependent() {
        const id = Number(playerId);
        if (!account?.owner || !Number.isInteger(id) || id < 1) {
            message = text('dependent_invalid_id');
            return;
        }
        saving = 'add'; message = '';
        const result:any = await fetchNui('addAccountDependent', {accountId:account.id, playerId:id, permissions});
        if (result?.success) {
            playerId = '';
            message = text('dependent_added');
            await loadMembers();
        } else {
            message = result?.reason === 'player_not_found'
                ? text('dependent_player_not_found')
                : text('dependent_add_failed');
        }
        saving = '';
    }

    async function updateMember(member:any) {
        if (saving) return;
        saving = member.cid; message = '';
        const result:any = await fetchNui('updateAccountDependent', {
            accountId:account.id, cid:member.cid, permissions:member.permissions
        });
        message = result?.success ? text('permissions_saved')
            : text('permissions_save_failed');
        saving = '';
    }

    async function removeMember(member:any) {
        if (saving) return;
        saving = member.cid; message = '';
        const result:any = await fetchNui('removeAccountDependent', {accountId:account.id,cid:member.cid});
        if (result?.success) {
            members = members.filter(item => item.cid !== member.cid);
            message = text('dependent_removed');
        } else message = text('dependent_remove_failed');
        saving = '';
    }
</script>

<section class="dependents-panel">
    <header><div class="heading-icon"><i class="fa-solid fa-user-shield"></i></div><div>
        <h3>{text('account_dependents')}</h3>
        <span>{account ? `${account.name} · #${account.id}` : text('select_account')}</span>
    </div></header>

    {#if account?.owner}
        <div class="add-box">
            <div class="section-title"><div><strong>{text('add_dependent')}</strong><span>{text('add_dependent_help')}</span></div></div>
            <div class="player-id"><label for="dependent-player-id">{text('player_id')}</label><div><i class="fa-solid fa-id-card"></i><input id="dependent-player-id" type="number" min="1" placeholder={text('player_id_example')} bind:value={playerId} /></div></div>
            <div class="permission-grid">
                <label><input type="checkbox" bind:checked={permissions.withdraw}/><span><i class="fa-solid fa-money-bill-transfer"></i><b>{text('permission_withdraw')}</b><small>{text('permission_withdraw_help')}</small></span></label>
                <label><input type="checkbox" bind:checked={permissions.transfer}/><span><i class="fa-solid fa-paper-plane"></i><b>{text('permission_transfer')}</b><small>{text('permission_transfer_help')}</small></span></label>
                <label><input type="checkbox" bind:checked={permissions.payInvoices}/><span><i class="fa-solid fa-file-circle-check"></i><b>{text('permission_invoices')}</b><small>{text('permission_invoices_help')}</small></span></label>
            </div>
            <button class="primary" on:click={addDependent} disabled={saving==='add'}>{#if saving==='add'}<i class="fa-solid fa-circle-notch fa-spin"></i>{:else}<i class="fa-solid fa-user-plus"></i>{/if} {text('add_access')}</button>
        </div>

        <div class="members-title"><div><strong>{text('authorized_players')}</strong><span>{members.length}</span></div><button on:click={()=>loadMembers()} disabled={loading}><i class:fa-spin={loading} class="fa-solid fa-rotate"></i></button></div>
        <div class="members">
            {#each members as member (member.cid)}
                <article>
                    <div class="member-head"><div class="avatar"><i class="fa-solid fa-user"></i></div><div><strong>{member.name}</strong><span>#{member.cid}</span></div><button class="remove" title={text('remove_access')} on:click={()=>removeMember(member)} disabled={!!saving}><i class="fa-solid fa-trash-can"></i></button></div>
                    <div class="toggles">
                        <label><span>{text('permission_withdraw')}</span><input type="checkbox" disabled={!!saving} bind:checked={member.permissions.withdraw} on:change={()=>updateMember(member)}/><i></i></label>
                        <label><span>{text('permission_transfer')}</span><input type="checkbox" disabled={!!saving} bind:checked={member.permissions.transfer} on:change={()=>updateMember(member)}/><i></i></label>
                        <label><span>{text('permission_invoices')}</span><input type="checkbox" disabled={!!saving} bind:checked={member.permissions.payInvoices} on:change={()=>updateMember(member)}/><i></i></label>
                    </div>
                </article>
            {:else}{#if !loading}<div class="empty"><i class="fa-solid fa-users-slash"></i><strong>{text('no_dependents')}</strong><span>{text('no_dependents_help')}</span></div>{/if}{/each}
        </div>
    {:else if account}
        <div class="delegated"><i class="fa-solid fa-shield-halved"></i><h4>{text('shared_access')}</h4><p>{text('shared_access_help')}</p>
            <div><span class:enabled={account.access?.withdraw}><i class="fa-solid fa-minus"></i>{text('permission_withdraw')}</span><span class:enabled={account.access?.transfer}><i class="fa-solid fa-paper-plane"></i>{text('permission_transfer')}</span><span class:enabled={account.access?.payInvoices}><i class="fa-solid fa-file-circle-check"></i>{text('permission_invoices')}</span></div>
        </div>
    {/if}
    {#if message}<p class="message">{message}</p>{/if}
</section>

<style>
    .dependents-panel{flex:1;min-width:0;height:100%;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:12px;padding:1.4rem;display:flex;flex-direction:column;gap:1.1rem;overflow:hidden;box-shadow:inset 0 1px rgba(255,255,255,.035)}
    header{display:flex;align-items:center;gap:.85rem;padding-bottom:1rem;border-bottom:1px solid var(--clr-border)}.heading-icon{width:42px;height:42px;border-radius:10px;display:grid;place-items:center;background:color-mix(in srgb,var(--clr-green) 14%,transparent);color:var(--clr-green)}h3{margin:0;color:var(--clr-text-bright);font-size:1.12rem}header span,.section-title span{display:block;color:var(--clr-text-muted);font-size:.76rem;margin-top:.18rem}
    .add-box{background:var(--clr-primary-dark);border:1px solid var(--clr-border);border-radius:12px;padding:1rem;display:grid;gap:.85rem}.section-title strong{color:var(--clr-text-bright)}.player-id{font-size:.7rem;text-transform:uppercase;font-weight:700;color:var(--clr-text-muted);display:grid;gap:.38rem}.player-id div{position:relative}.player-id i{position:absolute;left:.85rem;top:50%;transform:translateY(-50%);color:var(--clr-green)}input[type=number]{box-sizing:border-box;width:100%;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:9px;padding:.72rem .75rem .72rem 2.4rem;color:var(--clr-text-bright)}input:focus{border-color:var(--clr-green)}
    .permission-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.55rem}.permission-grid label{position:relative;cursor:pointer}.permission-grid input{position:absolute;opacity:0}.permission-grid span{height:100%;box-sizing:border-box;border:1px solid var(--clr-border);background:var(--clr-primary);border-radius:9px;padding:.72rem;display:grid;grid-template-columns:auto 1fr;column-gap:.5rem;align-items:center;color:var(--clr-text-muted)}.permission-grid input:checked+span{border-color:var(--clr-green);background:color-mix(in srgb,var(--clr-green) 10%,var(--clr-primary));color:var(--clr-green)}.permission-grid b{font-size:.76rem;color:var(--clr-text-bright)}.permission-grid small{grid-column:1/3;font-size:.62rem;margin-top:.28rem}.primary{border:0;border-radius:9px;padding:.75rem;background:var(--clr-green);color:var(--clr-accent-text);font-weight:800;cursor:pointer}.primary:disabled{opacity:.55}
    .members-title{display:flex;align-items:center;justify-content:space-between}.members-title>div{display:flex;gap:.5rem;align-items:center}.members-title strong{font-size:.82rem;color:var(--clr-text-bright);text-transform:uppercase}.members-title span{font-size:.68rem;background:var(--clr-primary-light);padding:.18rem .42rem;border-radius:20px;color:var(--clr-text-muted)}.members-title button,.remove{border:1px solid var(--clr-border);background:var(--clr-primary-light);color:var(--clr-text-muted);border-radius:8px;width:32px;height:32px;cursor:pointer}.members{flex:1;overflow-y:auto;display:flex;flex-direction:column;gap:.7rem;padding-right:.3rem}.members::-webkit-scrollbar{width:5px}.members::-webkit-scrollbar-thumb{background:var(--clr-border);border-radius:10px}.members article{background:var(--clr-primary-dark);border:1px solid var(--clr-border);border-radius:11px;padding:.85rem}.member-head{display:flex;align-items:center;gap:.65rem}.avatar{width:34px;height:34px;border-radius:9px;background:color-mix(in srgb,var(--clr-green) 12%,transparent);color:var(--clr-green);display:grid;place-items:center}.member-head>div:nth-child(2){display:flex;flex:1;flex-direction:column}.member-head strong{font-size:.84rem;color:var(--clr-text-bright)}.member-head span{font-size:.66rem;color:var(--clr-text-muted)}.remove{color:#ef4444}.toggles{display:grid;grid-template-columns:repeat(3,1fr);gap:.5rem;margin-top:.75rem;padding-top:.7rem;border-top:1px solid var(--clr-border)}.toggles label{display:flex;align-items:center;justify-content:space-between;gap:.3rem;font-size:.67rem;color:var(--clr-text-muted);cursor:pointer}.toggles input{display:none}.toggles i{width:26px;height:15px;border-radius:20px;background:var(--clr-border);position:relative}.toggles i:after{content:'';position:absolute;width:11px;height:11px;left:2px;top:2px;background:var(--clr-text-muted);border-radius:50%;transition:.16s}.toggles input:checked+i{background:var(--clr-green)}.toggles input:checked+i:after{left:13px;background:var(--clr-accent-text)}
    .empty,.delegated{margin:auto;text-align:center;color:var(--clr-text-muted);display:flex;flex-direction:column;align-items:center;gap:.55rem}.empty>i,.delegated>i{font-size:2rem;color:var(--clr-green);opacity:.75}.empty strong,.delegated h4{color:var(--clr-text-bright);margin:0}.empty span,.delegated p{font-size:.76rem;margin:0;max-width:430px}.delegated>div{display:flex;gap:.5rem;flex-wrap:wrap;justify-content:center;margin-top:.5rem}.delegated>div span{padding:.55rem .7rem;border:1px solid var(--clr-border);border-radius:8px;opacity:.45}.delegated>div span.enabled{opacity:1;border-color:var(--clr-green);color:var(--clr-green)}.delegated>div i{margin-right:.35rem}.message{font-size:.75rem;color:var(--clr-green);margin:0}
    @media(max-width:1100px){.permission-grid,.toggles{grid-template-columns:1fr}.dependents-panel{min-width:420px}}
</style>
