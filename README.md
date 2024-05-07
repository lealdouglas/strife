# Strife Terraform Setup

Strife é um projeto Terraform que implanta recursos necessários para explorar um ambiente de plataforma de dados na azure. Seu objetivo principal está associado ao projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster), no qual tem como objetivo entregar uma plataforma de dados simplificada para uso eficiente.
Serão implantados os recursos abaixo:

- `Resource Group` - Grupo de recurso do projeto
- `Storage account Gen2 - Raw` - Storage account para incluir os arquivos de entrada.
- `Workspace Databricks` - Workspace para explorar os dados e ambiente.
- `Account Databricks` - unity catalog e usuarios sincronizados na workspace.
- `Metastore Databricks` - Metastore para gestao do unity catalog associado com a workspace criada.
- `Storage Account Gen2 - Layers` - Storage account para uso das camadas: bronze, silver e gold.

## Conteúdo

- [Requisitos](#requisitos)
- [Usando repositório](#iniciorapido)
- [Estrutura do repositório](#estrutura)
- [Configurar service principal](#configserviceprincipal)
- [Custos do projeto](#estrutura)
- [Sobre Projeto](#dougslldatamaster)

## Requisitos<a id="requisitos"></a>

Para executar o terraform, é necessário ter uma `conta` na azure com apenas uma `subscricao` ativa, além disso, é importante ter um `service principal`, usuário de servico, para se autenticacao no uso das actions, `az login`. Consulte [como configurar service principal](#configserviceprincipal) para criar seu usuário de aplicacao.
Com isso, Informe as variaveis de ambiente:

- `ARM_TENANT_ID` - Tenant da subscricao.
- `ARM_SUBSCRIPTION_ID` - Subscricao no qual os recursos serao criados.
- `ARM_CLIENT_ID` - ID da aplicacao do service principal principal.
- `ARM_CLIENT_SECRET` - Secret da aplicacao do service principal principal.

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

## Configurar service principal<a id="configserviceprincipal"></a>

Utilize o comando `az ad sp create-for-rbac -n spnstrifedtm --role Contributor --scopes /subscriptions/00000000-0000-0000-0000-000000000000` para configurar um usuário de servico na subscricao desejada. Altere 00000000-0000-0000-0000-000000000000 pelo ID da sua subscricao. Esse SPN terá permissao para criar todo ambiente. Saiba mais: [az-ad-sp-create-for-rbac](https://learn.microsoft.com/pt-br/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac)

## Custos do projeto<a id="estrutura"></a>

O projeto é criado em seu ambiente azure, todo piloto ficou em torno de: R$0,00

## Sobre Projeto<a id="dougslldatamaster"></a>

Este projeto Terraform foi desenvolvido para atender o projeto final [dougsll-datamaster](https://github.com/lealdouglas/dougsll-datamaster) feito por Douglas leal.
