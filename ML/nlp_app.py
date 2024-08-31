# -*- coding: utf-8 -*-
"""
Created on Sun Feb 14 13:44:36 2021

@author: vetur
"""

from tensorflow import keras
import tensorflow
import pickle
import nltk
from nltk.corpus import stopwords
from nltk.stem.porter import PorterStemmer
import re
import numpy as np
from flask import Flask
from flask import jsonify
from flask import request
from flask_cors import CORS, cross_origin

app = Flask(__name__)
#cors = CORS(app)
#app.config['CORS_HEADERS'] = 'Content-Type'



def get_assets():
    global model,cv
    model = keras.models.load_model('firstModel.h5')
    print("model loaded")
    cv = pickle.load(open('CVObject.p','rb'))
    print("count vectorizer loaded")
    
def preprocess_text(description):
    global cv
    description = re.sub("[^a-zA-Z]", " ",description)
    description = description.lower()
    description = description.split()
    ps = PorterStemmer()
    description = [ps.stem(word) for word in description if word not in set(stopwords.words("english"))]
    description = (" ").join(description)
    description = cv.transform([description]).toarray()
    return description

get_assets()

@app.route("/predict",methods=['POST'])
@cross_origin()
def predict():
    global tags,model
    #print("predicting")
    message = request.get_json(force=True)
    description = message['text']
    print(description)
    description = preprocess_text(description)
    #print(description)
    prediction = model.predict(description)
    print(prediction)
    if prediction[0][0]<0.5:
        results = "not offensive"
    else:
        results = "offensive"
    response = {
        'prediction': results 
        }
    print(results)
    return jsonify(response)
    
if __name__=='__main__':
    app.run()




