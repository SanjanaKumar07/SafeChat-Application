import tensorflow as tf
from tensorflow.keras.layers import Dense, LSTM
from tensorflow.keras.models import Model
from tensorflow.keras.models import Sequential
import numpy as np
import pandas as pd

import tensorflow_hub as hub


# Load Pretrained Word2Vec
embed = hub.load("https://tfhub.dev/google/Wiki-words-250/2")


def fit_max_length(df, max_length):
    """
    get max token counts from train data,
    so we use this number as fixed length input to RNN cell
    """
    for i in range(len(df['text'])):
        if i % 200:
            print(i / len(df['text']))
        try:
            if len(df['text'][i].split(" ")) > max_length:
                df.iloc[i,1] = ' '.join(df['text'][i].split(" ")[:max_length])
        except:
            pass


def get_word2vec_enc(messages):
    """
    get word2vec value for each word in sentence.
    concatenate word in numpy array, so we can use it as RNN input
    """
    encoded_messages = []
    for i in range(len(messages)):
        # if i % 200:
        #     print(i / len(messages))
        tokens = messages[i].split(" ")
        word2vec_embedding = embed(tokens)
        encoded_messages.append(word2vec_embedding.numpy())
    return encoded_messages


def get_padded_encoded_messages(encoded_messages):
    """
    for short sentences, we prepend zero padding so all input to RNN has same length
    """
    padded_messages_encoding = np.array([])
    for j in range(len(encoded_messages)):
        if j % 200:
            print(j / len(encoded_messages))
        zero_padding_cnt = max_length - encoded_messages[j].shape[0]

        pad = np.zeros((1, 250))
        for i in range(zero_padding_cnt):
            encoded_messages[j] = np.concatenate((pad, encoded_messages[j]), axis=0)
        padded_messages_encoding = np.append(padded_messages_encoding, encoded_messages[j])
    return padded_messages_encoding


def preprocess(df):
    """
    encode text value to numeric value
    """
    df.dropna(inplace=True)
    df = df.iloc[:10000, :]
    df = df.reset_index()
    fit_max_length(df, max_length)

    messages = df['text'].tolist()

    encoded_messages = get_word2vec_enc(messages)
    padded_encoded_messages = get_padded_encoded_messages(encoded_messages)

    X = np.array(padded_encoded_messages)
    Y = np.array(df['is_offensive'].tolist())
    return X, Y



max_length = 50

X, Y = preprocess(df)