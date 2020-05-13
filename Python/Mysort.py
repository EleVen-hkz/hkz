import time,random
# #init = [1,23,5123,12451,51,235,6,0,2,1.2,7,123,6235,712]
# init=(random.randint(1,55555) for i in range(0,55555))
# print(time.asctime())
# for i in range(0,len(init)) :
#     #print('前面的数是 %s ' %init[i])
#     for j in range(i+1,len(init)):
#         #print("后面的数是 %s " % init[j])
#         if init[i] > init[j]:
#             init[i],init[j] = init[j],init[i]
#
# print("new is %s,\n now: %s"%(init,time.asctime()))


new=[]
a=[random.randint(1,55554) for i in range(0,5555)]
print(time.asctime())
while 1 :
    s=a[0]
    for i in range(1,len(a)):
        if s > a[i] :
            s=a[i]
    new.append(s)
    a.remove(a[a.index(s)])
    if len(a) == 0:
        break
print(new,time.asctime(),sep='\n')

