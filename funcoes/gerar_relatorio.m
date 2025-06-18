% Arquivo: Aircraft Data/funcoes/gerar_relatorio.m
%
% Descrição: Gera um relatório detalhado dos cálculos de desempenho de voo,
%            adaptando-se para relatórios de decolagem ou pouso.
%
% Parâmetros de Entrada:
%   dados_entrada         : Estrutura contendo todos os dados de entrada do usuário
%   resultados_wb         : Estrutura contendo os resultados de Massa & Equilíbrio (apenas para decolagem)
%   resultados_desempenho : Estrutura com resultados de desempenho (decolagem ou pouso)
%   resultados_pouso      : Estrutura com resultados de pouso (apenas para pouso)
%   status_final          : String do status final da operação (decolagem ou pouso)
%   modo_operacao         : String indicando o tipo de operação ('decolagem' ou 'pouso' ou 'erro')
%
% Saídas:
%   nome_arquivo_relatorio : Nome do arquivo .txt gerado.

function nome_arquivo_relatorio = gerar_relatorio(dados_entrada, resultados_wb, resultados_desempenho, resultados_pouso, status_final, modo_operacao)

    % --- 1. Formatar o Nome do Arquivo ---
    timestamp = datestr(now, 'yyyymmdd_HHMM');
    % Garantir que o modo_operacao seja válido para o nome do arquivo
    if ~strcmp(modo_operacao, 'decolagem') && ~strcmp(modo_operacao, 'pouso')
        nome_arquivo_relatorio = sprintf('relatorio_%s_ERRO_%s.txt', upper(dados_entrada.aeroporto_icao), timestamp);
    else
        nome_arquivo_relatorio = sprintf('relatorio_%s_%s_%s.txt', upper(dados_entrada.aeroporto_icao), upper(modo_operacao), timestamp);
    end
    
    % --- 2. Abrir o Arquivo para Escrita ---
    fid = fopen(nome_arquivo_relatorio, 'wt');
    if fid == -1
        error('Erro ao criar o arquivo de relatório: %s', nome_arquivo_relatorio);
    end

    % --- 3. Escrever o Cabeçalho do Relatório ---
    fprintf(fid, '===========================================================\n');
    fprintf(fid, '  RELATÓRIO DE DESEMPENHO DE VOO - AIRCRAFT DATA          \n');
    fprintf(fid, '  Operação: %s\n', upper(modo_operacao));
    fprintf(fid, '===========================================================\n');
    fprintf(fid, 'Data e Hora da Geração: %s\n', datestr(now));
    fprintf(fid, '-----------------------------------------------------------\n\n');

    % --- 4. Escrever Dados de Entrada Comuns ---
    fprintf(fid, '--- DADOS DE ENTRADA DA MISSÃO ---\n');
    fprintf(fid, '  Aeroporto Selecionado: %s (Elevação: %.0f ft)\n', ...
            dados_entrada.aeroporto_icao, dados_entrada.elevacao_aeroporto_ft);
    fprintf(fid, '  QNH: %.0f hPa\n', dados_entrada.qnh_hpa);
    fprintf(fid, '  Temperatura Externa do Ar (OAT): %.1f C\n', dados_entrada.temp_ambiente_c);
    fprintf(fid, '  Vento: %.0f kt de %.0f graus\n', dados_entrada.vento_velocidade, dados_entrada.vento_direcao);
    fprintf(fid, '  Altitude de Pressão Calculada: %.0f ft\n\n', dados_entrada.altitude_pressao_ft);


    % --- 5. Escrever Dados Específicos da Operação ---
    if strcmp(modo_operacao, 'decolagem')
        fprintf(fid, '--- CONFIGURAÇÃO E CARREGAMENTO (DECOLAGEM) ---\n');
        % Verificações de existencia de campo para evitar erro com NaN/N/A
        if isfield(dados_entrada, 'combustivel_litros') && ~isnan(dados_entrada.combustivel_litros)
            fprintf(fid, '  Volume de Combustível: %.0f litros\n', dados_entrada.combustivel_litros);
            fprintf(fid, '  Passageiros (Fila 1: %d, Fila 2: %d, Fila 3: %d)\n', ...
                    dados_entrada.passageiros_fila1, dados_entrada.passageiros_fila2, dados_entrada.passageiros_fila3);
            fprintf(fid, '  Carga (Frontal: %.0f kg, Traseira: %.0f kg)\n', ...
                    dados_entrada.carga_frontal_kg, dados_entrada.carga_traseira_kg);
        else
            fprintf(fid, '  Dados de Carregamento: N/A (Não aplicável para este modo de cálculo ou não fornecidos).\n');
        end
        
        if isfield(dados_entrada, 'flap_setting_graus') && ~isnan(dados_entrada.flap_setting_graus)
            fprintf(fid, '  Configuração de Flap (Decolagem): %.0f graus\n\n', dados_entrada.flap_setting_graus);
        else
            fprintf(fid, '  Configuração de Flap (Decolagem): N/A (Não aplicável ou não fornecida).\n\n');
        end

        fprintf(fid, '--- RESULTADOS DE MASSA E EQUILÍBRIO ---\n');
        fprintf(fid, '  Peso Total (GW): ');
        if ~isnan(resultados_wb.peso_total_kg)
            fprintf(fid, '%.2f kg (Status: %s)\n', resultados_wb.peso_total_kg, resultados_wb.status_peso);
        else
            fprintf(fid, 'N/A (Status: %s)\n', resultados_wb.status_peso);
        end
        fprintf(fid, '  CG Resultante: ');
        if ~isnan(resultados_wb.cg_resultante_m)
            fprintf(fid, '%.2f m (Status: %s)\n', resultados_wb.cg_resultante_m, resultados_wb.status_cg);
        else
            fprintf(fid, 'N/A (Status: %s)\n', resultados_wb.status_cg);
        end
        fprintf(fid, '  Massa e Equilíbrio: %s\n\n', resultados_wb.status_geral);

        fprintf(fid, '--- ANÁLISE DE PISTA E DESEMPENHO DE DECOLAGEM ---\n');
        fprintf(fid, '  Pista Sugerida: %02d (Direção %.0f), Comprimento: %.0f m\n', ...
                resultados_desempenho.pista_sugerida_direcao/10, resultados_desempenho.pista_sugerida_direcao, ...
                resultados_desempenho.pista_sugerida_comprimento);
        fprintf(fid, '  Componente de Vento de Proa na Pista Sugerida: %.1f kt\n\n', ...
                resultados_desempenho.componente_vento_proa);
        
        % Detalhes de todas as pistas analisadas (se existirem)
        if isfield(resultados_desempenho, 'detalhes_pistas_analisadas') && ...
           ~isempty(resultados_desempenho.detalhes_pistas_analisadas)
            fprintf(fid, '  Detalhes da Análise de Pistas:\n');
            fprintf(fid, '  ---------------------------------\n');
            for p_idx = 1:length(resultados_desempenho.detalhes_pistas_analisadas)
                p_detalhe = resultados_desempenho.detalhes_pistas_analisadas(p_idx);
                fprintf(fid, '    Pista %02d/%02d (Comp: %.0f m): Vento de Proa: %.1f kt\n', ...
                        p_detalhe.direcao_graus/10, mod(p_detalhe.direcao_graus/10 + 18, 36), ...
                        p_detalhe.comprimento_m, p_detalhe.componente_vento_proa);
            end
            fprintf(fid, '  ---------------------------------\n\n');
        end

        fprintf(fid, '  Distância de Decolagem Normal (TODR): ');
        if isfield(resultados_desempenho, 'distancia_todr_normal') && ~isnan(resultados_desempenho.distancia_todr_normal)
            fprintf(fid, '%.2f m\n', resultados_desempenho.distancia_todr_normal);
        else
            fprintf(fid, 'N/A\n');
        end
        fprintf(fid, '  Velocidade de Rotação (Vr): ');
        if isfield(resultados_desempenho, 'v_r_kt') && ~isnan(resultados_desempenho.v_r_kt)
            fprintf(fid, '%.2f kt\n', resultados_desempenho.v_r_kt);
        else
            fprintf(fid, 'N/A\n');
        end
        fprintf(fid, '  Velocidade de Decisão (V1): ');
        if isfield(resultados_desempenho, 'v1_kt') && ~isnan(resultados_desempenho.v1_kt)
            fprintf(fid, '%.2f kt\n', resultados_desempenho.v1_kt);
        else
            fprintf(fid, 'N/A\n');
        end
        fprintf(fid, '  Distância de Aceleração-Parada Requerida (ASDR): ');
        if isfield(resultados_desempenho, 'distancia_asdr') && ~isnan(resultados_desempenho.distancia_asdr)
            fprintf(fid, '%.2f m\n', resultados_desempenho.distancia_asdr);
        else
            fprintf(fid, 'N/A\n');
        end
        fprintf(fid, '  Distância de Decolagem com 1 Motor Inoperante (TODR OEI): ');
        if isfield(resultados_desempenho, 'distancia_todr_oei') && ~isnan(resultados_desempenho.distancia_todr_oei)
            fprintf(fid, '%.2f m\n\n', resultados_desempenho.distancia_todr_oei);
        else
            fprintf(fid, 'N/A\n\n');
        end

    elseif strcmp(modo_operacao, 'pouso') % Bloco para relatório de pouso
        fprintf(fid, '--- CONFIGURAÇÃO E CARREGAMENTO (POUSO) ---\n');
        if isfield(dados_entrada, 'peso_pouso_kg') && ~isnan(dados_entrada.peso_pouso_kg)
            fprintf(fid, '  Peso de Pouso (GW): %.2f kg\n', dados_entrada.peso_pouso_kg);
        else
            fprintf(fid, '  Peso de Pouso (GW): N/A (Não fornecido ou inválido)\n');
        end
        if isfield(dados_entrada, 'flap_setting_graus_pouso') && ~isnan(dados_entrada.flap_setting_graus_pouso)
            fprintf(fid, '  Configuração de Flap (Pouso): %.0f graus\n\n', dados_entrada.flap_setting_graus_pouso);
        else
            fprintf(fid, '  Configuração de Flap (Pouso): N/A (Não aplicável ou não fornecida)\n\n');
        end
        
        fprintf(fid, '--- RESULTADOS DE DESEMPENHO DE POUSO ---\n');
        % Resultados de pista comuns
        fprintf(fid, '  Pista Sugerida: %02d (Direção %.0f), Comprimento: %.0f m\n', ...
                resultados_desempenho.pista_sugerida_direcao/10, resultados_desempenho.pista_sugerida_direcao, ...
                resultados_desempenho.pista_sugerida_comprimento);
        fprintf(fid, '  Componente de Vento de Proa na Pista Sugerida: %.1f kt\n\n', ...
                resultados_desempenho.componente_vento_proa);
        
        % Detalhes de todas as pistas analisadas (se existirem)
        if isfield(resultados_desempenho, 'detalhes_pistas_analisadas') && ...
           ~isempty(resultados_desempenho.detalhes_pistas_analisadas)
            fprintf(fid, '  Detalhes da Análise de Pistas:\n');
            fprintf(fid, '  ---------------------------------\n');
            for p_idx = 1:length(resultados_desempenho.detalhes_pistas_analisadas)
                p_detalhe = resultados_desempenho.detalhes_pistas_analisadas(p_idx);
                fprintf(fid, '    Pista %02d/%02d (Comp: %.0f m): Vento de Proa: %.1f kt\n', ...
                        p_detalhe.direcao_graus/10, mod(p_detalhe.direcao_graus/10 + 18, 36), ...
                        p_detalhe.comprimento_m, p_detalhe.componente_vento_proa);
            end
            fprintf(fid, '  ---------------------------------\n\n');
        end

        fprintf(fid, '  Distância de Pouso Requerida (LDR): ');
        if isfield(resultados_pouso, 'distancia_ldr') && ~isnan(resultados_pouso.distancia_ldr)
            fprintf(fid, '%.2f m\n', resultados_pouso.distancia_ldr);
        else
            fprintf(fid, 'N/A\n');
        end
        fprintf(fid, '  Velocidade de Aproximação (Vapp): ');
        if isfield(resultados_pouso, 'v_app_kt') && ~isnan(resultados_pouso.v_app_kt)
            fprintf(fid, '%.2f kt\n\n', resultados_pouso.v_app_kt);
        else
            fprintf(fid, 'N/A\n\n');
        end

    else % MODO DE OPERAÇÃO INVÁLIDO OU ERRO
        fprintf(fid, '--- ERRO NO MODO DE OPERAÇÃO ---\n');
        fprintf(fid, '  Não foi possível gerar um relatório detalhado devido a um modo de operação inválido (%s).\n\n', modo_operacao);
    end


    % --- 6. Resumo Final ---
    fprintf(fid, '===========================================================\n');
    if strcmp(status_final, "OK") || strcmp(status_final, "OK - Peso Otimizado Calculado") || strcmp(status_final, "OK - Peso e Flap Otimizados")
        fprintf(fid, '  VEREDITO: OPERAÇÃO PRONTA: CONDIÇÕES OK.\n');
    else
        fprintf(fid, '  VEREDITO: OPERAÇÃO NÃO AUTORIZADA: %s\n', status_final);
    end
    fprintf(fid, '===========================================================\n');

    % --- 7. Fechar o Arquivo ---
    fclose(fid);
end