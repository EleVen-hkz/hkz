import random
num=random.randint(1,100)
c=0
while c <= 5 :
    you=int(input('来吧,来猜吧,1-100\n'))
    if you == num :
        print('wow!,中了')
        break
    else:
        print('很接近了,再\033[31;1m大\033[30;0m一点') if you < num else print('很接近了,再\033[32;1m小\033[30;0m一点')
        c+=1
else:
    print('可惜,正确的是%s' % num)
