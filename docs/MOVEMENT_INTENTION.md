> Atualização: o avanço lógico agora está em back/application/services/character_movement.gd. CharacterMovement recebe GridCoordinates no construtor e oferece update(character, delta, movement_speed = 80.0). RuntimeCharacter mantém apenas dados e operações de intenção/parada, sem depender de serviços da aplicação. O mecanismo ainda não está conectado a um step da API.

# Intenção de movimento — revisão aplicada

## Fluxo atual

Clique direito -> posição local do World -> GameApi.move_character()
-> MoveCharacterUseCase -> pathfinding -> RuntimeCharacter.begin_movement()
-> bool + diagnóstico -> novo snapshot -> animação correspondente.

Ainda não existe deslocamento. WALKING significa intenção pendente; o personagem
anima corrida no mesmo lugar até implementarmos step().

## Responsabilidades

- API valida a entrada DTO, adapta para MapPosition e propaga o resultado real.
- Use case busca personagem, converte coordenadas, calcula rota e rejeita falhas
  antes de efetivar alterações. Também fornece last_error.
- Entidade copia a rota e mantém juntos estado, índice e rota.
- Apresentação envia o ID controlado e reflete o snapshot confirmado.

## Métodos da entidade

begin_movement(new_path, next_index=0) -> bool

Constrói cópias de cada Cell antes de substituir campos. Entrada vazia, célula
nula ou índice inválido retorna false sem apagar o movimento anterior.
Receber o próprio character.path também funciona, pois não limpamos antes de copiar.

Quando next_index aponta para um centro pendente, registra WALKING. Quando aponta
para o fim da rota, chama stop_movement().

stop_movement()

Limpa a rota, reinicia next_cell_index=0 e registra IDLE.
Os antigos set_path()/clear_path() foram substituídos por essas operações.

## Índice

O use case pula somente os centros em que o personagem já está, com tolerância
de 0,000001 unidade. Não assume sempre índice 1. Se o personagem estiver fora do
centro da própria célula, a primeira célula ainda pode ser um ponto a alcançar.

Na posição inicial (24,136), pedir uma rota para outra célula livre começa no
índice 1. Clicar novamente no centro inicial termina a intenção e fica IDLE.

## Rejeição e apresentação

Destino bloqueado, fora do mapa, sem acesso, ID inexistente ou coordenadas
inválidas: false e last_error, sem alteração da intenção anterior.

GameScreen guarda controlled_runtime_id. No MVP de um único personagem, o vínculo
é feito uma única vez na abertura. Também é possível fornecê-lo no terceiro
argumento opcional de configure(). Não há seleção do primeiro personagem a cada clique.

Após um comando aceito, GameScreen pede e aplica o novo snapshot. Rejeições ficam
disponíveis em last_move_error, sem imprimir erros esperados como falhas da engine.
CharacterView escolhe run para WALKING e idle para IDLE, sem reiniciar a animação
a cada aplicação do mesmo estado. As duas animações estão em loop.

## Nomes e estilo

Corrigidos runtime_chracter, npf_service e path_finding_service.
Todos os 28 scripts com class_name foram verificados: extends vem antes de class_name.
O novo teste de movimento e os testes existentes sem class_name também começam por extends.

## Validação

Godot 4.4.1: seis suítes, 117.531 verificações, zero falhas.
Inclui 40 verificações novas de intenção, rejeição, cópias, autoatribuição, parada,
origem fora do centro e atualização visual. Os testes existentes foram atualizados
para os cinco argumentos atuais do construtor de GameApi.

Para executar o recorte novo:

```powershell
godot --headless --path . --script res://tests/move_character_test.gd
```

Não foram acrescentados estados, eventos de combate, interfaces genéricas ou novas
camadas. O próximo comportamento é consumir a rota no step e avançar a posição.
