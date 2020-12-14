import os

def greeting(event, context):
    return "{} from Lambda!".format(os.environ['greeting'])
