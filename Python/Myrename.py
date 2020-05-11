'''修改目录下的文件，以数字排列重命名'''
import os,string
num=[1,2,3,4,5,6,7,8,9,0]
def Myrename(path):
    if not os.path.isdir(path):
        print('not a dir ,Try again')
        exit()
    os.chdir(path)
    old=os.listdir()
    #print('当前'old)
    i = 1
    for f in old:
        #跳过目录
        if os.path.isdir(f):
            print('跳过目录%s'%f)
            continue
        isok=1
        while isok :
            #当源文件已经是符合要求时跳过
            if os.path.splitext(f)[0] in str(num):
                print('当前文件<%s>符合，跳过'% f)
                isok=0
                continue
            #当目的文件已存在时，仅累加不执行
            print('当前文件名： <%s>'%f,end='')
            print(' 改成 <%s>'%str(i)+os.path.splitext(f)[1])
            if not os.path.exists(str(i)+os.path.splitext(f)[1]):
                os.rename(f,str(i)+os.path.splitext(f)[1])
                i+=1
                isok=0
            else:
                print('%s.txt文件已存在，跳过'% i)
                i += 1

if __name__ == '__main__':
    path=input('输入目标目录（绝对路径）：')
    Myrename(path)
