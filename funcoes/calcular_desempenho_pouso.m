% Arquivo: Aircraft Data/funcoes/calcular_desempenho_pouso.m
%
% Descrição: Função para calcular a distância de pouso requerida (LDR)
%            e a velocidade de aproximação (Vapp) para uma aeronave.
%            Este é um modelo ALTAMENTE SIMPLIFICADO para fins didáticos.
%
% Parâmetros de Entrada:
%   peso_pouso_kg       : Peso bruto da aeronave no pouso (kg)
%   temp_ambiente_c     : Temperatura ambiente em Celsius
%   altitude_pressao_ft : Altitude de pressão do aeroporto em pés
%   vento_velocidade_kt : Velocidade do vento na pista em nós
%   vento_direcao_graus : Direção do vento em graus (0 para norte, 90 para leste, etc.)
%   pista_direcao_graus : Direção da pista em graus (ex: 290 para Pista 29)
%   flap_setting_graus  : Ângulo da configuração de flap para pouso (ex: 30, 40)
%
% Parâmetros de Saída:
%   distancia_pouso_m   : Distância de pouso requerida (LDR) em metros
%   v_app_kt            : Velocidade de aproximação (Vapp) em nós
%   status_pouso        : String com status ("OK", "Peso Excessivo Pouso", "Flap Invalido Pouso", "Performance Insuficiente Pouso")

function [distancia_pouso_m, v_app_kt, status_pouso] = ...
         calcular_desempenho_pouso(peso_pouso_kg, temp_ambiente_c, ...
                                   altitude_pressao_ft, ...
                                   vento_velocidade_kt, vento_direcao_graus, ...
                                   pista_direcao_graus, flap_setting_graus)

    % --- 1. Parâmetros Genéricos da Aeronave para Pouso (Simplificados) ---
    temp_isa_c = 15; % Graus Celsius
    alt_isa_ft = 0;  % Pés
    mlw_kg = 60000;  % Peso Máximo de Pouso (Maximum Landing Weight) - FICTÍCIO

    % Constantes para conversões
    kt_to_mps = 0.514444; % Nós para metros por segundo

    % --- Ajuste de Parâmetros Base com Base na Configuração de Flap de Pouso ---
    status_pouso = "OK";
    
    % Os valores base (ldr_base_m_isa, vapp_base_kt_isa)
    % e fatores de correção serão definidos dentro do switch para cada flap setting.
    
    switch flap_setting_graus
        case 30 % Flaps para Pouso (normal)
            peso_referencia_pouso_kg = 40000; % Peso de referência para cálculos de pouso
            ldr_base_m_isa = 1000; % Distância de pouso base em condições ISA (metros)
            vapp_base_kt_isa = 110; % Velocidade de aproximação base
            
        case 40 % Flaps para Pouso (Full Flaps / Short Field Landing)
            peso_referencia_pouso_kg = 40000;
            ldr_base_m_isa = 800;  % Menor distância de pouso
            vapp_base_kt_isa = 100; % Menor velocidade de aproximação
            
        otherwise
            status_pouso = "Flap Invalido Pouso";
            distancia_pouso_m = NaN;
            v_app_kt = NaN;
            return;
    end

    % --- Fatores de correção LINEARES para Pouso (FICTÍCIOS) ---
    fator_peso_ldr_m_por_kg = 0.04;   % Aumento na LDR por cada kg acima do peso de ref.
    fator_temp_ldr_m_por_c = 7;       % Aumento na LDR por cada grau C acima de ISA
    fator_alt_ldr_m_por_ft = 0.3;     % Aumento na LDR por cada pé acima do nível do mar ISA

    fator_peso_vapp_kt_por_kg = 0.0007; % Aumento na Vapp por cada kg
    fator_temp_vapp_kt_por_c = 0.07;    % Aumento na Vapp por cada C
    fator_alt_vapp_kt_por_ft = 0.003;   % Aumento na Vapp por cada ft

    % Vento para pouso: Headwind REDUZ LDR, Tailwind AUMENTA LDR
    % Este fator será positivo porque o vento de proa REDUZ a distância (multiplicador negativo no cálculo)
    fator_vento_ldr_m_por_kt = -10; % Redução de 10m na LDR por cada nó de headwind


    % --- 2. Cálculos de Fatores de Correção Ambientais e de Peso ---

    delta_peso = peso_pouso_kg - peso_referencia_pouso_kg;
    delta_temp = temp_ambiente_c - temp_isa_c;
    delta_alt = altitude_pressao_ft - alt_isa_ft;

    % Cálculo do componente do vento ao longo da pista (Headwind é positivo para redução da distância)
    % A mesma lógica usada para decolagem
    angulo_diferenca = abs(pista_direcao_graus - vento_direcao_graus);
    if angulo_diferenca > 180
        angulo_diferenca = 360 - angulo_diferenca;
    end
    vento_componente_proa_kt = vento_velocidade_kt * cosd(angulo_diferenca);


    % --- 3. Cálculo da Distância de Pouso (LDR) e Vapp Ajustadas ---

    distancia_pouso_m = ldr_base_m_isa;
    v_app_kt = vapp_base_kt_isa;

    % Ajustes baseados no peso
    distancia_pouso_m = distancia_pouso_m + (delta_peso * fator_peso_ldr_m_por_kg);
    v_app_kt = v_app_kt + (delta_peso * fator_peso_vapp_kt_por_kg);

    % Ajustes baseados na temperatura
    distancia_pouso_m = distancia_pouso_m + (delta_temp * fator_temp_ldr_m_por_c);
    v_app_kt = v_app_kt + (delta_temp * fator_temp_vapp_kt_por_c);

    % Ajustes baseados na altitude de pressão
    distancia_pouso_m = distancia_pouso_m + (delta_alt * fator_alt_ldr_m_por_ft);
    v_app_kt = v_app_kt + (delta_alt * fator_alt_vapp_kt_por_ft);

    % Ajuste para o vento (headwind reduz, tailwind aumenta LDR)
    distancia_pouso_m = distancia_pouso_m + (vento_componente_proa_kt * fator_vento_ldr_m_por_kt);

    % Garantir valores mínimos realistas
    if distancia_pouso_m < 500
        distancia_pouso_m = 500;
    end
    if v_app_kt < 80
        v_app_kt = 80;
    end


    % --- 4. Verificação de Status do Pouso ---
    if strcmp(status_pouso, "OK") % Se o flap não for inválido
        if peso_pouso_kg > mlw_kg
            status_pouso = "Peso Excessivo Pouso";
        end
        % Poderíamos adicionar um limite de distância "muito grande" aqui se desejado
        if distancia_pouso_m > 3500 % Exemplo: se precisar de mais de 3.5km, pode ser insuficiente
            status_pouso = "Performance Insuficiente Pouso";
        end
    end

end