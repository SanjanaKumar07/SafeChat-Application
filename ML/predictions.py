# -*- coding: utf-8 -*-
"""
Created on Sat Mar 20 23:10:24 2021

@author: vetur
"""

from tensorflow import keras
model = keras.models.load_model('thirdModel.h5')

import pickle
cv = pickle.load(open('finalCVObject.pkl','rb'))
mostFrequentWords = pickle.load(open('frequentWords.pkl','rb'))
mostFrequentStems = pickle.load(open('frequentStems.pkl','rb'))

from nltk.corpus import stopwords
from nltk.stem.porter import PorterStemmer
import re
ps = PorterStemmer()
from nltk.corpus import wordnet

for _ in range(10):
    testInp = input("enter your input : ")
    description = re.sub("[^a-zA-Z]", " ",testInp)
    description = description.lower()
    description = description.split()
    new = []
    for word in description:
        if word not in set(stopwords.words("english")):
            if ps.stem(word) in mostFrequentStems:
                new.append(ps.stem(word))
            else:
                for i in range(len(mostFrequentWords)):
                    try:
                        y = mostFrequentWords[i]
                        name1 = wordnet.synsets(word)[0].name()
                        first_word = wordnet.synset(name1)
                        name2 = wordnet.synsets(y)[0].name()
                        second_word = wordnet.synset(name2)
                        #print(first_word.wup_similarity(second_word))
                        if first_word.wup_similarity(second_word) > 0.8:
                            #print(x,y)
                            #print('Similarity: ' + str(first_word.wup_similarity(second_word)))
                            new.append(ps.stem(y))
                            break
                    except:
                        pass
    #description = [ps.stem(word) for word in description if word not in set(stopwords.words("english"))]
    description = (" ").join(new)
    description = cv.transform([description]).toarray()
    #print(description)
    result = model.predict(description)

    print(result)