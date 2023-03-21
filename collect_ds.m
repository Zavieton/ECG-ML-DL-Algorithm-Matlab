%% ��ȡȫ���ݿ�Ŀ������
clc; 
clear all;
addpath('./Func');

Name_whole=[100,101,102,103,104,105,106,107,108,109,111,112,113,114,115,...
    116,117,118,119,121,122,123,124,200,201,202,203,205,207,208,209,...
    210,212,213,214,215,217,219,220,221,222,223,228,230,231,232,233,234];


INFO=[];
Nb=[];Lb=[];Rb=[];Vb=[];Ab=[];Sb=[];
Pl=100;Pr=150;
for na=1:length(Name_whole)

    %------ SPECIFY DATA ------------------------------------------------------
    %------ ָ�������ļ� -------------------------------------------------------

    Name=num2str(Name_whole(na));
    PATH= './MIT-BIH'; % ָ�����ݵĴ���·��  
    HEADERFILE=strcat(Name, '.hea');% .hea ��ʽ��ͷ�ļ������ü��±���        
    ATRFILE=strcat(Name, '.atr'); % .atr ��ʽ�������ļ������ݸ�ʽΪ��������    
    DATAFILE=strcat(Name, '.dat');% .dat ��ʽ��ECG ����
    SAMPLES2READ=650000;          % ָ����Ҫ�����������
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
    fprintf(1,'\n$> WORKING ON %s ...\n', HEADERFILE); % ��Matlab�����д�����ʾ��ǰ����״̬
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
    end
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
    end
    clear A M1H M2H PRR PRL;
    fprintf(1,'\\n$> LOADING DATA FINISHED \n');

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
    
    fprintf(1,'\n$> ALL FINISHED \n');

    s=M(:,1);
    s=s';
    %%
    [QRS_amp,QRS_ind] = DS_detect(s,0,na);% ����QRS����㷨��
    
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
                   switch ann(n)
                        case 1
                            Nb=[Nb;SEG];
                        case 2
                            Lb=[Lb;SEG];
                        case 3
                            Rb=[Rb;SEG];
                        case 5
                            Vb=[Vb;SEG];
                        case 8
                            Ab=[Ab;SEG];
                        case 9
                            Sb=[Sb;SEG];
                   end

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
                   switch ann(m)
                        case 1
                            Nb=[Nb;SEG];
                        case 2
                            Lb=[Lb;SEG];
                        case 3
                            Rb=[Rb;SEG];
                        case 5
                            Vb=[Vb;SEG];
                        case 8
                            Ab=[Ab;SEG];
                        case 9
                            Sb=[Sb;SEG];
                   end

                    break;
                end
            end

        end

    end
end


%% Save Results
save('./N_dat.mat', 'Nb');
save('./L_dat.mat', 'Lb');
save('./R_dat.mat', 'Rb');
save('./V_dat.mat', 'Vb');

fprintf(1,'\n$> ALL SAVED \n');
