% Arquivo: Aircraft Data/funcoes/calcular_desempenho_decolagem.m
%
% Descrição: Função para calcular a distância de decolagem e a velocidade de rotação (Vr),
%            INCLUINDO ANÁLISE DE FALHA DE MOTOR (ASDR, TODR OEI, V1),
%            E VERIFICAÇÃO DE OBSTÁCULOS para uma aeronave.
%            Este é um modelo ALTAMENTE SIMPLIFICADO para fins didáticos.
%
% Parâmetros de Entrada:
%   peso_decolagem_kg   : Peso bruto de decolagem da aeronave (kg)
%   temp_ambiente_c     : Temperatura ambiente em Celsius
%   altitude_pressao_ft : Altitude de pressão do aeroporto em pés
%   vento_velocidade_kt : Velocidade do vento na pista em nós
%   vento_direcao_graus : Direção do vento em graus (0 para norte, 90 para leste, etc.)
%   pista_direcao_graus : Direção da pista em graus (ex: 290 para Pista 29)
%   flap_setting_graus  : Ângulo da configuração de flap para decolagem (ex: 0, 5, 10, 20)
%   altura_obstaculo_ft : Altura do obstáculo no final da pista (pés)
%
% Parâmetros de Saída:
%   distancia_todr_normal_m : Distância de decolagem normal (TODR ALL ENGINE) em metros
%   v_r_kt                  : Velocidade de rotação (Vr) em nós
%   v1_kt                   : Velocidade de decisão (V1) em nós
%   distancia_asdr_m        : Distância de aceleração-parada requerida (ASDR) em metros
%   distancia_todr_oei_m    : Distância de decolagem com um motor inoperante (TODR OEI) em metros
%   altura_sobre_obstaculo_oei_ft : Altura da aeronave sobre o obstáculo (OEI) em pés
%   status_decolagem      : String com status ("OK", "Peso Excessivo", "Flap Inválido", "Performance Insuficiente")

function [distancia_todr_normal_m, v_r_kt, v1_kt, distancia_asdr_m, distancia_todr_oei_m, altura_sobre_obstaculo_oei_ft, status_decolagem] = ...
         calcular_desempenho_decolagem(peso_decolagem_kg, temp_ambiente_c, ...
                                      altitude_pressao_ft, ...
                                      vento_velocidade_kt, vento_direcao_graus, ...
                                      pista_direcao_graus, flap_setting_graus, ...
                                      altura_obstaculo_ft) % NOVO PARÂMETRO

    % --- 1. Parâmetros Genéricos da Aeronave e Limites (Simplificados) ---
    temp_isa_c = 15; % Graus Celsius
    alt_isa_ft = 0;  % Pés
    mtow_performance_kg = 65000;

    % --- Ajuste de Parâmetros Base com Base na Configuração de Flap ---
    status_decolagem = "OK";
    
    % Parâmetros Específicos para Cálculos de Falha de Motor (FICTÍCIOS)
    vmcg_base_kt = 85; 
    vmca_base_kt = 90;
    
    % Constantes para conversões
    kt_to_mps = 0.514444; % Nós para metros por segundo
    ft_to_m = 0.3048; % Pés para metros
    g = 9.81; % m/s^2

    % NOVO: Gradiente de subida com um motor inoperante (em %) - FICTÍCIO
    % Influenciado por flap, peso, temperatura e altitude.
    % Um gradiente maior significa melhor subida.
    gradiente_subida_oei_base_percent = 2.0; % 2.0% de gradiente base (valor bem otimista para simulação)

    switch flap_setting_graus
        case 0 % Flaps Retraídos (clean)
            peso_referencia_kg = 40000;
            todr_base_m_isa = 600; 
            vr_base_kt_isa = 135;   
            
            fator_asdr_multiplicador = 1.05; 
            fator_todr_oei_multiplicador = 1.1; 
            v1_percent_of_vr = 0.90;
            gradiente_subida_oei_ajuste = 0.8; % Reduz gradiente para flaps limpos
            
        case 5 % Flaps para Decolagem 1
            peso_referencia_kg = 40000;
            todr_base_m_isa = 500; 
            vr_base_kt_isa = 125;   
            
            fator_asdr_multiplicador = 1.04; 
            fator_todr_oei_multiplicador = 1.08; 
            v1_percent_of_vr = 0.92;
            gradiente_subida_oei_ajuste = 0.9;
            
        case 10 % Flaps para Decolagem 2
            peso_referencia_kg = 40000;
            todr_base_m_isa = 400; 
            vr_base_kt_isa = 115;   
            
            fator_asdr_multiplicador = 1.03; 
            fator_todr_oei_multiplicador = 1.06; 
            v1_percent_of_vr = 0.94;
            gradiente_subida_oei_ajuste = 1.0; % Gradiente padrão
            
        case 20 % Flaps para Decolagem 3
            peso_referencia_kg = 40000;
            todr_base_m_isa = 300; 
            vr_base_kt_isa = 105;   
            
            fator_asdr_multiplicador = 1.01; 
            fator_todr_oei_multiplicador = 1.03; 
            v1_percent_of_vr = 0.96;
            gradiente_subida_oei_ajuste = 1.1; % Flaps maiores podem dar melhor gradiente inicial
            
        otherwise
            status_decolagem = "Flap Inválido";
            distancia_todr_normal_m = NaN;
            v_r_kt = NaN;
            v1_kt = NaN;
            distancia_asdr_m = NaN;
            distancia_todr_oei_m = NaN;
            altura_sobre_obstaculo_oei_ft = NaN; % Saída adicional
            return;
    end

    % --- Fatores de correção LINEARES ---
    fator_peso_todr_m_por_kg = 0.03; 
    fator_temp_todr_m_por_c = 5;     
    fator_alt_todr_m_por_ft = 0.2;   

    fator_peso_vr_kt_por_kg = 0.0005; 
    fator_temp_vr_kt_por_c = 0.05;    
    fator_alt_vr_kt_por_ft = 0.002;   

    fator_vento_todr_m_por_kt = -5; 


    % --- 3. Cálculos de Fatores de Correção Ambientais e de Peso ---
    delta_peso = peso_decolagem_kg - peso_referencia_kg;
    delta_temp = temp_ambiente_c - temp_isa_c;
    delta_alt = altitude_pressao_ft - alt_isa_ft;

    angulo_diferenca = abs(pista_direcao_graus - vento_direcao_graus);
    if angulo_diferenca > 180
        angulo_diferenca = 360 - angulo_diferenca;
    end
    vento_componente_proa_kt = vento_velocidade_kt * cosd(angulo_diferenca);


    % --- 4. Cálculo da Distância de Decolagem Normal (TODR ALL ENGINE) e Vr Ajustadas ---
    distancia_todr_normal_m = todr_base_m_isa;
    v_r_kt = vr_base_kt_isa;

    distancia_todr_normal_m = distancia_todr_normal_m + (delta_peso * fator_peso_todr_m_por_kg);
    v_r_kt = v_r_kt + (delta_peso * fator_peso_vr_kt_por_kg);

    distancia_todr_normal_m = distancia_todr_normal_m + (delta_temp * fator_temp_todr_m_por_c);
    v_r_kt = v_r_kt + (delta_temp * fator_temp_vr_kt_por_c);

    distancia_todr_normal_m = distancia_todr_normal_m + (delta_alt * fator_alt_todr_m_por_ft);
    v_r_kt = v_r_kt + (delta_alt * fator_alt_vr_kt_por_ft);

    distancia_todr_normal_m = distancia_todr_normal_m + (vento_componente_proa_kt * fator_vento_todr_m_por_kt);

    if distancia_todr_normal_m < 500
        distancia_todr_normal_m = 500;
    end
    if v_r_kt < 80
        v_r_kt = 80;
    end


    % --- 5. Cálculo de Velocidades Críticas Vmcg e Vmca (Ajustadas) ---
    vmcg_kt = vmcg_base_kt + (delta_alt * 0.001); % Vmcg aumenta com altitude
    vmca_kt = vmca_base_kt + (delta_alt * 0.001); % Vmca aumenta com altitude
    v_min_control_kt = max(vmcg_kt, vmca_kt);


    % --- 6. Cálculo de V1 (Velocidade de Decisão) ---
    v1_kt = v_r_kt * v1_percent_of_vr;
    
    % V1 deve ser >= Vmcg
    v1_kt = max(v1_kt, v_min_control_kt);
    
    % V1 deve ser <= Vr (não pode ser maior do que a velocidade de rotação)
    v1_kt = min(v1_kt, v_r_kt);


    % --- 7. Cálculo de Distâncias de Falha de Motor (ASDR e TODR OEI) ---
    distancia_asdr_m = distancia_todr_normal_m * fator_asdr_multiplicador;
    distancia_todr_oei_m = distancia_todr_normal_m * fator_todr_oei_multiplicador;
    
    % Garantir que as distâncias não sejam absurdas em casos extremos.
    if distancia_asdr_m < 500
        distancia_asdr_m = 500;
    end
    if distancia_todr_oei_m < 500
        distancia_todr_oei_m = 500;
    end


    % --- 8. Cálculo de Altura sobre Obstáculo (TODR OEI) ---
    % Altura atingida em 35ft (base padrão) após V2, ou para limpar obstáculo.
    % Modelo simplificado da subida com um motor inoperante.
    gradiente_subida_oei = gradiente_subida_oei_base_percent * gradiente_subida_oei_ajuste;
    % Ajustar gradiente por peso, temp e altitude (degrada performance)
    gradiente_subida_oei = gradiente_subida_oei * (1 - delta_peso * 0.000005 - delta_temp * 0.001 - delta_alt * 0.00005);
    
    % Assumimos que a aeronave está a 35ft no fim da TODR OEI (padrão)
    % A partir daí, ela sobe com o gradiente.
    % Distância adicional para subir do final da pista até o obstáculo
    distancia_apos_pista_m = max(0, distancia_todr_oei_m - pista_direcao_graus); % Aprox. onde obstáculo estaria. Simplificado.
    
    % Altura atingida sobre o obstáculo
    % Altura_ganha = gradiente * distancia_adicional
    % Considerando que a aeronave já estaria a 35ft de altura no final da TODR OEI.
    % A distância para calcular a altura sobre o obstáculo é complexa.
    % Simplificando: Altura atingida sobre o obstáculo = (comprimento_pista_disponivel_m - distancia_decolagem_ate_35ft) * gradiente
    % Para este modelo didático, vamos assumir que a altura atingida acima de 35ft no final da TODR OEI é:
    altura_ganha_adicional_ft = (comprimento_pista_disponivel_m - distancia_todr_oei_m) * (gradiente_subida_oei / 100) / ft_to_m;
    altura_sobre_obstaculo_oei_ft = max(35, 35 + altura_ganha_adicional_ft); % Começa com 35ft e ganha altura.

    % Se TODR OEI for maior que a pista, não pode limpar obstáculo
    if distancia_todr_oei_m > comprimento_pista_disponivel_m
        altura_sobre_obstaculo_oei_ft = -inf; % Não consegue nem decolar na pista, muito menos limpar obstáculo
    end


    % --- 9. Verificação de Status da Decolagem ---
    if strcmp(status_decolagem, "OK") % Se o flap não for inválido
        if peso_decolagem_kg > mtow_performance_kg
            status_decolagem = "Peso Excessivo";
        end
        % Adicionando uma verificação de "Performance Insuficiente" se as distâncias forem muito altas
        if distancia_asdr_m > 4000 || distancia_todr_oei_m > 4000
             status_decolagem = "Performance Insuficiente";
        end
        % Adicionar status de obstáculo
        if altura_sobre_obstaculo_oei_ft <= altura_obstaculo_ft && altura_sobre_obstaculo_oei_ft ~= -inf
            status_decolagem = "Obstaculo Nao Limpo";
        end
        if altura_sobre_obstaculo_oei_ft == -inf
            status_decolagem = "TODR OEI Excede Pista"; % Já cobre o problema de pista insuficiente para TODR OEI
        end
    end

end % Fim da função 'calcular_desempenho_decolagem'

