import  sys
def copy_file (s='/tmp/test',d='/tmp/default'):
    s_f=open(s,'rb')
    d_f=open(d,'ab')
    while 1:
        data=s_f.read(4096)
        if data:
            d_f.write(data)
        else:
            break
    s_f.close()
    d_f.close()
    return 0
print(len(sys.argv))
if len(sys.argv) == 1:
    print('未输入,默认将/tmp/test拷贝至/tmp/new_default')
    copy_file()
elif len(sys.argv) == 2 :
    print('\033[32;1m成功\033[30;0m,将%s拷贝至/tmp/default'% sys.argv[1])
    copy_file(sys.argv[1])
elif len(sys.argv) == 3 :
    print('\033[32;1m成功\033[30;0m,将%s拷贝至%s' % (sys.argv[1],sys.argv[2]))
    copy_file(sys.argv[1],sys.argv[2] )
else:
    print('\033[31;1m错误\033[30;0m,请依次输入源文件路径和目标路径')
