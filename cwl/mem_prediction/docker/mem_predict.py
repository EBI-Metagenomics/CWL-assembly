import os
import logging

import dill
from sklearn import neighbors
from sklearn import linear_model

from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.neural_network import MLPRegressor

import pandas as pd
import numpy as np
import argparse
import json

WORKDIR_PATH = os.path.dirname(__file__)
MODEL_PICKLE = os.path.join(WORKDIR_PATH, 'model.p')
MODEL_DATA = os.path.join(os.path.dirname(__file__), 'data.csv')

input_format = ['lineage1', 'lineage2', 'lineage3', 'lineage4', 'lineage5', 'base_count', 'read_count',
                'compressed_data_size', 'library_layout', 'library_strategy', 'library_source', 'name']

MIN_MEMORY = 10

class MemoryEstimator(object):
    input_numerical_columns = ['base_count', 'read_count', 'compressed_data_size']

    output_columns = ['peak_mem']

    def __init__(self, training_data=MODEL_DATA):
        self.input_scaler = None
        self.output_scaler = None
        self.columns = None
        self.linear_bias = (1.75, 0)
        try:
            self.load_model()
        except (dill.UnpicklingError, OSError) as e:
            logging.warning(e)
            logging.info('Re-training model due to error loading pickled model.')
            self.model = self.retrain(training_data)
            self.save()

    def apply_bias(self, value):
        return (value * self.linear_bias[0]) + self.linear_bias[1]

    def load_model(self):
        with open(MODEL_PICKLE, 'rb') as f:
            me = dill.load(f)
        self.model = me.model
        self.input_scaler = me.input_scaler
        self.output_scaler = me.output_scaler
        self.columns = me.columns

    def get_input_columns(self, df):
        return list(filter(lambda c: c not in self.output_columns, df.columns))

    def retrain(self, training_data):
        df = pd.read_csv(training_data)
        df = pd.get_dummies(df)
        input_columns = self.get_input_columns(df)
        self.columns = list(input_columns)
        x_train, x_test, y_train, y_test = train_test_split(df[input_columns], df[self.output_columns], test_size=0.33,
                                                            random_state=42)
        self.gen_data_scalers(x_train, y_train)
        x_train = self.pre_process_input(x_train)
        y_train = self.pre_process_output(y_train)

        model = MLPRegressor(verbose=True, learning_rate='adaptive')
        model = model.fit(x_train, y_train)
        self.evaluate_model(model, x_test, y_test)
        return model

    def evaluate_model(self, model, x_test, y_test):
        x_test = self.pre_process_input(x_test)
        pred_real = self.predict(x_test, model=model)
        req_real = y_test[self.output_columns].values

        pred_real = self.apply_bias(pred_real)

        pred_real = clip_low_mem(pred_real)

        mse = mean_squared_error(req_real, pred_real)
        passed = sum([1 for p, y in zip(pred_real, req_real) if p >= y])
        failed = sum([1 for p, y in zip(pred_real, req_real) if p < y])
        waste = np.mean([(p - y if p >= y else p) / (p + 1) for p, y in zip(pred_real, req_real)])
        for x in range(0, 5):
            print(pred_real[x], '=>', req_real[x])
        print('MSE: ', mse)
        print('Passed: ', passed)
        print('Failed: ', failed)
        print('Waste: ', waste)

    def save(self):
        with open(MODEL_PICKLE, 'wb+') as f:
            dill.dump(self, f)

    def gen_data_scalers(self, input_data, output_data):
        self.input_scaler = MinMaxScaler().fit(input_data)
        self.output_scaler = MinMaxScaler().fit(output_data)

    def pre_process_input(self, df):
        df = pd.get_dummies(df)
        if self.columns is not None and df.shape[1] != len(self.columns):
            df = df.reindex(columns=self.columns, fill_value=0)
        return self.input_scaler.transform(df)

    def pre_process_output(self, df):
        return self.output_scaler.transform(df)

    # Object must have keys lineage1 - lineage5, base_count, read_count, compressed_data_size,
    # library_layout, library_strategy, library_source, name (of assembler)
    def predict_from_raw(self, obj):
        df = pd.DataFrame(data=obj)
        return int(round(clip_low_mem(self.apply_bias(self.predict(self.pre_process_input(df))[0][0]))))

    def predict(self, df, model=None):
        if not model:
            model = self.model
        raw_prediction = model.predict(df).reshape(-1, 1)
        return self.output_scaler.inverse_transform(raw_prediction)


def clip_low_mem(df):
    return np.clip(df, a_min=MIN_MEMORY, a_max=None)

if __name__ == '__main__':
    me = MemoryEstimator()
    parser = argparse.ArgumentParser()
    parser.add_argument('--lineage', help='MGnify lineage eg: root:Host-Associated:Human', required=True)
    parser.add_argument('--base-count', type=int, help='Base count', required=True)
    parser.add_argument('--read-count', type=int, help='Read count', required=True)
    parser.add_argument('--size', type=int, help='Total compressed data size (Bytes)', required=True)
    parser.add_argument('--layout', required=True, help='ENA library layout (PAIRED | SINGLE)')
    parser.add_argument('--strategy', required=True, help='ENA library strategy (typically WGS')
    parser.add_argument('--source', required=True, help='ENA library source (typically METAGENOMIC)')
    parser.add_argument('--assembler', required=True, help='metaspades|spades|megahit')
    args = parser.parse_args()

    lineage = args.lineage.split(':')
    while len(lineage) <= 4:
        lineage.append(None)

    data = pd.DataFrame(
        data={'lineage1': [lineage[0]], 'lineage2': [lineage[1]], 'lineage3': [lineage[2]], 'lineage4': [lineage[3]],
              'lineage5': [lineage[4]], 'base_count': [args.base_count], 'read_count': [args.read_count],
              'compressed_data_size': [args.size], 'library_layout': [args.layout], 'library_strategy': [args.strategy],
              'library_source': [args.source], 'name': [args.assembler]})
    prediction = {"memory": me.predict_from_raw(data)}
    print(prediction)
    with open('cwl.output.json', 'w') as f:
        json.dump(prediction, f)
