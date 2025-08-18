# Documentação de Funcionamento - Championship Manager
Este documento descreve as principais funcionalidades e a arquitetura do aplicativo, servindo como um guia para futuras manutenções e desenvolvimento.

### 1. Arquitetura e Fluxo Principal
O aplicativo é inicializado em `main.dart`, que configura o Firebase, o tema global da aplicação e define o ponto de entrada.

O fluxo de autenticação é gerenciado pelo widget `auth_page.dart`, que utiliza um `StreamBuilder` para "ouvir" o estado de login do usuário e decidir qual tela exibir: `tela_login.dart` ou `tela_menu_principal.dart`.

#### Pontos de Atenção:
- **Tema Global**: Quase todo o estilo visual (cores, fontes, bordas de botões e campos de texto) é centralizado no `ThemeData` dentro de `main.dart`. Para mudanças visuais globais, comece por este arquivo.
- **Cores e Estilos de Texto**: As cores e estilos de fonte reutilizáveis estão definidos em `app_colors.dart` e `text_styles.dart` respectivamente.

### 2. Autenticação de Usuário
O fluxo de autenticação é composto por três telas principais:

- `tela_login.dart`: Permite que um usuário existente entre no aplicativo. Ela possui uma lógica de carregamento local (dentro do botão) e faz a verificação de internet antes de tentar o login.
- `tela_cadastro.dart`: Permite que um novo usuário crie uma conta. Utiliza o widget reutilizável `password_validation_fields.dart` para a validação da senha em tempo real e também possui lógica de carregamento local e verificação de internet.
- `tela_reautenticacao.dart`: É chamada antes de ações sensíveis (trocar e-mail, excluir conta) para confirmar a identidade do usuário, exigindo que ele digite sua senha novamente.

#### Pontos de Atenção:
- As telas de Login e Cadastro possuem sua própria lógica de verificação de internet e `loading` para oferecer uma experiência de UI específica (`loading` dentro do botão). As demais telas utilizam o assistente global.

### 3. Criação de Campeonato
Este é um fluxo de múltiplas telas para coletar as informações necessárias para um novo campeonato.

1. `tela_modo_campeonato.dart`: O usuário seleciona o tipo de campeonato. O modo selecionado é passado para as telas seguintes.
2. `tela_nome_campeonato.dart`: O usuário define o nome do campeonato. Esta tela verifica no Firestore se já existe um campeonato com o mesmo nome para aquele usuário.
3. `tela_adicionar_jogadores.dart`: O coração da criação. O usuário adiciona os jogadores. Ao clicar em "Avançar" (`_avancar`), a função:
    - Verifica a conexão com a internet usando o assistente global.
    - Gera a estrutura de partidas com base no modo de jogo (`_gerarPartidasPorRodada`).
    - Cria o documento principal do campeonato no Firestore, incluindo a tabela de classificação inicial.
    - Salva todas as partidas em uma subcoleção.
    - Navega para a tela principal do campeonato, limpando o histórico de navegação.

#### Pontos de Atenção:
- A função `_gerarPartidasPorRodada` em `tela_adicionar_jogadores.dart` contém o algoritmo Round-robin para o sorteio dos jogos. Qualquer mudança na lógica de sorteio deve ser feita aqui.

### 4. Gerenciamento de Campeonato
- `tela_principal_campeonato.dart`: É o painel de controle de um campeonato ativo. Ela é responsável por carregar todos os dados do campeonato do Firestore (`_carregarDadosDoCampeonato`) e exibi-los. O recarregamento dos dados acontece sempre que o usuário volta de uma tela que pode ter modificado o estado (como `tela_inserir_resultado.dart` ou `tela_cronograma.dart`).
- `tela_cronograma.dart`: Exibe todas as partidas, agrupadas por rodada. Ela busca os dados mais recentes do Firestore e permite que o usuário navegue para a edição de qualquer partida.
- `tela_campeao.dart`: Uma tela visual para celebrar o fim do campeonato, exibindo o campeão e um troféu sorteado.

### 5. Lógica Central: Cálculo de Resultados
A função mais complexa e crítica do aplicativo é a `_finalizarPartida` dentro de `tela_inserir_resultado.dart`.

#### Responsabilidades:

1. Verificar a conexão com a internet.
2. Buscar os dados mais recentes do campeonato no Firestore.
3. **Reverter o placar antigo**: Se a partida estiver sendo editada, a função primeiro subtrai todos os pontos, vitórias, gols, etc., que o resultado anterior havia gerado.
4. **Aplicar o novo placar**: Adiciona os pontos, vitórias, gols, etc., com base no novo resultado inserido.
5. **Ordenar a classificação**: Aplica todos os critérios de desempate (Pontos > Vitórias > SG > GP > Confronto Direto > Sorteio).
6. **Finalizar o campeonato**: Verifica se a partida jogada foi a última. Se sim, atualiza o status do campeonato, define o campeão e sorteia um troféu.
7. Salvar todas as alterações (partida e classificação) no Firestore usando um WriteBatch.

##### Pontos de Atenção:
- Esta função é o "cérebro" do campeonato. Qualquer alteração nos critérios de desempate ou na forma como os pontos são calculados deve ser feita aqui.
- A lógica de ordenação (sort) é particularmente sensível.

## 6. Widgets Reutilizáveis
Para manter a consistência visual e o código limpo, criamos vários widgets reutilizáveis na pasta `app/lib/widgets/`:

- `background_scaffold.dart`: O esqueleto de todas as nossas telas, com a imagem de fundo e a lógica para não redimensionar com o teclado.
- `square_icon_button.dart`: O botão quadrado com ícone SVG, usado em rodapés e ações.
- `menu_button.dart`: O botão de menu principal, com ícone (círculo ou quadrado) e texto.
- `selection_button.dart`: O botão retangular com um `SquareIconButton` na direita, usado em listas e na tela de configurações.
- `password_validation_fields.dart`: O conjunto de campos de senha e confirmação com validação em tempo real.

E outros mais específicos como `match_row_widget.dart`, `round_card_widget.dart`, etc.

### 7. Utilitários
A pasta `app/lib/utils/` contém funções "assistentes" globais:

- `connectivity_utils.dart`: Centraliza toda a lógica de verificação de internet, exibição de `loading` e tratamento de timeout/erros. Ponto de atenção: Se precisar mudar o tempo de timeout ou a forma como a conexão é verificada, altere aqui.
- `popup_utils.dart`: Contém as funções mostrarPopupAlerta e mostrarPopupConfirmacao para padronizar os diálogos do aplicativo.
- `validators.dart`: Contém a lógica de validação de formato de e-mail.