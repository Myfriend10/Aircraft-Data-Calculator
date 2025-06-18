% Arquivo: Aircraft Data/funcoes/otimizar_peso_decolagem.m
%
% Descrição: Encontra o peso máximo de decolagem (GW) permitido para uma dada pista
%            e condições ambientais/configuração de flap, garantindo que TODR,
%            ASDR e TODR OEI sejam menores ou iguais ao comprimento da pista,
%            e que o obstáculo seja limpo.
%            Utiliza um algoritmo de BUSCA BINÁRIA para maior eficiência.
%
% Parâmetros de Entrada:
%   comprimento_pista_disponivel_m : Comprimento da pista disponível em metros
%   temp_ambiente_c                : Temperatura ambiente em Celsius
%   altitude_pressao_ft            : Altitude de pressão em pés
%   vento_velocidade_kt            : Velocidade do vento em nós
%   vento_direcao_graus            : Direção do vento em graus
%   pista_direcao_graus            : Direção da pista em graus
%   flap_setting_graus             : Configuração de flap
%   peso_vazio_operacional_kg      : Peso vazio operacional (para limite inferior de busca)
%   mtow_aeronave_kg               : MTOW máximo da aeronave (limite superior de busca)
%   altura_obstaculo_ft            : Altura do obstáculo a ser transposto (pés)
%
% Saídas:
%   peso_max_decolagem_otimizado_kg : O peso máximo permitido para a decolagem
%   status_otimizacao             : String com status ("OK", "Nao foi possivel decolar", "Erro: Flap Invalido")

function [peso_max_decolagem_otimizado_kg, status_otimizacao] = ...
         otimizar_peso_decolagem(comprimento_pista_disponivel_m, temp_ambiente_c, ...
                                 altitude_pressao_ft, ...
                                 vento_velocidade_kt, vento_direcao_graus, ...
                                 pista_direcao_graus, flap_setting_graus, ...
                                 peso_vazio_operacional_kg, mtow_aeronave_kg, ...
                                 altura_obstaculo_ft) % NOVO PARÂMETRO DE ENTRADA

    % --- 1. Parâmetros da Busca Binária ---
    % Range inicial de busca para o peso
    peso_min_busca = peso_vazio_operacional_kg; % Começa a busca a partir do peso vazio da aeronave
    peso_max_busca = mtow_aeronave_kg;
    
    precisao_kg = 10; % Precisão desejada para o peso otimizado (ex: 10 kg)
    max_iter = 100;   % Número máximo de iterações para evitar loops infinitos

    peso_max_decolagem_otimizado_kg = NaN; % Inicializa como NaN
    status_otimizacao = "Nao foi possivel decolar"; % Assume falha inicialmente
    
    % --- 2. Pré-verificação de Flap ---
    % Testar com um peso baixo para ver se o flap é válido (e se a performance básica é OK)
    [~, ~, ~, ~, ~, ~, status_flap_check] = ... % NOVO RETORNO: altura_sobre_obstaculo_oei_ft
        calcular_desempenho_decolagem(peso_min_busca, temp_ambiente_c, ...
                                     altitude_pressao_ft, ...
                                     vento_velocidade_kt, vento_direcao_graus, ...
                                     pista_direcao_graus, flap_setting_graus, ...
                                     altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO
    
    if strcmp(status_flap_check, "Flap Inválido")
        status_otimizacao = "Erro: Flap Inválido";
        return; % Sai da função se o flap for inválido
    end
    
    % --- 3. Executar Busca Binária ---
    fprintf('  Iniciando otimização de peso por Busca Binária (Min: %.0fkg, Max: %.0fkg, Precisão: %.0fkg)...\n', ...
            peso_min_busca, peso_max_busca, precisao_kg);

    peso_otimizado_temp = peso_min_busca; % Armazena o melhor peso encontrado até agora

    for iter = 1:max_iter
        % Ponto médio do intervalo atual
        peso_teste = (peso_min_busca + peso_max_busca) / 2;
        
        % Arredondar para o incremento de peso desejado
        peso_teste = round(peso_teste / precisao_kg) * precisao_kg;

        % Garante que não testamos o mesmo peso repetidamente e que estamos dentro dos limites
        if peso_teste == peso_min_busca || peso_teste == peso_max_busca
            if (peso_max_busca - peso_min_busca) < precisao_kg * 2
                 break;
            end
        end
        
        % Chama a função de desempenho com o peso_teste
        [distancia_todr_normal, ~, ~, distancia_asdr, distancia_todr_oei, altura_sobre_obstaculo_oei_ft, status_perf_interno] = ... % NOVO RETORNO
            calcular_desempenho_decolagem(peso_teste, temp_ambiente_c, ...
                                         altitude_pressao_ft, ...
                                         vento_velocidade_kt, vento_direcao_graus, ...
                                         pista_direcao_graus, flap_setting_graus, ...
                                         altura_obstaculo_ft); % PASSAGEM DO NOVO PARÂMETRO
        
        % Verifica se o peso_teste é válido
        % Uma aeronave é válida se TODAS as condições são satisfeitas:
        eh_valido = false;
        if strcmp(status_perf_interno, "OK") && ... % Garante que o status interno da função é OK
           (distancia_todr_normal <= comprimento_pista_disponivel_m) && ...
           (distancia_asdr <= comprimento_pista_disponivel_m) && ...
           (distancia_todr_oei <= comprimento_pista_disponivel_m) && ...
           (altura_sobre_obstaculo_oei_ft > altura_obstaculo_ft) % Verifica se o obstáculo é limpo
            eh_valido = true;
        end

        if eh_valido
            % Se é válido, tentamos um peso maior. O peso_teste é um candidato.
            peso_otimizado_temp = peso_teste;
            peso_min_busca = peso_teste;
        else
            % Se não é válido, precisamos de um peso menor.
            peso_max_busca = peso_teste;
        end
        
        % Condição de parada: intervalo muito pequeno
        if (peso_max_busca - peso_min_busca) < precisao_kg
            break;
        end
    end
    
    % --- 4. Finalização da Otimização ---
    % O peso_otimizado_temp conterá o maior peso que atendeu às condições.
    % Se nada foi encontrado acima do peso_min_busca, significa que nem o mínimo é possível.
    
    if peso_otimizado_temp >= peso_vazio_operacional_kg && ~isnan(peso_otimizado_temp) % Deve ser >= peso vazio real
        peso_max_decolagem_otimizado_kg = peso_otimizado_temp;
        status_otimizacao = "OK";
        fprintf('  Otimização concluída. Peso máximo encontrado: %.0fkg.\n', peso_max_decolagem_otimizado_kg);
    else
        peso_max_decolagem_otimizado_kg = NaN;
        status_otimizacao = "Nao foi possivel decolar";
        fprintf('  AVISO: Não foi possível encontrar um peso seguro para decolagem nas condições dadas.\n');
    end

end