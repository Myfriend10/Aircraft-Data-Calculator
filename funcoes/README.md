# Aircraft Data: Calculadora de Desempenho de Voo

## Visão Geral

O projeto **Aircraft Data** é uma calculadora de desempenho de aeronaves desenvolvida em **GNU Octave**. Ele simula funcionalidades encontradas em sistemas de gerenciamento de voo (FMS) e softwares de planejamento de desempenho, auxiliando na análise e segurança das operações de decolagem e pouso.

Este projeto visa ser uma ferramenta didática robusta para explorar conceitos de massa e equilíbrio, aerodinâmica de desempenho e otimização em cenários aviônicos.

## Autor / Desenvolvido por

* **Ricardo Azevedo** - Engenheiro de Software
    * Local: Palmas, Tocantins
    * Registro CREA: 2421661374/TOCANTINS

### Perfil Profissional

Profissional com formação em Engenharia de Software, especialização em Telecomunicações e conhecimentos em Aviação.

### Credenciais Profissionais

* **Engenharia de Software:** Registro CREA: 2421661374/TOCANTINS
* **Telecomunicações:** Técnico em Telecomunicações CFT / Rádio Frequência (Certificação Profissional Conselho Federal dos Técnicos)
* **Formação em Aviação:**
    * Teórico de Piloto de Avião (Instituto: Aeroclube de Goiás)
    * Curso de Aviônicos (Aerotd)

## Funcionalidades Principais

* **Massa e Equilíbrio (Weight & Balance - W&B):** Calcula o peso bruto (GW) e o centro de gravidade (CG) da aeronave, com validações de limites operacionais.
* **Desempenho de Decolagem:**
    * Cálculo de Distâncias Requeridas (TODR Normal, ASDR, TODR OEI).
    * Cálculo de Velocidades Críticas (Vr, V1).
    * Verificação de **Obstáculos** na trajetória de subida com motor inoperante.
    * **Otimização de Peso:** Determina o peso máximo de decolagem para uma pista e configuração de flap dados.
    * **Otimização de Peso e Flap:** Encontra o peso máximo absoluto e a melhor configuração de flap.
* **Desempenho de Pouso:** Cálculo de Distância de Pouso Requerida (LDR) e Velocidade de Aproximação (Vapp).
* **Análise de Pista:** Sugere a pista mais favorável com base no vento e fornece detalhes de todas as pistas do aeroporto.
* **Relatórios Detalhados:** Gera um arquivo de texto (`.txt`) com um resumo completo da análise de desempenho.

## Estrutura do Projeto

Aircraft Data/
├── funcoes/
│   ├── calcular_w_b.m
│   ├── calcular_desempenho_decolagem.m
│   ├── calcular_desempenho_pouso.m
│   ├── otimizar_peso_decolagem.m
│   └── gerar_relatorio.m
├── dados_aeroportos.m
├── aeroportos_db.mat
└── main_aircraft_data.m


*(Observação: Outros arquivos como `simular_malha_fechada_PI.m`, `simular_sensor_altitude.m`, `main.m`, `main_wb.m`, `main_decolagem.m` são de projetos anteriores ou testes intermediários e não são essenciais para o funcionamento final deste projeto. Podem ser movidos ou ignorados.)*

## Configurando e executando

### Pré-requisitos

* **GNU Octave:** Certifique-se de ter o GNU Octave instalado em seu sistema. Baixe em [octave.org](https://octave.org/).

### Passos de Instalação e Execução

1.  **Obtenha o Projeto:**
    * Baixe os arquivos do projeto para o seu computador.
    * Navegue até a pasta `Aircraft Data` no seu terminal.

2.  **Crie o Banco de Dados de Aeroportos:**
    Este passo precisa ser executado **uma única vez** para gerar o arquivo `aeroportos_db.mat`.
    No terminal do Octave, execute:
    ```octave
    cd '~/Caminho/Para/Sua/Pasta/Aircraft Data' # Ajuste para o caminho correto do seu projeto
    dados_aeroportos
    ```

3.  **Execute a Calculadora:**
    Com o `aeroportos_db.mat` criado, você pode iniciar a calculadora.
    No terminal do Octave, execute:
    ```octave
    cd '~/Caminho/Para/Sua/Pasta/Aircraft Data' # Ajuste novamente
    main_aircraft_data
    ```

4.  **Interagindo com o Programa:**
    O programa solicitará entradas no terminal para dados do aeroporto, condições ambientais, altura do obstáculo e o modo de cálculo desejado (1, 2, 3 ou 4), seguido de dados específicos do modo.

## Modos de Cálculo

O `main_aircraft_data.m` oferece 4 modos de cálculo distintos:

1.  **Calcular Desempenho de Decolagem para um Peso e Flap dados:** Analisa o desempenho de decolagem para um cenário específico de peso e configuração de flap.
2.  **Otimizar Peso de Decolagem para um Flap dado:** Encontra o peso máximo de decolagem que pode ser atingido com uma configuração de flap específica, dadas as condições de pista e ambiente.
3.  **Otimizar Peso E Flap de Decolagem:** Realiza uma busca para identificar o peso máximo de decolagem e a configuração de flap (dentre as opções 0, 5, 10, 20 graus) que permitem esse peso máximo.
4.  **Calcular Desempenho de Pouso:** Realiza a análise para a fase de pouso, calculan