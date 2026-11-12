# Etapa 06 — Integração com API ou Serviço Externo

**Disciplina:** Tecnologia e Construção de Software 2
**Autor:** Lucas Carvalho Pacheco
**Projeto:** Plotter — gestão de lavoura por talhões

## 1. Objetivo da Etapa

Integrar o Plotter a um **serviço externo** por meio de comunicação em rede (HTTP), cumprindo o que a proposta previa na seção 10 (*"Necessidade de Comunicação com APIs Externas"*): consultar a **previsão do tempo** para ajudar o produtor a decidir se as condições são seguras para as próximas aplicações de defensivos.

Na prática, o app passou a mostrar:

- no **Detalhe do Talhão**, o cartão **"Condições para aplicação"**, com a previsão dos próximos 5 dias e a indicação **Favorável / Evitar** para pulverizar em cada dia;
- no formulário de **Novo/Editar Registro**, ao escolher uma data de hoje em diante, a **previsão daquele dia** logo abaixo do campo de data.

A comunicação HTTP com o backend próprio (Etapa 5), que faz as operações de consulta, envio, atualização e exclusão de talhões e registros, continua funcionando e também está descrita aqui (seção 4.2).

## 2. Serviço Externo Utilizado

| Item | Valor |
|---|---|
| Serviço | **OpenWeatherMap** (<https://openweathermap.org>) |
| API | *5 day / 3 hour forecast*: previsão de 5 dias em intervalos de 3 horas |
| Documentação oficial | <https://openweathermap.org/forecast5> |
| Base URL | `https://api.openweathermap.org/data/2.5` |
| Protocolo / formato | HTTPS, respostas em JSON (UTF-8) |
| Autenticação | Chave de API (`appid`) enviada como parâmetro da URL |
| Plano | Gratuito: basta criar uma conta; os limites de chamadas por minuto e por mês estão na página de preços do serviço |

**Por que o OpenWeatherMap:** é o serviço citado na proposta. O endpoint de 5 dias a cada 3 horas faz parte do plano gratuito, entrega vento, chuva, umidade e temperatura (o que importa para pulverização) e aceita `lang=pt_br`, que devolve as descrições em português.

## 3. Arquitetura e Fluxo de Comunicação

O app **não fala direto com o OpenWeatherMap**. Ele chama uma rota nova do backend próprio, que consulta o serviço externo com a chave guardada no servidor:

```text
App Flutter                          Backend (Node/Express)                          OpenWeatherMap
──────────────────────────────────────────────────────────────────────────────────────────────────────
PrevisaoTempoCard / PrevisaoDoDiaCard
  │ (estado: carregando)
  ▼
PlotterCrud.previsaoDoTempo()
  │ previsão de menos de 10 min? → devolve a mesma (sem rede)
  ▼
PlotterApi.previsaoDoTempo()
  │  GET /clima/previsao  ─────────────►  ServicoClima.previsao()
  │                                          │ não configurado? → 503
  │                                          │ cache de menos de 30 min? → devolve
  │                                          ▼
  │                                        GET /data/2.5/forecast?lat&lon&units&lang&appid ──►  (40 intervalos de 3 h)
  │                                          ◄──────────────────────────────────────── 200 JSON / 401 / 429 / 5xx
  │                                          │ agrupa por dia no fuso da fazenda,
  │                                          │ avalia cada intervalo para pulverização,
  │                                          │ guarda em cache por 30 min
  │  ◄──── 200 JSON resumido  ─────────────  ┘   (ou 502/503/504 com {erro})
  ▼
PrevisaoTempo.fromJson → estado: sucesso | ausência de dados | erro
```

Motivos para passar pelo backend:

1. **A chave fica só no servidor** (`backend/.env`, fora do Git). Um app instalado pode ser descompilado, então qualquer chave embutida nele estaria exposta.
2. **Menos dados trafegam no celular:** em vez de 40 intervalos com dezenas de campos, o app recebe até 5 dias já resumidos.
3. **A regra de negócio fica em um lugar só:** a avaliação "bom dia para pulverizar?" é feita no servidor e pode ser ajustada sem publicar uma nova versão do app.
4. **Cache no servidor:** vários aparelhos dividem a mesma consulta, o que economiza a cota gratuita.

## 4. Endpoints Utilizados

### 4.1 Serviço externo (chamado pelo backend)

| Método | Endpoint | Parâmetros | Uso |
|---|---|---|---|
| GET | `https://api.openweathermap.org/data/2.5/forecast` | `lat`, `lon` (coordenadas da fazenda), `units=metric` (°C e m/s), `lang=pt_br`, `appid` (chave) | Previsão de 5 dias / 3 horas |

### 4.2 Backend próprio (chamado pelo app)

Base URL: `http://<endereço-do-computador>:3000`. No emulador Android o padrão é `http://10.0.2.2:3000`; para mudar, use `--dart-define=API_URL=...`.

| Operação | Método | Rota | Resposta |
|---|---|---|---|
| **Consulta da previsão do tempo (Etapa 6)** | **GET** | **`/clima/previsao`** | `200` previsão · `502`/`503`/`504` com `{erro}` |
| Verificar se o servidor está no ar | GET | `/health` | `200 {"status":"ok"}` |
| Consulta de talhões | GET | `/talhoes`, `/talhoes/:id` | `200` · `404` |
| Envio (criação) de talhão | POST | `/talhoes` | `201` talhão com `id` · `400` |
| Atualização de talhão | PUT | `/talhoes/:id` | `200` · `400` · `404` |
| Exclusão de talhão | DELETE | `/talhoes/:id` | `200 {"registrosRemovidos": n}` · `404` |
| Consulta de registros | GET | `/registros[?talhaoId=n]`, `/registros/:id` | `200` · `404` |
| Envio (criação) de registro | POST | `/registros` | `201` · `400` |
| Atualização de registro | PUT | `/registros/:id` | `200` · `400` · `404` |
| Exclusão de registro | DELETE | `/registros/:id` | `204` · `404` |

Assim o app tem **consulta** (GET da previsão, de talhões e de registros), **envio** (POST) e **atualização** (PUT) de dados por HTTP.

## 5. Estrutura dos Dados Trocados

### 5.1 Backend → OpenWeatherMap (requisição)

```http
GET /data/2.5/forecast?lat=-17.7923&lon=-50.9192&units=metric&lang=pt_br&appid=<CHAVE> HTTP/1.1
Host: api.openweathermap.org
Accept: application/json
```

### 5.2 OpenWeatherMap → Backend (resposta, campos usados)

```json
{
  "cod": "200",
  "cnt": 40,
  "list": [
    {
      "dt": 1763002800,
      "main": { "temp": 23.0, "temp_min": 21.4, "temp_max": 24.2, "humidity": 72 },
      "weather": [{ "id": 801, "main": "Clouds", "description": "algumas nuvens", "icon": "02d" }],
      "wind": { "speed": 2.1, "deg": 120 },
      "pop": 0.05,
      "rain": { "3h": 1.4 },
      "dt_txt": "2026-11-13 03:00:00"
    }
  ],
  "city": { "name": "Rio Verde", "country": "BR", "timezone": -10800 }
}
```

| Campo | Significado | Como é usado |
|---|---|---|
| `dt` | Início do intervalo de 3 h (Unix, UTC) | Somado a `city.timezone` para obter a data e a hora locais da fazenda |
| `main.temp`, `temp_min`, `temp_max` | Temperatura (°C) | Faixa do dia; acima de 30 °C o intervalo é desfavorável |
| `main.humidity` | Umidade relativa (%) | Média do dia; abaixo de 50% o intervalo é desfavorável |
| `wind.speed` | Vento médio (m/s) | Convertido para km/h (× 3,6); acima de 10 km/h o intervalo é desfavorável |
| `pop` | Probabilidade de chuva (0 a 1) | Maior valor do dia; 50% ou mais torna o intervalo desfavorável |
| `rain.3h` | Chuva prevista no intervalo (mm) | Total do dia; 0,5 mm ou mais torna o intervalo desfavorável |
| `weather[0].description` / `icon` | Descrição em português e código do ícone | Do intervalo mais próximo do meio-dia |
| `city.name`, `city.timezone` | Localidade e fuso (segundos) | Nome exibido no cartão; agrupamento por dia local |

Intervalos malformados são descartados. Uma resposta sem `list`, ou que não é JSON, é tratada como erro do serviço.

### 5.3 Backend → App: `GET /clima/previsao` (sucesso)

```json
{
  "fonte": "OpenWeatherMap",
  "local": "Rio Verde",
  "latitude": -17.7923,
  "longitude": -50.9192,
  "atualizadoEm": "2026-11-12T10:58:37.201Z",
  "dias": [
    {
      "data": "2026-11-13",
      "descricao": "Chuva leve",
      "icone": "10d",
      "tempMin": 21.4,
      "tempMax": 32.1,
      "umidade": 68,
      "ventoKmh": 7.6,
      "probChuva": 85,
      "chuvaMm": 7,
      "pulverizacao": {
        "adequada": true,
        "motivo": "Janela favorável: 06h–09h.",
        "horarios": ["06:00"]
      }
    }
  ]
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| `fonte` | texto | Serviço de origem |
| `local` | texto | Localidade mais próxima das coordenadas (`"Fazenda"` se o serviço não informar) |
| `latitude`, `longitude` | número | Coordenadas consultadas |
| `atualizadoEm` | texto ISO 8601 | Quando o servidor obteve a previsão do serviço externo |
| `dias` | lista (0 a 5) | Um item por dia, do mais próximo ao mais distante. **Lista vazia = ausência de dados.** |
| `dias[].data` | `aaaa-mm-dd` | Dia no fuso da fazenda |
| `dias[].tempMin`, `tempMax` | número (°C) | Menor e maior temperatura previstas no dia |
| `dias[].umidade` | inteiro (%) | Umidade média |
| `dias[].ventoKmh` | número | Maior vento médio previsto no dia |
| `dias[].probChuva` | inteiro (%) | Maior probabilidade de chuva no dia |
| `dias[].chuvaMm` | número | Chuva total prevista no dia |
| `dias[].pulverizacao.adequada` | booleano | `true` se há pelo menos um intervalo diurno (06h às 18h) favorável |
| `dias[].pulverizacao.motivo` | texto | Janelas favoráveis ou a principal restrição do dia |
| `dias[].pulverizacao.horarios` | lista de `HH:MM` | Início de cada intervalo de 3 h favorável |

**Regra de avaliação** (`LIMITES_PULVERIZACAO` em `backend/src/clima.ts`): cada intervalo diurno de 3 h é favorável quando **não** há chuva prevista (≥ 0,5 mm ou probabilidade ≥ 50%), o vento fica em até 10 km/h, a temperatura em até 30 °C e a umidade em pelo menos 50%. Intervalos favoráveis seguidos viram uma janela ("06h–12h"). Se o dia não tiver nenhum, o motivo informado é a restrição que mais se repete, com prioridade para chuva, depois vento, calor e ar seco.

### 5.4 Backend → App: erros

Mesmo formato de erro da Etapa 5:

```json
{ "erro": "O serviço de previsão do tempo está indisponível no momento." }
```

| Situação | Resposta do OpenWeatherMap | Resposta do backend | Mensagem exibida no app |
|---|---|---|---|
| Chave ou coordenadas não configuradas | — (não é chamado) | `503` | *"A previsão do tempo ainda não foi configurada no servidor."* |
| Chave inválida ou ainda não ativada | `401` | `502` | *"O serviço de previsão do tempo está indisponível no momento."* |
| Limite de consultas atingido | `429` | `503` | *"O limite de consultas à previsão do tempo foi atingido. Tente novamente mais tarde."* |
| Serviço fora do ar | `5xx` | `502` | *"O serviço de previsão do tempo está indisponível no momento."* |
| Serviço não respondeu em 6 s | — | `504` | *"O serviço de previsão do tempo demorou para responder. Tente novamente."* |
| Falha de rede do servidor | — | `502` | *"Não foi possível consultar o serviço de previsão do tempo."* |
| Resposta que não é JSON ou sem `list` | `200` inválido | `502` | *"O serviço de previsão do tempo enviou dados inválidos."* |
| Backend desligado / celular sem rede | — | — | *"Sem conexão com o servidor. Verifique a internet e tente novamente."* |
| Backend não respondeu em 8 s | — | — | *"O servidor demorou para responder…"* |
| JSON do backend em formato inesperado | — | `200` | *"O servidor enviou uma resposta inválida."* |

O detalhe técnico (por exemplo, "chave recusada, 401") vai **só para o log do servidor**. O log nunca mostra a URL, porque ela contém a chave.

### 5.5 App ↔ Backend: envio e atualização (Etapa 5)

`POST /talhoes` e `PUT /talhoes/:id` (corpo JSON):

```json
{ "nome": "Talhão 05 - Pivô Leste", "cultura": "Trigo", "areaHa": 12.5, "estagio": "", "pivo": "", "status": "pendente" }
```

`POST /registros` e `PUT /registros/:id`:

```json
{ "talhaoId": 5, "insumo": "Fungicida", "tipo": "defensivo", "data": "2026-11-14", "quantidade": "0.5 L/ha", "responsavel": "", "observacoes": "" }
```

A resposta devolve o mesmo objeto com o `id` gerado pelo PostgreSQL. Erros de validação voltam como `400 {"erro": "...", "campos": {"campo": "motivo"}}`. Os detalhes estão em [`etapa-05.md`](etapa-05.md#5-tratamento-de-entradas-inválidas).

## 6. Tratamento dos Estados

A consulta da previsão tem quatro estados explícitos no código (`sealed class EstadoPrevisao` em `lib/widgets/previsao_tempo_card.dart`), e cada um tem apresentação própria:

| Estado | Classe | Detalhe do talhão | Formulário de registro |
|---|---|---|---|
| **Carregando** | `PrevisaoCarregando` | Indicador de progresso + *"Consultando a previsão do tempo…"* | *"Consultando a previsão para 14/11/2026…"* |
| **Sucesso** | `PrevisaoCarregada` | Lista de até 5 dias ("Hoje", "Amanhã", "sex., 15/11"), cada um com ícone, descrição, faixa de temperatura, chuva, vento, motivo e o selo **Favorável** (verde, ✓) ou **Evitar** (laranja); no rodapé, fonte e horário da atualização | Previsão do dia escolhido, com selo e motivo |
| **Erro** | `PrevisaoComErro` | Ícone de nuvem cortada, a mensagem da tabela 5.4 e o botão **"Tentar de novo"** | Igual, dentro do cartão do formulário |
| **Ausência de dados** | `PrevisaoSemDados` (lista `dias` vazia) | *"Nenhuma previsão disponível para a localização da fazenda no momento."* + **"Consultar de novo"** | Idem; e, se a data escolhida estiver fora dos 5 dias cobertos: *"Sem previsão do tempo para 24/11/2026: ela fica disponível apenas para os próximos 5 dias."* |

Outros cuidados:

- **Acessibilidade:** o conteúdo do cartão é uma *live region*, então o leitor de tela anuncia quando o carregamento termina em sucesso ou erro. Cada dia é lido como uma frase só, o selo diz "Favorável para aplicar" ou "Evitar aplicação" e a situação nunca é mostrada só pela cor (cor, ícone e texto, como no selo de status do talhão). O cartão passa nos testes de contraste e de rótulo de alvos de toque do Flutter.
- **Sem servidor configurado** (modo só local, usado nos testes da Etapa 4), o cartão não aparece.
- **Datas passadas** não consultam a previsão: lançar uma aplicação já feita não depende do tempo.
- **Falha não trava nada:** a previsão é informativa, então o formulário pode ser salvo mesmo com o cartão em erro.
- **Cache:** o app reaproveita por 10 minutos a previsão já recebida. Ao abrir o formulário a partir do detalhe, a previsão aparece na hora, sem carregar de novo. Erros não ficam guardados: "Tentar de novo" sempre faz uma nova requisição.
- O status da conexão (Ajustes e faixa do Dashboard) também é atualizado pela consulta da previsão. Se o backend responde, mesmo com erro do serviço externo, o servidor continua "conectado"; se o backend não responde, o app passa para "sem conexão".

Nas operações da Etapa 5 (criar, editar e excluir talhões e registros), os estados continuam tratados assim: **carregando** = botão "Salvar" com indicador e desabilitado, e "puxar para atualizar" no Dashboard; **sucesso** = SnackBar verde; **erro** = SnackBar vermelho com a mensagem da API e a faixa "Sem conexão com o servidor" com "Tentar de novo"; **ausência de dados** = estados vazios ("Nenhuma aplicação lançada para este talhão.", Dashboard e Histórico sem itens).

## 7. Configuração do Serviço

Nenhuma credencial está no repositório. O arquivo `backend/.env` está no `.gitignore`, e o `backend/.env.example` traz só nomes de variáveis e valores de exemplo, sem chave.

1. Crie uma conta gratuita em <https://home.openweathermap.org/users/sign_up>.
2. Depois de confirmar o e-mail, copie a chave em **API keys** (<https://home.openweathermap.org/api_keys>). **Chaves novas podem levar até 2 horas para serem ativadas**; antes disso o serviço responde `401` e o app mostra *"O serviço de previsão do tempo está indisponível no momento."*.
3. No `backend/.env`, que é criado a partir do `.env.example`, preencha:

   | Variável | Obrigatória | Exemplo | Descrição |
   |---|---|---|---|
   | `OPENWEATHER_API_KEY` | sim | *(sua chave)* | Chave do OpenWeatherMap. Fica só no servidor. |
   | `FAZENDA_LAT` | sim | `-17.7923` | Latitude da fazenda, em graus decimais (sul é negativo) |
   | `FAZENDA_LON` | sim | `-50.9192` | Longitude da fazenda (oeste é negativo) |
   | `OPENWEATHER_URL` | não | `https://api.openweathermap.org/data/2.5` | Só para apontar para um servidor simulado em testes |

4. Reinicie a API (`npm run dev`). Sem a chave, a API sobe normalmente, avisa no terminal *"Previsão do tempo desativada…"* e a rota responde `503`; o restante do app continua funcionando.

O **app não precisa de nenhuma configuração nova**: continua usando apenas o `API_URL` da Etapa 5.

## 8. Instruções para Executar e Testar a Integração

### 8.1 Subir o backend e o app

```bash
cd backend
npm install
cp .env.example .env        # preencha OPENWEATHER_API_KEY (seção 7)
docker compose up -d        # PostgreSQL local
npm run seed                # carga de exemplo (só se o banco estiver vazio)
npm run dev                 # API em http://localhost:3000
```

Conferência rápida, no navegador ou com `curl`: `http://localhost:3000/clima/previsao` deve devolver o JSON da seção 5.3.

```bash
# na raiz do projeto, em outro terminal
flutter pub get
flutter run                                                        # emulador Android → http://10.0.2.2:3000
flutter run --dart-define=API_URL=http://<IP-do-computador>:3000   # aparelho físico na mesma rede
```

### 8.2 Roteiro de teste manual

1. **Sucesso:** entre no app, toque em um talhão. O cartão **"Condições para aplicação"** mostra o indicador de carregamento e depois os 5 dias com os selos *Favorável* ou *Evitar*.
2. **Formulário:** no detalhe, toque em **"Novo registro"** e escolha a data de amanhã. Abaixo do campo aparece *"Previsão para dd/mm/aaaa"* com o selo e o motivo, sem novo carregamento, porque a previsão foi reaproveitada.
3. **Ausência de dados:** escolha uma data daqui a 10 dias. Aparece *"Sem previsão do tempo para …: ela fica disponível apenas para os próximos 5 dias."*. Escolha uma data passada: o cartão some.
4. **Erro do serviço externo:** apague o valor de `OPENWEATHER_API_KEY` no `.env` e reinicie a API. Feche e reabra o app, porque ele reaproveita por 10 minutos a previsão já recebida, e abra um talhão: aparece *"A previsão do tempo ainda não foi configurada no servidor."* com **"Tentar de novo"**. Com uma chave errada, a mensagem é *"O serviço de previsão do tempo está indisponível no momento."*.
5. **Sem conexão:** pare a API (`Ctrl+C`), feche e reabra o app e abra um talhão. O cartão mostra *"Sem conexão com o servidor…"* com **"Tentar de novo"**. Suba a API novamente e toque no botão: a previsão volta.

### 8.3 Testes automatizados

```bash
cd backend
npm test            # 25 testes (13 da Etapa 5 + 12 da previsão do tempo), sem internet e sem chave
npm run typecheck

cd ..
flutter analyze
flutter test        # 37 testes (25 das Etapas 3 a 5 + 12 da previsão do tempo)
```

| Arquivo | O que cobre |
|---|---|
| `backend/test/clima.test.ts` (12) | URL e parâmetros enviados ao OpenWeatherMap; resumo por dia no fuso da fazenda (temperaturas, umidade média, vento em km/h, chuva total); janelas favoráveis e motivo de cada restrição (vento, chuva, dia sem período diurno); intervalo malformado ignorado; cache de 30 min; lista vazia (ausência de dados); `503` sem chave e com coordenadas inválidas; `401` → `502` sem expor a chave; `429` → `503`; tempo esgotado → `504`; falha de rede; resposta não JSON ou sem `list`; erro não fica em cache. O OpenWeatherMap é simulado por um `fetch` falso. |
| `test/previsao_tempo_test.dart` (12) | Cliente: rota e método, conversão do JSON, textos formatados, reaproveitamento da previsão, mensagem do servidor nos erros `502`/`503`, JSON inesperado, modo sem servidor. Cartão do detalhe: **carregando → sucesso**, **erro → "Tentar de novo" → sucesso**, **sem conexão**, **ausência de dados**, além de contraste e rótulos de toque. Formulário: previsão da data escolhida, data além de 5 dias, data passada sem consulta. |
| Demais arquivos | Testes das Etapas 3 a 5, mantidos sem alteração e passando. |

### 8.4 Verificação de ponta a ponta realizada

Com o PostgreSQL no Docker e a API rodando de verdade:

- **Servidor simulado do OpenWeatherMap** (mesmo formato de resposta, via `OPENWEATHER_URL`): `GET /clima/previsao` devolveu 5 dias com janelas e restrições coerentes com os dados. O `PlotterCrud` do app consultou a previsão e, na mesma execução, criou um talhão e um registro agendado, alterou o registro, sincronizou e excluiu tudo. O servidor simulado recebeu **uma única** requisição para duas consultas, o que confirma o cache.
- **OpenWeatherMap real** com uma chave inválida, de propósito: o serviço respondeu `401 Invalid API key`, a API devolveu `502` com *"O serviço de previsão do tempo está indisponível no momento."*, o log registrou a dica sobre a chave e a chave não apareceu na resposta. Isso confirma a comunicação real pela internet e o tratamento de erro.
- **Sem chave no `.env`:** `503` com *"A previsão do tempo ainda não foi configurada no servidor."* e o aviso no terminal na inicialização.
- **API desligada:** o app recebeu *"Sem conexão com o servidor…"* e passou para o status offline.

## 9. Principais Decisões Técnicas

1. **OpenWeatherMap, endpoint de 5 dias / 3 horas:** é o serviço da proposta e está no plano gratuito. O *One Call 3.0*, mais completo, exige cadastro de pagamento.
2. **Integração pelo backend, e não direto no app:** protege a chave, reduz os dados no celular, centraliza a regra agronômica e permite cache compartilhado (seção 3).
3. **`fetch` nativo do Node 20**, sem biblioteca nova, com `AbortSignal.timeout(6 s)`. O limite é menor que os 8 s do app, para que o usuário receba a mensagem específica do serviço externo e não um tempo esgotado genérico.
4. **Códigos HTTP distintos para falhas do serviço externo** (`502`, `503`, `504`). O app mostra a mensagem do servidor só nesses casos; para `500` continua com a mensagem genérica, sem expor detalhes internos.
5. **Avaliação por intervalo de 3 h, e não por média do dia:** um dia pode ter manhã boa e tarde chuvosa. O produtor precisa saber se existe uma janela e em que horário.
6. **Agrupamento por dia no fuso da fazenda** (`city.timezone`), e não no fuso do servidor ou em UTC. Sem isso, a previsão da noite cairia no dia errado.
7. **Coordenadas da fazenda no `.env`:** os talhões ainda não têm localização própria, e talhões de uma mesma fazenda ficam a poucos quilômetros uns dos outros, então a previsão é praticamente a mesma.
8. **Previsão não é gravada no SQLite:** é um dado que envelhece em horas. Mostrar uma previsão antiga sem conexão poderia induzir uma aplicação na hora errada, então sem conexão o app mostra o erro.
9. **Estados como `sealed class`:** o `switch` do Dart obriga a tratar os quatro estados, e o compilador acusa se algum for esquecido.
10. **Ícones do Material**, e não as imagens do OpenWeatherMap: não dependem de download e seguem o tema do app.
11. **Testes sem internet:** o backend injeta um `fetch` falso no `ServicoClima`, e o app usa `MockClient`. A verificação real foi feita à parte (seção 8.4).

## 10. Arquivos Criados ou Alterados na Etapa 6

| Arquivo | Situação | Papel |
|---|---|---|
| `backend/src/clima.ts` | novo | `ServicoClima`: chamada ao OpenWeatherMap, tempo limite, cache, tradução de erros, resumo por dia e avaliação para pulverização. |
| `backend/src/routes/clima.ts` | novo | Rota `GET /clima/previsao`. |
| `backend/test/clima.test.ts` | novo | Testes da integração com o serviço externo simulado. |
| `backend/src/app.ts` | alterado | Registra a rota `/clima` e recebe o `ServicoClima` por parâmetro. |
| `backend/src/server.ts` | alterado | Lê a configuração do clima no `.env` e avisa se estiver desativada. |
| `backend/.env.example` | alterado | Variáveis `OPENWEATHER_API_KEY`, `FAZENDA_LAT`, `FAZENDA_LON` e `OPENWEATHER_URL`, sem a chave. |
| `lib/models/previsao_tempo.dart` | novo | Modelos `PrevisaoTempo` e `PrevisaoDia`, com `fromJson` e textos formatados. |
| `lib/widgets/previsao_tempo_card.dart` | novo | Estados da consulta, `PrevisaoTempoCard` (detalhe), `PrevisaoDoDiaCard` (formulário) e `SeloPulverizacao`. |
| `test/previsao_tempo_test.dart` | novo | Testes do cliente e dos quatro estados na interface. |
| `lib/data/plotter_api.dart` | alterado | `previsaoDoTempo()`; mensagens do servidor para `502`, `503` e `504`. |
| `lib/data/plotter_crud.dart` | alterado | `previsaoDoTempo()`, `previsaoRecente` (cache de 10 min) e `previsaoDisponivel`. |
| `lib/screens/talhao_detail_screen.dart` | alterado | Cartão "Condições para aplicação". |
| `lib/screens/novo_registro_screen.dart` | alterado | Previsão da data escolhida (hoje em diante). |
| `lib/screens/ajuda_screen.dart` | alterado | Item de ajuda sobre a previsão do tempo. |
| `README.md` | alterado | Funcionalidades, configuração e limitações da Etapa 6. |

## 11. Limitações Conhecidas

- **Uma localização para a fazenda inteira:** todos os talhões usam a mesma previsão. Guardar coordenadas por talhão fica para uma etapa futura.
- **Horizonte de 5 dias**, limite do plano gratuito. Aplicações agendadas para mais longe mostram o aviso de ausência de previsão.
- **Regra agronômica simplificada:** os limites (vento, chuva, temperatura e umidade) são valores usuais de referência e não consideram o produto, o bico ou a cultura. Também não são avaliados vento fraco demais (risco de inversão térmica) nem chuva nas horas seguintes ao intervalo.
- **Previsão não fica disponível offline**, por decisão (seção 9, item 8).
- O cache do servidor fica em memória: ao reiniciar a API, a primeira consulta vai ao OpenWeatherMap novamente.
- As limitações da Etapa 5 continuam: sem autenticação, HTTP sem TLS em desenvolvimento e gravações offline não enfileiradas.
