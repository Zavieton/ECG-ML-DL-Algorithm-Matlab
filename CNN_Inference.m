clear;
clc;
addpath('./CNN');
addpath('./Func');

%% Load Model
load('./model/cnn_model.mat');
fprintf('\n$> Successful Load Model To Mem\n')


% N 108 106 105 100 223 234 233 228
% RBBB 212 124 118 232 231

%% Preprocess
name = 108;

SEGS = []; %保存 片段
LABEL = []; % 保存 标注类别
Pl=100;Pr=150;
Name_whole=[name];

for na=1:length(Name_whole)
    Name=num2str(Name_whole(na));
    PATH= './MIT-BIH';
    HEADERFILE=strcat(Name, '.hea');     
    ATRFILE=strcat(Name, '.atr');
    DATAFILE=strcat(Name, '.dat');
    SAMPLES2READ = 6000; % 采样长度
    
    signalh= fullfile(PATH, HEADERFILE);    % 通过函数 fullfile 获得头文件的完整路径
    fid1=fopen(signalh,'r');    % 打开头文件，其标识符为 fid1 ，属性为'r'--“只读”
    z= fgetl(fid1);             % 读取头文件的第一行数据，字符串格式
    A= sscanf(z, '%*s %d %d %d',[1,3]); % 按照格式 '%*s %d %d %d' 转换数据并存入矩阵 A 中
    nosig= A(1);    % 信号通道数目
    sfreq=A(2);     % 数据采样频率
    clear A;        % 清空矩阵 A ，准备获取下一行数据
    
    for k=1:nosig           % 读取每个通道信号的数据信息
        z= fgetl(fid1);
        A= sscanf(z, '%*s %d %d %d %d %d',[1,5]);
        dformat(k)= A(1);           % 信号格式; 这里只允许为 212 格式
        gain(k)= A(2);              % 每 mV 包含的整数个数
        bitres(k)= A(3);            % 采样精度（位分辨率）
        zerovalue(k)= A(4);         % ECG 信号零点相应的整数值
        firstvalue(k)= A(5);        % 信号的第一个整数值 (用于偏差测试)
    end
    fclose(fid1);
    clear A;

    %------ LOAD BINARY DATA --------------------------------------------------
    %------ 读取 ECG 信号二值数据 ----------------------------------------------
    
    if dformat~= [212,212], error('this script does not apply binary formats different to 212.'); end;
    signald= fullfile(PATH, DATAFILE);           
    fid2=fopen(signald,'r');
    A= fread(fid2, [3, SAMPLES2READ], 'uint8')';  % matrix with 3 rows, each 8 bits long, = 2*12bit
    fclose(fid2);

    M2H= bitshift(A(:,2), -4);        
    M1H= bitand(A(:,2), 15);          
    PRL=bitshift(bitand(A(:,2),8),9);    
    PRR=bitshift(bitand(A(:,2),128),5);   
    M( : , 1)= bitshift(M1H,8)+ A(:,1)-PRL;
    M( : , 2)= bitshift(M2H,8)+ A(:,3)-PRR;
    if M(1,:) ~= firstvalue, error('inconsistency in the first bit values'); end;
    switch nosig
    case 2
        M( : , 1)= (M( : , 1)- zerovalue(1))/gain(1);
        M( : , 2)= (M( : , 2)- zerovalue(2))/gain(2);
        TIME=(0:(SAMPLES2READ-1))/sfreq;
    case 1
        M( : , 1)= (M( : , 1)- zerovalue(1));
        M( : , 2)= (M( : , 2)- zerovalue(1));
        M=M';
        M(1)=[];
        sM=size(M);
        sM=sM(2)+1;
        M(sM)=0;
        M=M';
        M=M/gain(1);
        TIME=(0:2*(SAMPLES2READ)-1)/sfreq;
    otherwise  % this case did not appear up to now!
        % here M has to be sorted!!!
        disp('Sorting algorithm for more than 2 signals not programmed yet!');
    end
    clear A M1H M2H PRR PRL;
    
    %------ LOAD ATTRIBUTES DATA ----------------------------------------------
    atrd= fullfile(PATH, ATRFILE);      % attribute file with annotation data
    fid3=fopen(atrd,'r');
    A= fread(fid3, [2, inf], 'uint8')';
    fclose(fid3);
    ATRTIME=[];
    ANNOT=[];
    sa=size(A);
    saa=sa(1);
    i=1;
    while i<=saa
        annoth=bitshift(A(i,2),-2);
        if annoth==59
            ANNOT=[ANNOT;bitshift(A(i+3,2),-2)];
            ATRTIME=[ATRTIME;A(i+2,1)+bitshift(A(i+2,2),8)+...
                    bitshift(A(i+1,1),16)+bitshift(A(i+1,2),24)];
            i=i+3;
        elseif annoth==60
            % nothing to do!
        elseif annoth==61
            % nothing to do!
        elseif annoth==62
            % nothing to do!
        elseif annoth==63
            hilfe=bitshift(bitand(A(i,2),3),8)+A(i,1);
            hilfe=hilfe+mod(hilfe,2);
            i=i+hilfe/2;
        else
            ATRTIME=[ATRTIME;bitshift(bitand(A(i,2),3),8)+A(i,1)];
            ANNOT=[ANNOT;bitshift(A(i,2),-2)];
        end
       i=i+1;
    end
    ANNOT(length(ANNOT))=[];       % last line = EOF (=0)
    ATRTIME(length(ATRTIME))=[];   % last line = EOF
    clear A;
    ATRTIME= (cumsum(ATRTIME))/sfreq;
    ind= find(ATRTIME <= TIME(end));
    ATRTIMED= ATRTIME(ind);
    ANNOT=round(ANNOT);
    ANNOTD= ANNOT(ind);

    s=M(:,1);
    s=s';
    

    %%
    [QRS_amp,QRS_ind] = DS_detect(s,1,na);% 调用QRS检测算法；
    
    %%
    Nt=size(QRS_ind,2);
    R_TIME=ATRTIMED(ANNOTD==1 | ANNOTD ==2 | ANNOTD==3 | ANNOTD==5 | ANNOTD==8 |ANNOTD==9 );

    REF_ind=round(R_TIME'.*360);
    Nr=size(REF_ind,2);
    ann=ANNOTD(ANNOTD==1 | ANNOTD ==2 | ANNOTD==3 | ANNOTD==5 | ANNOTD==8 |ANNOTD==9);

    if Nt>Nr
        typ=0;
    else
        typ=1;
    end

    if typ==0
        for n=1:Nr
            ref=REF_ind(n);
            for m=1:Nt
                act_ind=QRS_ind(m);
                if abs(ref-act_ind)<=54
                   if act_ind<Pl || (SAMPLES2READ-act_ind)<Pr
                        break;
                   else
                        SEG=s((act_ind-Pl+1):(act_ind+Pr));
                   end
                   
                   LABEL = [LABEL;ann(n)];
                   SEGS=[SEGS;SEG];
    
                   break;
                end 
            end

        end
    else
        for n=1:Nt
            act_ind=QRS_ind(n);
            for m=1:Nr
                if abs(act_ind-REF_ind(m))<=54
                   if act_ind<Pl || (SAMPLES2READ-act_ind)<Pr
                        break;
                   else
                        SEG=s((act_ind-Pl+1):(act_ind+Pr));
                   end
                   
                   LABEL = [LABEL; ann(m)];
                   SEGS=[SEGS;SEG];
                   
                   break;
                end
            end
        end
    end
end

% if length(LABEL)==0
%     continue
% end

%% Inference
cls = ["Normal", "PVC", "RBBB", "LBBB"];
[n, l] = size(SEGS);
SEGS = SEGS-repmat(mean(SEGS,2),1,250);
p = [];
for j = 1:n
    [~,~,out] = cnntest1d(cnn, SEGS(j,:)',[0,0,0,0]);
    m = max(out);
    predict = 1; % Default Set
    for i = 1:length(out)
        if m == out(i)
            predict = i;
            break
        end
    end
    p = [p;predict];
end

% label transfer
lb = [1,2,3,5];

L = [];
for i = 1:length(LABEL)
    for j = 1:4
        if LABEL(i)==lb(j)
            L = [L;j];
            break
        end
    end
end



predict = mode(p);
lab = mode(L);
fprintf('\n$> ECG Signal of %s',DATAFILE);
fprintf('\n$> Prediction is %d %s. \n$> Label is %d %s',predict, cls(predict), L(1), cls(lab));
if predict ==  lab 
    fprintf('\n$> Predict Correctly.\n');
else
    fprintf('\n$> Incorrectly.\n');
end

%% Draw Segment
figure();

for i = 1:4
    subplot(2,2,i);
    plot(SEGS(i,:));
    title('example');
    grid on;
end

%% Draw result curve
figure();
set(gcf,'unit','normalized','position',[0.2,0.1,0.64,0.32]);
space = {32};
string=[strcat('ECG Signal of ',space, DATAFILE), strcat('CNN Predict Result is  ', space, cls(predict)), strcat(' Ground Truth is  ',space, cls(lab))];
plot(M(:,1));
title(string);
grid on;



