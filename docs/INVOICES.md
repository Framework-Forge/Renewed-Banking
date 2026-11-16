# API de faturas do Renewed Banking

Outros recursos podem criar uma fatura persistente pelo servidor:

```lua
local result = exports['Renewed-Banking']:CreateInvoice({
    externalId = 'conta-luz:123',
    recipient = citizenid,
    issuer = 'Companhia de Energia',
    receiverAccount = 'government',
    title = 'Conta de energia',
    description = 'Consumo do imóvel 123',
    amount = 850,
    dueAt = os.time() + (7 * 86400),
    interestRate = 1.5,
    interestInterval = 'day', -- day ou hour
    metadata = { propertyId = 123 }
})
```

`externalId` é idempotente dentro do recurso emissor: repetir a mesma chamada não duplica a fatura.
Quando juros ou vencimento forem omitidos, são usados os padrões de `Config.invoices`.

Para encerrar uma fatura paga fora do banco:

```lua
exports['Renewed-Banking']:ResolveInvoice('conta-luz:123', 'paid')
```

O recurso emissor pode acompanhar pagamentos feitos no banco:

```lua
AddEventHandler('Renewed-Banking:server:invoicePaid', function(invoice)
    if invoice.issuerResource ~= GetCurrentResourceName() then return end
    -- invoice.externalId, invoice.total e invoice.metadata
end)
```
