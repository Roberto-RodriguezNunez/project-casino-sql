/* ARCHIVO: sql/05_triggers.sql
   DESCRIPCIÓN: Disparadores (Triggers) para automatización y validaciones.
   PROYECTO: Casino DB
*/

-- 1. TRIGGER: CONTROL DE MOROSOS
-- Impide borrar un cliente si tiene saldo negativo (deudas).
CREATE OR REPLACE TRIGGER controlMorosos
BEFORE DELETE ON CLIENTE 
FOR EACH ROW 
BEGIN 
    IF :OLD.SALDO < 0 THEN 
        RAISE_APPLICATION_ERROR (-20006, 'El cliente ID '|| :OLD.ID_CLIENTE || ' es moroso. Debe '|| ABS(:OLD.SALDO) || ' euros. No se puede borrar.'); 
    END IF;
END;
/

-- 2. TRIGGER: GENERACIÓN DE RONDAS DE TORNEO
-- Crea automáticamente las rondas (1, 2 o 3) según el premio del torneo insertado.
CREATE OR REPLACE TRIGGER rondasTorneo
AFTER INSERT ON TORNEO 
FOR EACH ROW 
DECLARE
    limite NUMBER; 
BEGIN
    IF :NEW.PREMIO < 5000 THEN 
        limite := 1;
    ELSIF :NEW.PREMIO >= 5000 AND :NEW.PREMIO < 15000 THEN 
        limite := 2;
    ELSE 
        limite := 3;
    END IF; 

    FOR i IN 1 .. limite LOOP
        INSERT INTO RONDA_TORNEO (ID_TORNEO, RONDA_TORNEO, FECHA_RONDA, DESCRIPCION_RONDA) 
        VALUES (:NEW.ID_TORNEO, i, :NEW.FECHA, :NEW.DESCRIPCION || ' Ronda :' || i); 
    END LOOP; 
EXCEPTION 
     WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Error en Trigger rondasTorneo: '||SQLERRM);
END;
/

-- 3. TRIGGER: ACTUALIZACIÓN DE RONDAS
-- Ajusta las rondas si se cambia el premio de un torneo existente.
CREATE OR REPLACE TRIGGER rondasTorneoUpdates
AFTER UPDATE OF PREMIO ON TORNEO
FOR EACH ROW
DECLARE
    rondas_actuales NUMBER;
    rondas_nuevas NUMBER;
BEGIN
    -- Calcular nuevas rondas necesarias
    IF :NEW.PREMIO < 5000 THEN
        rondas_nuevas := 1;
    ELSIF :NEW.PREMIO BETWEEN 5000 AND 15000 THEN
        rondas_nuevas := 2;
    ELSE
        rondas_nuevas := 3;
    END IF;

    -- Contar rondas existentes
    SELECT COUNT(*) INTO rondas_actuales
    FROM RONDA_TORNEO
    WHERE ID_TORNEO = :NEW.ID_TORNEO;

    -- Ajustar (Añadir o Borrar)
    IF rondas_nuevas > rondas_actuales THEN
        FOR i IN (rondas_actuales + 1) .. rondas_nuevas LOOP
            INSERT INTO RONDA_TORNEO (ID_TORNEO, RONDA_TORNEO, FECHA_RONDA, DESCRIPCION_RONDA)
            VALUES (:NEW.ID_TORNEO, i, SYSDATE, 'Ronda generada automticamente');
        END LOOP;
    ELSIF rondas_nuevas < rondas_actuales THEN
        DELETE FROM RONDA_TORNEO
        WHERE ID_TORNEO = :NEW.ID_TORNEO AND RONDA_TORNEO > rondas_nuevas;
    END IF;
END;
/

-- 4. TRIGGER: VALIDAR SALDO PARA APUESTAS
-- Impide que un cliente apueste ms dinero del que tiene en su saldo.
CREATE OR REPLACE TRIGGER validarSaldoApuestaCJMA
AFTER INSERT ON CLIENTE_JUEGO_MESA_APUESTA
FOR EACH ROW
DECLARE
    saldo_cliente NUMBER;
    valor_apuesta NUMBER;
BEGIN
    -- Obtener saldo
    SELECT SALDO INTO saldo_cliente FROM CLIENTE WHERE ID_CLIENTE = :NEW.ID_CLIENTE;
    -- Obtener valor de la apuesta
    SELECT VALOR INTO valor_apuesta FROM APUESTA WHERE ID_APUESTA = :NEW.ID_APUESTA;

    IF saldo_cliente < valor_apuesta THEN
        RAISE_APPLICATION_ERROR(-20001, 'Saldo insuficiente para realizar la apuesta.');
    END IF;
END;
/

-- 5. TRIGGER: PAGO DE PREMIOS
-- Cuando se asigna un ganador a un torneo, se le ingresa el dinero automticamente.
CREATE OR REPLACE TRIGGER saldoPremios
AFTER UPDATE ON TORNEO
FOR EACH ROW
BEGIN
    IF :NEW.GANADOR IS NOT NULL THEN
        UPDATE CLIENTE
        SET SALDO = SALDO + :NEW.PREMIO
        WHERE ID_CLIENTE = :NEW.GANADOR;
    END IF;
END;
/