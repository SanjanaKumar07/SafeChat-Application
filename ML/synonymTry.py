# -*- coding: utf-8 -*-
"""
Created on Sun Apr 18 20:59:30 2021

@author: vetur
"""

import numpy as np
import pandas as pd
import pickle

file = open("bigCorpus.pkl",'rb')
corpus = pickle.load(file)
file.close()

wordCount = {}
for i in range(len(corpus)):
    
    #print(x[i])
    words = corpus[i].split()
    for word in words:
        try:
            wordCount[word]+=1
        except:
            wordCount[word] = 1
    
counts = np.array(list(wordCount.values()))
#counts = np.resize(counts,(95064,1))
mostFrequentWordIndexes = counts.argsort()[-2000:][::-1]

words = list(wordCount.keys())

mostFrequentStemmedWords = [words[i] for i in mostFrequentWordIndexes]
with open('frequentStems.pkl', 'wb') as file:
      
    # A new file will be created
    pickle.dump(mostFrequentStemmedWords, file)


file = open("stemDict.pkl",'rb')
stemDict = pickle.load(file)
file.close()


mostFrequentWords = [next(iter(stemDict[x])) for x in mostFrequentStemmedWords]

'''with open('frequentWords.pkl', 'wb') as file:
      
    # A new file will be created
    pickle.dump(mostFrequentWords, file)'''


from sklearn.feature_extraction.text import CountVectorizer
cv = CountVectorizer(max_features = 2000)
X = cv.fit_transform(corpus).toarray()

'''with open('finalCVObject.pkl', 'wb') as file:
      
    # A new file will be created
    pickle.dump(cv, file)'''
    
    
    
CVObjectDict = {}
for word in mostFrequentStemmedWords:
    counts = cv.transform([word]).toarray()
    counts = counts[0]
    ind = counts.argsort()[-1:][::-1]
    CVObjectDict[word]=ind

dataset = pd.read_csv('better_csv.csv')
y = dataset.iloc[:,0].values



from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2, random_state = 0)


from keras.models import Sequential
from keras.layers import Dense
classifier = Sequential()

#adding the  input layer and the first hidden layer
classifier.add(Dense(units=500, input_dim = 2000, activation='relu', kernel_initializer="uniform"))

#adding the second hidden layer
classifier.add(Dense(units=200, activation='relu', kernel_initializer="uniform"))
#classifier.add(Dense(units=20, activation='relu', kernel_initializer="uniform"))
classifier.add(Dense(units=1, activation="sigmoid", kernel_initializer="uniform"))

#compiling the ANN(training)

classifier.compile(optimizer = "adam", loss = "binary_crossentropy",metrics=['accuracy'])
#the loss function is the value that will be optimised(mostly minimised) by the optimiser

#fitting the classifier with X_train and y_train
history = classifier.fit(X_train,y_train,batch_size = 64,epochs = 10)
#classifier.save("thirdModel.h5")

#print("predicting")
# Predicting the Test set results
y_pred = classifier.predict(X_test)
y_pred = (y_pred > 0.5)

#print("matrix")
from sklearn.metrics import confusion_matrix
cm = confusion_matrix(y_test, y_pred)
print("Test accruacy = ")
print((cm[0][0] + cm[1][1])/(cm[1][0] + cm[0][1] + cm[1][1] + cm[0][0]))
#print("done")

