#双色球模拟器
#6个红色球号码和1个蓝色球号码组成。红色球号码从1--33中选择；蓝色球号码从1--16中选择
import random
myred=[2,6,14,16,19,24]
mybule=[14]
count=0
while 1 :
    red=[]
    for i in range(0,6):
        red.append(random.randint(1,33))
    bule=random.randint(1,16)
    red.sort()
    if myred == red :
        if mybule == bule:
            print("WOW,500万,一共%s次"% count)
            break
        else:
            print("红球都对了，可惜就差一点。已经玩了%s次"% count)
            count = count + 1
    else:
        count=count+1

