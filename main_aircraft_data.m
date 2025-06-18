% Arquivo: Aircraft Data/main_aircraft_data.m
% Descrição: Script principal para a Calculadora de Desempenho de Aeronaves
%            COMPLETO: Massa & Equilíbrio, Decolagem (Normal/Falha de Motor/Otimização),
%            Sugestão de Pista, Desempenho de Pouso, e Geração de Relatório.
%            ÚLTIMA ATUALIZAÇÃO: Inclusão da Altura do Obstáculo e passagem para funções.

clc;        % Limpa a janela de comando do Octave
clear all;  % Limpa todas as variáveis do workspace
close all;  % Fecha todas as janelas de gráficos abertas

fprintf('====================================================\n');
fprintf('  AIRCRAFT DATA - CALCULADORA DE DESEMPENHO DE VOO  \n');
fprintf('====================================================\n\n');

% --- 1. Configuração do Ambiente ---
fprintf('Configurando ambiente...\n');
addpath('funcoes'); % Adiciona a pasta de funções ao path
load('aeroportos_db.mat'); % Carrega o banco de dados de aeroportos

% Lista os aeroportos disponíveis para o usuário
fprintf('Aeroportos disponíveis no banco de dados: ');
fprintf('%s ', fieldnames(aeroportos){:});
fprintf('\n');


% --- 2. Dados de Entrada Comuns (Simulando a Interface do Usuário / FMS) ---
fprintf('--- Entrada de Dados da Missão ---\n');

% Estrutura para armazenar todos os dados de entrada
dados_entrada = struct();

% Seleção do Aeroporto
aeroporto_icao = upper(input('  Código ICAO do Aeroporto (ex: ESSA): ', 's'));
if ~isfield(aeroportos, aeroporto_icao)
    fprintf('ERRO: Aeroporto %s não encontrado no banco de dados.\n', aeroporto_icao);
    fprintf('Por favor, verifique o código ICAO e tente novamente.\n');
    return; % Aborta o script
end
dados_entrada.aeroporto_icao = aeroporto_icao;

% Carrega os dados do aeroporto selecionado
dados_aeroporto = aeroportos.(aeroporto_icao);
dados_entrada.elevacao_aeroporto_ft = dados_aeroporto.elevacao_ft;
pistas_disponiveis = dados_aeroporto.pistas; % [direcao, comprimento_m; ...]

fprintf('  Aeroporto Selecionado: %s (Elevação: %.0f ft)\n', dados_entrada.aeroporto_icao, dados_entrada.elevacao_aeroporto_ft);


% Parâmetros da Aeronave Base (Estáticos para este modelo)
peso_vazio_operacional = 40000; % kg
cg_vazio = 10.0;                % metros do datum
mtow_aeronave = 65000;          % kg (MTOW máximo da aeronave, para otimização)
mlw_aeronave = 60000;           % kg (MLW máximo da aeronave, para pouso)


% Condições Ambientais (Simulando METAR)
fprintf('\n[Condições Ambientais]\n');
dados_entrada.qnh_hpa = input('  QNH (hPa): ');
dados_entrada.temp_ambiente_c = input('  Temperatura Externa do Ar (OAT em C): ');
dados_entrada.vento_velocidade = input('  Velocidade do Vento (nós - kt): ');
dados_entrada.vento_direcao = input('  Direção do Vento (graus - de onde sopra): ');

% NOVO: Altura do Obstáculo (comum para decolagem e pouso)
dados_entrada.altura_obstaculo_ft = input('  Altura do Obstáculo na Extensão da Pista (pés, ex: 0 para pista livre): ');


% --- Opção de Cálculo: (Agora com Pouso) ---
fprintf('\n[Modo de Cálculo]\n');
fprintf('  1 para Calcular Desempenho de Decolagem para um Peso e Flap dados\n');
fprintf('  2 para Otimizar Peso de Decolagem para um Flap dado\n');
fprintf('  3 para Otimizar Peso E Flap de Decolagem (encontrar o melhor Flap para o maior peso)\n');
fprintf('  4 para Calcular Desempenho de Pouso\n');
modo_calculo_str = input('  Escolha o modo: ', 's');
modo_calculo = str2num(modo_calculo_str);


fprintf('\nDados de entrada coletados. Processando...\n');


% --- 3. Cálculo da Altitude de Pressão ---
qnh_in_hg = dados_entrada.qnh_hpa / 33.86375;
dados_entrada.altitude_pressao_ft = dados_entrada.elevacao_aeroporto_ft + (29.92 - qnh_in_hg) * 1000;
fprintf('  Altitude de Pressão Calculada: %.0f ft\n', dados_entrada.altitude_pressao_ft);


% --- 4. Análise e Sugestão de Pista (Comum para todos os modos) ---
fprintf('\n--- Análise e Sugestão de Pista ---\n');
melhor_pista_direcao_graus = 0;
maior_componente_proa = -inf;
melhor_pista_comprimento = 0;
componente_vento_proa_sugerida = 0;

% Inicializa a estrutura de detalhes das pistas ANTES do loop
detalhes_pistas_analisadas = struct('direcao_graus', {}, 'comprimento_m', {}, 'componente_vento_proa', {});
idx_pista = 0; % Contador para o índice da estrutura

fprintf('Pistas disponíveis para %s:\n', dados_entrada.aeroporto_icao);
for p = 1:size(pistas_disponiveis, 1)
    pista_dir_base = pistas_disponiveis(p, 1);
    pista_dir_graus = pista_dir_base * 10;
    pista_comp = pistas_disponiveis(p, 2);

    angulo_relativo = abs(pista_dir_graus - dados_entrada.vento_direcao);
    if angulo_relativo > 180
        angulo_relativo = 360 - angulo_relativo;
    end
    
    componente_proa = dados_entrada.vento_velocidade * cosd(angulo_relativo);

    fprintf('  Pista %02d/%02d (Direção %.0f, Comp: %.0f m): Vento de Proa: %.1f kt\n', ...
            pista_dir_base, mod(pista_dir_base + 18, 36), pista_dir_graus, pista_comp, componente_proa);

    % Armazena os detalhes desta pista
    idx_pista = idx_pista + 1;
    detalhes_pistas_analisadas(idx_pista).direcao_graus = pista_dir_graus;
    detalhes_pistas_analisadas(idx_pista).comprimento_m = pista_comp;
    detalhes_pistas_analisadas(idx_pista).componente_vento_proa = componente_proa;

    if componente_proa > maior_componente_proa
        maior_componente_proa = componente_proa;
        melhor_pista_direcao_graus = pista_dir_graus;
        melhor_pista_comprimento = pista_comp;
        componente_vento_proa_sugerida = componente_proa;
    end
end

if melhor_pista_direcao_graus > 0
    fprintf('\n  Pista Sugerida para Decolagem/Pouso: %02d (Direção %.0f), Comprimento: %.0f m\n', ...
            melhor_pista_direcao_graus/10, melhor_pista_direcao_graus, melhor_pista_comprimento);
    pista_direcao_selecionada = melhor_pista_direcao_graus;
    comprimento_pista_disponivel_m = melhor_pista_comprimento;
else
    fprintf('\n  AVISO: Não foi possível sugerir uma pista. Usando a primeira pista disponível como padrão.\n');
    pista_direcao_selecionada = pistas_disponiveis(1,1) * 10;
    comprimento_pista_disponivel_m = pistas_disponiveis(1,2);
    componente_vento_proa_sugerida = dados_entrada.vento_velocidade * cosd(abs(pista_direcao_selecionada - dados_entrada.vento_direcao));
end

% Armazenar resultados de pista na estrutura de desempenho para o relatório
resultados_desempenho_pista = struct();
resultados_desempenho_pista.pista_sugerida_direcao = pista_direcao_selecionada;
resultados_desempenho_pista.pista_sugerida_comprimento = comprimento_pista_disponivel_m;
resultados_desempenho_pista.componente_vento_proa = componente_vento_proa_sugerida;
resultados_desempenho_pista.detalhes_pistas_analisadas = detalhes_pistas_analisadas;


% --- 5. Lógica de Execução com Base no Modo Escolhido ---

% Inicializa variáveis de entrada que podem não ser preenchidas em todos os modos, mas são usadas no relatório
dados_entrada.combustivel_litros = NaN; 
dados_entrada.passageiros_fila1 = NaN; 
dados_entrada.passageiros_fila2 = NaN; 
dados_entrada.passageiros_fila3 = NaN; 
dados_entrada.carga_frontal_kg = NaN; 
dados_entrada.carga_traseira_kg = NaN; 
dados_entrada.peso_total_decolagem_kg = NaN; % Pode ser preenchido ou otimizado
dados_entrada.flap_setting_graus = NaN; % Para decolagem
dados_entrada.peso_pouso_kg = NaN; % Para pouso
dados_entrada.flap_setting_graus_pouso = NaN; % Para pouso


% Inicializa estruturas de resultados para evitar erros no relatório
resultados_wb = struct('peso_total_kg', NaN, 'cg_resultante_m', NaN, 'status_peso', 'N/A', 'status_cg', 'N/A', 'status_geral', 'N/A');
resultados_desempenho = resultados_desempenho_pista; % Começa com dados da pista, resto NaN
resultados_desempenho.distancia_todr_normal = NaN; 
resultados_desempenho.v_r_kt = NaN;
resultados_desempenho.v1_kt = NaN;
resultados_desempenho.distancia_asdr = NaN;
resultados_desempenho.distancia_todr_oei = NaN;
resultados_desempenho.status_interno = "N/A";
resultados_desempenho.altura_sobre_obstaculo_oei_ft = NaN; % NOVO: para relatório

resultados_pouso = struct(); % Nova estrutura para resultados de pouso
resultados_pouso.distancia_ldr = NaN;
resultados_pouso.v_app_kt = NaN;
resultados_pouso.status_interno = "N/A";


status_final_geral_script = "N/A"; % Veredito final


if modo_calculo == 1 % CALCULAR DESEMPENHO PARA UM PESO E FLAP DADOS (DECOLAGEM)
    fprintf('\n--- MODO: CALCULAR DESEMPENHO DECOLAGEM PARA PESO E FLAP DADOS ---\n');
    modo_operacao = 'decolagem'; 

    % Peso e Balanceamento: Solicita os dados de carregamento
    fprintf('\n[Peso e Balanceamento]\n');
    dados_entrada.combustivel_litros = input('  Volume de Combustível (litros): ');
    dados_entrada.passageiros_fila1 = input('  Passageiros na Fila 1: ');
    dados_entrada.passageiros_fila2 = input('  Passageiros na Fila 2: ');
    dados_entrada.passageiros_fila3 = input('  Passageiros na Fila 3: ');
    dados_entrada.carga_frontal_kg = input('  Carga Compartimento Frontal (kg): ');
    dados_entrada.carga_traseira_kg = input('  Carga Compartimento Traseira (kg): ');

    [peso_total_decolagem_kg_wb, cg_final_m, status_w, status_c] = ...
        calcular_w_b(peso_vazio_operacional, cg_vazio, ...
                     dados_entrada.combustivel_litros, ...
                     dados_entrada.passageiros_fila1, dados_entrada.passageiros_fila2, dados_entrada.passageiros_fila3, ...
                     dados_entrada.carga_frontal_kg, dados_entrada.carga_traseira_kg);

    % Preencher resultados_wb
    resultados_wb.peso_total_kg = peso_total_decolagem_kg_wb;
    resultados_wb.cg_resultante_m = cg_final_m;
    resultados_wb.status_peso = status_w;
    resultados_wb.status_cg = status_c;
    
    fprintf('  Peso Total (GW): %.2f kg (Status: %s)\n', resultados_wb.peso_total_kg, resultados_wb.status_peso);
    fprintf('  CG Resultante: %.2f m (Status: %s)\n', resultados_wb.cg_resultante_m, resultados_wb.status_cg);

    % Solicita o flap setting para este modo
    flaps_validos = [0, 5, 10, 20];
    input_valido_flap = false;
    while ~input_valido_flap
        flap_str = input('  Configuração de Flap para Decolagem (0, 5, 10 ou 20 graus): ', 's');
        flap_num = str2num(flap_str);
        if isscalar(flap_num) && any(flap_num == flaps_validos)
            dados_entrada.flap_setting_graus = flap_num;
            input_valido_flap = true;
        else
            fprintf('    !!! ERRO: Flap inválido. Por favor, digite 0, 5, 10 ou 20. !!!\n');
        end
    end

    % Verificação Crítica de W&B
    if (strcmp(resultados_wb.status_peso, "Acima MTOW") || strcmp(resultados_wb.status_cg, "CG Dianteiro Demais") || strcmp(resultados_wb.status_cg, "CG Traseiro Demais"))
        fprintf('\n!!! ALERTA DE SEGURANÇA: Problema no Peso e/ou CG. Não é seguro prosseguir com a decolagem. !!!\n');
        resultados_wb.status_geral = "Problema de Peso/CG";
        status_final_geral_script = "Problema de Peso/CG";
        
        % Definir valores de desempenho como NaN em caso de erro de W&B para o relatório
        resultados_desempenho.distancia_todr_normal = NaN;
        resultados_desempenho.v_r_kt = NaN;
        resultados_desempenho.v1_kt = NaN;
        resultados_desempenho.distancia_asdr = NaN;
        resultados_desempenho.distancia_todr_oei = NaN;
        resultados_desempenho.status_interno = "Problema de W&B";
        resultados_desempenho.altura_sobre_obstaculo_oei_ft = NaN; % Novo campo
        
        fprintf('====================================================\n');
        fprintf('  VEREDITO: VOO NÃO AUTORIZADO: %s\n', status_final_geral_script);
        fprintf('====================================================\n');
        return; 

    else
        resultados_wb.status_geral = "OK";
        fprintf('  Massa e Equilíbrio: OK. Prosseguindo para o desempenho de decolagem.\n');
    end

    % Cálculo de Desempenho de Decolagem Completo
    fprintf('\n--- Calculando Desempenho de Decolagem (Normal e Falha de Motor) ---\n');
    [distancia_todr_normal, vr_kt, v1_kt, distancia_asdr, distancia_todr_oei, altura_sobre_obstaculo_oei_ft, status_perf_interno] = ...
        calcular_desempenho_decolagem(resultados_wb.peso_total_kg, dados_entrada.temp_ambiente_c, ...
                                     dados_entrada.altitude_pressao_ft, ...
                                     dados_entrada.vento_velocidade, dados_entrada.vento_direcao, pista_direcao_selecionada, ...
                                     dados_entrada.flap_setting_graus, ...
                                     dados_entrada.altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO

    % Preencher resultados_desempenho
    resultados_desempenho.distancia_todr_normal = distancia_todr_normal;
    resultados_desempenho.v_r_kt = vr_kt;
    resultados_desempenho.v1_kt = v1_kt;
    resultados_desempenho.distancia_asdr = distancia_asdr;
    resultados_desempenho.distancia_todr_oei = distancia_todr_oei;
    resultados_desempenho.status_interno = status_perf_interno;
    resultados_desempenho.altura_sobre_obstaculo_oei_ft = altura_sobre_obstaculo_oei_ft; % NOVO PREENCHIMENTO

    if strcmp(resultados_desempenho.status_interno, "Flap Inválido")
        fprintf('\n!!! ERRO: Configuração de Flap Inválida. Decolagem não calculada. !!!\n');
        status_final_geral_script = "Flap Inválido";
    elseif strcmp(resultados_desempenho.status_interno, "Peso Excessivo")
        fprintf('\n!!! ALERTA: Peso Excessivo para esta configuração. Verifique MTOW. !!!\n');
    elseif strcmp(resultados_desempenho.status_interno, "Performance Insuficiente")
        fprintf('\n!!! ALERTA: Performance Insuficiente nas condições atuais. !!!\n');
    elseif strcmp(resultados_desempenho.status_interno, "Obstaculo Nao Limpo")
        fprintf('\n!!! ALERTA: Obstáculo Não Limpo. Decolagem não autorizada. !!!\n');
    elseif strcmp(resultados_desempenho.status_interno, "TODR OEI Excede Pista")
        fprintf('\n!!! ALERTA: TODR OEI excede pista. Decolagem não autorizada. !!!\n');
    end


    fprintf('  Distância de Decolagem Normal (TODR): %.2f m\n', resultados_desempenho.distancia_todr_normal);
    fprintf('  Velocidade de Rotação (Vr): %.2f kt\n', resultados_desempenho.v_r_kt);
    fprintf('  Velocidade de Decisão (V1): %.2f kt\n', resultados_desempenho.v1_kt);
    fprintf('  Distância de Aceleração-Parada Requerida (ASDR): %.2f m\n', resultados_desempenho.distancia_asdr);
    fprintf('  Distância de Decolagem com 1 Motor Inoperante (TODR OEI): %.2f m\n', resultados_desempenho.distancia_todr_oei);
    fprintf('  Altura Sobre Obstáculo (TODR OEI): %.2f ft\n', resultados_desempenho.altura_sobre_obstaculo_oei_ft); % NOVO OUTPUT


    % Verificação Final de Pista e Performance
    status_final_geral_script = "OK";

    if distancia_todr_normal > resultados_desempenho.pista_sugerida_comprimento
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = "Pista Insuficiente para Decolagem Normal";
        else
            status_final_geral_script = [status_final_geral_script, ', Pista Insuficiente para Decolagem Normal'];
        end
    end

    if distancia_asdr > resultados_desempenho.pista_sugerida_comprimento
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = "Pista Insuficiente para Aceleração-Parada";
        else
            status_final_geral_script = [status_final_geral_script, ', Pista Insuficiente para Aceleração-Parada'];
        end
    end

    if distancia_todr_oei > resultados_desempenho.pista_sugerida_comprimento
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = "Pista Insuficiente para Decolagem c/ Motor Inoperante";
        else
            status_final_geral_script = [status_final_geral_script, ', Pista Insuficiente para Decolagem c/ Motor Inoperante'];
        end
    end
    
    % NOVO: Verificação de Obstáculo no status final
    if resultados_desempenho.altura_sobre_obstaculo_oei_ft <= dados_entrada.altura_obstaculo_ft && resultados_desempenho.altura_sobre_obstaculo_oei_ft ~= -inf
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = "Obstaculo Nao Limpo";
        else
            status_final_geral_script = [status_final_geral_script, ', Obstaculo Nao Limpo'];
        end
    end
    if resultados_desempenho.altura_sobre_obstaculo_oei_ft == -inf % Caso de TODR OEI já excede pista (vem do status interno)
         if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = "TODR OEI Excede Pista";
        else
            status_final_geral_script = [status_final_geral_script, ', TODR OEI Excede Pista'];
        end
    end


    if ~strcmp(resultados_desempenho.status_interno, "OK") && ~strcmp(resultados_desempenho.status_interno, "Flap Inválido") && ~strcmp(resultados_desempenho.status_interno, "Obstaculo Nao Limpo") && ~strcmp(resultados_desempenho.status_interno, "TODR OEI Excede Pista")
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = resultados_desempenho.status_interno;
        else
            status_final_geral_script = [status_final_geral_script, ', ', resultados_desempenho.status_interno];
        end
    end


    fprintf('  Comprimento da Pista Sugerida/Usada: %.0f m\n', resultados_desempenho.pista_sugerida_comprimento);
    fprintf('  Status Final da Performance de Decolagem: %s\n', status_final_geral_script);


elseif modo_calculo == 2 % OTIMIZAR PESO PARA UM FLAP DADO (DECOLAGEM)
    fprintf('\n--- MODO: OTIMIZAR PESO PARA FLAP DADO ---\n');
    modo_operacao = 'decolagem';

    % NÂO pede dados de W&B aqui, usa os dados otimizados para o relatório
    dados_entrada.combustivel_litros = NaN; 
    dados_entrada.passageiros_fila1 = NaN; 
    dados_entrada.passageiros_fila2 = NaN; 
    dados_entrada.passageiros_fila3 = NaN; 
    dados_entrada.carga_frontal_kg = NaN; 
    dados_entrada.carga_traseira_kg = NaN; 

    % Solicita o flap setting para este modo
    flaps_validos = [0, 5, 10, 20];
    input_valido_flap = false;
    while ~input_valido_flap
        flap_str = input('  Configuração de Flap para Decolagem (0, 5, 10 ou 20 graus): ', 's');
        flap_num = str2num(flap_str);
        if isscalar(flap_num) && any(flap_num == flaps_validos)
            dados_entrada.flap_setting_graus = flap_num;
            input_valido_flap = true;
        else
            fprintf('    !!! ERRO: Flap inválido. Por favor, digite 0, 5, 10 ou 20. !!!\n');
        end
    end

    % Chama a função de otimização de peso
    [peso_otimizado, status_otimizacao] = ...
        otimizar_peso_decolagem(comprimento_pista_disponivel_m, dados_entrada.temp_ambiente_c, ...
                                 dados_entrada.altitude_pressao_ft, ...
                                 dados_entrada.vento_velocidade, dados_entrada.vento_direcao, ...
                                 pista_direcao_selecionada, dados_entrada.flap_setting_graus, ...
                                 peso_vazio_operacional, mtow_aeronave, ...
                                 dados_entrada.altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO

    fprintf('\n--- Resultados da Otimização de Peso ---\n');
    if strcmp(status_otimizacao, "OK")
        fprintf('  Peso Máximo de Decolagem Permitido para a Pista: %.2f kg\n', peso_otimizado);
        fprintf('  Verifique o W&B para este peso se desejar prosseguir com a decolagem.\n');
        status_final_geral_script = "OK - Peso Otimizado Calculado";
    else
        fprintf('  Erro na Otimização: %s\n', status_otimizacao);
        status_final_geral_script = ['Erro na Otimização: ', status_otimizacao];
    end

    % Preencher resultados_wb (com peso otimizado - simulado) para o relatório
    resultados_wb.peso_total_kg = peso_otimizado;
    resultados_wb.cg_resultante_m = NaN; 
    resultados_wb.status_peso = status_otimizacao;
    resultados_wb.status_cg = "N/A";
    resultados_wb.status_geral = status_otimizacao;

    % Preencher resultados_desempenho (simulado para relatório)
    resultados_desempenho = resultados_desempenho_pista;
    resultados_desempenho.distancia_todr_normal = NaN; % Não é exibido aqui
    resultados_desempenho.v_r_kt = NaN;
    resultados_desempenho.v1_kt = NaN;
    resultados_desempenho.distancia_asdr = NaN;
    resultados_desempenho.distancia_todr_oei = NaN;
    resultados_desempenho.status_interno = status_otimizacao;
    resultados_desempenho.altura_sobre_obstaculo_oei_ft = NaN; % Não recalculado aqui

elseif modo_calculo == 3 % OTIMIZAR PESO E FLAP (DECOLAGEM)
    fprintf('\n--- MODO: OTIMIZAR PESO E FLAP ---\n');
    modo_operacao = 'decolagem';

    % NÂO pede dados de W&B aqui
    dados_entrada.combustivel_litros = NaN; 
    dados_entrada.passageiros_fila1 = NaN; 
    dados_entrada.passageiros_fila2 = NaN; 
    dados_entrada.passageiros_fila3 = NaN; 
    dados_entrada.carga_frontal_kg = NaN; 
    dados_entrada.carga_traseira_kg = NaN; 
    dados_entrada.peso_total_decolagem_kg = NaN; % Será o peso otimizado final

    melhor_peso_geral = -inf; % Inicializa com o menor possível
    melhor_flap_geral = NaN;
    
    % Flaps válidos para iteração
    flaps_validos = [0, 5, 10, 20];

    fprintf('\n  Iniciando otimização para cada configuração de Flap...\n');

    for k = 1:length(flaps_validos)
        flap_atual = flaps_validos(k);
        fprintf('\n  Testando Flap: %.0f graus\n', flap_atual);

        % Chama a otimização de peso para o flap atual
        [peso_otimizado_para_flap, status_otimizacao_flap] = ...
            otimizar_peso_decolagem(comprimento_pista_disponivel_m, dados_entrada.temp_ambiente_c, ...
                                     dados_entrada.altitude_pressao_ft, ...
                                     dados_entrada.vento_velocidade, dados_entrada.vento_direcao, ...
                                     pista_direcao_selecionada, flap_atual, ...
                                     peso_vazio_operacional, mtow_aeronave, ...
                                     dados_entrada.altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO
        
        if strcmp(status_otimizacao_flap, "OK") && peso_otimizado_para_flap > melhor_peso_geral
            melhor_peso_geral = peso_otimizado_para_flap;
            melhor_flap_geral = flap_atual;
        end
    end

    fprintf('\n--- Resultados da Otimização de Peso e Flap ---\n');
    if melhor_peso_geral > -inf % Se um peso válido foi encontrado
        fprintf('  Peso Máximo de Decolagem Otimizado: %.2f kg\n', melhor_peso_geral);
        fprintf('  Melhor Configuração de Flap: %.0f graus\n', melhor_flap_geral);
        fprintf('  Verifique o W&B para este peso e use esta configuração de flap.\n');
        status_final_geral_script = "OK - Peso e Flap Otimizados";
        
        % Atualiza dados_entrada para o relatório com o melhor flap e peso
        dados_entrada.flap_setting_graus = melhor_flap_geral;
        dados_entrada.peso_total_decolagem_kg = melhor_peso_geral;

        % Preencher resultados_wb (simulado) para o relatório
        resultados_wb.peso_total_kg = melhor_peso_geral;
        resultados_wb.cg_resultante_m = NaN; 
        resultados_wb.status_peso = "OK - Otimizado";
        resultados_wb.status_cg = "N/A";
        resultados_wb.status_geral = "OK - Peso e Flap Otimizados";

        % Preencher resultados_desempenho (simulado) para o relatório com o melhor flap
        % Vamos recalcular o desempenho para o melhor peso e flap para ter dados no relatório
        [distancia_todr_normal, vr_kt, v1_kt, distancia_asdr, distancia_todr_oei, altura_sobre_obstaculo_oei_ft, status_perf_interno] = ... % NOVO RETORNO
            calcular_desempenho_decolagem(melhor_peso_geral, dados_entrada.temp_ambiente_c, ...
                                         dados_entrada.altitude_pressao_ft, ...
                                         dados_entrada.vento_velocidade, dados_entrada.vento_direcao, ...
                                         pista_direcao_selecionada, melhor_flap_geral, ...
                                         dados_entrada.altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO
        
        resultados_desempenho = resultados_desempenho_pista;
        resultados_desempenho.distancia_todr_normal = distancia_todr_normal;
        resultados_desempenho.v_r_kt = vr_kt;
        resultados_desempenho.v1_kt = v1_kt;
        resultados_desempenho.distancia_asdr = distancia_asdr;
        resultados_desempenho.distancia_todr_oei = distancia_todr_oei;
        resultados_desempenho.status_interno = status_perf_interno;
        resultados_desempenho.altura_sobre_obstaculo_oei_ft = altura_sobre_obstaculo_oei_ft; % NOVO PREENCHIMENTO


    else
        fprintf('  AVISO: Não foi possível encontrar uma configuração de peso/flap segura para decolagem.\n');
        status_final_geral_script = "Nao foi possivel decolar com nenhum flap";

        % Preencher resultados com NaN/N/A para o relatório
        dados_entrada.flap_setting_graus = NaN;
        dados_entrada.peso_total_decolagem_kg = NaN;
        resultados_wb = struct('peso_total_kg', NaN, 'cg_resultante_m', NaN, 'status_peso', 'Erro', 'status_cg', 'Erro', 'status_geral', 'Erro');
        resultados_desempenho = resultados_desempenho_pista;
        resultados_desempenho.distancia_todr_normal = NaN;
        resultados_desempenho.v_r_kt = NaN;
        resultados_desempenho.v1_kt = NaN;
        resultados_desempenho.distancia_asdr = NaN;
        resultados_desempenho.distancia_todr_oei = NaN;
        resultados_desempenho.status_interno = "Erro na Otimização Total";
        resultados_desempenho.altura_sobre_obstaculo_oei_ft = NaN; % Novo campo
    end

elseif modo_calculo == 4 % NOVO: CALCULAR DESEMPENHO DE POUSO
    fprintf('\n--- MODO: CALCULAR DESEMPENHO DE POUSO ---\n');
    modo_operacao = 'pouso'; 

    % Solicita o peso de pouso
    dados_entrada.peso_pouso_kg = input('  Peso de Pouso (GW) (kg): ');

    % Solicita o flap setting para pouso
    flaps_validos_pouso = [30, 40];
    input_valido_flap_pouso = false;
    while ~input_valido_flap_pouso
        flap_pouso_str = input('  Configuração de Flap para Pouso (30 ou 40 graus): ', 's');
        flap_pouso_num = str2num(flap_pouso_str);
        if isscalar(flap_pouso_num) && any(flap_pouso_num == flaps_validos_pouso)
            dados_entrada.flap_setting_graus_pouso = flap_pouso_num;
            input_valido_flap_pouso = true;
        else
            fprintf('    !!! ERRO: Flap inválido para Pouso. Por favor, digite 30 ou 40. !!!\n');
        end
    end

    % Chama a função de cálculo de desempenho de pouso
    [distancia_ldr, v_app_kt, status_pouso_interno] = ...
        calcular_desempenho_pouso(dados_entrada.peso_pouso_kg, dados_entrada.temp_ambiente_c, ...
                                 dados_entrada.altitude_pressao_ft, ...
                                 dados_entrada.vento_velocidade, dados_entrada.vento_direcao, ...
                                 pista_direcao_selecionada, dados_entrada.flap_setting_graus_pouso);

    % Preencher resultados_pouso
    resultados_pouso.distancia_ldr = distancia_ldr;
    resultados_pouso.v_app_kt = v_app_kt;
    resultados_pouso.status_interno = status_pouso_interno;

    fprintf('  Distância de Pouso Requerida (LDR): %.2f m\n', resultados_pouso.distancia_ldr);
    fprintf('  Velocidade de Aproximação (Vapp): %.2f kt\n', resultados_pouso.v_app_kt);

    % Verificação Final de Pista para Pouso
    status_final_geral_script = "OK";
    if resultados_pouso.distancia_ldr > resultados_desempenho_pista.pista_sugerida_comprimento
        status_final_geral_script = "Pista Insuficiente para Pouso";
    end
    if ~strcmp(resultados_pouso.status_interno, "OK")
        if strcmp(status_final_geral_script, "OK")
            status_final_geral_script = resultados_pouso.status_interno;
        else
            status_final_geral_script = [status_final_geral_script, ', ', resultados_pouso.status_interno];
        end
    end
    fprintf('  Comprimento da Pista Sugerida/Usada: %.0f m\n', resultados_desempenho_pista.pista_sugerida_comprimento);
    fprintf('  Status Final da Performance de Pouso: %s\n', status_final_geral_script);

else % MODO INVÁLIDO
    fprintf('\n!!! ERRO: Modo de cálculo inválido. Por favor, escolha 1, 2, 3 ou 4. !!!\n');
    status_final_geral_script = "Modo de Cálculo Inválido";
    modo_operacao = 'erro'; % CORREÇÃO: Define o modo de operação como erro

    % Inicializa estruturas com NaN/N/A para o relatório, em caso de modo inválido
    dados_entrada.combustivel_litros = NaN; 
    dados_entrada.passageiros_fila1 = NaN; 
    dados_entrada.passageiros_fila2 = NaN; 
    dados_entrada.passageiros_fila3 = NaN; 
    dados_entrada.carga_frontal_kg = NaN; 
    dados_entrada.carga_traseira_kg = NaN; 
    dados_entrada.peso_total_decolagem_kg = NaN;
    dados_entrada.qnh_hpa = NaN;
    dados_entrada.temp_ambiente_c = NaN;
    dados_entrada.vento_velocidade = NaN;
    dados_entrada.vento_direcao = NaN;
    dados_entrada.flap_setting_graus = NaN;
    dados_entrada.peso_pouso_kg = NaN; 
    dados_entrada.flap_setting_graus_pouso = NaN; 
    dados_entrada.altitude_pressao_ft = NaN; 

    resultados_wb = struct('peso_total_kg', NaN, 'cg_resultante_m', NaN, 'status_peso', 'Erro', 'status_cg', 'Erro', 'status_geral', 'Erro');
    
    resultados_desempenho = resultados_desempenho_pista; 
    resultados_desempenho.distancia_todr_normal = NaN;
    resultados_desempenho.v_r_kt = NaN;
    resultados_desempenho.v1_kt = NaN;
    resultados_desempenho.distancia_asdr = NaN;
    resultados_desempenho.distancia_todr_oei = NaN;
    resultados_desempenho.status_interno = "Modo Inválido";
    resultados_desempenho.altura_sobre_obstaculo_oei_ft = NaN;

    resultados_pouso = struct(); 
    resultados_pouso.distancia_ldr = NaN;
    resultados_pouso.v_app_kt = NaN;
    resultados_pouso.status_interno = "Modo Inválido";

end


% --- Resumo Final e Geração de Relatório (Comum para todos os modos) ---
fprintf('\n====================================================\n');
if strcmp(status_final_geral_script, "OK") || strcmp(status_final_geral_script, "OK - Peso Otimizado Calculado") || strcmp(status_final_geral_script, "OK - Peso e Flap Otimizados")
    fprintf('  VEREDITO: OPERAÇÃO PRONTA: CONDIÇÕES OK.\n');
else
    fprintf('  VEREDITO: OPERAÇÃO NÃO AUTORIZADA: %s\n', status_final_geral_script);
end
fprintf('====================================================\n');

% Chamada da função para gerar o relatório
nome_relatorio_gerado = gerar_relatorio(dados_entrada, resultados_wb, resultados_desempenho, resultados_pouso, status_final_geral_script, modo_operacao);
fprintf('\nRelatório gerado: %s\n', nome_relatorio_gerado);

% Opcional: Remover a pasta do path
% rmpath('funcoes');