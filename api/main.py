#!/usr/bin/python
# -*- coding: utf-8 -*-

from flask import Flask, jsonify, request

app = Flask(__name__)

comentario = [
    {'nome': 'Gledson',   'comentario': 'A previsao do tempo nao pode faltar'},
    {'nome': 'Vinicius',  'comentario': 'Jornal para todos'},
    {'nome': 'Thiago',    'comentario': 'Bom dia SP volta jaaa'},
    {'nome': 'Alexandre', 'comentario': 'Sempre informado'},
    {'nome': 'Paulo',     'comentario': 'Noticia muito boa'},
]


@app.route('/')
def get_comentario():
  return jsonify(comentario), 200


@app.route("/Oportunidade")
def salvador():
    return "Achamos um novo Cliente, Lojas Mel, criar E-Vendas"


@app.route("/ferias")
def ferias():
    return "Sua proxima ferias serah em 2021"


@app.route("/sobre")
def sobre():
    return "Olá, Eu Sou o Gledson"


@app.route('/comentario', methods=['POST'])
def add_coment():
  print(request.get_json())
  comentario.append(request.get_json())
  return '', 204


@app.route('/comentario/<string:nome>', methods=['GET'])
def pesquisa(nome):
    busca = comentario[0]
    i = 0
    for i, c in enumerate(comentario):
      if c['nome'] == nome:
        busca = comentario[i]
    return jsonify({'comentario': busca})


@app.route('/comentario/<string:nome>',  methods=['DELETE'])
def del_comentario(nome):
  for i, c in enumerate(comentario):
    if c['nome'] == nome:
      del comentario[i]
  return "vc excluiu o comentario " + comentario[i], 204


@app.route('/comentario/<string:nome>', methods=['PUT'])
def upone(nome):
    editar = request.get_json()
    for i, c in enumerate(comentario):
      if c['nome'] == nome:
        comentario[i] = editar
    return "O comentario editado foi: " + comentario[i], 204


@app.route('/status')
def status():
  status = {'status': 'up'}
  return jsonify(status), 200


if __name__ == '__main__':
  #app.run(debug=True, host='localhost')
  app.run(host='0.0.0.0', port=3001)
