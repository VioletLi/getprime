import random

def genDBLuxuryitems(filePath, size):
    datas=[]
    for i in range(0, size//2):
        price = random.randint(0, 700)
        datas.append((i, price))
    for i in range(size//2, size):
        price = random.randint(701,2000)
        datas.append((i, price))
    with open(filePath, "w") as f:
        for i in range(0, size):
            f.write(f"items({i},\'item_{i}\',{datas[i][1]}).\n")
        for i in range(size//2, size):
            f.write(f"luxuryitems({i},\'item_{i}\',{datas[i][1]}).\n")
    print(f"Generated {size} items to {filePath}")


def genDBAllitems(filePath, size):
    pass

def genDBCourses(filePath, size):
    pass

def genDBBookinfo(filePath, size):
    pass