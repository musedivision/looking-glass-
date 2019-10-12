import re
import torch

from torchvision import datasets
from torchvision import transforms

import utils
from transformer_net import TransformerNet
from vgg import Vgg16

# setup the process
device = torch.device("cpu")
state_dict = torch.load('./saved_models/udnie.pth')

# start net up earlywith torch.no_grad():
style_model = TransformerNet()
# remove saved deprecated running_* keys in InstanceNorm from the checkpoint
for k in list(state_dict.keys()):
    if re.search(r'in\d+\.running_(mean|var)$', k):
        del state_dict[k]
style_model.load_state_dict(state_dict)
style_model.to(device)


def stylize(**args):

    content_image = utils.load_image(args["content_image"], scale=args["content_scale"])
    content_transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Lambda(lambda x: x.mul(255))
    ])
    content_image = content_transform(content_image)
    content_image = content_image.unsqueeze(0).to(device)
    print('xx')
    print(content_image.size())
    output = style_model(content_image)
    # utils.save_image(args.output_image, output[0])
    return output[0], content_image 


