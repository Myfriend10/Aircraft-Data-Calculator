% Arquivo: CalculadoraAviao/funcoes/calcular_w_b.m
%
% Descrição: Função para calcular o peso total e o Centro de Gravidade (CG)
%            de uma aeronave, verificando os limites operacionais.
%
% Parâmetros de Entrada:
%   peso_vazio_operacional_kg : Peso vazio operacional da aeronave (kg)
%   cg_vazio_m                : CG do peso vazio operacional (metros do datum)
%   combustivel_litros        : Volume de combustível (litros)
%   passageiros_fila1         : Número de passageiros na fila 1
%   passageiros_fila2         : Número de passageiros na fila 2
%   passageiros_fila3         : Número de passageiros na fila 3
%   carga_frontal_kg          : Peso da carga no compartimento frontal (kg)
%   carga_traseira_kg         : Peso da carga no compartimento traseiro (kg)
%
% Parâmetros de Saída:
%   peso_total_kg             : Peso bruto de decolagem (Gross Weight - GW) em kg
%   cg_resultante_m           : Centro de gravidade final em metros do datum
%   status_peso               : String com status de peso ("OK", "Acima MTOW")
%   status_cg                 : String com status de CG ("OK", "CG Dianteiro Demais", "CG Traseiro Demais")

function [peso_total_kg, cg_resultante_m, status_peso, status_cg] = ...
         calcular_w_b(peso_vazio_operacional_kg, cg_vazio_m, ...
                      combustivel_litros, ...
                      passageiros_fila1, passageiros_fila2, passageiros_fila3, ...
                      carga_frontal_kg, carga_traseira_kg)

    % --- 1. Definição dos Dados Genéricos da Aeronave (Estações e Limites) ---
    % Estes são os parâmetros fixos para este modelo de aeronave.
    % Em um sistema real, estes viriam de um banco de dados da aeronave.

    % Estações (Arms) dos itens de peso (distância do datum em metros)
    estacao_combustivel_m = 15.0;
    estacao_fila1_m = 5.0;
    estacao_fila2_m = 8.0;
    estacao_fila3_m = 12.0;
    estacao_carga_frontal_m = 3.0;
    estacao_carga_traseira_m = 18.0;

    % Outros parâmetros
    densidade_combustivel_kg_por_litro = 0.8; % Ex: 0.8 kg/L (para Jet A-1)
    peso_medio_passageiro_kg = 80;            % Peso médio assumido por passageiro

    % Limites da Aeronave
    mtow_kg = 65000; % Peso Máximo de Decolagem (Maximum Takeoff Weight)
    cg_min_m = 9.0;  % Limite mínimo (mais dianteiro) do CG
    cg_max_m = 11.0; % Limite máximo (mais traseiro) do CG


    % --- 2. Cálculos dos Pesos e Momentos de Cada Item ---

    % Inicializa o peso total e o momento total com o peso vazio
    peso_total_kg = peso_vazio_operacional_kg;
    momento_total_kg_m = peso_vazio_operacional_kg * cg_vazio_m;

    % Combustível
    peso_combustivel_kg = combustivel_litros * densidade_combustivel_kg_por_litro;
    momento_combustivel_kg_m = peso_combustivel_kg * estacao_combustivel_m;
    peso_total_kg = peso_total_kg + peso_combustivel_kg;
    momento_total_kg_m = momento_total_kg_m + momento_combustivel_kg_m;

    % Passageiros
    peso_passageiros_fila1_kg = passageiros_fila1 * peso_medio_passageiro_kg;
    momento_passageiros_fila1_kg_m = peso_passageiros_fila1_kg * estacao_fila1_m;
    peso_total_kg = peso_total_kg + peso_passageiros_fila1_kg;
    momento_total_kg_m = momento_total_kg_m + momento_passageiros_fila1_kg_m;

    peso_passageiros_fila2_kg = passageiros_fila2 * peso_medio_passageiro_kg;
    momento_passageiros_fila2_kg_m = peso_passageiros_fila2_kg * estacao_fila2_m;
    peso_total_kg = peso_total_kg + peso_passageiros_fila2_kg;
    momento_total_kg_m = momento_total_kg_m + momento_passageiros_fila2_kg_m;

    peso_passageiros_fila3_kg = passageiros_fila3 * peso_medio_passageiro_kg;
    momento_passageiros_fila3_kg_m = peso_passageiros_fila3_kg * estacao_fila3_m;
    peso_total_kg = peso_total_kg + peso_passageiros_fila3_kg;
    momento_total_kg_m = momento_total_kg_m + momento_passageiros_fila3_kg_m;

    % Carga
    momento_carga_frontal_kg_m = carga_frontal_kg * estacao_carga_frontal_m;
    peso_total_kg = peso_total_kg + carga_frontal_kg;
    momento_total_kg_m = momento_total_kg_m + momento_carga_frontal_kg_m;

    momento_carga_traseira_kg_m = carga_traseira_kg * estacao_carga_traseira_m;
    peso_total_kg = peso_total_kg + carga_traseira_kg;
    momento_total_kg_m = momento_total_kg_m + momento_carga_traseira_kg_m;


    % --- 3. Cálculo do CG Resultante ---
    % CG = Momento Total / Peso Total
    if peso_total_kg > 0
        cg_resultante_m = momento_total_kg_m / peso_total_kg;
    else
        cg_resultante_m = 0; % Evita divisão por zero se o peso for zero
    end


    % --- 4. Verificação dos Limites Operacionais ---

    % Verificação de Peso
    if peso_total_kg > mtow_kg
        status_peso = "Acima MTOW";
    else
        status_peso = "OK";
    end

    % Verificação de CG
    if cg_resultante_m < cg_min_m
        status_cg = "CG Dianteiro Demais";
    elseif cg_resultante_m > cg_max_m
        status_cg = "CG Traseiro Demais";
    else
        status_cg = "OK";
    end

end