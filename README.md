# Strife Terraform Setup

Strife é um projeto Terraform que implanta recursos necessários para explorar um ambiente de plataforma de dados na azure. Seu objetivo principal está associado ao projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster), no qual tem como objetivo entregar uma plataforma de dados simplificada para uso eficiente.
Serão implantados os recursos abaixo:

- IMAGEM

## Contents

- [Usando repositório](#iniciorapido)
- [Estrutura do repositório](#estrutura)
- [Requisitos](#requisitos)
- [Sobre Projeto dougsll-datamaster](#dougslldatamaster)

## Usando repositório<a id="iniciorapido"></a>

Existem duas maneiras de usar este repositório:

- Use repos template final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster), no qual utiliza desse repositório para criar o ambiente exploratório.
- Reutilize módulos deste repositório como referência para seu projeto individuall.

## Estrutura do repositório<a id="estrutura"></a>

O repositório está organizado da seguinte forma:::

- `lakehouse` - Implementacao dos recursos base para criar o ambiente de exploratório de dados na azure.
- `lakehouse\modules` - implementação de módulos específico para criacao de usuário e grupo no aad.
- `azureadb-uc` - Configuracao do unity catalog e sincronizacao dos usuarios aad para account databricks.
- `azureadb-uc\modules` - implementação de módulos específico para criacao configuracao do metastore e external object do unity catalog.
- `cicd-pipelines` - Implementação de pipelines de CI/CD para automatizar suas implantações do Terraform usando GitHub Actions

## Requisitos<a id="requisitos"></a>

Para executar o terraform, é necessário configurar as variaveis de ambiente abaixo:

- Subscription_id
- app_id

## Sobre Projeto dougsll-datamaster<a id="dougslldatamaster"></a>

Este projeto Terraform foi desenvolvido para atender o projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster) feito por Douglas leal.
