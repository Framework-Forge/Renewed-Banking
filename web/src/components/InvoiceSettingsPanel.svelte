<script lang="ts">
    import { invoiceAdmin, translations, applyAppearance } from '../store/stores';
    import { fetchNui } from '../utils/fetchNui';

    let settings:any={...$invoiceAdmin.settings}, message='', saving=false;
    const text = (key: string) => $translations?.[key] ?? key;

    async function save(){
        if(saving) return;
        saving=true;
        message='';
        try {
            const result:any=await fetchNui('saveInvoiceSettings',settings);
            if(result&&result.success){
                settings={...result.settings};
                invoiceAdmin.set({canManage:true,settings});
                applyAppearance(settings);
                message=text('settings_saved');
            } else {
                message=text('operation_failed');
            }
        } catch (_) {
            message=text('operation_failed');
        } finally {
            saving=false;
        }
    }
</script>

<section class="panel">
    <header>
        <div class="header-icon"><i class="fa-solid fa-sliders"></i></div>
        <div><h3>{text('bank_admin_settings')}</h3><span>{text('bank_admin_subtitle')}</span></div>
    </header>

    <form on:submit|preventDefault={save}>
        <fieldset>
            <legend>{text('bank_interaction')}</legend>
            <div class="form-grid">
                <label>{text('interaction_mode')}<select bind:value={settings.interactionMode}><option value="target">{text('interaction_target')}</option><option value="interact">{text('interaction_interact')}</option></select></label>
                <label>{text('respect_walls')}<select bind:value={settings.respectWalls}><option value={true}>{text('walls_hide')}</option><option value={false}>{text('walls_allow')}</option></select></label>
            </div>
            <p>{text('interaction_help')}</p>
        </fieldset>
        <fieldset>
            <legend><i class="fa-solid fa-shield-halved"></i> {text('bank_identity')}</legend>
            <div class="form-grid">
                <label class="wide">{text('bank_logo_url')}<input type="text" maxlength="2048" placeholder="img/bank.png" bind:value={settings.logoUrl}/></label>
                <label>{text('bank_name_label')}<input type="text" maxlength="60" bind:value={settings.bankName}/></label>
                <label>{text('bank_subtitle_label')}<input type="text" maxlength="80" bind:value={settings.bankSubtitle}/></label>
                <label>{text('overview_title_label')}<input type="text" maxlength="100" placeholder={text('overview_title')} bind:value={settings.overviewTitle}/></label>
                <label>{text('overview_subtitle_label')}<input type="text" maxlength="160" placeholder={text('overview_subtitle')} bind:value={settings.overviewSubtitle}/></label>
            </div>
            {#if settings.logoUrl}
                <div class="logo-preview"><span>{text('preview')}</span><img src={settings.logoUrl} alt={settings.bankName || text('bank_logo')} /></div>
            {/if}
        </fieldset>

        <fieldset>
            <legend><i class="fa-solid fa-palette"></i> {text('appearance_settings')}</legend>
            <div class="color-grid">
                <div class="field"><span>{text('primary_color')}</span><div class="color-field"><input aria-label={text('primary_color')} type="color" bind:value={settings.primaryColor}/><code>{settings.primaryColor}</code></div></div>
                <div class="field"><span>{text('hover_color')}</span><div class="color-field"><input aria-label={text('hover_color')} type="color" bind:value={settings.primaryHoverColor}/><code>{settings.primaryHoverColor}</code></div></div>
                <div class="field"><span>{text('background_color')}</span><div class="color-field"><input aria-label={text('background_color')} type="color" bind:value={settings.backgroundColor}/><code>{settings.backgroundColor}</code></div></div>
                <div class="field"><span>{text('surface_color')}</span><div class="color-field"><input aria-label={text('surface_color')} type="color" bind:value={settings.surfaceColor}/><code>{settings.surfaceColor}</code></div></div>
                <div class="field"><span>{text('card_color')}</span><div class="color-field"><input aria-label={text('card_color')} type="color" bind:value={settings.cardColor}/><code>{settings.cardColor}</code></div></div>
                <div class="field"><span>{text('border_color')}</span><div class="color-field"><input aria-label={text('border_color')} type="color" bind:value={settings.borderColor}/><code>{settings.borderColor}</code></div></div>
                <div class="field"><span>{text('text_color')}</span><div class="color-field"><input aria-label={text('text_color')} type="color" bind:value={settings.textColor}/><code>{settings.textColor}</code></div></div>
                <div class="field"><span>{text('muted_text_color')}</span><div class="color-field"><input aria-label={text('muted_text_color')} type="color" bind:value={settings.mutedTextColor}/><code>{settings.mutedTextColor}</code></div></div>
                <div class="field"><span>{text('accent_text_color')}</span><div class="color-field"><input aria-label={text('accent_text_color')} type="color" bind:value={settings.accentTextColor}/><code>{settings.accentTextColor}</code></div></div>
                <div class="field opacity"><span>{text('ui_opacity')}</span><div><input aria-label={text('ui_opacity')} type="range" min="0.55" max="1" step="0.01" bind:value={settings.uiOpacity}/><output>{Math.round((settings.uiOpacity||0.98)*100)}%</output></div></div>
            </div>
        </fieldset>

        <fieldset>
            <legend><i class="fa-solid fa-file-invoice-dollar"></i> {text('invoice_rules')}</legend>
            <div class="form-grid">
                <label>{text('default_due_days')}<input type="number" min="0" max="3650" bind:value={settings.defaultDueDays}/></label>
                <label>{text('default_interest_rate')}<input type="number" min="0" max="100" step="0.01" bind:value={settings.defaultInterestRate}/></label>
                <label>{text('interest_interval')}<select bind:value={settings.defaultInterestInterval}><option value="day">{text('per_day')}</option><option value="hour">{text('per_hour')}</option></select></label>
                <label>{text('max_interest_rate')}<input type="number" min="0" max="100" step="0.01" bind:value={settings.maxInterestRate}/></label>
                <label>{text('max_total_multiplier')}<input type="number" min="1" max="100" step="0.1" bind:value={settings.maxTotalMultiplier}/></label>
            </div>
        </fieldset>

        <footer>
            {#if message}<p>{message}</p>{/if}
            <button type="submit" disabled={saving}><i class:fa-spin={saving} class={saving?'fa-solid fa-circle-notch':'fa-solid fa-floppy-disk'}></i> {saving?text('saving'):text('save_settings')}</button>
        </footer>
    </form>
</section>

<style>
    .panel{flex:1;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:12px;overflow:hidden;display:flex;flex-direction:column;box-shadow:inset 0 1px rgba(255,255,255,.035)}
    header{display:flex;align-items:center;gap:1rem;padding:1.35rem 1.5rem;border-bottom:1px solid var(--clr-border);background:linear-gradient(90deg,color-mix(in srgb,var(--clr-green) 8%,transparent),transparent)}
    .header-icon{width:38px;height:38px;display:grid;place-items:center;border:1px solid color-mix(in srgb,var(--clr-green) 30%,transparent);border-radius:8px;background:color-mix(in srgb,var(--clr-green) 9%,transparent);color:var(--clr-green)}
    h3{margin:0;color:var(--clr-text-bright);font-size:1.2rem}header span{color:var(--clr-text-muted);font-size:.82rem}
    form{padding:1.4rem;overflow-y:auto;display:flex;flex-direction:column;gap:1.2rem}
    fieldset{border:1px solid var(--clr-border);border-radius:10px;padding:1.2rem;background:var(--clr-primary-dark)}
    legend{padding:0 .6rem;color:var(--clr-text-bright);font-weight:700;font-size:.86rem;text-transform:uppercase;letter-spacing:.045em}legend i{color:var(--clr-green);margin-right:.4rem}
    .form-grid,.color-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem}.color-grid{grid-template-columns:repeat(3,minmax(0,1fr))}
    label,.field{display:flex;flex-direction:column;gap:.48rem;color:var(--clr-text-muted);font-size:.76rem;font-weight:700;text-transform:uppercase;letter-spacing:.025em}.wide,.opacity{grid-column:1/-1}
    input,select{width:100%;min-height:40px;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:7px;padding:.78rem .9rem;color:var(--clr-text-bright);transition:.18s ease}input:focus,select:focus{border-color:var(--clr-green);box-shadow:0 0 10px var(--clr-accent-glow)}
    .color-field{display:grid;grid-template-columns:42px 1fr;gap:.55rem;align-items:center;background:var(--clr-primary);border:1px solid var(--clr-border);border-radius:7px;padding:.35rem}.color-field input{height:34px;min-height:34px;padding:2px;border:0}.color-field code{color:var(--clr-text);font-size:.78rem}
    .opacity>div{display:grid;grid-template-columns:1fr 58px;gap:1rem;align-items:center}.opacity input{padding:0;accent-color:var(--clr-green)}output{text-align:center;color:var(--clr-green);font-weight:800}
    .logo-preview{margin-top:1rem;display:flex;align-items:center;gap:1rem;padding:.75rem 1rem;border:1px dashed var(--clr-border);border-radius:8px;color:var(--clr-text-muted);font-size:.75rem;text-transform:uppercase}.logo-preview img{width:54px;height:54px;object-fit:contain}
    footer{position:sticky;bottom:0;display:flex;justify-content:flex-end;align-items:center;gap:1rem;padding-top:.4rem}footer p{margin-right:auto;color:var(--clr-green)}
    button{border:1px solid color-mix(in srgb,var(--clr-green) 65%,transparent);border-radius:8px;padding:.85rem 1.25rem;background:var(--clr-green);color:var(--clr-accent-text);font-weight:800;cursor:pointer;box-shadow:0 0 14px var(--clr-accent-glow)}button:disabled{opacity:.55;cursor:not-allowed}
    @media(max-width:1050px){.color-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
</style>
