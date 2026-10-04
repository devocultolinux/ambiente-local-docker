# Ambiente local com Docker Compose

Este repositório reúne serviços para desenvolvimento e ferramentas de integração contínua. O Compose organiza os serviços em dois perfis: `dev` e `ic`. O script `inicializar_ambiente.sh` permite escolher um deles e para o outro antes de iniciar.

## Requisitos

- Linux com Docker Engine e o plugin Docker Compose (`docker compose`)
- OpenSSL, para gerar o identificador do cluster Kafka
- Recomenda-se reservar pelo menos 8 GB de RAM e 15 GB de disco. OpenSearch, SonarQube e Jenkins podem exigir mais recursos conforme o uso.

O script tenta iniciar o serviço Docker com `sudo` caso o daemon ainda não esteja ativo. Se preferir não usar `sudo`, configure o acesso ao Docker para seu usuário antes de executar o script.

## Configuração

Na raiz do projeto, crie `.env` a partir do exemplo:

```bash
cp .env-exemplo .env
```

Preencha as variáveis usadas pelo Compose:

| Variável | Uso |
|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Usuário, senha e banco do PostgreSQL |
| `SONARQUBE_JDBC_USERNAME`, `SONARQUBE_JDBC_PASSWORD` | Credenciais do SonarQube no PostgreSQL |
| `SONARQUBE_JDBC_URL` | URL JDBC do banco, por exemplo `jdbc:postgresql://postgres:5432/sonar` (ajuste o banco ao valor de `POSTGRES_DB`) |
| `SENHA_OPENSEARCH` | Senha inicial do usuário administrador do OpenSearch |
| `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`, `MONGO_INITDB_DATABASE` | Configuração inicial do MongoDB |
| `ID_CLUSTER_KAFKA` | ID do cluster Kafka no modo KRaft |

Gere o ID do Kafka e copie o resultado para `ID_CLUSTER_KAFKA` em `.env`:

```bash
openssl rand -base64 16 | tr -d '=\n' | tr '+/' '-_'
```

As variáveis `SENHA_GRAFANA` e `SENHA_REDIS` aparecem no exemplo, mas não são referenciadas pelo Compose atual. Redis está sem autenticação configurada. O Dashboard do OpenSearch e o pipeline do Logstash usam credenciais definidas diretamente em seus arquivos de configuração; revise esses valores antes de expor o ambiente a outras máquinas.

Não compartilhe o arquivo `.env`, pois ele contém credenciais.

## Iniciar

Execute na raiz do repositório:

```bash
chmod +x inicializar_ambiente.sh  # necessário apenas uma vez
./inicializar_ambiente.sh
```

Escolha uma opção no menu:

1. **Integração e Entrega Contínua (CI/CD)** inicia o perfil `ic` e para os serviços do perfil `dev`.
2. **Desenvolvimento** inicia o perfil `dev` e para os serviços do perfil `ic`.

Os comandos diretos não param automaticamente o outro perfil. O script faz essa troca usando `stop`; isso para os contêineres, mas preserva os dados que estiverem em volumes ou na camada do contêiner.

## Serviços e endereços

As portas abaixo são publicadas no host. Dentro da rede do Compose, os serviços se comunicam pelos nomes dos serviços e pelas portas internas.

### Perfil `dev`

| Serviço | Endereço local | Observações |
|---|---|---|
| MongoDB | `localhost:27017` | Banco NoSQL |
| Redis | `localhost:6379` | Inicializado com AOF; sem volume nomeado |
| RedisInsight | <http://localhost:8083> | Interface do Redis |
| Kafka | `localhost:9092` | KRaft, broker único; na rede Compose use `kafka:29092` |
| Kafka UI | <http://localhost:8081> | Interface do Kafka |
| OpenSearch | <http://localhost:9200> | Busca e indexação; credencial `admin` e senha definida em `SENHA_OPENSEARCH` |
| OpenSearch Dashboards | <http://localhost:5601> | Visualização do OpenSearch |
| Logstash | `localhost:1514` (TCP e UDP) | Entrada GELF e saída para OpenSearch |

### Perfil `ic`

| Serviço | Endereço local | Observações |
|---|---|---|
| PostgreSQL | `localhost:5432` | Banco usado pelo SonarQube |
| SonarQube | <http://localhost:9001> | A porta interna `9000` é publicada como `9001` |
| Jenkins | <http://localhost:8080> | Agentes podem se conectar em `localhost:50000` |
| Nexus | <http://localhost:8082> | Gerenciador de artefatos |


## Dados e recursos

O Compose não declara volumes nomeados para os bancos ou para os serviços. Assim, os dados gravados apenas na camada dos contêineres podem ser perdidos quando eles forem removidos ou recriados. Redis tem AOF habilitado, mas sem volume configurado os arquivos também ficam na camada do contêiner. Jenkins monta o socket Docker do host e SonarQube monta `./sonarqube/extensions`.

OpenSearch e SonarQube têm configurações de memória no Compose; Kafka e Logstash também recebem limites de heap da JVM. Esses valores não representam uma medição do consumo total. O uso real varia conforme a carga, além da memória do sistema e de outros processos. Garanta memória e disco livres antes de iniciar todos os serviços.

## Solução de problemas

**Docker não está ativo ou o usuário não tem acesso:** verifique `docker info`. Inicie o daemon ou ajuste as permissões do usuário.

**Porta ocupada:** identifique o processo usando a porta e encerre-o ou altere o mapeamento no `docker-compose.yml`. No Linux:

```bash
lsof -i :9200
```

Troque o perfil e o serviço conforme necessário. O PostgreSQL tem healthcheck, e o SonarQube aguarda o banco ficar saudável antes de iniciar.

## Referências

- [Docker Compose](https://docs.docker.com/compose/)
- [Apache Kafka](https://kafka.apache.org/documentation/)
- [OpenSearch](https://opensearch.org/docs/)
- [SonarQube](https://docs.sonarsource.com/sonarqube-server/)
