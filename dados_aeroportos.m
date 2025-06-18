% Arquivo: AIRCRAFT_DATA/dados_aeroportos.m
% Descrição: Script para criar e salvar um "banco de dados" simplificado de aeroportos.
%            Execute este script UMA VEZ para gerar o arquivo 'aeroportos_db.mat'.

clc; clear all; close all;

fprintf('--- Criando Banco de Dados de Aeroportos --- \n');

% Estrutura de dados para armazenar os aeroportos
% Cada aeroporto é uma célula com:
% {ICAO_CODE, Elevacao_ft, [Pista1_Direcao, Pista1_Comprimento; Pista2_Direcao, Pista2_Comprimento; ...]}

% Aeroporto 1: SBKP (Campinas/Viracopos - Exemplo)
aeroportos.SBKP.elevacao_ft = 2171;
aeroportos.SBKP.pistas = [
    15, 3263;  % Pista 15/33 (Direção 150, Comprimento 3263m)
    33, 3263   % Direção 330
];

% Aeroporto 2: SBGR (Guarulhos - Exemplo)
aeroportos.SBGR.elevacao_ft = 2470;
aeroportos.SBGR.pistas = [
    09, 3700;  % Pista 09/27 (Direção 090, Comprimento 3700m)
    27, 3700;
    10, 3000;  % Pista 10/28 (Direção 100, Comprimento 3000m)
    28, 3000
];

% Aeroporto 3: ESSA (Malmö - seu exemplo da imagem)
aeroportos.ESSA.elevacao_ft = 237;
aeroportos.ESSA.pistas = [
    11, 2800;  % Pista 11/29 (Direção 110, Comprimento 2800m)
    29, 2800
];

% Aeroporto 4: SBTP (Palmas)
aeroportos.SBTP.elevacao_ft = 771;
aeroportos.SBTP.pistas = [
    13, 3300;
    31, 3300
];

% Aeroporto 5: SBBR (Brasília)
aeroportos.SBBR.elevacao_ft = 3497;
aeroportos.SBBR.pistas = [
    11, 3300;
    29, 3300
];

% Aeroporto 6: SBEG (Manaus)
aeroportos.SBEG.elevacao_ft = 262;
aeroportos.SBEG.pistas = [
    10, 2700;
    28, 2700
];

% Aeroporto 7: SBBE (Belém)
aeroportos.SBBE.elevacao_ft = 43;
aeroportos.SBBE.pistas = [
    06, 2530;
    24, 2530
];

% Aeroporto 8: SBCF (Confins/Belo Horizonte)
aeroportos.SBCF.elevacao_ft = 2736;
aeroportos.SBCF.pistas = [
    16, 3000;
    34, 3000
];


% Salva a estrutura 'aeroportos' em um arquivo .mat
save ('aeroportos_db.mat', 'aeroportos');

fprintf('Banco de dados de aeroportos "aeroportos_db.mat" criado com sucesso.\n');
fprintf('Aeroportos cadastrados: SBKP, SBGR, ESSA.\n');