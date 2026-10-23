> Registro da primeira tela. A etapa seguinte já captura clique direito, prepara a intenção de movimento e alterna idle/run. Consulte MOVEMENT_INTENTION.md; o deslocamento por step ainda não foi implementado.

# Primeira tela da partida

## Ordem de execução

1. Main carrega os JSONs pelo DataGateway.
2. Constrói GameApi com o gateway já pronto.
3. Chama start_game(0, 0).
4. A API delega a criação ao StartGameUseCase.
5. O use case busca os profiles, cria RuntimeMap, valida Cell(8, 1), gera o ID
   e usa GridCoordinates.cell_to_center() para obter MapPosition(24, 136).
6. Cria RuntimeCharacter em IDLE e devolve GameState à API.
7. Main instancia e configura GameScreen e a entrega ao ScreenRoot.
8. No _ready(), GameScreen chama get_game_state() e monta a tela pelo DTO.

Não há step, movimento, input de gameplay ou cálculo de rota nessa entrega.

## Arquivos principais para estudar

- main.gd: composição e início da partida.
- back/api.gd: mantém o estado ativo e oferece start_game/get_game_state.
- back/application/use_cases/start_game_use_case.gd: criação da partida.
- back/snapshot_mapper.gd: inclui identificadores de textura do personagem.
- front/screens/game_screen.gd e .tscn: representação do snapshot.
- front/components/entities/character_view.gd e .tscn: personagem dentro do mundo.
- front/services/texture_loader.gd: resolve texturas de personagens e mapas.

## Dados e texturas

CharacterDto recebeu textures: Array[String], com cópia do array do profile.
Isso evita usar o nome de exibição Swordman como caminho de arquivo. O identificador
real do personagem é swordsman_m. O novo argumento do construtor é opcional,
preservando os usos antigos com quatro argumentos.

TextureLoader.load_map_texture("map01_texture") resolve o arquivo
res://assets/textures/scenario/maps/map01.png por uma tabela explícita do front.
O banco continua fornecendo identificadores, não Texture2D ou caminhos de nós.

## Coordenadas e apresentação

O mapa tem 272x240 pixels e é exibido no tamanho nativo, centralizado no viewport
640x360. World fica em (184,60); o Sprite2D do mapa tem centered=false, logo o canto
superior esquerdo corresponde à origem lógica (0,0).

O personagem recebe position=(24,136), relativa ao World. A soma com a posição do
World é apenas apresentação. A API nunca recebe esse deslocamento de tela.

O sprite de personagem usa frames de 80x80; os pés do asset estão aproximadamente
24 pixels abaixo do centro do frame. Por isso o filho Sprite tem offset (0,-24),
mantendo o Node2D da entidade como posição dos pés. Esse ajuste é visual e específico
do asset atual; futuros personagens podem precisar de offsets próprios.

A animação idle foi configurada como loop. Não foi reutilizado o comportamento de
preview que troca automaticamente idle/run/attack/action/death. A tela antiga de
preview e seus componentes foram removidos. Main abre somente GameScreen.

apply_snapshot() mantém um registro runtime_id -> CharacterView: reutiliza views
existentes, cria ausentes e remove as que não constam mais no snapshot. Hoje é chamado
uma vez ao abrir a tela; não há polling ou simulação automática.

## Retornos da API

- start_game(character_id, map_profile_id) -> bool.
- IDs inexistentes ou spawn bloqueado retornam false e preenchem last_error.
- Uma tentativa inválida não substitui uma partida já existente.
- get_game_state() -> GameStateDto; retorna null antes de começar uma partida.
- Cada início válido gera um novo runtime_id.

Spawn (8,1) é temporário e fica explícito no use case. Se editar o mapa e bloquear
essa célula, a criação falha com diagnóstico; não teleporta silenciosamente para
outro lugar. Quando necessário, mover o spawn para o MapProfile/JSON.

## Validação em Godot 4.4.1

- 25 verificações de início/apresentação: IDs, spawn livre, conversão, snapshots,
  textura real, centralização, reutilização de views, remoção e idle em loop.
- 78 verificações do gateway e 14 do snapshot mapper continuam passando.
- Imagem real renderizada conferida visualmente.

Executar da pasta do projeto, substituindo godot pelo executável:

```powershell
godot --headless --path . --script res://tests/game_start_test.gd
```

Use F5 para abrir normalmente. Se o editor pedir, recarregue os arquivos do disco.
