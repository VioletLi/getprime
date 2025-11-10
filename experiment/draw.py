import matplotlib.pyplot as plt
# import numpy as np

fwd_db={
    "luxuryitems":[0.000711,0.0014838,0.0077054,0.018185],
    "all_items":[0.0006226,0.0009504,0.004374,0.0080852],
    "courses":[0.0013886,0.0057168,0.027783,0.0547786],
    "book_info":[0.0019424,0.0062114,0.0232154,0.0474992]
}
bwd_db={
    "luxuryitems":[0.0008082,0.0015376,0.0070762,0.01656],
    "all_items":[0.0011372,0.0022334,0.0126284,0.0251246],
    "courses":[0.0027558,0.0074176,0.0381368,0.0724922],
    "book_info":[0.0018276,0.005104,0.0230012,0.0425898]
}
fwd_op={
    "luxuryitems":[0.026459,0.0351826,0.0590258,0.074377],
    "all_items":[0.0257208,0.0930322,0.1807902,0.2586328],
    "courses":[0.0978824,0.1623854,0.2404394,0.274794],
    "book_info":[0.0702688,0.1233378,0.1823996,0.231346]
}
bwd_op={
    "luxuryitems":[0.0199846,0.034645,0.0567508,0.0704976],
    "all_items":[0.0362646,0.0803756,0.121635,0.1587318],
    "courses":[0.113874,0.268719,0.4281426,0.5959982],
    "book_info":[0.0612396,0.1465638,0.228269,0.3089508]
}

# 横轴定义
db_sizes = [100, 1000, 5000, 10000]
ops = [5, 10, 15, 20]

# 转换为毫秒
def to_ms(d): 
    return {k:[v_i*1000 for v_i in v] for k,v in d.items()}

fwd_db = to_ms(fwd_db)
bwd_db = to_ms(bwd_db)
fwd_op = to_ms(fwd_op)
bwd_op = to_ms(bwd_op)

# 绘图风格
plt.style.use("seaborn-whitegrid")
plt.rcParams.update({
    'font.size': 9,
    'axes.titlesize': 9,
    'axes.labelsize': 9,
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    'legend.fontsize': 8
})

fig, axes = plt.subplots(2, 2, figsize=(7, 7), sharey='row') 


titles = [
    "Runtime vs. Database Size (Forward Transformation)",
    "Runtime vs. Database Size (Backward Transformation)",
    "Runtime vs. Operation Count (Forward Transformation)",
    "Runtime vs. Operation Count (Backward Transformation)"
]
datasets = [fwd_db, bwd_db, fwd_op, bwd_op]
x_values = [db_sizes, db_sizes, ops, ops]
x_labels = ["Database Size", "Database Size", "Operation Count", "Operation Count"]

panel_labels = ['(a)', '(b)', '(c)', '(d)']

# 绘制4张子图
for i, ax in enumerate(axes.flat):
    data = datasets[i]
    x = x_values[i]
    
    for label, y in data.items():
        ax.plot(x, y, label=label, marker='o', markersize=3, linewidth=1)

    if i < 2:
        ax.set_xlim(0, 10000)
        ax.set_xticks([0, 2500, 5000, 7500, 10000])
    else:
        ax.set_xlim(5, 20)
        ax.set_xticks([5, 10, 15, 20])

    ax.set_xlabel(x_labels[i], labelpad=5, loc='right')
    ax.set_ylabel("Time (ms)")

    ax.text(0.5, -0.15, titles[i], ha='center', va='center', transform=ax.transAxes, fontsize=9)
    # panel标签放在标题下面
    ax.text(0.5, -0.2, panel_labels[i], transform=ax.transAxes,
            fontsize=9, fontweight='bold', va='center', ha='center')

    ax.legend(fontsize=7, loc='upper left', frameon=False)
# 调整子图间距
plt.subplots_adjust(left=0.08, right=0.92, top=0.94, bottom=0.25, wspace=0.2, hspace=0.3)
fig.tight_layout(rect=[0, 0.02, 1, 1])
plt.show()
