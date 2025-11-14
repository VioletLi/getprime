import random

def genDBLuxuryitems(filePath, size):
    datas = []
    for i in range(0, size//2):
        price = random.randint(0, 700)
        datas.append((i, price))
    for i in range(size//2, size):
        price = random.randint(701,2000)
        datas.append((i, price))
    with open(filePath+"/"+str(size)+"_ini", "w") as f:
        for i in range(0, size):
            f.write(f"items({i},\'item_{i}\',{datas[i][1]}).\n")
        for i in range(size//2, size):
            f.write(f"luxuryitems({i},\'item_{i}\',{datas[i][1]}).\n")
    with open(filePath+"/"+str(size)+"_f", "w") as f:
        for i in range(0, size):
            f.write(f"items({i},\'item_{i}\',{datas[i][1]}).\n")
    with open(filePath+"/"+str(size)+"_b", "w") as f:
        for i in range(size//2, size):
            f.write(f"luxuryitems({i},\'item_{i}\',{datas[i][1]}).\n")
    print(f"Generated {size} items to {filePath}")


def genDBAllitems(filePath, size):
    with open(filePath+"/"+str(size)+"_ini","w") as f:
        for i in range(0,size//4):
            f.write(f"on_sale('item_{i}').\n")
        for i in range(size//4, size//2):
            f.write(f"in_stock('item_{i}').\n")
        for i in range(size//2,size//4*3):
            f.write(f"on_sale('item_{i}').\nin_stock('item_{i}').\n")
        for i in range(0,size//4*3):
            f.write(f"all_items('item_{i}').\n")
    with open(filePath+"/"+str(size)+"_f", "w") as f:
        for i in range(0,size//4):
            f.write(f"on_sale('item_{i}').\n")
        for i in range(size//4, size//2):
            f.write(f"in_stock('item_{i}').\n")
        for i in range(size//2,size//4*3):
            f.write(f"on_sale('item_{i}').\nin_stock('item_{i}').\n")
    with open(filePath+"/"+str(size)+"_b", "w") as f:
        for i in range(0,size//4*3):
            f.write(f"all_items('item_{i}').\n")
    print(f"Generated {size} items to {filePath}")

def genDBCourses(filePath, size):
    with open(filePath+"/"+str(size)+"_ini", "w") as f:
        for i in range(0, size // 10):
            f.write(f"enrollment('course_{i}','stu_{i}').\n")
        for i in range(size // 10, size * 2 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\n")
        for i in range(size * 2 // 10, size * 3 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\nenrollment('course_{i}','stu_{i}3').\n")
        for i in range(size * 3 // 10, size * 4 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\nenrollment('course_{i}','stu_{i}3').\nenrollment('course_{i}','stu_{i}4').\n")
        for i in range(0, size * 4 // 10):
            f.write(f"courses('course_{i}').\n")
    with open(filePath+"/"+str(size)+"_f", "w") as f:
        for i in range(0, size // 10):
            f.write(f"enrollment('course_{i}','stu_{i}').\n")
        for i in range(size // 10, size * 2 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\n")
        for i in range(size * 2 // 10, size * 3 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\nenrollment('course_{i}','stu_{i}3').\n")
        for i in range(size * 3 // 10, size * 4 // 10):
            f.write(f"enrollment('course_{i}','stu_{i}1').\nenrollment('course_{i}','stu_{i}2').\nenrollment('course_{i}','stu_{i}3').\nenrollment('course_{i}','stu_{i}4').\n")
    with open(filePath+"/"+str(size)+"_b", "w") as f:
        for i in range(0, size * 4 // 10):
            f.write(f"courses('course_{i}').\n")
    print(f"Generated {size} items to {filePath}")


def genDBBookinfo(filePath, size):
    group=size//6
    with open(filePath+"/"+str(size)+"_ini", "w") as f:
        for i in range(0, group+1):
            f.write(f"author('book_{i}','author_{i}').\n")
        for i in range(group+1,2*group+1):
            f.write(f"author('book_{i}','author_{i}').\nedition('book_{i}','ver0').\n")
        for i in range(2*group+1,3*group+2):
            f.write(f"author('book_{i}','author_{i}').\nedition('book_{i}','ver0').\nedition('book_{i}','ver1').\n")
        for i in range(0, group+1):
            f.write(f"book_info('book_{i}','author_{i}','NULL').\n")
        for i in range(group+1,2*group+1):
            f.write(f"book_info('book_{i}','author_{i}','ver0').\n")
        for i in range(2*group+1,3*group+2):
            f.write(f"book_info('book_{i}','author_{i}','ver0').\nbook_info('book_{i}','author_{i}','ver1').\n")
    with open(filePath+"/"+str(size)+"_f", "w") as f:
        for i in range(0, group+1):
            f.write(f"author('book_{i}','author_{i}').\n")
        for i in range(group+1,2*group+1):
            f.write(f"author('book_{i}','author_{i}').\nedition('book_{i}','ver0').\n")
        for i in range(2*group+1,3*group+2):
            f.write(f"author('book_{i}','author_{i}').\nedition('book_{i}','ver0').\nedition('book_{i}','ver1').\n")
    with open(filePath+"/"+str(size)+"_b", "w") as f:
        for i in range(0, group+1):
            f.write(f"book_info('book_{i}','author_{i}','NULL').\n")
        for i in range(group+1,2*group+1):
            f.write(f"book_info('book_{i}','author_{i}','ver0').\n")
        for i in range(2*group+1,3*group+2):
            f.write(f"book_info('book_{i}','author_{i}','ver0').\nbook_info('book_{i}','author_{i}','ver1').\n")
    print(f"Generated {size} items to {filePath}")