# Step da partida

## Contrato público

`GameApi.step_game() -> GameStateDto`

Sem argumentos. Cada chamada representa 1/60 de segundo de simulação, e não o
tempo real decorrido desde a última chamada. Antes de start_game(), retorna null
e preenche last_error. get_game_state() continua sendo só leitura, sem avançar tempo.

## Fluxo

```text
Main._physics_process()
    -> API.step_game()
        -> StepGameUseCase.execute(GameState)
            -> CharacterMovement.update(character, 1/60) para cada personagem
            -> SnapshotMapper.game_state_to_dto(GameState)
    -> GameScreen.apply_snapshot(dto)
```

Main é o único dono do relógio da partida. O projeto foi configurado explicitamente
para 60 atualizações físicas por segundo. Não chame step_game() de cada view nem
também em _process(), pois cada chamada adicional avança tempo adicional.
Se mudar a frequência, ajuste conjuntamente StepGameUseCase e project.godot.

O mesmo GameState é atualizado; não se cria outra partida em cada step.
Só depois de atualizar TODOS os personagens é gerado um snapshot novo, desconectado
dos objetos vivos. Não há armazenamento de snapshots anteriores no back.

## Divisão de responsabilidades

- RuntimeCharacter: posição, intenção, estado, rota e progresso; begin/stop_movement.
- CharacterMovement: executa o comportamento de movimento e ignora IDLE.
- StepGameUseCase: coordena uma atualização completa e a produção do snapshot.
- GameState: contém entidades e mapa, sem depender de serviços de aplicação.
- Main: liga o ciclo físico da engine ao endpoint e à apresentação.

A proposta de entidades terem step() também seria possível. Não é uma exigência
do DDD. Aqui foi mantida a escolha anterior de extrair movimento, evitando
reinjetar GridCoordinates/CharacterMovement em cada entidade.
Não foram criadas classes separadas para IDLE e WALKING.

## Velocidade

Foi preservada a regra `movement_speed = 40.0 * character.character_profile.agility`.
Agilidade 1: 40 unidades/s, ou 2,5 células retas/s.
Agilidade 2: 80 unidades/s, ou 5 células retas/s.
O serviço recebe apenas personagem e delta, como você alterou.

Corrigido o acesso ao profile antes da checagem de personagem nulo.
Adicionada tolerância de chegada de 0,000001 unidade para não deixar WALKING
por um tick extra quando a soma de passos tem erro de arredondamento.

## DI e testes

Main cria uma única instância de CharacterMovement usando o mesmo GridCoordinates
da partida. GameApi a recebe no sexto argumento e a entrega ao StepGameUseCase.
Os testes foram atualizados para esse construtor e para a velocidade por agilidade.

Em Godot 4.4.1 passaram 22 verificações do step, 34 de movimento, 40 de intenção,
25 de início/apresentação, 78 do gateway, 14 do mapper e 23 de input: 236 no total.
Testados dois personagens com agilidades distintas, 60 ticks equivalendo a um
segundo lógico, independência de snapshots, chegada e mudança visual para idle.

```powershell
godot --headless --path . --script res://tests/step_game_test.gd
```

Foi observado um aviso de recurso GDScript de CharacterProfile retido ao encerrar
a execução headless. Os testes funcionais passam; esse aviso de encerramento
permanece pendente, sem modificar o contrato do banco ou os profiles para contorná-lo.
