# ETAPA 7 — GERENCIAMENTO DE ESTADO GLOBAL E RECURSOS DO DISPOSITIVO

## Objetivo

Implementar gerenciamento de estado compartilhado e integrar a aplicação com pelo menos um recurso nativo do dispositivo.

## Enunciado

Implemente pelo menos um mecanismo de gerenciamento de estado que ultrapasse o escopo de uma única tela.

Além disso, integre pelo menos um recurso nativo do dispositivo, de acordo com a pertinência ao projeto.

Exemplos de recursos nativos:

* câmera;  
* galeria;  
* localização;  
* sensores;  
* notificações;  
* compartilhamento;  
* armazenamento de arquivos;  
* outros recursos equivalentes.

A funcionalidade escolhida deverá possuir integração real com a aplicação.

O aluno deverá explicar:

1. Qual estado foi tratado como global;  
2. Por que esse estado foi tratado como global;  
3. Qual recurso nativo foi utilizado;  
4. Quais permissões são necessárias;  
5. Como a aplicação trata falhas ou indisponibilidade do recurso.

A escolha do mecanismo de gerenciamento de estado e do recurso nativo deverá ser compatível com a tecnologia escolhida e com o escopo da aplicação.

### Entrega

A entrega deverá ser realizada no mesmo repositório Git utilizado nas etapas anteriores.

O aluno deverá:

1. Implementar o gerenciamento de pelo menos um estado compartilhado entre diferentes partes da aplicação;  
2. Integrar pelo menos um recurso nativo do dispositivo;  
3. Atualizar o README do projeto;  
4. Criar o arquivo docs/etapa-07.md, contendo:  
   * mecanismo de gerenciamento de estado utilizado;  
   * identificação dos estados tratados globalmente;  
   * justificativa para o tratamento desses estados como globais;  
   * recurso nativo utilizado;  
   * justificativa da escolha do recurso;  
   * permissões necessárias;  
   * descrição do fluxo de utilização do recurso;  
   * tratamento de falhas ou indisponibilidade do recurso;  
   * instruções para execução e teste;  
5. Criar a tag Git etapa-07;  
6. Fornecer o link para o repositório Git.

A avaliação será realizada prioritariamente pela inspeção do código-fonte e da execução da aplicação.

A documentação deverá auxiliar a identificação das funcionalidades, mas a existência e a implementação do gerenciamento de estado e do recurso nativo deverão ser verificáveis no código.

