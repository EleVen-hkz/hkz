import random
while 1:
    long=int(input('输入数列长度,至少为3:(输入0退出)'))
    if long==0 :
        break
    else:
        a=[random.randint(0,999)]
        a.append(a[0]+1)
        for i in range(1,long-1):
            new=a[-1]+a[-2]
            a.append(new)
        print(a)
