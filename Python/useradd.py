'''
that is useradd
'''
import subprocess,sys,get_passwd
def add_user(name,file='/tmp/user.info'):
    '''
    useradd script
    '''
    code = subprocess.run('id %s &> /dev/null' % name, shell=True)
    if not code.returncode:
        print('用户已存在')
        return
# get passwd
    passwd = get_passwd.get_pass()
    print(passwd)
# useradd
    subprocess.run('useradd %s' % name, shell=True)
    subprocess.run('echo %s|passwd --stdin %s'%(passwd,name),shell=True)
#write info
    with open(file,'a') as info:
        info.write('''
userinfo:
username:%s
passwd:%s
#-------------------
        '''%(name,passwd))
    print('用户信息存放在%s'%file)

if __name__=='__main__':
    if len(sys.argv) == 2:
        add_user(sys.argv[1])
    elif len(sys.argv) == 3:
        add_user(sys.argv[1],sys.argv[2])
    else:
        print('Usage: useradd.py username [info_file]')

