import io

import boto3
import PIL.Image
import torch
from torch.utils import model_zoo
import torchvision


s3_client = boto3.client('s3')

valid_transform = torchvision.transforms.Compose([
    torchvision.transforms.Resize(size=256, interpolation=PIL.Image.ANTIALIAS),
    torchvision.transforms.CenterCrop(size=224),
    torchvision.transforms.ToTensor(),
])


class SetupModel(object):
    model = torchvision.models.resnet.ResNet(torchvision.models.resnet.BasicBlock, [2, 2, 2, 2])

    def __init__(self, f):
        self.f = f

        model_url = torchvision.models.resnet.model_urls['resnet18']  # should encrypt models in real life
        self.model.load_state_dict(model_zoo.load_url(model_url, model_dir='/tmp'))  # be careful writing model to disc
        self.model.eval()

    def __call__(self, *args, **kwargs):
        return self.f(*args, **kwargs)


def predict(r):
    input_batch = []
    with PIL.Image.open(io.BytesIO(r)) as im:
        im = im.convert('RGB')
        input_batch.append(valid_transform(im))

    input_batch_var = torch.autograd.Variable(torch.stack(input_batch, dim=0), volatile=True)
    return SetupModel.model(input_batch_var)


@SetupModel  # download the model when servicing request and enable it to persist across requests in memory
def handler(event, _):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        # being paranoid and not writing user data to disc (should also be encrypted in real life)
        model_output = predict(s3_client.get_object(Bucket=bucket, Key=key)['Body'].read())
        return str(model_output)
