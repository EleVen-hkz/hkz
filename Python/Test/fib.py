import random
while 1:
    long=int(input('输入数列长度,至少为3:(输入0退出)'))
    if long==0 :
        break
    else:
        a=[0]
        a.append(a[0]+1)
        for i in range(1,long):
            new=a[-1]+a[-2]
            a.append(new)
        print(a[1:])

def fib(max):
    n, a, b = 0, 0, 1
    while n < max:
        print(b)
        a, b = b, a + b
        n = n + 1
    return 'done'
