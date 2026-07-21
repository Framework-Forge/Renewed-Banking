<script lang="ts">
    export let transaction: any;
    import { formatMoney } from "../../utils/misc";
    import { translations } from "../../store/stores";
    function getTimeElapsed(seconds: number): string {
        let retData: string;
        const timestamp = Math.floor(Date.now() / 1000)-seconds;
        const minutes = Math.floor(timestamp / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        const weeks = Math.floor(days / 7);

        if (weeks !== 0 && weeks > 1) {
            retData = $translations.weeks.replace("%s", weeks);
        } else if (weeks !== 0 && weeks === 1) {
            retData = $translations.aweek;
        } else if (days !== 0 && days > 1) {
            retData = $translations.days.replace("%s", days);
        } else if (days !== 0 && days === 1) {
            retData = $translations.aday;
        } else if (hours !== 0 && hours > 1) {
            retData = $translations.hours.replace("%s", hours);
        } else if (hours !== 0 && hours === 1) {
            retData = $translations.ahour;
        } else if (minutes !== 0 && minutes > 1) {
            retData = $translations.mins.replace("%s", minutes);
        } else if (minutes !== 0 && minutes === 1) {
            retData = $translations.amin;
        } else {
            retData = $translations.secs;
        }
        return retData;
    }
</script>

<section class="transaction">
    <h5>
        <span class="title-container" class:withdrawTitle={transaction.trans_type === "withdraw"}>
            {transaction.title}
            <p>[{transaction.trans_type.toUpperCase()}]</p>
        </span>
        <span class="trans_id" class:withdrawId={transaction.trans_type === "withdraw"}>{transaction.trans_id}</span>
    </h5>
    <h4>
        <div style="display: flex; flex-direction: column; justify-content: flex-start; align-items: flex-start;">
            <span class:withdraw={transaction.trans_type === "withdraw"}>
                <i class="fa-solid fa-money-bill"></i>
                {formatMoney(transaction.amount)}
            </span>
        </div>
        <span> {transaction.receiver} </span>
        <span>{getTimeElapsed(transaction.time)} <br /> {transaction.issuer}</span>
    </h4>

    <h6>
        {$translations.message} <br />
        {transaction.message}
    </h6>
</section>

<style>
    .transaction {
        background-color: var(--surface-2);
        padding: 1.4rem 1.6rem;
        border-radius: var(--radius-sm);
        border: 1px solid var(--border);
        font-size: 1.3rem;
        font-weight: 400;
        transition: border-color 0.2s ease;
    }
    .transaction:hover {
        border-color: var(--border-hover);
    }
    .transaction:not(:last-child) {
        margin-bottom: 1rem;
    }

    /* ── Header row ── */
    .title-container {
        display: flex;
        align-items: center;
        gap: 0.7rem;
        font-family: var(--font-heading);
        font-size: 1.3rem;
        font-weight: 600;
        color: var(--text);
    }

    /* deposit type badge */
    .title-container > p {
        background-color: rgba(16, 185, 129, 0.15);
        color: var(--brand-bright);
        border: 1px solid rgba(16, 185, 129, 0.30);
        padding: 0.3rem 0.8rem;
        border-radius: 6px;
        font-size: 1rem;
        font-family: var(--font-family);
        font-weight: 600;
        letter-spacing: 0.04em;
    }
    /* withdraw type badge */
    .title-container.withdrawTitle > p {
        background-color: rgba(248, 113, 113, 0.12);
        color: var(--danger);
        border: 1px solid rgba(248, 113, 113, 0.28);
    }

    /* transaction ID chip */
    .trans_id {
        background-color: rgba(16, 185, 129, 0.12);
        color: var(--brand-bright);
        border: 1px solid rgba(16, 185, 129, 0.25);
        padding: 0.3rem 0.9rem;
        border-radius: 6px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.1rem;
        font-family: var(--font-heading);
        font-weight: 500;
    }
    .trans_id.withdrawId {
        background-color: rgba(248, 113, 113, 0.10);
        color: var(--danger);
        border-color: rgba(248, 113, 113, 0.25);
    }

    .transaction h5 {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding-bottom: 0.9rem;
        margin-bottom: 1.1rem;
        border-bottom: 1px solid var(--border);
    }

    /* ── Amount / details row ── */
    .transaction h4 {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        font-size: 1.2rem;
        margin-bottom: 1.2rem;
        color: var(--text-sec);
    }
    /* amount — deposit */
    .transaction h4 span:first-child {
        font-family: var(--font-heading);
        font-size: 1.6rem;
        font-weight: 700;
        color: var(--brand-bright);
        letter-spacing: -0.01em;
    }
    /* amount — withdraw */
    .transaction h4 span.withdraw {
        color: var(--danger);
    }
    .transaction h4 span:nth-child(2) {
        color: var(--text-sec);
        font-size: 1.2rem;
    }
    .transaction h4 span:nth-child(3) {
        color: var(--text-muted);
        font-size: 1.15rem;
        text-align: right;
    }

    /* ── Message row ── */
    .transaction h6 {
        color: var(--text-muted);
        font-size: 1.15rem;
        font-weight: 400;
        line-height: 1.5;
        padding-top: 0.8rem;
        border-top: 1px solid var(--border);
        margin: 0;
    }
    .transaction h6 span {
        margin-top: 0.5rem;
    }
</style>
