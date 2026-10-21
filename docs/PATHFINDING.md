# Pathfinding lógico — guia de estudo

Implementado para Dungeon Academy, Godot 4.4.1.

## Onde ler, nesta ordem

1. `back/domain/entities/cell.gd`: uma coordenada (linha, coluna).
2. `back/domain/entities/map.gd`: dimensões e células ocupadas.
3. `back/application/services/pathfinding_service.gd`: busca A*.
4. `tests/pathfinding_test.gd`: mapas de exemplo e testes executáveis.

O contrato é `find_path(start: Cell, goal: Cell, map: Map) -> Array[Cell]`.
Retorna TODAS as células adjacentes, incluindo início e destino. Não há
suavização, pixels, centro de célula, conversão para posição, estado WALKING
ou movimentação. O serviço não modifica o mapa nem as células de entrada.

- Início e destino livres e iguais: retorna uma cópia dessa única célula.
- Destino inalcançável, célula bloqueada/fora dos limites ou entrada nula: `[]`.
- Uma rota pode ter mais de uma solução de mesmo custo; não existe uma única
  sequência obrigatória nesses casos.

## O problema como grafo

Cada célula livre é um vértice. Cada movimento permitido para uma vizinha
é uma aresta. Não precisamos construir todos os vértices ou arestas em memória:
calculamos até oito vizinhas quando exploramos uma célula.

O mapa usa dimensões e um índice de obstáculos. Não precisa criar uma matriz
com um objeto Cell para cada lugar. A grade existe logicamente mesmo assim.

Usamos índices baseados em zero: em N linhas, 0 <= row < N. O índice N não existe.

## Movimentos e custos

Uma vizinha difere em no máximo 1 na linha e na coluna e não é a célula atual.
São quatro movimentos retos e quatro diagonais.

Reto: custo 1.
Diagonal: custo sqrt(2), aproximadamente 1,41421356.

Por quê? Em um quadrado com lado 1, a diagonal mede sqrt(1² + 1²) = sqrt(2).
São unidades abstratas de custo, não segundos nem pixels. Assim o algoritmo
minimiza distância nesse grafo, não simplesmente quantidade de células.

Para ir de (r,c) para (r+1,c+1), exigimos livres:
- destino (r+1,c+1);
- lateral (r+1,c);
- lateral (r,c+1).

Uma única lateral bloqueada já impede a diagonal. Isso evita cortar cantos.
Essa regra não substitui a modelagem futura da largura física do personagem.

## A ideia central do A*

Não fazemos o personagem experimentar caminhos. A busca explora possibilidades
em memória e só devolve a rota final quando termina.

Para cada célula n, mantemos:

g(n): menor custo DESCOBERTO desde o início até n.
h(n): estimativa de custo de n até o destino.
f(n) = g(n) + h(n): estimativa do custo da rota completa passando por n.

Não confundir g com distância em linha reta desde a origem: g soma os custos
dos passos da rota descoberta, incluindo desvios reais por obstáculos.

A cada iteração, exploramos a célula aberta com menor f. Não escolhemos apenas
a menor distância até o destino: isso ignoraria o custo que já acumulamos.

## Como calculamos h: distância octil

dr = abs(goal.row - current.row)
dc = abs(goal.column - current.column)
d = min(dr, dc)
s = max(dr, dc) - d
h = d * sqrt(2) + s * 1

Uma diagonal reduz simultaneamente uma diferença de linha e uma de coluna.
Podemos fazer isso d vezes. Depois sobra diferença em um único eixo: s passos.

Exemplo: diferença de 3 linhas e 5 colunas.
3 diagonais + 2 retos; h = 3*sqrt(2) + 2 = aproximadamente 6,24264069.

Esse é o menor custo em uma grade SEM obstáculos. Colocar obstáculos só elimina
possibilidades: não cria um caminho mais barato. Portanto h nunca superestima
o custo real restante (é admissível).

Também é consistente: para cada movimento permitido n -> v,
h(n) <= custo(n,v) + h(v). A distância octil é uma distância mínima na grade
livre, logo respeita essa desigualdade triangular. Remover arestas bloqueadas
mantém a propriedade nas arestas restantes.

Isso justifica não reabrir células fechadas nesta implementação. Com estes
custos, mapa estático durante a chamada e essa heurística, o destino escolhido
como menor f tem custo ótimo no grafo. A afirmação não vale automaticamente
se alguém trocar custos ou heurística arbitrariamente.

## O que cada estrutura guarda

open_set: células descobertas que ainda podemos explorar, em um Array.
open_index: mesmas coordenadas, indexadas para consultar pertencimento rápido.
closed_set: coordenadas já exploradas/finalizadas.
g_score: menor custo descoberto para cada coordenada.
f_score: g + h para priorizar a busca.
came_from: predecessor na melhor rota conhecida para cada coordenada.

As chaves são strings como "2:3". Duas instâncias Cell(2,3) têm identidades
diferentes, mas a chave é a mesma. equals() também compara coordenadas.
Não confiar no operador == entre dois objetos para igualdade por valor.

## A busca, na ordem do código

1. Validar início, destino e mapa. Tratar início igual ao destino.
2. Abrir a origem com g=0 e f=h(origem).
3. Escolher a célula aberta de menor f.
4. Se ela é o destino, reconstruir e retornar a rota.
5. Removê-la das abertas e registrá-la como fechada.
6. Gerar suas oito possíveis vizinhas.
7. Descartar fora dos limites, ocupadas, fechadas e diagonais proibidas.
8. Calcular tentative_g = g(atual) + custo_do_movimento.
9. Se esse custo não melhora o g conhecido da vizinha, ignorar essa alternativa.
10. Se melhora, atualizar g, f e came_from da vizinha; abrir se ainda não estiver aberta.
11. Repetir. Se não restam abertas, não existe rota: retornar [].

O passo 9/10 se chama relaxamento. Exemplo: uma célula tinha g=7; agora
chegamos a ela com custo 5,4. Atualizamos seu predecessor e seu custo para 5,4.
Não precisamos copiar uma rota inteira para cada tentativa.

Quando a vizinha já está no Array aberto, a entrada correspondente do Dictionary
é atualizada. A escolha seguinte consulta esse Dictionary, portanto enxerga o
novo f mesmo sem trocar a instância Cell dentro do Array.

## Reconstrução

came_from guarda quem antecede cada célula na melhor rota descoberta.
Ao selecionar o destino, seguimos os predecessores:

destino -> anterior -> anterior -> origem

Acumulamos cópias das células e invertemos o Array:

origem -> ... -> destino

Repare: células exploradas que não ficaram nessa cadeia NÃO aparecem no retorno.
"Todas as células" significa todas as células DO CAMINHO, não todas as visitadas
durante a busca.

## Exemplo real executado nos testes

Mapa de 6 linhas e 7 colunas. Parede na coluna 3, linhas 0 até 3.
Início (1,1), destino (1,5). Coordenadas sempre na ordem (row,column).

```text
. . . # . . .
. S . # . G .
. . * # * . .
. . * # * . .
. . * * * . .
. . . . . . .
```

Rota devolvida:

```text
(1,1) -> (2,2) -> (3,2) -> (4,2) -> (4,3)
      -> (4,4) -> (3,4) -> (2,4) -> (1,5)
```

São 9 células e 8 movimentos: 6 retos + 2 diagonais.
Custo total = 6 + 2*sqrt(2) = aproximadamente 8,82842712.

Por que não atravessar de (3,2) para (4,3) na diagonal? Porque a lateral (3,3)
está bloqueada. É necessário descer primeiro para (4,2).

No início, h(1,1)=4. Entre as vizinhas:
- (1,2): g=1, h=3, f=4.
- (0,2): g=sqrt(2), h=1*sqrt(2)+2, f=aproximadamente 4,8284.
- (2,2): os mesmos custos do caso anterior.

A busca considera (1,2) primeiro, mas isso não significa que ela entrará na
rota final. A parede exige explorar alternativas e o encadeamento de menor
custo termina passando por baixo dela.

## Usar o serviço sem endpoint

```gdscript
var obstacles: Array[Cell] = [
    Cell.new(0, 3), Cell.new(1, 3),
    Cell.new(2, 3), Cell.new(3, 3)
]
var map := Map.new(6, 7, obstacles)
var service := PathfindingService.new()
var path: Array[Cell] = service.find_path(Cell.new(1,1), Cell.new(1,5), map)
```

Não foi criado endpoint novo. O serviço é uma dependência interna, que pode
ser testada diretamente sem passar pela API ou por telas.

Futuramente:

input de posição -> comando da API -> conversor posição/célula
-> PathfindingService -> rota guardada na entidade -> step avança movimento
-> snapshot de posições -> apresentação.

A configuração da conversão e do mundo físico deve ser compartilhada de forma
coerente com as regras; não significa que apenas o front decide escalas ou
colisões. Nada disso precisa entrar no algoritmo de rota em células.

## Executar os testes novamente

No terminal, dentro da pasta do projeto (substitua godot pelo seu executável):

```powershell
godot --headless --editor --import
godot --headless --path . --script res://tests/pathfinding_test.gd
```

A primeira execução registra as classes/importações, caso o editor ainda não
tenha feito isso. A segunda não abre interface; imprime o mapa e os resultados.
Código de saída 0 significa sucesso, 1 significa falha.

Testes executados com Godot 4.4.1:
- Todas as 512 configurações de bloqueios de uma grade 3x3.
- Todos os 81 pares ordenados de início/destino em cada uma: 41.472 consultas.
- Mais 200 mapas 8x10 reproduzíveis, com seed 20261021.
- Demonstração com parede, abertura da parede após busca, linha e coluna únicas.
- Limites, entradas nulas, origem igual ao destino e células bloqueadas.
- Adjacência de cada par retornado e proibição de cortar cantos.
- Ausência de ciclos e correspondência dos extremos.
- Custo mínimo comparado com Dijkstra implementado separadamente no teste.
- Cópias defensivas e operações occupy/release do mapa.

Resultado: 117.351 verificações, 41.676 comparações de rotas, 0 falhas.
O Dijkstra de referência usa índices numéricos e Arrays, sem heurística e sem
usar os métodos privados do serviço. Testes não são prova para todo mapa
possível, mas exercitam exaustivamente os mapas pequenos e casos maiores.

## Limites atuais e alterações adicionais

- Busca síncrona, seleção linear da menor prioridade, adequada ao estudo/MVP.
  Não é uma solução otimizada para mapas gigantes; fila de prioridade é futura.
- Apenas terreno uniforme, livre ou bloqueado; sem custos de terreno e corpo físico.
- Map.rows/columns ainda são mutáveis: trate dimensões como fixas após criar o mapa.
- Cell também é mutável: não altere coordenadas durante uma busca.
- [] não distingue motivo da falha. Isso respeita o contrato pedido.
- Sem dependência de Node, Vector2, AStarGrid2D, sprite ou textura no serviço.
  RefCounted/Array/Dictionary ainda dependem do runtime GDScript.
- Corrigidos os nomes ocupy -> occupy e is_ocuppied -> is_occupied em Map.
- Cell.equals agora aceita null com segurança; _to_string facilita estudar saídas.
- Dimensões negativas em Map são normalizadas para zero.
- Corrigido extends duplicado em back/api.gd, mantendo RefCounted.

## Referências para estudar

- https://www.redblobgames.com/pathfinding/a-star/introduction.html
- https://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
