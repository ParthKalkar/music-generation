from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np

app = Flask(__name__)

def select_significant_words(text_weight_pairs, num_words):
    texts = [pair['text'] for pair in text_weight_pairs]
    weights = [pair['weight'] for pair in text_weight_pairs]
    print(texts)
    vectorizer = TfidfVectorizer(stop_words='english')
    tfidf_matrix = vectorizer.fit_transform(texts)
    print(tfidf_matrix)
    feature_names = vectorizer.get_feature_names_out()

    weighted_tfidf_matrix = tfidf_matrix.multiply(np.array(weights)[:, np.newaxis])
    weighted_tfidf_scores = weighted_tfidf_matrix.sum(axis=0)

    weighted_tfidf_scores_array = np.asarray(weighted_tfidf_scores).flatten()
    num_words_to_select = min(num_words, len(feature_names))

    top_indices = weighted_tfidf_scores_array.argsort()[-num_words_to_select:][::-1]

    top_words = [feature_names[i] for i in top_indices]

    return top_words

@app.route('/')
def home():
    return "Welcome to the Music Generation API"

@app.route('/significant-words', methods=['POST'])
def get_significant_words():
    data = request.json
    text_weight_pairs = data.get('text_weight_pairs')
    num_words = data.get('num_words')

    if not text_weight_pairs or num_words is None:
        return jsonify({"error": "Invalid input"}), 400

    result = select_significant_words(text_weight_pairs, num_words)
    return jsonify({"significant_words": result})

if __name__ == '__main__':
    app.run(debug=True)
