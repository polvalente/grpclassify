import json
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


class ResultExporter():
    def __init__(self, json_filename):
        with open(json_filename, 'r') as f:
            # sort by stream_id
            data = sorted(json.load(f).items(), key=lambda x: x[0])

            # index now represents the stream_id
            data = list(map(lambda x: x[1], data))

            self.num_streams = len(data)
            print(self.num_streams)

            self.total_call_times = np.array(
                list(map(lambda x: np.array(x['total_call_times']), data)))
            print(self.total_call_times.shape)

            self.timestamps = np.array(
                list(map(lambda x: x['timestamps'], data)))

    def plot_time_per_batch_vs_timestamps(self):
        # Need only to plot for one stream since they are all equal in time_per_batch
        plt.figure()
        plt.grid(b='gray')
        stream_id = 0
        print(self.timestamps.shape)
        timestamps = self.timestamps[stream_id, 2:]
        time_per_batch_in_usec = self.total_call_times[stream_id, 2:]
        time_per_batch_in_ms = time_per_batch_in_usec / 1_000

        # scale = 0.01
        # miny = min(time_per_batch_in_ms)
        # maxy = max(time_per_batch_in_ms) + scale * miny
        # miny *= (1 - scale)
        # plt.ylim((miny, maxy))

        ts = pd.Series(time_per_batch_in_ms, index=timestamps)

        avg = ts.rolling(window=15, min_periods=1).mean()

        std = ts.rolling(window=15, min_periods=1).std()
        plt.errorbar(
            timestamps,
            avg,
            yerr=std,
            errorevery=30,
            fmt='b',
            ecolor='r',
            linewidth=1.75,
            capsize=5,
            capthick=1.5
        )
        plt.legend(['Tempo de Processamento',
                    'Média móvel (15 amostras, lagging)'], loc='upper left')
        plt.ylabel('Tempo de Processamento por Lote (ms)')
        plt.xlabel('Tempo (s)')
        # plt.show()
        plt.savefig('./exported_results/tempo_por_lote_%d_streams.eps' %
                    self.num_streams, format='eps')

    def export_dropped_frames_table(self):
        table_header = r'''
\begin{table}[H]
    \centering
    \caption{Quadros Perdidos}
    \label{tab:results:dropped_frames_table}
    \begin{tabular}{|c|c|}
    \toprule
    Número de \textit{streams} & Quadros Perdidos \\
    \midrule
    '''

        table_footer = r''''
    \bottomrule
    \end{tabular}
\end{table}'''

        fetched_frames = self.timestamps.shape[1]
        line = r'%d & %d \\' % (self.num_streams, fetched_frames)
        table = table_header + line + table_footer
        with open('./exported_results/dropped_frames_table_%d_streams.tex' % self.num_streams, 'w+') as f:
            f.write(table)


base_path = './apps/grpclassify/priv/results/'

filenames = [
    '1_streams/AWS_DROP_FRAMES_GPU_2019-08-29_15:00:07.509988_results.json',
    '1_streams/AWS_NO_DROP_FRAMES_GPU_2019-08-29_14:53:06.654803_results.json',
    '2_streams/AWS_DROP_FRAMES_GPU_2019-08-29_14:57:54.157751_results.json',
    '2_streams/AWS_NO_DROP_FRAMES_GPU_2019-08-29_14:51:36.077328_results.json',
    '3_streams/AWS_NO_DROP_FRAMES_GPU_2019-08-29_14:48:07.162299_results.json',
    '3_streams/AWS_DROP_FRAMES_GPU_2019-08-29_14:45:48.120783_results.json'
]

for filename in filenames:
    print('Processing file:', filename)
    filename = base_path + filename
    exporter = ResultExporter(filename)
    if 'NO_DROP_FRAMES' in filename:
        exporter.plot_time_per_batch_vs_timestamps()
    else:
        exporter.export_dropped_frames_table()
