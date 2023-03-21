%% �ο�rddata.m,����QRS��һ����ȫ���ݿ�������
%-------------------------------------------------------------------------
clc; clear all;tic,
addpath('./Func');

% Name_whole=[100,101,102,103,104,105,106,107,108,109,111,112,113,114,115,...
%     116,117,118,119,121,122,123,124,200,201,202,203,205,207,208,209,...
%     210,212,213,214,215,217,219,220,221,222,223,228,230,231,232,233,234];
Name_whole=[100,101];

INFO=[];fs=360;
for na=1:length(Name_whole)
    
    %------ SPECIFY DATA ------------------------------------------------------
    %------ ָ�������ļ� -------------------------------------------------------

    Name=num2str(Name_whole(na));
    PATH= './MIT-BIH'; % ָ�����ݵĴ���·��  
    HEADERFILE=strcat(Name, '.hea');% .hea ��ʽ��ͷ�ļ������ü��±���        
    ATRFILE=strcat(Name, '.atr'); % .atr ��ʽ�������ļ������ݸ�ʽΪ��������    
    DATAFILE=strcat(Name, '.dat');% .dat ��ʽ��ECG ����
    SAMPLES2READ=1800;
    % SAMPLES2READ=650000;          % ָ����Ҫ�����������
                                % ��.dat�ļ��д洢������ͨ�����ź�:
                                % ����� 2*SAMPLES2READ ������ 

    %------ LOAD HEADER DATA --------------------------------------------------
    %------ ����ͷ�ļ����� -----------------------------------------------------
    %
    % ʾ�����ü��±��򿪵�117.hea �ļ�������
    %
    %      117 2 360 650000
    %      117.dat 212 200 11 1024 839 31170 0 MLII
    %      117.dat 212 200 11 1024 930 28083 0 V2
    %      # 69 M 950 654 x2
    %      # None
    %
    %-------------------------------------------------------------------------
    fprintf(1,'\n$> WORKING ON %s ...', HEADERFILE); % ��Matlab�����д�����ʾ��ǰ����״̬
    % 
    % ��ע������ fprintf �Ĺ��ܽ���ʽ��������д�뵽ָ���ļ��С�
    % ���ʽ��count = fprintf(fid,format,A,...)
    % ���ַ���'format'�Ŀ����£�������A��ʵ�����ݽ��и�ʽ������д�뵽�ļ�����fid�С��ú���������д�����ݵ��ֽ��� count��
    % fid ��ͨ������ fopen ��õ������ļ���ʶ����fid=1����ʾ��׼��������������Ļ��ʾ����fid=2����ʾ��׼ƫ�
    %
    signalh= fullfile(PATH, HEADERFILE);    % ͨ������ fullfile ���ͷ�ļ�������·��
    fid1=fopen(signalh,'r');    % ��ͷ�ļ������ʶ��Ϊ fid1 ������Ϊ'r'--��ֻ����
    z= fgetl(fid1);             % ��ȡͷ�ļ��ĵ�һ�����ݣ��ַ�����ʽ
    A= sscanf(z, '%*s %d %d %d',[1,3]); % ���ո�ʽ '%*s %d %d %d' ת�����ݲ�������� A ��
    nosig= A(1);    % �ź�ͨ����Ŀ
    sfreq=A(2);     % ���ݲ���Ƶ��
    clear A;        % ��վ��� A ��׼����ȡ��һ������
    for k=1:nosig           % ��ȡÿ��ͨ���źŵ�������Ϣ
        z= fgetl(fid1);
        A= sscanf(z, '%*s %d %d %d %d %d',[1,5]);
        dformat(k)= A(1);           % �źŸ�ʽ; ����ֻ����Ϊ 212 ��ʽ
        gain(k)= A(2);              % ÿ mV ��������������
        bitres(k)= A(3);            % �������ȣ�λ�ֱ��ʣ�
        zerovalue(k)= A(4);         % ECG �ź������Ӧ������ֵ
        firstvalue(k)= A(5);        % �źŵĵ�һ������ֵ (����ƫ�����)
    end;
    fclose(fid1);
    clear A;

    %------ LOAD BINARY DATA --------------------------------------------------
    %------ ��ȡ ECG �źŶ�ֵ���� ----------------------------------------------
    %
    if dformat~= [212,212], error('this script does not apply binary formats different to 212.'); end;
    
    signald= fullfile(PATH, DATAFILE);            % ���� 212 ��ʽ�� ECG �ź�����
    fid2=fopen(signald,'r');
    A= fread(fid2, [3, SAMPLES2READ], 'uint8')';  % matrix with 3 rows, each 8 bits long, = 2*12bit
    fclose(fid2);
    % ͨ��һϵ�е���λ��bitshift����λ�루bitand�����㣬���ź��ɶ�ֵ����ת��Ϊʮ������
    M2H= bitshift(A(:,2), -4);        %�ֽ���������λ����ȡ�ֽڵĸ���λ
    M1H= bitand(A(:,2), 15);          %ȡ�ֽڵĵ���λ
    PRL=bitshift(bitand(A(:,2),8),9);     % sign-bit   ȡ���ֽڵ���λ�����λ�������ƾ�λ
    PRR=bitshift(bitand(A(:,2),128),5);   % sign-bit   ȡ���ֽڸ���λ�����λ����������λ
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
    end;
    clear A M1H M2H PRR PRL;
    fprintf(1,'\n$> Read Data from');
    fprintf(1,'\n --- %s',signald);
    fprintf(1,'\n --- %s',signalh);

    fprintf(1,'\n$> LOADING DATA FINISHED ');

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
       end;
       i=i+1;
    end;
    ANNOT(length(ANNOT))=[];       % last line = EOF (=0)
    ATRTIME(length(ATRTIME))=[];   % last line = EOF
    clear A;
    ATRTIME= (cumsum(ATRTIME))/sfreq;
    ind= find(ATRTIME <= TIME(end));
    ATRTIMED= ATRTIME(ind);
    ANNOT=round(ANNOT);
    ANNOTD= ANNOT(ind);

    %------ DISPLAY DATA ------------------------------------------------------
    %{
    figure(1); clf, box on, hold on
    plot(TIME, M(:,1),'r');
    if nosig==2
        plot(TIME, M(:,2),'b');
    end;
    for k=1:length(ATRTIMED)
        text(ATRTIMED(k),0,num2str(ANNOTD(k)));
    end;
    xlim([TIME(1), TIME(end)]);
    xlabel('Time / s'); ylabel('Voltage / mV');
    string=['ECG signal ',DATAFILE];
    title(string);
    fprintf(1,'\\n$> DISPLAYING DATA FINISHED \n');
    %}
    % -------------------------------------------------------------------------
    
    fprintf(1,'\n$> Number of leads�� %d, Sampling frequency�� %d, Sampling beats�� %d', nosig, sfreq, SAMPLES2READ);
    fprintf(1,'\n$> ALL FINISHED');

    %% ---------------------------------------------------------------
    s=M(:,1);
    ecg_i=s';
    %%
    [QRS_amp,QRS_ind] = DS_detect(ecg_i,1,na); % ����QRS������㷨��
    %%
    Nt=size(QRS_ind,2);
    R_TIME=ATRTIMED(ANNOTD~=14 & ANNOTD~=16 & ANNOTD~=18 & ANNOTD~=19 & ANNOTD~=20 & ANNOTD~=21 & ANNOTD~=22 & ...
    ANNOTD~=23 & ANNOTD~=24 & ANNOTD~=27  & ANNOTD~=28 & ANNOTD~=29 & ANNOTD~=30 & ...
    ANNOTD~=32 & ANNOTD~=33 & ANNOTD~=37 & ANNOTD~=39 & ANNOTD~=40);
    REF_ind=round(R_TIME'.*fs);
    Nr=size(REF_ind,2);
    if Nt>Nr
        typ=0;
    else
        typ=1;
    end
    TP=0;FP=0;FN=0;
    if typ==0
        QRS_ind_buf=[];
        for n=1:Nr
            ref=REF_ind(n);
            for m=1:Nt
                if abs(ref-QRS_ind(m))<=0.15*fs
                   QRS_ind_buf=[QRS_ind_buf QRS_ind(m)];
                   TP=TP+1;
                   break; 
                end 
            end
            if m==Nt&&abs(ref-QRS_ind(Nt))>0.15*fs
                FN=FN+1;
            end
        end
        FP=Nt-size(QRS_ind_buf,2);
    else
        REF_ind_buf=[];
        for n=1:Nt
            qrs=QRS_ind(n);
            for m=1:Nr
                if abs(qrs-REF_ind(m))<=0.15*fs
                    REF_ind_buf=[REF_ind_buf REF_ind(m)];
                    TP=TP+1;
                    break;
                end
            end
            if m==Nr&&abs(qrs-REF_ind(Nr))>0.15*fs
                FP=FP+1;
            end
        end
        FN=Nr-size(REF_ind_buf,2);
    end
    Se=TP/(TP+FN);Pp=TP/(TP+FP);
    info=[Name_whole(na),Nr,TP,FP,FN,Se,Pp];
    INFO=[INFO;info];
end
final=[0,sum(INFO(:,2)),sum(INFO(:,3)),sum(INFO(:,4)),sum(INFO(:,5)),...
    0,0];
final(6)=final(3)/(final(3)+final(5));
final(7)=final(3)/(final(3)+final(4));
INFO=[INFO;final];

fprintf(1,'\n');