import random
xuanze=['石头','剪刀','布']
win=[['布','石头'],['石头','剪刀'],['剪刀','布']]
hum_win,robot_win,count=0,0,0
while 1:
    count+=1
    robot=random.choice(xuanze)
    hum=int(input('''
输入剪刀石头布,
0:石头
1:剪刀
2:布
'''))
    hum=xuanze[hum]
    now=[hum,robot]
    print('机器人出%s,你出了%s'% (robot,hum))
    if now in win:
        print('\033[31;1mYou Win\033[30;0m')
        hum_win+=1
    elif hum==robot:
        print('\033[33;1m平局\033[30;0m')
    else:
        print('\033[32;1mYou Lose\033[30;m')
        robot_win+=1
    if robot_win > 2 :
        print('一共玩了%s把,机器人率先赢了3把.胜!'% count)
        break
    elif hum_win > 2:
        print('一共玩了%s把,你率先赢了3吧,胜!!!'% count)
        break
