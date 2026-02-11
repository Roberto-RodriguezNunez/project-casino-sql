/* ARCHIVO: tests/test_scenarios.sql
   DESCRIPCIÓN: Scripts de prueba para validar procedimientos y triggers.
   PROYECTO: Casino DB
*/

SET SERVEROUTPUT ON;

-- ==========================================
-- 1. PRUEBAS DE LOGICA PL/SQL (Procedures)
-- ==========================================

PROMPT Probando: mostrarInfoCliente...
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Caso 1: Cliente con ganancias ---');
    mostrarInfoCliente(2, TO_DATE('2024-01-05', 'YYYY-MM-DD'));

    DBMS_OUTPUT.PUT_LINE('--- Caso 2: Cliente con prdidas ---');
    mostrarInfoCliente(4, TO_DATE('2024-01-10', 'YYYY-MM-DD'));
END;
/

PROMPT Probando: mostrarMesasInactivas...
BEGIN 
    mostrarMesasInactivas();
END;
/

PROMPT Probando: estadisticasClientes...
BEGIN
    estadisticasClientes(1); 
END;
/

PROMPT Probando: bonusVIPs...
BEGIN
    -- Aplicar un bono de 50 a los VIPs elegibles
    bonusVIPs(50); 
END;
/

PROMPT Probando: calcularGastoSalariosCasino...
BEGIN
    calcularGastoSalariosCasino(1); 
END;
/

PROMPT Probando: calcularRecaudacionMesas...
BEGIN
    DBMS_OUTPUT.PUT_LINE('Recaudacion Casino 1 (Trimestre 1): ' || 
    calcularRecaudacionMesas(1, TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-03-31', 'YYYY-MM-DD')));
END;
/

-- ==========================================
-- 2. PRUEBAS DE TRIGGERS
-- ==========================================

PROMPT Probando Trigger: CONTROL MOROSOS...
DECLARE
    v_id_moroso NUMBER := 999;
BEGIN 
    -- 1. Crear cliente moroso falso
    INSERT INTO CLIENTE (ID_CLIENTE, NOMBRE, EDAD, TELEFONO, DNI, SALDO) 
    VALUES (v_id_moroso, 'Cliente Moroso Test', 22, 123123123, '99999999Z', -1000);
    
    -- 2. Intentar borrarlo (Deberia fallar)
    BEGIN
        DELETE FROM CLIENTE WHERE ID_CLIENTE = v_id_moroso;
    EXCEPTION 
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXITO! El trigger bloqueo el borrado: ' || SQLERRM);
    END;
    
    -- Limpieza (Restaurar saldo para poder borrarlo y limpiar la prueba)
    UPDATE CLIENTE SET SALDO = 0 WHERE ID_CLIENTE = v_id_moroso;
    DELETE FROM CLIENTE WHERE ID_CLIENTE = v_id_moroso;
END;
/

PROMPT Probando Trigger: RONDAS TORNEO (Creacion automatica)...
BEGIN 
    -- Insertar torneo con premio bajo (debe crear 2 rondas)
    INSERT INTO TORNEO (ID_TORNEO, PREMIO, FECHA, DESCRIPCION, GANADOR) 
    VALUES (999, 7500, SYSDATE, 'Torneo Test Trigger', NULL); 
    
    COMMIT;
END;
/
-- Verificacion visual
SELECT * FROM RONDA_TORNEO WHERE ID_TORNEO = 999;

-- Limpieza de prueba
DELETE FROM TORNEO WHERE ID_TORNEO = 999;