<script>
    import { notify } from "../store/stores";
</script>

<section class="notificaion-container">
    <section class="notificaion-content">
        <i class="start-icon  fa fa-info-circle faa-shake animated fa-2x" />
        <strong class="font__weight-bold" style="font-size:0.69vw;">{$notify}</strong> 
    </section>
</section>

<style>
    .notificaion-container {
        width: 22rem;
        box-sizing: border-box;
        position: absolute;
        left: 50%;
        top: 3%;
        transform: translateX(-50%);
        animation: fadeSlideUp 0.2s ease both;
    }
    .notificaion-content {
        background-color: var(--surface-1);
        border: 1px solid var(--border-active);
        box-shadow: 0 0 0 1px rgba(255,255,255,0.03),
                    0 12px 24px -6px rgba(0,0,0,0.50),
                    0 0 20px 0 var(--glow);
        padding: 1.4rem 1.8rem;
        border-radius: var(--radius-sm);
        font-size: 1.3rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        color: var(--text);
    }
    .notificaion-content i {
        color: var(--brand-bright);
        flex-shrink: 0;
    }
    .notificaion-content strong {
        font-family: var(--font-family);
        font-size: 1.3rem !important;
        font-weight: 500;
        color: var(--text);
    }
</style>
