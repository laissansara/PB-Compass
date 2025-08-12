# Projeto WordPress em Alta Disponibilidade na AWS

### Introdução e Objetivo

O objetivo central deste projeto foi a concepção e implementação de uma infraestrutura robusta escalável e de alta disponibilidade para hospedar uma aplicação WordPress na nuvem AWS. A arquitetura foi desenhada para simular um ambiente de produção, onde a falha de um componente individual não compromete a disponibilidade total do serviço, utilizando para isso os principais serviços gerenciados da AWS.

### Fundação da Rede (Configuração da VPC)

A base de toda a infraestrutura foi a criação de uma Virtual Private Cloud (VPC) personalizada, que funciona como uma rede privada e isolada na nuvem. Para garantir a alta disponibilidade, a VPC foi configurada para operar em duas Zonas de Disponibilidade (AZs) distintas.

* **Sub-redes Públicas e Privadas:** Dentro da VPC, a rede foi segmentada em sub-redes. Foram criadas duas sub-redes públicas e quatro sub-redes privadas. As sub-redes públicas foram designadas para os recursos que precisam de acesso direto à internet, como o Application Load Balancer e os NAT Gateways. As sub-redes privadas foram utilizadas para proteger os componentes mais sensíveis, como as instâncias EC2 da aplicação e o banco de dados RDS, que não devem ser expostos diretamente à internet.

* **Conectividade com a Internet:** A comunicação com a internet foi estabelecida através de um Internet Gateway (IGW), que foi anexado à VPC. Para permitir que as instâncias nas sub-redes privadas pudessem iniciar conexões com a internet (para atualizações e download de pacotes), foram provisionados NAT Gateways nas sub-redes públicas.

* **Roteamento:** As Tabelas de Rotas foram configuradas para controlar o fluxo de tráfego. A tabela de rota principal, associada às sub-redes públicas, direciona todo o tráfego externo (`0.0.0.0/0`) para o IGW. Tabelas de rotas customizadas, associadas às sub-redes privadas, direcionam o tráfego externo para os NAT Gateways, garantindo o acesso controlado à internet.
