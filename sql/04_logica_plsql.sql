/* ARCHIVO: sql/04_logica_plsql.sql
   DESCRIPCIÓN: Procedimientos almacenados y Funciones (Lógica de Negocio).
   PROYECTO: Casino DB
*/

SET SERVEROUTPUT ON;

/* ---------------------------------------------------------
   PROCEDIMIENTO: estadisticasClientes
   Desc: Muestra estadísticas básicas de un casino dado.
   --------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE estadisticasClientes ( casino IN CASINO.ID_CASINO%TYPE )
IS 
    numClientes NUMBER ; 
    numVips NUMBER ; 
    numNormal NUMBER ; 
    nombreCasino CASINO.NOMBRE%TYPE;
BEGIN 
    -- Obtener nombre del casino
    SELECT NOMBRE INTO nombreCasino FROM CASINO WHERE ID_CASINO = casino;
    
    -- Contar clientes totales
    SELECT COUNT(*) INTO numClientes
    FROM CASINO_TIENE_CLIENTE
    WHERE ID_CASINO = casino;

    -- Contar VIPs
    SELECT COUNT(*) INTO numVips
    FROM CASINO_TIENE_CLIENTE C, VIP V
    WHERE C.ID_CASINO = casino AND C.ID_CLIENTE = V.ID_VIP;
    
    -- Contar Normales
    SELECT COUNT(*) INTO numNormal
    FROM CASINO_TIENE_CLIENTE C, NORMAL N
    WHERE C.ID_CASINO = casino AND C.ID_CLIENTE = N.ID_NORMAL;

    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('ESTADÍSTICAS DEL CASINO: ' || nombreCasino);
    DBMS_OUTPUT.PUT_LINE('Clientes Totales: ' || numClientes);
    DBMS_OUTPUT.PUT_LINE('Clientes VIP: ' || numVips);
    DBMS_OUTPUT.PUT_LINE('Clientes Normales: ' || numNormal);
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');

EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el casino con ID ' || casino);
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/

/* ---------------------------------------------------------
   PROCEDIMIENTO: bonusVIPs
   Desc: Aplica un bono de saldo a los VIPs Oro/Platinum que han perdido dinero.
   --------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE bonusVIPs 
IS 
    CURSOR c_vip IS SELECT * FROM VIP;
    v_vip c_vip%ROWTYPE;
    saldo_actual CLIENTE.SALDO%TYPE;
    regimen VIP.REGIMEN_VIP%TYPE; 
BEGIN 
    FOR v_vip IN c_vip LOOP 
        -- Obtenemos saldo y régimen
        SELECT SALDO INTO saldo_actual FROM CLIENTE WHERE ID_CLIENTE = v_vip.ID_VIP;
        regimen := v_vip.REGIMEN_VIP;

        -- Lógica de bonificación
        IF saldo_actual < 0 THEN 
            IF regimen = 'Gold' THEN 
                UPDATE CLIENTE SET SALDO = SALDO + 50 WHERE ID_CLIENTE = v_vip.ID_VIP;
                DBMS_OUTPUT.PUT_LINE('Bono de 50 aplicado al cliente Gold ID: ' || v_vip.ID_VIP);
            ELSIF regimen = 'Platinum' THEN 
                UPDATE CLIENTE SET SALDO = SALDO + 100 WHERE ID_CLIENTE = v_vip.ID_VIP;
                DBMS_OUTPUT.PUT_LINE('Bono de 100 aplicado al cliente Platinum ID: ' || v_vip.ID_VIP);
            END IF;
        END IF; 
    END LOOP; 
END; 
/

/* ---------------------------------------------------------
   PROCEDIMIENTO: mostrarInfoCliente
   Desc: Historial de apuestas de un cliente en una fecha específica.
   --------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE mostrarInfoCliente ( id_cliente IN NUMBER , fecha IN DATE ) 
IS 
    CURSOR c_info IS 
        SELECT M.TIPO_JUEGO, A.DESCRIPCION, A.RESULTADO, A.VALOR
        FROM CLIENTE_JUEGO_MESA_APUESTA C, APUESTA A, MESA_JUEGO M, JUEGO J
        WHERE C.ID_CLIENTE = id_cliente 
          AND C.ID_APUESTA = A.ID_APUESTA
          AND C.ID_MESA_JUEGO = M.ID_MESA
          AND C.ID_JUEGO = J.ID_JUEGO
          AND J.FECHA = fecha;
          
    v_info c_info%ROWTYPE;
    total_ganado NUMBER := 0;
    nombre_cli CLIENTE.NOMBRE%TYPE;
BEGIN 
    SELECT NOMBRE INTO nombre_cli FROM CLIENTE WHERE ID_CLIENTE = id_cliente;
    
    DBMS_OUTPUT.PUT_LINE('HISTORIAL DE APUESTAS - Cliente: ' || nombre_cli || ' Fecha: ' || fecha);
    
    FOR v_info IN c_info LOOP 
        DBMS_OUTPUT.PUT_LINE('Juego: ' || v_info.TIPO_JUEGO || ' | Apuesta: ' || v_info.DESCRIPCION || ' | Resultado: ' || v_info.RESULTADO || ' | Valor: ' || v_info.VALOR);
        
        IF v_info.RESULTADO = 'ganada' THEN
            total_ganado := total_ganado + v_info.VALOR;
        ELSE
            total_ganado := total_ganado - v_info.VALOR;
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Balance total del día: ' || total_ganado || '€');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('El cliente no existe o no tiene registros.');
END;
/

/* ---------------------------------------------------------
   PROCEDIMIENTO: mostrarMesasInactivas
   Desc: Reporte de mesas cerradas o en mantenimiento por sala.
   --------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE mostrarMesasInactivas 
IS 
    CURSOR c_salas IS SELECT ID_SALA, NOMBRE FROM SALA;
    v_sala c_salas%ROWTYPE;
    
    CURSOR c_mesas (p_sala NUMBER) IS 
        SELECT ID_MESA, TIPO_JUEGO, ESTADO 
        FROM MESA_JUEGO 
        WHERE ID_SALA = p_sala AND ESTADO IN ('Cerrada', 'Mantenimiento');
        
    v_mesa c_mesas%ROWTYPE;
BEGIN 
    FOR v_sala IN c_salas LOOP 
        DBMS_OUTPUT.PUT_LINE('Revisando Sala: ' || v_sala.NOMBRE);
        FOR v_mesa IN c_mesas(v_sala.ID_SALA) LOOP
            DBMS_OUTPUT.PUT_LINE('   -> Mesa ' || v_mesa.ID_MESA || ' (' || v_mesa.TIPO_JUEGO || ') está ' || v_mesa.ESTADO);
        END LOOP;
    END LOOP;
END;
/

/* ---------------------------------------------------------
   FUNCIÓN: calcularGastoSalariosCasino
   Desc: Calcula el coste total en nóminas de un casino.
   --------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE calcularGastoSalariosCasino ( id_casino IN NUMBER )
IS 
    total_salarios NUMBER := 0;
BEGIN 
    SELECT SUM(SALARIO) INTO total_salarios
    FROM EMPLEADO
    WHERE CASINO_TRABAJA = id_casino;
    
    DBMS_OUTPUT.PUT_LINE('Gasto total en salarios para el Casino ' || id_casino || ': ' || NVL(total_salarios, 0) || '€');
EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Error al calcular salarios.');
END; 
/

/* ---------------------------------------------------------
   FUNCIÓN: calcularRecaudacionMesas
   Desc: Suma el dinero jugado en mesas en un rango de fechas.
   --------------------------------------------------------- */
CREATE OR REPLACE FUNCTION calcularRecaudacionMesas ( 
    id_casino IN NUMBER, 
    fechaInicio IN DATE, 
    fechaFin IN DATE 
) RETURN NUMBER 
IS 
    total_recaudado NUMBER := 0;
BEGIN 
    SELECT SUM(A.VALOR) INTO total_recaudado
    FROM APUESTA A, JUEGO J, MESA_JUEGO M, SALA S
    WHERE A.EN_QUE_JUEGO = J.ID_JUEGO
      AND J.EN_QUE_MESA = M.ID_MESA
      AND M.ID_SALA = S.ID_SALA
      AND S.CASINO_PERTENECE = id_casino
      AND J.FECHA BETWEEN fechaInicio AND fechaFin;

    RETURN NVL(total_recaudado, 0);
END;
/