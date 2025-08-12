# Projeto WordPress em Alta Disponibilidade na AWS

## Objetivo

O objetivo central deste projeto foi a concepção e implementação de uma infraestrutura robusta escalável e de alta disponibilidade para hospedar uma aplicação WordPress na nuvem AWS. A arquitetura foi 
desenhada para simular um ambiente de produção, onde a falha de um componente individual não compromete a disponibilidade total do serviço, utilizando para isso os principais serviços gerenciados da AWS.

## Tecnologias Utilizadas

### Cloud & Infraestrutura AWS
* **Amazon VPC:** Criação de uma rede privada e isolada com sub-redes públicas e privadas.
* **Amazon EC2:** Servidores virtuais (instâncias) para hospedar a aplicação.
* **Auto Scaling Group:** Automação da escalabilidade e auto-recuperação (self-healing) das instâncias.
* **Application Load Balancer (ALB):** Balanceamento de carga de tráfego HTTP entre as múltiplas instâncias.
* **Amazon RDS:** Serviço de banco de dados relacional gerenciado (MySQL) para persistência dos dados do WordPress.
* **Amazon EFS:** Sistema de arquivos de rede compartilhado e elástico para os arquivos de mídia do WordPress.
* **Security Groups:** Firewall a nível de instância para controle detalhado do tráfego entre as camadas da aplicação.
* **NAT Gateway & Internet Gateway:** Componentes da VPC para gerenciar a conectividade de rede com a internet de forma segura.

### Aplicação e Containerização
* **WordPress:** A aplicação principal do projeto.
* **Docker:** Plataforma de containerização utilizada para empacotar e rodar a aplicação WordPress de forma isolada e consistente.
* **Docker Compose:** Ferramenta para definir e orquestrar o serviço do WordPress dentro de cada instância EC2.


### Automação e Sistema Operacional
* **Ubuntu Server 22.04 LTS:** Sistema operacional base para as instâncias EC2.
* **Bash Scripting (`user-data`):** Script de automação para provisionamento e configuração completa das instâncias no momento da inicialização (instalação de pacotes, montagem de EFS, e orquestração do Docker).

## Construção do projeto
### Fundação da Rede (Configuração da VPC)

A base de toda a infraestrutura foi a criação de uma Virtual Private Cloud (VPC) personalizada, que funciona como uma rede privada e isolada na nuvem. Para garantir a alta disponibilidade, a VPC foi configurada para operar em duas Zonas de Disponibilidade (AZs) distintas.

* **Sub-redes Públicas e Privadas:** Dentro da VPC, a rede foi segmentada em sub-redes. Foram criadas duas sub-redes públicas e quatro sub-redes privadas. As sub-redes públicas foram designadas para os recursos que precisam de acesso direto à internet, como o Application Load Balancer e os NAT Gateways. As sub-redes privadas foram utilizadas para proteger os componentes mais sensíveis, como as instâncias EC2 da aplicação e o banco de dados RDS, que não devem ser expostos diretamente à internet.

* **Conectividade com a Internet:** A comunicação com a internet foi estabelecida através de um Internet Gateway (IGW), que foi anexado à VPC. Para permitir que as instâncias nas sub-redes privadas pudessem iniciar conexões com a internet (para atualizações e download de pacotes), foram provisionados NAT Gateways nas sub-redes públicas.

* **Roteamento:** As Tabelas de Rotas foram configuradas para controlar o fluxo de tráfego. A tabela de rota principal, associada às sub-redes públicas, direciona todo o tráfego externo (`0.0.0.0/0`) para o IGW. Tabelas de rotas customizadas, associadas às sub-redes privadas, direcionam o tráfego externo para os NAT Gateways, garantindo o acesso controlado à internet.

### Camada de Persistência de Dados (RDS e EFS)

Com a rede estabelecida, a próxima etapa foi configurar os serviços de armazenamento persistente.

* **Banco de Dados (Amazon RDS):** Para armazenar os dados do WordPress, foi utilizado o Amazon RDS com o mecanismo MySQL. A instância foi configurada como `db.t3.micro` e sem a opção de Multi-AZ habilitada. A instância foi posicionada nas sub-redes privadas de dados para máxima segurança, com um Grupo de Segurança (`rds-sg`) configurado para permitir conexões apenas das instâncias EC2.

* **Armazenamento de Arquivos (Amazon EFS):** Para garantir que os arquivos de mídia (uploads, temas, plugins) fossem consistentes entre todas as instâncias do WordPress, foi implementado o Amazon EFS. Este serviço provê um sistema de arquivos de rede (NFS) que foi montado automaticamente em cada instância EC2 durante a inicialização, via script `user-data`. Um Grupo de Segurança (`efs-sg`) foi criado para permitir o tráfego NFS apenas a partir das instâncias EC2.

### Camada de Aplicação (EC2, Docker e Auto Scaling)

Esta fase focou na configuração dos servidores que rodam a aplicação WordPress.

* **Containerização com Docker:** Seguindo uma abordagem moderna, a aplicação WordPress foi containerizada usando Docker. Isso desacopla a aplicação do sistema operacional, garantindo consistência e portabilidade.

* **Launch Template e User Data:** Um Launch Template foi criado para servir como um "molde" para as instâncias EC2. Ele foi configurado para usar uma AMI do Ubuntu Server 22.04 LTS e um script `user-data` detalhado. Este script foi o coração da automação, responsável por:
    1.  Instalar o Docker e o Docker Compose.
    2.  Montar o sistema de arquivos EFS.
    3.  Criar um arquivo `docker-compose.yml` que define o serviço do WordPress, configurando-o para usar o RDS como banco de dados e o EFS como volume para os arquivos.
    4.  Iniciar o contêiner do WordPress.
       
 * **Auto Scaling Group (ASG):** Foi configurado para gerenciar as instâncias EC2, garantindo que a aplicação seja escalável e resiliente. Ele foi ajustado para manter um mínimo de duas instâncias, distribuídas entre as duas Zonas de Disponibilidade. Uma política de escalonamento baseada na utilização média de CPU foi implementada, permitindo que o ASG adicione ou remova instâncias automaticamente conforme a demanda.

### Ponto de Entrada e Segurança (ALB e Security Groups)

* **Application Load Balancer (ALB):** Um ALB foi posicionado nas sub-redes públicas para atuar como o único ponto de entrada para o tráfego dos usuários, distribuindo as solicitações para as instâncias saudáveis no Grupo de Destino.

* **Grupos de Segurança (Security Groups):** A segurança da rede foi reforçada com múltiplos grupos de segurança, cada um atuando como um firewall para seu respectivo componente, garantindo uma comunicação controlada e segura entre as camadas da arquitetura.

### Depuração e Resolução de Problemas (Troubleshooting)

 A fase de testes revelou que as instâncias EC2 não estavam atingindo o estado "Healthy". Um processo de depuração foi necessário:

 1.  **Diagnóstico via Bastion Host:** Foi provisionada uma instância EC2 temporária em uma sub-rede pública (Bastion Host) para obter acesso SSH seguro às instâncias privadas e analisar os logs.

2.  **Correção de DNS da VPC:** A análise do log `user-data` revelou um erro de DNS (`Name or service not known`) ao tentar montar o EFS. A solução foi habilitar as opções "Resolução de DNS" e "Nomes de host DNS" nas configurações da VPC.

3.  **Ajuste do Health Check:** A análise dos logs do Docker (`docker logs`) via Bastion Host mostrou que a aplicação respondia com um código de status HTTP `302` (Redirecionamento). A verificação de saúde (Health Check) do ALB foi ajustada para aceitar tanto `200` quanto `302` como códigos de sucesso, garantindo uma configuração adequada do Health Check.

## Conclusão 
O projeto foi concluído com sucesso, resultando em uma arquitetura WordPress funcional, segura e de alta disponibilidade na AWS. A implementação abordou conceitos fundamentais de redes em nuvem, serviços gerenciados, automação com `user-data`, containerização com Docker e práticas de depuração sistemática. 

## Anexo: Script de Automação (User Data)

O script `user-data` completo, responsável pela automação da configuração das instâncias EC2, pode ser encontrado no seguinte arquivo:

* ### [user-data.sh](user-data.sh)
