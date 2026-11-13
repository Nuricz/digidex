# DigiDex

Digidex personal y **offline** para *Digimon Story: Cyber Sleuth* y *Hacker's Memory*, hecha en Flutter (solo Android).

> Proyecto de uso personal, sin fines de lucro. Los datos, textos e imágenes pertenecen a sus respectivos dueños (ver [Créditos](#créditos-y-fuentes)). No está pensado para publicarse ni distribuirse.

## Qué hace

- **Listado de Digimon** (341) con buscador por nombre o número, filtros por etapa, atributo, tipo y juego, y orden por número, nombre o cualquier stat (HP, SP, ATK, DEF, INT, SPD) de mayor a menor o al revés, en Lv 1, 50 o 99.
- **ABI requerido** para digievolucionar a cada Digimon, como dato aparte (no es un stat): se puede mostrar en el listado y ordenar por él.
- **Favoritos** y **registrado en el juego** (check) por Digimon, con filtros rápidos (solo favoritos; todos / registrados / sin registrar) y contador.
- **Ficha** con artwork, stats base por nivel, movimientos con su efecto, evoluciones y devoluciones con sus requisitos, y navegación al Digimon anterior/siguiente y botón de inicio.
- **Movimientos** (492): listado con buscador y filtro por elemento; al abrir uno se ve qué hace y qué Digimon lo aprenden y en qué nivel.
- **Comparador** de stats entre dos Digimon.
- Descripciones de Digimon, efectos de habilidades y de movimientos **traducidos al español**; nombres de Digimon, ataques, habilidades y términos del juego se dejan en inglés.

## Datos

Todo vive en `assets/data/digimon.json` (se carga al iniciar, no hay red):

| Campo | Contenido |
|---|---|
| `digimon[]` | stats base (Lv 1/50/99), movimientos con nivel, evoluciones, requisitos de digievolución, descripción (`description` / `descriptionEs`), habilidad (`supportSkill`), imagen |
| `moveInfo{}` | efecto de cada movimiento (`description` / `descriptionEs`) |
| `personalities` | referencia de personalidades (no se usa en la app) |

Imágenes: `assets/icons/` (ícono por Digimon), `assets/images/` (artwork de la ficha), `assets/elements/` (íconos de elemento).

### Limitaciones conocidas

- **`inCyberSleuth_estimated` es una estimación**, no un dato confirmado: se obtuvo cruzando contra una lista de Wikimon y mapeos de nombres hechos a mano. Puede haber errores.
- Los stats y movimientos provienen de una wiki que documenta *Hacker's Memory*; para un mismo Digimon podrían diferir un poco del *Cyber Sleuth* original.
- Las traducciones son automáticas y solo se revisaron parcialmente; algunas frases del texto original son confusas y la traducción las respeta.
- Algunas imágenes con resplandores o sombras pintadas se muestran sobre una tarjeta blanca (`imageOpaque: true`) en vez de con el fondo transparente.
- Los favoritos y registrados se guardan en el dispositivo (`shared_preferences`): **se pierden al desinstalar la app**.

## Cómo correrlo

Requisitos: Flutter estable (desarrollado con 3.44) y un dispositivo o emulador Android.

```bash
flutter pub get
flutter run          # o F5 en VS Code ("Digimon Pokedex")
flutter test         # tests de datos, orden, favoritos y pantallas
flutter analyze
```

## Estructura

```
lib/
  data/      modelos, repositorio (carga el JSON e indexa movimientos) y lógica de orden
  state/     favoritos y registrados (persistencia local)
  screens/   listado, ficha, movimientos, comparador
  widgets/   fila de lista, íconos, selector de Digimon
assets/
  data/ icons/ images/ elements/ icon/
test/        datos, orden, favoritos, y pruebas de interfaz
```

## Créditos y fuentes

- Datos de Digimon, movimientos, evoluciones, íconos de lista y de elemento: [Grindosaur](https://www.grindosaur.com/).
- Artwork de las fichas: [Digimon Wiki (Fandom)](https://digimon.fandom.com/).
- Lista de Digimon de Cyber Sleuth usada para estimar la disponibilidad por juego: [Wikimon](https://wikimon.net/).
- Ícono de la app: portada de *Digimon Story: Cyber Sleuth Complete Edition*.
- Digimon y los materiales del juego son propiedad de Bandai Namco Entertainment y Toei Animation. Este proyecto no está afiliado a ellos.
