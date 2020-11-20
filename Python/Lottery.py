#双色球模拟器
#6个红色球号码和1个蓝色球号码组成。红色球号码从1--33中选择；蓝色球号码从1--16中选择
import random,time
myred=[2,6,14,16,19,24]
mybule=14
count=0
state={"一等奖":0,"二等奖":0,"三等奖":0,"四等奖":0,"五等奖":0,"六等奖":0,}
while 1 :
    #time.sleep(0.01)
    count=count+1
    red=[]
    while len(red) < 6:
        n=random.randint(1,33)
        if n not in red:
            red.append(n)
    bule=random.randint(1,16)
    red.sort()

    yes=0
    for i in red:
        if i in myred:
            yes+=1
    if yes == 0 :
        if bule == mybule:
            print("六等奖，5块钱")
            state["六等奖"]+=1
        else:
            print("咣！")
    elif yes == 1 :
        if  bule == mybule:
            print("六等奖，5块钱")
            state["六等奖"]+=1
        else:
            print("咣！")
    elif yes ==2 :
        if  bule == mybule:
            print("六等奖，5块钱")
            state["六等奖"]+=1
        else:
            print("咣！")
    elif yes == 3 :
        if  bule == mybule:
            print("5等奖，10块钱")
            state["五等奖"]+=1
        else:
            print("咣！")
    elif yes == 4 :
        if  bule == mybule:
            print("4等奖，200块钱")
            state["四等奖"]+=1
        else:
            print("5等奖，10块钱")
            state["五等奖"]+=1
    elif yes == 5 :
        if  bule == mybule:
            print("3等奖，3000块钱")
            state["三等奖"]+=1
        else:
            print("4等奖，200块钱")
            state["四等奖"]+=1
    elif yes == 6 :
        if  bule == mybule:
            print("1等奖!，500W!")
            state["一等奖"]+=1
        else:
            print("2等奖，当期高奖级奖金的25%")
            state["二等奖"]+=1
    print("本次开奖号码",red,bule)
    print("你一共玩了%s次"%count)
    print("当前中奖情况:",state)

