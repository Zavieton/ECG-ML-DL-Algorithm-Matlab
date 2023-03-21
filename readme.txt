0. 数据 
Download from https://physionet.org/content/mitdb/1.0.0/
*.atr：标记文件，保存着人工标注的心拍位置和类型
*.dat: 数据文件，保存着我们需要的心电信号
*.hea：头文件，保存着这条记录的附加信息
具体见 Data Instructions.txt


1 数据可视化
run rddata.m
可视化数据集中的数据
输出图像 
-- figure1 为 多通道数据在时间维度上展开，横坐标为采样时间(S)，纵坐标采样时刻 mV
-- figure2 为 多通道数据在不同通道上分开表示，横坐标为采样次数，纵坐标采样时刻 mV

2 QRS波识别检测
run DS_test.m
步骤：
-- 解析ECG数据，二进制-->十进制序列
-- 调用函数DS_detect 返回图像为QRS波的检测结果

3 心拍截取
run SegBeat.m
这里主要基于上述的QRS识别结果，对序列片段进行截取,可视化展示了其中一段截取到的心拍序列
[向左包含100个点，向右包含150个点,截取的每个心拍长度为250个点（约0.7s）]  cited CSDN blog

4 数据集的提取
针对开源MIT-BIH的四种分类 “正常（N）”，“左束支阻滞（LBBB）”，“右束支阻滞（RBBB）”，“室性早搏（PVC）”
分别保存其心拍截取情况 --> *.mat
-- L_dat.mat 左束支阻滞
-- R_dat.mat 右束支阻滞
-- V_dat.mat 室性早搏
-- N_dat.mat 正常

5 基于CNN的分类器
run ClassificationCNN.m
模型为一维CNN，训练 ~epoch
模型保存至 ./model/cnn_model.mat
运行后figure为训练过程的损失曲线
输出不同类别下的准确率

6 模型推理
run CNN_Inference.m
-- 从一条采集数据中取数 截取拍数可以修改变量name
-- 预处理数据，按照QRS截取拍
-- 尺度变化&模型推理