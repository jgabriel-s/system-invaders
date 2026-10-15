
-- SPACE INVADERS: SYSTEM FAILURE
-- Blue Team vs Red Team
-- API gráfica: Lupi Game

-- PALETA RGB555
Palette = {
    0x0000, -- 0: Preto
    0x7FFF, -- 1: Branco
    0x001F, -- 2: Azul
    0x7C00, -- 3: Vermelho
    0x03FF, -- 4: Ciano
    0x7FE0, -- 5: Amarelo
    0x03E0, -- 6: Verde
    0x3DEF  -- 7: Cinza
}

-- CONFIGURACOES
SCREEN_W = 480
SCREEN_H = 270
MAX_SCORE = 1000
ENEMY_POINTS = 25

-- ESTADO DO JOGO
player = {
    x = 240,
    y = 245,
    speed = 3,
    cooldown = 0
}

enemies = {}
bullets = {}
enemyBullets = {}

score = 0
lives = 3
gameState = "playing"

enemyDX = 0.65
enemyDrop = 7
enemyShootTimer = 0

-- CRIAR 40 VIRUS
for row = 1, 5 do
    for col = 1, 8 do
        table.insert(enemies, {
            x = 62 + (col - 1) * 46,
            y = 35 + (row - 1) * 23,
            alive = true,
            row = row
        })
    end
end

-- DESENHAR A NAVE AZUL
function drawPlayer()
    -- Corpo
    ui.trisfill(
        player.x, player.y - 9,
        player.x - 10, player.y + 7,
        player.x + 10, player.y + 7,
        2
    )

    ui.rectfill(
        player.x - 4, player.y,
        player.x + 4, player.y + 5,
        4
    )

    -- Canhoes
    ui.rectfill(
        player.x - 12, player.y + 3,
        player.x - 9, player.y + 7,
        2
    )

    ui.rectfill(
        player.x + 9, player.y + 3,
        player.x + 12, player.y + 7,
        2
    )
end

-- DESENHAR UM VIRUS VERMELHO
function drawEnemy(e)
    if not e.alive then
        return
    end

    ui.rectfill(
        e.x - 8, e.y - 5,
        e.x + 8, e.y + 5,
        3
    )

    -- Olhos digitais
    ui.rectfill(
        e.x - 5, e.y - 2,
        e.x - 2, e.y + 1,
        1
    )

    ui.rectfill(
        e.x + 2, e.y - 2,
        e.x + 5, e.y + 1,
        1
    )

    -- Pernas do virus
    ui.line(
        e.x - 6, e.y + 5,
        e.x - 10, e.y + 9,
        3
    )

    ui.line(
        e.x + 6, e.y + 5,
        e.x + 10, e.y + 9,
        3
    )
end

-- DISPARO DA NAVE
function shoot()
    if player.cooldown <= 0 then
        table.insert(bullets, {
            x = player.x,
            y = player.y - 10,
            speed = 5
        })

        player.cooldown = 12
        sfx.fx(0, 76)
    end
end

-- ATUALIZAR PROJETEIS AZUIS
function updateBullets()
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.y = b.y - b.speed

        if b.y < 0 then
            table.remove(bullets, i)
        else
            -- Colisao com os virus
            for j = 1, #enemies do
                local e = enemies[j]

                if e.alive
                and math.abs(b.x - e.x) < 10
                and math.abs(b.y - e.y) < 9 then

                    e.alive = false
                    score = score + ENEMY_POINTS

                    table.remove(bullets, i)

                    sfx.fx(1, 84)
                    break
                end
            end
        end
    end
end

-- DISPAROS DOS VIRUS
function updateEnemyBullets()
    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.y = b.y + b.speed

        -- Atingiu a nave azul?
        if math.abs(b.x - player.x) < 11
        and math.abs(b.y - player.y) < 9 then

            table.remove(enemyBullets, i)
            lives = lives - 1
            sfx.fx(1, 45)

            if lives <= 0 then
                gameState = "lost"
            end

        elseif b.y > SCREEN_H then
            table.remove(enemyBullets, i)
        end
    end
end

-- MOVIMENTAR OS VIRUS
function updateEnemies(frame)
    local hitWall = false

    for i = 1, #enemies do
        local e = enemies[i]

        if e.alive then
            e.x = e.x + enemyDX

            if e.x >= 463 or e.x <= 17 then
                hitWall = true
            end

            -- Virus alcancou a zona da nave
            if e.y >= player.y - 15 then
                gameState = "lost"
            end
        end
    end

    if hitWall then
        enemyDX = -enemyDX

        for i = 1, #enemies do
            if enemies[i].alive then
                enemies[i].y =
                    enemies[i].y + enemyDrop
            end
        end
    end

    -- Escolher um virus vivo para atirar
    enemyShootTimer = enemyShootTimer + 1

    if enemyShootTimer >= 45 then
        enemyShootTimer = 0

        local aliveCount = 0

        for i = 1, #enemies do
            if enemies[i].alive then
                aliveCount = aliveCount + 1
            end
        end

        if aliveCount > 0 then
            local targetNumber =
                (math.floor(frame / 45) % aliveCount) + 1

            local current = 0

            for i = 1, #enemies do
                local e = enemies[i]

                if e.alive then
                    current = current + 1

                    if current == targetNumber then
                        table.insert(enemyBullets, {
                            x = e.x,
                            y = e.y + 8,
                            speed = 2
                        })
                        break
                    end
                end
            end
        end
    end
end

-- DESENHAR O FUNDO DIGITAL
function drawBackground(frame)
    ui.cls(0)

    -- Linhas de dados no fundo
    for i = 1, 12 do
        local x = (i * 41 + frame * 2) % SCREEN_W
        local y = (i * 23) % SCREEN_H

        ui.rectfill(x, y, x + 1, y + 1, 7)
    end

    -- Linha de perigo
    ui.line(0, 225, SCREEN_W, 225, 3)

    ui.print("SYSTEM DEFENSE // BLUE TEAM", 8, 5, 4)
    ui.print("SCORE: " .. score, 8, 17, 1)
    ui.print("LIVES: " .. lives, 390, 17, 5)

    ui.rect(7, 29, 473, 259, 7)
end

-- DESENHAR OS PROJETEIS
function drawBullets()
    for i = 1, #bullets do
        local b = bullets[i]

        ui.rectfill(
            b.x - 1, b.y - 4,
            b.x + 1, b.y + 4,
            4
        )
    end

    for i = 1, #enemyBullets do
        local b = enemyBullets[i]

        ui.rectfill(
            b.x - 2, b.y - 3,
            b.x + 2, b.y + 3,
            3
        )
    end
end

-- TELA DE FIM
function drawEndScreen()
    ui.cls(0)

    ui.rectfill(35, 45, 445, 220, 7)
    ui.rect(35, 45, 445, 220, 3)

    if gameState == "won" then
        ui.print("SYSTEM RESTORED", 160, 78, 6)
        ui.print("BLUE TEAM WINS!", 170, 105, 4)
        ui.print("ALL VIRUSES ELIMINATED", 135, 130, 1)
    else
        ui.print("FALHA DO SISTEMA", 155, 75, 3)
        ui.print("RED TEAM WINS", 170, 102, 3)
        ui.print("VIRUS INVASION COMPLETE", 125, 128, 1)
    end

    ui.print("FINAL SCORE: " .. score, 170, 157, 5)
    ui.print("PRESS Z TO RESTART", 155, 190, 4)
end

-- REINICIAR O JOGO
function restartGame()
    player.x = 240
    player.y = 245
    player.cooldown = 0

    enemies = {}
    bullets = {}
    enemyBullets = {}

    for row = 1, 5 do
        for col = 1, 8 do
            table.insert(enemies, {
                x = 62 + (col - 1) * 46,
                y = 35 + (row - 1) * 23,
                alive = true,
                row = row
            })
        end
    end

    score = 0
    lives = 3
    enemyDX = 0.65
    enemyShootTimer = 0
    gameState = "playing"
end

-- LOOP PRINCIPAL DO LUPI
function update(frame)

    -- A paleta deve ser registrada a cada quadro
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    -- Tela final
    if gameState ~= "playing" then
        drawEndScreen()

        if ui.btnp(BTN_Z) then
            restartGame()
        end

        return
    end

    -- Movimento da nave
    if ui.btn(LEFT) then
        player.x = player.x - player.speed
    end

    if ui.btn(RIGHT) then
        player.x = player.x + player.speed
    end

    player.x = ui.mid(15, player.x, 465)

    -- Controle de disparo
    if player.cooldown > 0 then
        player.cooldown = player.cooldown - 1
    end

    if ui.btn(BTN_Z) then
        shoot()
    end

    -- Atualizar o mundo
    updateEnemies(frame)
    updateBullets()
    updateEnemyBullets()

    -- Vitoria: 40 virus x 25 pontos = 1000
    if score >= MAX_SCORE then
        score = MAX_SCORE
        gameState = "won"
    end

    -- Desenhar a cena
    drawBackground(frame)

    for i = 1, #enemies do
        drawEnemy(enemies[i])
    end

    drawPlayer()
    drawBullets()

    -- Barra de progresso
    ui.rect(145, 17, 325, 23, 7)

    local barWidth = math.floor(score / MAX_SCORE * 176)

    if barWidth > 0 then
        ui.rectfill(
            147, 19,
            147 + barWidth, 21,
            6
        )
    end

    ui.print("Z: FIRE", 200, 249, 4)
end
