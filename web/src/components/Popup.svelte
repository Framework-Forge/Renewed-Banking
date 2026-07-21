<script lang="ts">
    import { accounts, activeAccount, popupDetails, loading, translations } from "../store/stores";
    import {fetchNui} from "../utils/fetchNui"
    let amount: number = 0;
    let comment: string = "";
    let stateid: string = "";
    $: account = $accounts.find((accountItem: any) => $activeAccount === accountItem.id);

    function closePopup() {
        popupDetails.update((val: any) => ({
            ...val,
            actionType: ""
        }));
    }

    function submitInput() {
        loading.set(true);
        fetchNui($popupDetails.actionType, {fromAccount: $popupDetails.account.id, amount: amount, comment: comment, stateid: stateid}).then(retData => {
            setTimeout(() => {
                if (retData !== false){
                    accounts.set(retData);
                }
                loading.set(false);
            }, 1000);
        })
        closePopup();
    }
</script>

<section class="popup-container">
    <section class="popup-content">
        <h2> {$popupDetails.account.type}{$translations.account}/ {$popupDetails.account.id}</h2>
        <hr class="popup-divider" />
        <form action="#">
            <div class="form-row">
                <label for="amount">{$translations.amount}</label>
                <input bind:value={amount} type="number" name="amount" id="amount" placeholder="$" />
            </div>

            <div class="form-row">
                <label for="comment">{$translations.comment}</label>
                <input bind:value={comment} type="text" name="comment" id="comment" placeholder="//" />
            </div>

            {#if $popupDetails.actionType === "transfer"}
                <div class="form-row">
                    <label for="stateId">{$translations.transfer}</label>
                    <input bind:value={stateid} type="text" name="stateId" id="stateId" placeholder="#" />
                </div>
            {/if}

            <div class="btns-group">
                <button type="button" class="btn btn-orange" on:click={closePopup}>{$translations.cancel}</button>
                <button type="button" class="btn btn-green" on:click={() => submitInput()}>{$translations.confirm}</button>
            </div>
        </form>
    </section>
</section>

<style>
    .popup-container {
        position: fixed;
        top: 0;
        left: 0;
        bottom: 0;
        right: 0;
        background-color: rgba(0, 0, 0, 0.55);
        display: flex;
        align-items: center;
        justify-content: center;
        animation: fadeSlideUp 0.2s ease both;
    }

    .popup-content {
        max-width: 54rem;
        width: 100%;
        background-color: var(--surface-1);
        border: 1px solid var(--border);
        padding: 4rem;
        border-radius: var(--radius);
        box-shadow: 0 0 0 1px rgba(255,255,255,0.03),
                    0 25px 50px -12px rgba(0,0,0,0.60);
    }

    h2 {
        font-family: var(--font-heading);
        font-size: 1.8rem;
        font-weight: 600;
        letter-spacing: -0.02em;
        color: var(--text);
        margin-bottom: 0.4rem;
        text-align: center;
    }

    .popup-divider {
        border: none;
        border-top: 1px solid var(--border);
        margin: 1.8rem 0 2.4rem;
    }

    .form-row {
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
        color: var(--text);
        margin-bottom: 1.6rem;
    }
    .form-row label {
        font-size: 1.2rem;
        font-weight: 500;
        color: var(--text-sec);
        letter-spacing: 0.03em;
        text-transform: uppercase;
    }
    .form-row input {
        width: 100%;
        border-radius: 8px;
        background-color: var(--surface-3);
        border: 1px solid var(--border);
        padding: 1.2rem 1.4rem;
        color: var(--text);
        font-family: var(--font-family);
        font-size: 1.4rem;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    .form-row input::placeholder {
        color: var(--text-muted);
    }
    .form-row input:focus {
        border-color: var(--border-active);
        box-shadow: 0 0 0 3px var(--glow);
    }

    .btns-group {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.8rem;
        margin-top: 0.8rem;
    }
</style>
