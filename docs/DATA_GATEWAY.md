# Catálogo de dados estáticos e estado runtime

## Fluxo de inicialização

```text
Main
  -> DataGateway.load_all()
       -> GameDataLoader lê e valida os JSONs
       -> converte registros em CharacterProfile e MapProfile
       -> cria CharacterRepository e MapRepository, indexados por ID
       -> publica os dois repositórios e marca is_ready
  -> GameApi.new(gateway)
  -> configura e exibe a tela
```

O carregamento é único por instância de gateway. Chamadas seguintes a load_all()
não reabrem arquivos. Não há Autoload novo nem leitura de disco em consultas.

O gateway é um catálogo em memória somente de leitura, não um banco transacional
ou sistema de persistência. A configuração dos registros continua nos JSONs.

## Organização

```text
back/domain/profiles/
  character_profile.gd
  map_profile.gd

back/domain/entities/
  runtime_character.gd
  runtime_map.gd
  game_state.gd

back/infrastructure/
  data_gateway.gd
  game_data_loader.gd
  repositories/
    character_repository.gd
    map_repository.gd
```

GameDataLoader concentra leitura, diagnóstico e mapeamento dos dois formatos.
DataGateway coordena, sem precisar conhecer detalhes de navegação ou apresentação.
Repositórios oferecem get_by_id(), get_all(), has_id() e count(), sem métodos
públicos de inserir, remover ou atualizar registros.

## Usar

```gdscript
var gateway := DataGateway.new()
if not gateway.load_all():
    push_error(gateway.last_error)
    return

var character_profile := gateway.get_character(0)
var map_profile := gateway.get_map(0)

var character := RuntimeCharacter.new("1", character_profile)
var map := RuntimeMap.from_profile(map_profile)

# Alternativa: consultar diretamente o repositório do gateway.
var all_characters := gateway.characters.get_all()
var exists := gateway.maps.has_id(0)
```

IDs inexistentes retornam null. Não gere outra entidade silenciosamente nesse caso.

## Contrato de isolamento dos registros

- O repositório copia os profiles recebidos ao ser construído.
- Cada consulta devolve uma cópia nova.
- get_all() também copia cada profile, não apenas o Array.
- Arrays de texturas são copiados.
- MapProfile copia o Array de células e CADA objeto Cell.
- RuntimeCharacter e RuntimeMap.from_profile() também copiam o profile recebido.

Assim, alterar nome, atributos, texturas ou células de um objeto obtido não muda
o registro armazenado. Uma consulta seguinte continua retornando o dado original.

Precisão importante: as cópias locais são mutáveis; os profiles não são objetos
congelados. O contrato é que o catálogo original não seja alterável por consultas.
Campos com prefixo _ são detalhes internos por convenção do GDScript, não uma
barreira de segurança contra código que deliberadamente acesse esses campos.

Esse isolamento deve ser mantido ao adicionar campos: se houver novas coleções
ou objetos aninhados, atualizar copy() e os testes. Se um dia surgirem referências
cíclicas, a cópia precisará usar um contexto de objetos já copiados para não
recursar infinitamente. Esse mecanismo não foi antecipado agora.

## Profile e runtime

CharacterProfile contém o registro estático: ID, nome, agilidade e identificadores
de textura. RuntimeCharacter contém runtime_id, character_profile, estado,
posição e progresso da rota.

MapProfile contém ID, nome, dimensões, identificadores de textura e bloqueios
iniciais. RuntimeMap contém uma grade mutável independente para a partida.
O pathfinding agora recebe RuntimeMap; a implementação de A* não foi alterada.

Modificar os bloqueios de RuntimeMap não muda MapProfile nem futuras partidas.
O construtor por dimensões de RuntimeMap foi preservado para mapas de teste,
enquanto from_profile() monta o mapa proveniente dos registros estáticos.

Referenciar CharacterProfile em RuntimeCharacter é adequado: a instância em jogo
sabe qual definição representa. O nome character foi ajustado para character_profile
para explicitar isso. O snapshot mapper lê o nome a partir desse profile.

## Formato e validação

Os JSONs existentes foram preservados, inclusive nomes e obstáculos.

- Raiz deve ser um objeto com data como Array.
- IDs devem ser inteiros não negativos e únicos na tabela.
- Nomes e identificadores de textura não podem ser vazios.
- Agilidade deve ser finita e não negativa; não foi definida uma regra de velocidade.
- map_size é [rows, columns]: [15, 17].
- occupied_cells é uma lista de [row, column].
- Dimensões devem ser positivas; células devem estar dentro do mapa e sem duplicação.
- textures permanece uma lista de identificadores, não de Texture2D carregadas.

O loader não valida caminhos de imagens: map01_texture é um identificador de
apresentação, que o carregador visual deverá resolver quando a tela do mapa existir.

Falhas retornam false em load_all(), com last_error descritivo e is_ready=false.
Nenhum repositório parcialmente carregado é publicado. Pode tentar carregar
novamente após corrigir o erro. Uma tabela vazia é estruturalmente válida, mas
os casos de uso ainda devem verificar se os IDs exigidos existem.

Não há referências entre registros nos JSONs atuais. O ponto para uma futura
etapa de hidratação fica após ler/mapear todas as tabelas e antes de publicá-las.

## Integração preservada

- Main carrega o gateway e o injeta em GameApi.
- O personagem de preview agora vem do registro 0 de characters.json.
- A tela antiga de preview foi removida. A partida renderiza apenas o personagem
  carregado do banco; characters.json contém um personagem.
- GameState, SnapshotMapper e CharacterDto tiveram referências antigas de Character
  atualizadas para RuntimeCharacter.
- CharacterDto ainda referencia o enum de RuntimeCharacter, como já ocorria com
  Character; mover o enum para um contrato compartilhado fica para uma mudança própria.

Ao preparar a exportação, garantir a inclusão dos JSONs de assets/data no pacote.

## Verificação

Na pasta do projeto, substituindo godot pelo executável Godot 4.4.1:

```powershell
godot --headless --editor --import
godot --headless --path . --script res://tests/data_gateway_test.gd
godot --headless --path . --script res://tests/pathfinding_test.gd
```

Resultado: 78 verificações da camada de dados e 117.351 verificações de pathfinding,
todas sem falhas. Testados campos inválidos, IDs duplicados, arquivo ausente, JSON
malformado, atomicidade do carregamento, cópias profundas, criação runtime,
snapshot e inicialização da tela. A suíte de navegação segue comparando com Dijkstra.

As fixtures gateway_malformed.json e gateway_wrong_root.json são propositalmente
inválidas e existem só para testes. Não são arquivos do banco em assets/data.
