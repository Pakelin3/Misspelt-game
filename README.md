# Misspelt - Godot Project

**Misspelt** es un juego _roguelite survivor_ educativo desarrollado en Godot 4. Combina la intensa jugabilidad de supervivencia contra hordas de enemigos con mecánicas de aprendizaje de vocabulario y ortografía.

El proyecto está diseñado para integrarse con una aplicación web (escrita en React).

---

## 📖 Características Principales

- **Supervivencia y Hordas**: Lucha contra oleadas interminables de enemigos y jefes.
- **Recolección de Letras**: Gana experiencia derrotando enemigos y recoge letras que caen como botín para formar palabras clave.
- **Mecánica de Quiz Educativo**: Al completar una palabra, el juego se pausa y se abre un _quiz_ en la interfaz web superpuesta. Responder correctamente otorga gran cantidad de experiencia.
- **Sistema de Castigo (La Ñ)**: Si fallas el quiz o lo cierras, aparecerá un jefe "Castigo" (La letra Ñ), el cual es agresivo y devora otras letras menores para curarse.
- **Diferentes Clases**: Juega con distintos personajes, cada uno con un estilo de juego y armas únicas.
- **Mejoras Aleatorias (Roguelite)**: Sube de nivel para elegir entre tres cartas de mejora: estadísticas generales, mejoras específicas de clase, y opciones de supervivencia.
- **Integración Web Bidireccional**: Godot envía estadísticas a la web y reacciona a los parámetros enviados por la URL (clase, dificultad, lista de palabras).

---

## 🧙‍♂️ Clases Disponibles

El juego cuenta con cuatro personajes jugables, cada uno con su propio comportamiento y árbol de mejoras específico (Carta 2).

### 1. El Mago (Mage)

- **Ataque**: Dispara proyectiles mágicos a los enemigos más cercanos.
- **Estilo**: Balanceado.
- **Mejoras Exclusivas**:
  - _Multicast_: Añade más proyectiles por disparo.
  - _Disparo Perforante_: Los proyectiles atraviesan enemigos.
  - _Archimago_: Gran aumento de daño base.

### 2. El Brujo (Warlock)

- **Ataque**: Genera un aura oscura inactiva que daña a los enemigos constantemente en un área circular. No dispara.
- **Estilo**: Corto alcance / Daño en área (AoE).
- **Mejoras Exclusivas**:
  - _Corrupción_: Expande el tamaño del aura.
  - _Vacío Famélico_: Aumenta la velocidad (reduce los ticks) en la que el aura inflige daño.
  - _Segador de Almas_: Al matar enemigos dentro del área, recuperas salud.

### 3. El Erudito (Erudit)

- **Ataque**: Libros mágicos que orbitan alrededor del jugador dañando y repeliendo enemigos.
- **Estilo**: Controlador de masas y defensa rotatoria.
- **Mejoras Exclusivas**:
  - _Más Conocimiento_: Añade libros extra a la órbita.
  - _Lectura Rápida_: Los libros giran más rápido alrededor de ti.
  - _Libros Pesados_: Aumenta drásticamente el empuje (_knockback_) al impactar.

### 4. El Campesino (Farmer)

- **Ataque**: Lanza una guadaña que viaja una distancia y luego regresa a sus manos, como un bumerán.
- **Estilo**: Daño direccional y de regreso.
- **Mejoras Exclusivas**:
  - _Guadaña Afilada_: La guadaña atraviesa un enemigo antes de volver.
  - _Cosecha Magna_: Aumenta el tamaño de la guadaña.
  - _Doble Guadaña_: Lanza múltiples guadañas.
  - _Segar Almas_: Perforación infinita.
  - _Cosecha Crítica_: Añade una probabilidad del 15% de asestar un golpe crítico (doble daño).

---

## ⚙️ Mecánicas Base y Sistemas

### El Administrador del Juego (GameManager)

Singleton principal encargado de gobernar el estado de la partida:

- Gestiona la fluidez entre Godot y React mediante `JavaScriptBridge`.
- Decodifica los parámetros `words`, `difficulty`, y `skin` de la URL para inicializar el juego.
- Gestiona si el quiz está activo (`quiz_active`) para pausar instancias y la música de fondo.

### Sistema de Mejoras y Subida de Nivel

Al juntar _XP gems_:

1.  **Carta 1 (Estadísticas Base)**: Fuerza (Daño plano), Poder Arcano (Daño %), Reflejos (Velocidad de movimiento/ataque), Piel de Hierro (Reducción de daño plana).
2.  **Carta 2 (Clase)**: Mejoras mecánicas descritas en la sección de clases.
3.  **Carta 3 (Supervivencia)**: Descanso (Cura y aumenta HP máximo) y Regeneración (Cura pasiva cada 5 segundos).

### La Horda de Letras (Enemigos)

- **Letras Enemigas Básicas**: Letras del abecedario generadas por el `EnemySpawner`.
- **Dropping**: Tienen una probabilidad de soltar la letra que representan al morir. Si el jugador recolecta esa letra y forma parte de la _Palabra Objetivo_ (`target_word`), se añade a la caja de texto.
- **Boss Castigo (La Ñ)**: Generada mediante `EventBus.spawn_punishment_boss`. Devora a los enemigos más pequeños para curarse, sirviendo como castigo para fallar el elemento educativo del juego.

### Transición Musical y Eventos Globales

`MusicManager` y `EventBus` trabajan de la mano para:

- Reducir el volumen nativo de la música temporalmente cuando se elige un nivel.
- Cambiar a la "música intensa" si el jugador debe lidiar con la 'Ñ'.
- Notificar la muerte o salida manual del juego para reportar resultados y XP a React (`send_game_over_to_web`, `send_exit_to_web`).

---

## 🚀 Uso en entorno Web / React

El juego espera existir dentro de un Iframe, de la siguiente forma base instalada:
`https://url-del-juego.com/?skin=warlock&difficulty=1&words=GATO,PERRO,CASA`

**Callbacks esperados del lado de React:**

- `window.triggerQuiz(word)`: Disparado cuando el jugador arma una palabra.
- `window.handleGameOver(xp, time, killed_letters, boss_kills)`: Cuando el jugador muere o gana.
- `window.handleExitGame()`: Cuando el jugador pulsa en 'Salir'.

**Envío de eventos hacia Godot:**
React debe llamar a la referencia global expuesta para devolver el valor del quiz:

- `window.godotQuizCallback([true/false])`: Inyecta el triunfo o el fallo (activa la 'Ñ') y resume el juego.
