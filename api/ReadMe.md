### Eventos e Objetivo

O produto será entregue em duas partes

- Primeira a infraestrutura iAC
- Segunda o deploy/publicação da aplicacao automatica

Pois existe Ganhos:

Poderá realizar testes proximo ou igual a realidade de produção.

Modulo de infra que poderá ser utilizado como template para outros projetos

Flexbilidade para realizar o deploy continuo.

Manutenção, será realizada nos modulos.

Escalabilidade - ASG poderá ser implementado

----------
```
Recursos criados/utilizados:
Configuracao: quantidade e tipo,  1 EC2  - t2.micro
mapeamento(regiao e rede minimo duas )  
VPC
SUBNET 
IG
ROUTE TABLE
EIP
EC2
ECS - orquestrar containers
Confgurar ECS para executar configuracao EC2, pois tbm pode usar fargate (sem ec2)
Securitygroup
ECS Service
Atribuicao do IAM / perfil aws com acesso aos recursos
ECS TASK

```

## IAAS - IAC 

Deploy da stack de infra ja Codificada em cloudformation 
--- 
```
   $ aws cloudformation deploy \
   --template-file infra/iac.yml \
   --region us-east-1 \
   --stack-name desafio \
   --capabilities CAPABILITY_NAMED_IAM
   ```

## PAAS - APP - API

 ```
   $ ./deploy.sh us-east-1 desafio
   ```