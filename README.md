# Desafio Jack Experts - Projeto Nginx WebApp com Helm

## Descrição

Este projeto é uma aplicação simples de página HTML estática servida pelo Nginx, implantada em um cluster Kubernetes usando Helm. A página HTML é configurável via `ConfigMap` e a aplicação é gerenciada através de um **Helm Chart**. A imagem Docker da aplicação é criada, versionada e publicada no Docker Hub automaticamente através de um pipeline CI/CD no GitHub Actions.

## Estrutura do Projeto

```bash
.
├── Dockerfile           # Define a imagem Docker da aplicação
├── helm-chart/          # Helm Chart para configurar e implantar a aplicação
│   ├── templates/       # Modelos para Deployment, Service, ConfigMap, etc.
│   ├── values.yaml      # Valores padrão configuráveis para o Helm Chart
│   └── Chart.yaml       # Metadados do Helm Chart
├── index.html           # Arquivo HTML base
├── .dockerignore        # Arquivo que ignora diretórios e arquivos no build do Docker
└── README.md            # Documentação do projeto
```

## Pré-requisitos

Certifique-se de ter as seguintes ferramentas instaladas:

- [Docker](https://www.docker.com/get-started)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)
- Um cluster Kubernetes (pode ser local com Minikube ou em um provedor de nuvem)
- Uma conta no [Docker Hub](https://hub.docker.com)

---

## Instruções de Instalação

### 1. Clonar o Repositório

```bash
git clone https://github.com/alexbraga/desafiojack2024.git
cd desafiojack2024
```

### 2. Configurar o Docker

Se necessário, faça login no Docker Hub para publicar a imagem Docker:

```bash
docker login -u seu-usuario
```

### 3. Construir a Imagem Docker

Construa a imagem Docker localmente:

```bash
docker build -t seu-usuario/desafiojack .
```

### 4. Subir a Imagem Docker para o Docker Hub

Depois de construir a imagem, envie-a para o Docker Hub:

```bash
docker tag seu-usuario/desafiojack seu-usuario/desafiojack:1.0
docker push seu-usuario/desafiojack:1.0
```

Substitua `1.0` pelo número da versão desejado.

---

## Como Usar a Aplicação

### Executar Localmente com Docker

Para testar a aplicação localmente usando Docker, execute o seguinte comando:

```bash
docker run -d -p 8080:8080 seu-usuario/desafiojack
```

Agora, acesse `http://localhost:8080` em seu navegador.

### Deploy no Kubernetes com Helm

#### 1. Configurar o Cluster Kubernetes

Certifique-se de que o cluster Kubernetes está rodando corretamente. Por exemplo, você pode iniciar um cluster local com Minikube:

```bash
minikube start
```

#### 2. Configurar o Helm Chart

O Helm Chart para a aplicação está na pasta `helm-chart/`. Você pode personalizar o conteúdo do HTML editando o arquivo `values.yaml`:

```yaml
htmlContent: |
  <html>
    <head><title>Aplicação Customizada</title></head>
    <body>
      <h1>Bem-vindo ao Desafio Jack Experts!</h1>
    </body>
  </html>
```

#### 3. Instalar a Aplicação

Use o Helm para instalar a aplicação no Kubernetes:

```bash
helm install desafiojack ./helm-chart
```

Verifique os pods e serviços que foram criados:

```bash
kubectl get pods
kubectl get svc
```

Se você estiver usando Minikube, pode obter o URL do serviço com:

```bash
minikube service desafiojack-service --url
```

Adicione a seguinte lina ao final do arquivo `/etc/hosts`:
```
<IP do serviço>  desafiojack.com
```

### Atualizar a Aplicação

Para aplicar alterações, como a modificação do conteúdo HTML, edite o `values.yaml` e execute:

```bash
helm upgrade desafiojack ./helm-chart
```

---

## Pipeline CI/CD

O projeto utiliza o GitHub Actions para construir e publicar automaticamente a imagem Docker a cada `push` ou `pull request` no branch `main`. O pipeline segue estas etapas:

1. **Checkout do código**: Obtém o código fonte do repositório.
2. **Configuração de Tags**: Verifica a última tag da imagem Docker publicada no GitHub e gera a próxima versão seguindo o padrão `X.0`.
3. **Build da Imagem Docker**: Usa o `Dockerfile` presente na raiz do projeto para criar uma nova imagem Docker.
4. **Publicação no Docker Hub**: A imagem gerada é enviada ao Docker Hub, autenticada via secrets do repositório.

### Arquivo de Workflow (GitHub Actions)

O pipeline CI/CD está definido no arquivo `.github/workflows/docker-image.yml`:

```yaml
name: Docker Image CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Get latest tag
      id: get_tag
      run: |
        latest_tag=$(git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+$' | head -n 1)
        if [ -z "$latest_tag" ]; then
          next_tag="1.0"
        else
          major_version=$(echo $latest_tag | cut -d. -f1)
          next_tag=$((major_version + 1)).0
        fi
        echo "::set-output name=tag::$next_tag"

    - name: Build the Docker image
      run: |
        docker build . --file Dockerfile --tag my-image-name:${{ steps.get_tag.outputs.tag }}

    - name: Push the Docker image
      run: |
        docker tag my-image-name:${{ steps.get_tag.outputs.tag }} dockerhub-username/my-image-name:${{ steps.get_tag.outputs.tag }}
        echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
        docker push dockerhub-username/my-image-name:${{ steps.get_tag.outputs.tag }}
```

### Configuração de Secrets

Certifique-se de configurar as seguintes variáveis de **secrets** no seu repositório GitHub:

- `DOCKER_USERNAME`: Seu nome de usuário no Docker Hub.
- `DOCKER_PASSWORD`: Sua senha ou token de acesso ao Docker Hub.
