#Solução Api Comentários

##Decisoes a serem tomadas 

IAC, definir um estrutura que pode ser reutilizavel 
e de alta Flexbilidade para realizar o deploy da aplicacao. 

O produto será entregue em duas partes

- Primeira a infraestrutura iAC
- Segunda o deploy/publicação da aplicacao automatica

Pois existem Ganhos:

Poderá realizar testes proximo ou igual a realidade de produção.

Modulo de infra que poderá ser utilizado como template para outros projetos

Flexbilidade para realizar o deploy continuo, por parte da equipe de desenvolvimento.

Manutenção, será realizada nos modulos/repositorio.

Escalabilidade - ASG poderá ser implementado de forma rapida

#Monitoria Via CloudWatch - nesse primeiro momento 
coletando dados do container

Recursos - Cloudwatch ECS insights
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#cw:dashboard=ECS

# Testes da Api

Curl: 
# Adiciona comentário 
'''
curl --request POST \
  --url http://localhost/comentario \
  --header 'content-type: application/json' \
  --data '{
	"nome": "Theo",
	"comentario": "Aguardar o RH"
}'
'''
# Retorna todos os Comentários
'''
curl http://localhost/
'''
# Excluir um Comentário
curl http://localhost/
# busca um comentário, pelo nome da pessoa
'''
curl http://localhost/comentario/nome:Paulo  
'''

#https://cursosserverlessaws.club.hotmart.com/t/page/ZYOmdN267d
