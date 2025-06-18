% Arquivo: AIRCRAFT_DATA/main_decolagem.m
% Descrição: Script principal para testar a função de cálculo de Desempenho de Decolagem.

clc;        % Limpa a janela de comando do Octave
clear all;  % Limpa todas as variáveis do workspace
close all;  % Fecha todas as janelas de gráficos abertas

fprintf('--- Calculadora de Desempenho de Decolagem ---\n\n');

% --- 1. Dados de Entrada para o Cálculo de Desempenho ---
% Estes seriam os inputs do usuário em uma interface real.

% Dados da Aeronave e Carga
peso_decolagem = 60000; % kg (Exemplo: resultado do cálculo de W&B)

% Condições Ambientais e da Pista
temp_ambiente = 25;       % Graus Celsius (OAT - Outside Air Temperature)
altitude_pressao = 2000;  % Pés (Pressure Altitude)
vento_velocidade = 15;    % nós (Ex: 15 kt)
vento_direcao = 270;      % Graus (Ex: vento de Oeste)
pista_direcao = 290;      % Graus (Ex: Pista 29)
comprimento_pista_disponivel_m = 2000; % Comprimento da pista disponível para decolagem (metros)

fprintf('Dados de Entrada:\n');
fprintf('  Peso de Decolagem: %.2f kg\n', peso_decolagem);
fprintf('  Temperatura Ambiente: %.1f C\n', temp_ambiente);
fprintf('  Altitude de Pressão: %.0f ft\n', altitude_pressao);
fprintf('  Vento: %.0f kt de %.0f graus (Pista %.0f)\n', vento_velocidade, vento_direcao, pista_direcao);
fprintf('  Pista Disponível: %.0f m\n\n', comprimento_pista_disponivel_m);


% --- 2. Adiciona a pasta 'funcoes' ao path do Octave ---
fprintf('Adicionando a pasta ''funcoes'' ao path do Octave...\n');
addpath('funcoes');


% --- 3. Chama a função de cálculo de Desempenho de Decolagem ---
fprintf('Calculando Desempenho de Decolagem...\n');
[distancia_todr, vr, status_perf] = ...
    calcular_desempenho_decolagem(peso_decolagem, temp_ambiente, ...
                                 altitude_pressao, ...
                                 vento_velocidade, vento_direcao, pista_direcao);

fprintf('Cálculo concluído.\n\n');


% --- 4. Exibe os Resultados e Verifica o Comprimento da Pista ---
fprintf('--- Resultados do Desempenho de Decolagem ---\n');
fprintf('  Distância de Decolagem Requerida (TODR): %.2f m\n', distancia_todr);
fprintf('  Velocidade de Rotação (Vr): %.2f kt\n', vr);
fprintf('  Status Preliminar do Desempenho: %s\n', status_perf); % Status interno da função

% Verificação final de pista insuficiente
if (strcmp(status_perf, "OK")) % Se o status da função já não for de erro de peso
    if distancia_todr > comprimento_pista_disponivel_m
        status_final_pista = "Pista Insuficiente";
    else
        status_final_pista = "OK";
    end
else
    status_final_pista = status_perf; % Repassa o status de erro de peso
end

fprintf('  Status Final da Pista: %s\n', status_final_pista);
fprintf('------------------------------------------\n\n');

% Opcional: Remover a pasta do path
% rmpath('funcoes');