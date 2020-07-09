import boto3
import traceback

client = boto3.client('autoscaling')

def lambda_handler(event, context):

    try:
        start_asgec2_instances(event, context)
        stop_asgec2_instances(event, context)
        
    except Exception as e:
            displayException(e)
            traceback.print_exc()

def start_asgec2_instances(event, context):
    # Pegar o Parametro de acao
    action = event.get('action')

    if action is None:
        action = ''

    # Verificar a acao 
    if action.lower() in ['start']:
        response = client.set_desired_capacity(
            AutoScalingGroupName='EC2ContainerService-asg-cluster-EcsInstanceAsg-JPJUDXLHUB48',
            DesiredCapacity=1,
            HonorCooldown=True,
        )
        print("Auto Scaling Group sua capacidade desejada foi alterada para valor 1")
def stop_asgec2_instances(event, context):
    # Pegar o Parametro de acao
    action = event.get('action')

    # Verificar a acao 
    if action.lower() in ['stop']:
        response = client.set_desired_capacity(
            AutoScalingGroupName='EC2ContainerService-asg-cluster-EcsInstanceAsg-JPJUDXLHUB48',
            DesiredCapacity=0,
            HonorCooldown=True,
        )
        print("Auto Scaling Group sua capacidade desejada foi alterada para valor 0")
   
def displayException(exception):
    exception_type = exception.__class__.__name__ 
    exception_message = str(exception) 

    print("Exception tipo: %s; Exception msg: %s;" % (exception_type, exception_message))
