import os
import dill
import logging

from sklearn import neighbors
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import pandas as pd
import numpy as np

WORKDIR_PATH = os.path.dirname(__file__)
MODEL_PICKLE = os.path.join(WORKDIR_PATH, 'model.p')
MODEL_DATA = os.path.join(os.path.dirname(__file__), 'cleaned.csv')

input_format = ['lineage1', 'lineage2', 'lineage3', 'lineage4', 'lineage5', 'base_count', 'read_count',
                'compressed_data_size', 'library_layout', 'library_strategy', 'library_source', 'name']


class MemoryEstimator(object):
    input_numerical_columns = ['base_count', 'read_count', 'compressed_data_size']

    output_columns = ['peak_mem']

    def __init__(self, training_data=MODEL_DATA):
        self.input_scaler = None
        self.output_scaler = None
        self.num_columns = None

        try:
            self.load_model()
        except (dill.UnpicklingError, OSError) as e:
            logging.warning(e)
            logging.info('Re-training model due to error loading pickled model.')
            self.model = self.retrain(training_data)
            self.save()

    def load_model(self):
        with open(MODEL_PICKLE, 'rb') as f:
            me = dill.load(f)
        self.model = me.model
        self.input_scaler = me.input_scaler
        self.output_scaler = me.output_scaler
        self.num_columns = me.columns

    def get_input_columns(self, df):
        return list(filter(lambda c: c not in self.output_columns, df.columns))

    def retrain(self, training_data):
        df = pd.read_csv(training_data)
        df = pd.get_dummies(df)
        input_columns = self.get_input_columns(df)
        x_train, x_test, y_train, y_test = train_test_split(df[input_columns], df[self.output_columns], test_size=0.33,
                                                            random_state=42)
        self.gen_data_scalers(x_train, y_train)
        x_train = self.pre_process_input(x_train)
        self.num_columns = x_train.shape[1]
        y_train = self.pre_process_output(y_train)
        model = MLPRegressor(hidden_layer_sizes=(100,), activation='relu', solver='adam', alpha=0.001, batch_size='auto',
                   learning_rate='constant', learning_rate_init=0.01, power_t=0.5, max_iter=1000, shuffle=True,
                   random_state=None, tol=0.0001, verbose=True, warm_start=False, momentum=0.9,
                   nesterovs_momentum=True, early_stopping=False, validation_fraction=0.1, beta_1=0.9, beta_2=0.999,
                   epsilon=1e-08).fit(x_train, y_train)

        self.evaluate_model(model, x_test, y_test)

        model = neighbors.KNeighborsRegressor(5, weights='distance', algorithm='kd_tree').fit(x_train, y_train)

        self.evaluate_model(model, x_test, y_test)
        return model

    def evaluate_model(self, model, x_test, y_test):
        x_test = self.pre_process_input(x_test)
        pred_real = self.predict(x_test, model=model)
        req_real = y_test[self.output_columns].values

        pred_real = (pred_real * 1.2).round() + 5

        mse = mean_squared_error(req_real, pred_real)
        passed = sum([1 for p, y in zip(pred_real, req_real) if p >= y])
        failed = sum([1 for p, y in zip(pred_real, req_real) if p < y])
        waste = np.mean([(p - y if p >= y else p) / (p + 1) for p, y in zip(pred_real, req_real)])

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
        if self.num_columns is not None and df.shape[1]!=self.num_columns:
            df = df.reindex(columns=self.num_columns, fill_value=0)
        return self.input_scaler.transform(df)

    def pre_process_output(self, df):
        return self.output_scaler.transform(df)

    def predict_from_raw(self, df):
        return self.predict(self.pre_process_input(df))

    def predict(self, df, model=None):
        if not model:
            model = self.model
        raw_prediction = model.predict(df).reshape(-1,1)
        return self.output_scaler.inverse_transform(raw_prediction)


if __name__ == '__main__':
    me = MemoryEstimator()
    data = pd.DataFrame(
        data={'lineage1': ['root'], 'lineage2': ['Host-Associated'], 'lineage3': [None], 'lineage4': [None],
              'lineage5': [None], 'base_count': [31256240400], 'read_count': [104187468],
              'compressed_data_size': [19390952362], 'library_layout': ['PAIRED'], 'library_strategy': ['WGS'],
              'library_source': ['METAGENOMIC'], 'name': ['metaspades']})
    print(me.predict_from_raw(data))
    # me.save()
