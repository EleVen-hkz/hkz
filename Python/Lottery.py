#双色球模拟器
#6个红色球号码和1个蓝色球号码组成。红色球号码从1--33中选择；蓝色球号码从1--16中选择
import random,time
myred=[2,6,14,16,19,24]
mybule=[14]
count=0
while 1 :
    time.sleep(0.3)
    red=[]
    while len(red) < 6:
        n=random.randint(1,33)
        if n not in red:
            red.append(n)
    bule=random.randint(1,16)
    red.sort()
    print(red,bule)
    if myred == red :
        if mybule == bule:
            print("WOW,500万,一共%s次"% count)
            break
        else:
            print("就差一点,已经%s次"% count)
            count = count + 1
    else:
        count=count+1

