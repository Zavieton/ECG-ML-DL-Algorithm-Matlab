clear;clc;
addpath('./CNN');
addpath('./Func');

%% �������ݣ�
fprintf('Loading data...\n');
tic;
load('./dat/N_dat.mat');
load('./dat/L_dat.mat');
load('./dat/R_dat.mat');
load('./dat/V_dat.mat');
fprintf('Finished Load Data!\n');
toc;
fprintf('=============================================================\n');
%% ����ʹ����������ÿһ��5000�������ɱ�ǩ,one-hot���룻
fprintf('Data preprocessing...\n');
tic;
Nb=Nb(1:20000,:);Label1=repmat([1;0;0;0],1,20000);
Vb=Vb(1:7000,:);Label2=repmat([0;1;0;0],1,7000);
Rb=Rb(1:7000,:);Label3=repmat([0;0;1;0],1,7000);
Lb=Lb(1:7000,:);Label4=repmat([0;0;0;1],1,7000);

Data=[Nb;Vb;Rb;Lb];
Label=[Label1,Label2,Label3,Label4];

clear Nb;clear Label1;
clear Rb;clear Label2;
clear Lb;clear Label3;
clear Vb;clear Label4;
Data=Data-repmat(mean(Data,2),1,250); %ʹ�źŵľ�ֵΪ0��ȥ�����ߵ�Ӱ�죻
fprintf('Finished!\n');
toc;
fprintf('=============================================================\n');

%% ���ݻ�����ģ��ѵ�����ԣ�
fprintf('Model training and testing...\n');
Nums=randperm(41000);      %�����������˳�򣬴ﵽ���ѡ��ѵ������������Ŀ�ģ�
train_x=Data(Nums(1:35000),:);
test_x=Data(Nums(35001:end),:);
train_y=Label(:,Nums(1:35000));
test_y=Label(:,Nums(35001:end));
train_x=train_x';
test_x=test_x';

cnn.layers = {
    struct('type', 'i') %input layer
    struct('type', 'c', 'outputmaps', 4, 'kernelsize', 31,'actv','relu') %convolution layer
    struct('type', 's', 'scale', 5,'pool','mean') %sub sampling layer
    struct('type', 'c', 'outputmaps', 8, 'kernelsize', 6,'actv','relu') %convolution layer
    struct('type', 's', 'scale', 3,'pool','mean') %subsampling layer
};
cnn.output = 'softmax';  %ȷ��cnn�ṹ��
                         %ȷ����������
opts.alpha = 0.005;       %ѧϰ�ʣ�
opts.batchsize = 16;     %batch���С��
opts.numepochs = 40;     %����epoch��

cnn = cnnsetup1d(cnn, train_x, train_y);      %����1D CNN;
cnn = cnntrain1d(cnn, train_x, train_y,opts); %ѵ��1D CNN;
[er,bad,out] = cnntest1d(cnn, test_x, test_y);%����1D CNN;

[~,ptest]=max(out,[],1);
[~,test_yt]=max(test_y,[],1);


%% Calculate Accuracy
Correct_Predict=zeros(1,4);                     %ͳ�Ƹ���׼ȷ�ʣ�
Class_Num=zeros(1,4);                           %���õ���������
Conf_Mat=zeros(4);
for i=1:6000
    Class_Num(test_yt(i))=Class_Num(test_yt(i))+1;
    Conf_Mat(test_yt(i),ptest(i))=Conf_Mat(test_yt(i),ptest(i))+1;
    if ptest(i)==test_yt(i)
        Correct_Predict(test_yt(i))= Correct_Predict(test_yt(i))+1;
    end
end


ACCs=Correct_Predict./Class_Num;
fprintf('Accuracy = %.2f%%\n',(1-er)*100);
fprintf('Accuracy_N = %.2f%%\n',ACCs(1)*100);
fprintf('Accuracy_V = %.2f%%\n',ACCs(2)*100);
fprintf('Accuracy_R = %.2f%%\n',ACCs(3)*100);
fprintf('Accuracy_L = %.2f%%\n',ACCs(4)*100);

%% Draw loss figures
loss_epochs = cnn.Ls;
figure();
plot(loss_epochs,'-xb','LineWidth',1);
title('CNN Training Loss');
grid on;
xlabel('Number of epochs');ylabel('Loss');

%% Save Model
save('./model/cnn_model','cnn');