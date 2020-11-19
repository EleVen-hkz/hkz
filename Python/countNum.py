#求s=a+aa+aaa+aaaa+aa...a的值，其中a是一个数字。例如2+22+222+2222+22222(此时共有5个数相加)，几个数相加由键盘控制
count=int(input("count: "))
num=int(input("num: "))
n=[num]
sum=0
for i in range(1,count) :
    new=n[-1]*10+n[0]
    n.append(new)
print(n)
for i in n:
    sum+=i
print("结果是：%s " %sum)

