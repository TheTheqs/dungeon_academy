# Guia das alterações

## Ordem sugerida para estudar

1. `main.gd`: cria GameApi e TextureLoader, instancia a tela, configura e apresenta.
2. `front/screens/characters_screen.gd`: configure() guarda as dependências; _ready() usa os filhos e refresh_characters() atualiza a apresentação sem argumentos.
3. `front/screens/screen_root.gd`: recebe a tela pronta; remove e libera a anterior.
4. `front/components/entities/character_preview.gd`: centraliza o Sprite2D na área do Control, inclusive ao redimensionar.

## Layout

Main agora é Control com Full Rect. Antes, o Node2D fazia esta cadeia de Controls permanecer com tamanho zero. O HBox continua dividindo a largura igualmente. O Sprite2D é centralizado explicitamente porque não usa anchors de Control.

Viewport preservado: 640 × 360, janela 1280 × 720. Com duas colunas os centros internos são (160, 180) e (480, 180). Um terceiro preview com Expand + Fill horizontal participa automaticamente da divisão.

## Dependências

Não há Autoload API ou FS. GameApi é RefCounted; TextureLoader já era. Main mantém uma instância de cada e as entrega à tela. ServicesContainer foi removido. class_name registra um tipo, não uma instância global.

Configure é chamado ANTES de adicionar a tela à árvore: ele só guarda referências. Depois, _ready() pode acessar os @onready e apresentar os personagens.

## Nomes

- characters_screens -> characters_screen; CharactersScreens -> CharactersScreen.
- character_component / CharacterComponent -> character_preview / CharacterPreview.
- set_component -> set_character; set_screen -> refresh_characters.
- get_enemy_chracter -> get_enemy_character.
- root interno -> ScreenHost; h_container -> CharactersRow.
- player/enemy (nós) -> PlayerPreview/EnemyPreview.
- sprite/anime (nós) -> Sprite/AnimationPlayer; variável anime -> animation_player.
- character_root -> CHARACTER_TEXTURES_PATH.
- Contratos de textura agora usam Texture2D.

O catálogo de telas por string foi substituído por show_screen(screen). Assim não existe mais o acesso a uma chave inválida após push_error(). As telas antigas recebem remove_child() e queue_free().

A sequência idle/run/attack/action/death foi preservada como demonstração. Não foi introduzido um sistema de combate nem um framework de DI.

Execute pela cena Main (F5): a tela isolada requer as dependências que Main injeta.
