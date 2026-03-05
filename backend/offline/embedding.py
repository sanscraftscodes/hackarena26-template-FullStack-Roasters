from model_loader import get_model

model = get_model()

def embed(texts):

    return model.encode(texts)