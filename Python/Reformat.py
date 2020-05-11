import os,sys
def Reformat(sformat,dformat,path) :
    os.chdir(path)
    all=os.listdir()
    n=0
    for i in all :
        old=i.split('.')
        new=''
        if old[-1] == sformat:
            for j in range(len(old)-1):
                new=new+old[j]+'.'
            os.rename(i,new+dformat)
            n+=1

    print('没有找到%s格式的文件'%sformat) if n == 0 else print('共找到并修改%d个文件'%n)
if __name__ == '__main__':
    if len(sys.argv) == 1 :
        p=input('请输入需要修改的目录（绝对路径,默认为当前目录）：')
        s=input('请输入源格式（例如txt）：')
        d=input('请输入想要变成的格式（例如MP3）：')
        Reformat(s,d,p) if p else Reformat(s,d,os.getcwd())
    elif len(sys.argv) == 4:
        Reformat(sys.argv[1],sys.argv[2],sys.argv[3])
    elif len(sys.argv) == 3:
        Reformat(sys.argv[1],sys.argv[2],os.getcwd())
    else:
        print('usage: reformat <源格式> <目标格式> <>')
