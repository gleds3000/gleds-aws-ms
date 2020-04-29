REGION=$1
STACK_NAME=$2

DEPLOYABLE_SERVICES=(
	api
);

PRIMARY='\033[0;34m'
NC='\033[0m' 


printf "${PRIMARY}* Fetching current stack state${NC}\n";

QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`ClusterName\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`ALBArn\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`ECSRole\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`Url\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`VPCId\`].OutputValue
]
EOF)

RESULTS=$(aws cloudformation describe-stacks \
	--stack-name $STACK_NAME \
	--region $REGION \
	--query "$QUERY" \
	--output text);
RESULTS_ARRAY=($RESULTS)

CLUSTER_NAME=${RESULTS_ARRAY[0]}
ALB_ARN=${RESULTS_ARRAY[1]}
ECS_ROLE=${RESULTS_ARRAY[2]}
URL=${RESULTS_ARRAY[3]}
VPCID=${RESULTS_ARRAY[4]}

printf "${PRIMARY}* Authenticating with EC2 Container Repository${NC}\n";

`aws ecr get-login --region $REGION --no-include-email`

# Versionamento do container usando TAG com data e hora 
TAG=`date +%s`

for SERVICE_NAME in "${DEPLOYABLE_SERVICES[@]}"
do
	printf "${PRIMARY}* Busca o ECR  \`${SERVICE_NAME}\`${NC}\n";

	# Find the ECR repo to push to
	REPO=`aws ecr describe-repositories \
		--region $REGION \
		--repository-names "$SERVICE_NAME" \
		--query "repositories[0].repositoryUri" \
		--output text`

	if [ "$?" != "0" ]; then
		# The repository was not found, create it
		printf "${PRIMARY}* Creating new ECR repository for service \`${SERVICE_NAME}\`${NC}\n";

		REPO=`aws ecr create-repository \
			--region $REGION \
			--repository-name "$SERVICE_NAME" \
			--query "repository.repositoryUri" \
			--output text`
	fi

	printf "${PRIMARY}* Building \`${SERVICE_NAME}\`${NC}\n";

	# Construir o Container docker e colocar a tag 
	(cd ./$SERVICE_NAME );
	docker build -t $SERVICE_NAME ./$SERVICE_NAME
	docker tag $SERVICE_NAME:latest $REPO:$TAG

	# Carregando para o ECR E iniciando o deploy
	printf "${PRIMARY}* Enviando \`${SERVICE_NAME}\`${NC}\n";

	docker push $REPO:$TAG

	printf "${PRIMARY}* task definition criada para o API \`${SERVICE_NAME}\`${NC}\n";

	#Aplicar Configuracao basica para o container
	CONTAINER_DEFINITIONS=$(cat <<-EOF
		[{
			"name": "$SERVICE_NAME",
			"image": "$REPO:$TAG",
			"cpu": 256,
			"memory": 256,
			"portMappings": [{
				"containerPort": 3000,
				"hostPort": 0
			}],
			"essential": true
		}]
	EOF)

	TASK_DEFINITION_ARN=`aws ecs register-task-definition \
		--region $REGION \
		--family $SERVICE_NAME \
		--container-definitions "$CONTAINER_DEFINITIONS" \
		--query "taskDefinition.taskDefinitionArn" \
		--output text`

	# Verifica se existe
	STATUS=`aws ecs describe-services \
		--region $REGION \
		--cluster $CLUSTER_NAME \
		--services $SERVICE_NAME \
		--query "services[0].status" \
		--output text`

	if [ "$STATUS" != "ACTIVE" ]; then
		
		# Se ja criou ok se nao criar novamente no caso de rodar duas vezes o script.

		if [ -e "./$SERVICE_NAME/rule.json" ]; then
			printf "${PRIMARY}* Configuracao do servico web facing  \`${SERVICE_NAME}\`${NC}\n";
			printf "${PRIMARY}* Cria um target group por servico \`${SERVICE_NAME}\`${NC}\n";

			TARGET_GROUP_ARN=`aws elbv2 create-target-group \
				--region $REGION \
				--name $SERVICE_NAME \
				--vpc-id $VPCID \
				--port 80 \
				--protocol HTTP \
				--health-check-protocol HTTP \
				--health-check-path / \
				--health-check-interval-seconds 6 \
				--health-check-timeout-seconds 5 \
				--healthy-threshold-count 2 \
				--unhealthy-threshold-count 2 \
				--query "TargetGroups[0].TargetGroupArn" \
				--output text`

			printf "${PRIMARY}* Load balance pronto \`${SERVICE_NAME}\`${NC}\n";

			LISTENER_ARN=`aws elbv2 describe-listeners \
				--region $REGION \
				--load-balancer-arn $ALB_ARN \
				--query "Listeners[0].ListenerArn" \
				--output text`

			if [ "$LISTENER_ARN" == "None" ]; then
				printf "${PRIMARY}* Criando Listener do load balancer${NC}\n";

				LISTENER_ARN=`aws elbv2 create-listener \
					--region $REGION \
					--load-balancer-arn $ALB_ARN \
					--port 80 \
					--protocol HTTP \
					--query "Listeners[0].ListenerArn" \
					--default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
					--output text`
			fi

			printf "${PRIMARY}* Adiciona regras ao load balancer listener \`${SERVICE_NAME}\`${NC}\n";

			# Ajustes no target group e listener para que cada servico seja unico
			RULE_DOC=`cat ./services/$SERVICE_NAME/rule.json |
								jq ".ListenerArn=\"$LISTENER_ARN\" | .Actions[0].TargetGroupArn=\"$TARGET_GROUP_ARN\""`

			aws elbv2 create-rule \
				--region $REGION \
				--cli-input-json "$RULE_DOC"

			printf "${PRIMARY}* Criando o servico para executar o docker  \`${SERVICE_NAME}\`${NC}\n";

			LOAD_BALANCERS=$(cat <<-EOF
				[{
					"targetGroupArn": "$TARGET_GROUP_ARN",
					"containerName": "$SERVICE_NAME",
					"containerPort": 3000
				}]
			EOF)

			RESULT=`aws ecs create-service \
				--region $REGION \
				--cluster $CLUSTER_NAME \
				--load-balancers "$LOAD_BALANCERS" \
				--service-name $SERVICE_NAME \
				--role $ECS_ROLE \
				--task-definition $TASK_DEFINITION_ARN \
				--desired-count 1`
		else
			# Caso nao funcione o servico web interface, podemos executar sem o load balance e ter apenas o ip
			printf "${PRIMARY}* service sem load balance \`${SERVICE_NAME}\`${NC}\n";
			RESULT=`aws ecs create-service \
				--region $REGION \
				--cluster $CLUSTER_NAME \
				--service-name $SERVICE_NAME \
				--task-definition $TASK_DEFINITION_ARN \
				--desired-count 1`
		fi
	else
		# Caso ja esteja tudo UP, podemos atualizar  .
		printf "${PRIMARY}* Atualizando o servico \`${SERVICE_NAME}\` com a nova task definition \`${TASK_DEFINITION_ARN}\`${NC}\n";
		RESULT=`aws ecs update-service \
			--region $REGION \
			--cluster $CLUSTER_NAME \
			--service $SERVICE_NAME \
			--task-definition $TASK_DEFINITION_ARN`
	fi
done

printf "${PRIMARY}* Meu DNS/endereco Consta aqui: http://${URL}${NC}\n";
printf "${PRIMARY}* (O container pode demorar para inicializar até 5 minutos, apos essa msg.)${NC}\n";

