# Proposta Técnica/Comercial - Plotter

**Disciplina:** Tecnologia e Construção de Software 2
**Etapa:** 01 - Proposta e planejamento da aplicação mobile
**Autor:** Lucas Carvalho Pacheco
**Data:** 26/08/2026

## 1. Nome da Aplicação
**Plotter** 

## 2. Problema que a Aplicação Pretende Resolver
Os produtores rurais enfrentam grande desorganização no controle diário das atividades de campo. Atualmente, o registro de aplicações de defensivos, fertilizantes e cronogramas de manejo é feito de forma dispersa em anotações de papel ou cadernos. Isso gera perda de dados, falta de rastreabilidade e confusão sobre o que já foi aplicado e o que ainda está pendente em cada área.

## 3. Público-Alvo
Produtores agrícolas, gerentes de fazenda e operadores de campo que trabalham diretamente no manejo diário de lavouras divididas em talhões ou pivôs.

## 4. Objetivo Principal
Centralizar e organizar em um único software mobile todas as atividades agrícolas diárias da fazenda, permitindo que o produtor visualize de forma rápida e clara o status operacional de cada talhão.

## 5. Descrição das Principais Funcionalidades
- **Gerenciamento de Talhões/Pivôs:** Visualizar a fazenda dividida em áreas específicas (talhões).
- **Histórico de Aplicações:** Registrar e consultar insumos (defensivos e fertilizantes) aplicados em cada talhão.
- **Notificações:** Alertas push proativos avisando o produtor sobre aplicações agendadas (ex: "aplicação agendada para amanhã").
- **Status de Tarefas (Feito vs. Pendente):** Painel visual indicando o andamento das operações de cada área.
- **Sincronização Offline:** Capacidade de registrar dados mesmo sem internet no campo, sincronizando-os automaticamente quando houver conexão (essencial para o contexto rural).

## 6. Telas Previstas para a Aplicação
1. **Login/Perfil:** Tela de autenticação do usuário (gerente ou operador), com controle de permissões de acesso conforme o papel de cada um na fazenda.
2. **Dashboard (Home):** Lista dos talhões ativos com indicadores visuais rápidos (ex: "Sem pendências", "Aplicação atrasada").
3. **Detalhes do Talhão:** Detalhamento do talhão selecionado, exibindo a cultura plantada, estágio atual e resumo do último manejo.
4. **Cadastro/Edição de Talhão:** Tela para criar um novo talhão ou editar informações de um já existente (cultura, área, pivô associado).
5. **Histórico e Agenda:** Cronograma interativo exibindo a linha do tempo do que já foi aplicado e o calendário das próximas aplicações planejadas.
6. **Novo Registro (Formulário):** Tela simples para o operador inserir rapidamente a aplicação de um produto (data, tipo de produto, dosagem, talhão aplicado).
7. **Relatórios/Indicadores:** Visão consolidada de todos os talhões, voltada ao gerente, com médias e indicadores gerais de produtividade e manejo.
8. **Configurações/Sincronização:** Tela para visualizar o status offline/online, forçar sincronização manual e conferir os últimos dados enviados ao servidor.

## 7. Fluxo Básico de Navegação

**Fluxo principal:**
Login/Perfil → Dashboard (Home) → Detalhes do Talhão → Histórico e Agenda → Novo Registro

**Ramificações a partir do Dashboard:**
Do Dashboard, o usuário também pode acessar diretamente as telas de Cadastro/Edição de Talhão, Relatórios/Indicadores e Configurações/Sincronização, sem precisar passar pelas etapas do fluxo principal.

```text
Login/Perfil
      │
      ▼
Dashboard (Home)
      │
      ├──▶ Detalhes do Talhão ──▶ Histórico e Agenda ──▶ Novo Registro
      ├──▶ Cadastro/Edição de Talhão
      ├──▶ Relatórios/Indicadores
      └──▶ Configurações/Sincronização
```

## 8. Tecnologia Escolhida para o Desenvolvimento Mobile
**Flutter**

*Justificativa:* Flutter é ideal para o projeto por permitir alta performance na renderização de mapas de talhões e suporte nativo robusto para persistência de dados em banco local offline.

## 9. Tecnologia Escolhida para o Backend
**Node.js (com Express e TypeScript)**

*Justificativa:* O Node.js foi escolhido por seu ecossistema maduro e amplamente testado em produção, com bibliotecas prontas para praticamente todas as necessidades do projeto (autenticação, conexão com PostgreSQL, envio de notificações push e integração com APIs externas de clima). O uso de **TypeScript** adiciona tipagem estática ao código, reduzindo erros comuns em tempo de desenvolvimento e tornando a manutenção mais segura à medida que a API cresce. O **Express** complementa essa base fornecendo uma camada leve e flexível para criação de rotas REST, o que agiliza o desenvolvimento sem impor uma estrutura rígida. Somado a isso, a natureza assíncrona e orientada a eventos do Node.js é bem adequada ao caso de uso do Plotter, que envolve múltiplos dispositivos sincronizando dados simultaneamente após períodos offline.

## 10. Necessidade de Comunicação com APIs Externas
**Sim.** Comunicação com API de **Previsão do Tempo** (como *OpenWeatherMap*) para ajudar o produtor a planejar se as condições climáticas são seguras para as próximas aplicações de defensivos.

## 11. Forma Prevista de Armazenamento de Dados
- **Local:** Banco de dados **SQLite**.
- **Nuvem:** Banco relacional **PostgreSQL** hospedado no **Supabase**.

## 12. Repositório Git Contendo o Projeto Inicial
Link para o repositório no GitHub, com a Tag `etapa-01` criada no commit de entrega.

> _Repositório: [https://github.com/lcpachecoo/Plotter]_

## 13. Estrutura Inicial de Diretórios do Projeto

```text
Plotter/ 
├── docs/
│   └── proposta.md      <-- Este documento
├── README.md            <-- README explicativo do repositório
├── src/                 <-- Código-fonte do app
│   ├── assets/          <-- Imagens e ícones do sistema
│   ├── components/      <-- Componentes visuais reaproveitáveis
│   ├── screens/         <-- As 8 telas mapeadas na arquitetura
│   └── services/        <-- Camada de serviços e conexões de API
```

## Observação Final

Esta proposta representa o planejamento inicial do Plotter para a Etapa 1 do projeto. Decisões técnicas - como a estrutura do banco de dados, o mecanismo de resolução de conflitos na sincronização offline e o detalhamento de cada endpoint da API - serão refinadas nas próximas etapas de desenvolvimento, à medida que o protótipo evoluir e novos requisitos forem identificados junto ao público-alvo.