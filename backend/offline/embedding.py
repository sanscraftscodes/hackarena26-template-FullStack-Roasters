if __package__:
    from .model_loader import get_model
else:
    from model_loader import get_model

model = get_model()

def embed(texts):

    return model.encode(texts)
