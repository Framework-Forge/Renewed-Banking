# Renewed-Banking — revisão de idiomas

Implementação em 01/10/2026. **APROVADO pelo responsável no FiveM em 01/10/2026:** funcionamento do Renewed-Banking confirmado após as conversões de cache e idiomas. Esta confirmação não equivale a benchmark ou auditoria integral de segurança.

## Entregue

- Os 22 arquivos em `locales/` possuem as mesmas 216 chaves, incluindo configurações de interação, aparência, faturas, dependentes e mensagens de exportação.
- Preservadas as traduções existentes; preenchidas as lacunas das telas novas e traduzidos os rótulos de dashboard antes repetidos em inglês nos outros idiomas.
- Removidos os fallbacks de texto fixo dos componentes. O idioma continua sendo carregado por `pr_lib.locale()` e enviado à NUI no evento `updateLocale`.
- Corrigida a codificação mista do componente `InvoiceSettingsPanel.svelte`: UTF-8, sem caracteres de substituição nos rótulos.
- Datas das faturas e valores monetários da NUI seguem o idioma enviado pelo bridge, sem fixar português/inglês na formatação.
- Descrições geradas de pagamento/estorno de faturas, crédito/débito e mensagens bancárias usam chaves de idioma no Lua. Erros de valores recebem o nome traduzido da operação.
- Bundle de produção recompilado em `web/public/build/`.

## Dados que não são traduções

Nomes de contas/jogadores, marca do banco, subtítulo configurado, títulos e descrições personalizados de faturas e mensagens digitadas são dados do usuário/administrador. São preservados, sem tradução automática nem regravação do banco. Registros históricos já gravados em um idioma não são reescritos nesta etapa. Identificadores técnicos, nomes de providers (`Target`/`Interact`), caminhos de assets, comentários e diagnóstico técnico de console não são rótulos de interface.

## Validação executada

| Verificação | Resultado |
|---|---|
| `node tests/locales_test.cjs` | 22 catálogos UTF-8, paridade de 216 chaves, cobertura de referências e parâmetros das novas mensagens. |
| `node tests/ui_locale_test.cjs` | 15 componentes sem textos estáticos visíveis nos nós de texto e atributos de acessibilidade/placeholder auditados. |
| `lua55.exe tests/interaction_cache_test.lua` | Regressão de cache/snapshot/deltas aprovada. |
| `luac55.exe -p` | 9 arquivos Lua, incluindo o teste, aprovados. `config.lua` não alterado: usa hashes nativos FiveM, não suportados pelo parser Lua padrão. |
| Svelte check | Zero erros e zero warnings; seis hints de código existente. |
| `npm run build` | Bundle de produção gerado. |

Estes testes são estáticos/isolados, não execução no FXServer nem revisão linguística por falantes nativos de todos os idiomas.

## Homologação no jogo

1. Reiniciar `Renewed-Banking` e abrir banco/ATM.
2. Conferir as configurações de interação, opções de paredes, identidade, aparência e regras de faturamento.
3. Conferir lista/pagamento de faturas, datas, juros, dependentes e exportação de transações.
4. Testar outros idiomas pela configuração do PR Bridge, reinicializando os recursos necessários ao carregamento do idioma; verificar que não aparecem português fixo, chaves cruas ou caracteres corrompidos.
5. Conferir notificações de erro/sucesso e mensagens bancárias quando o envio de mensagens estiver habilitado.

Após aprovação do responsável, atualizar o status no plano de migração do PR Bridge.
