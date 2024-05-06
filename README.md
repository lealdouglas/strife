# Strife Terraform Setup

Strife é um projeto Terraform que implanta recursos necessários para explorar um ambiente de plataforma de dados na azure. Seu objetivo principal está associado ao projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster), no qual tem como objetivo entregar uma plataforma de dados simplificada para uso eficiente.
Serão implantados os recursos abaixo:

- `Resource Group` - Grupo de recurso do projeto
- `Storage account Gen2 - Raw` - Storage account para incluir os arquivos de entrada.
- `Workspace Databricks` - Workspace para explorar os dados e ambiente.
- `Account Databricks` - unity catalog e usuarios sincronizados na workspace.
- `Metastore Databricks` - Metastore e metadados para gestao do unity catalog assignados com a workspace criada.
- `Storage Account Gen2 - Layers` - Storage account para uso das camadas: bronze, silver e gold.

## Contents

- [Requisitos](#requisitos)
- [Usando repositório](#iniciorapido)
- [Estrutura do repositório](#estrutura)
- [Custos do projeto](#estrutura)
- [Sobre Projeto dougsll-datamaster](#dougslldatamaster)

## Requisitos<a id="requisitos"></a>

Para executar o terraform, é necessário ter uma `conta` na azure com apenas uma `subscricao` ativa, além disso, é importante ter um `service principal`, usuário de servico, para que seja possível executar as `actions` de forma automatizada. Configurar as variaveis de ambiente abaixo em seu repositório:

- `SUBSCRIPTION_ID` - Subscricao no qual os recursos serao criados
- `APPLICATION_ID` - ID da aplicacao do service principal principal

## Usando repositório<a id="iniciorapido"></a>

Existem duas maneiras de usar este repositório:

- Use repos template final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster), no qual utiliza desse repositório para criar o ambiente exploratório.
- Reutilize módulos deste repositório como referência para seu projeto individuall.

## Estrutura do repositório<a id="estrutura"></a>

O repositório está organizado da seguinte forma:

- `lakehouse` - Implementacao dos recursos base para criar o ambiente de exploratório de dados na azure.
- `lakehouse\modules` - Criacao de usuário e grupo no aad.
- `azureadb-uc` - Configuracao do unity catalog e sincronizacao dos usuarios aad para account databricks.
- `azureadb-uc\modules` - Configuracao do metastore e external object do unity catalog.
- `cicd-pipelines` - Action para implementar terraform em seu ambiente azure.

- [Custos do projeto](#custos)

O projeto é criado em seu ambiente azure, todo piloto ficou em torno de: R$0,00

## Sobre Projeto dougsll-datamaster<a id="dougslldatamaster"></a>

Este projeto Terraform foi desenvolvido para atender o projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster) feito por Douglas leal.
