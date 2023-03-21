function [QRS_amp,QRS_ind] = DS_detect( ecg_i,gr, na)
%% function [QRS_amp,QRS_ind]=DS_detect(ecg_i,gr)
%% ����
% ecg_i : ԭ�źţ�һά����
% gr : ��ͼ���0������ͼ��1����ͼ
%% ���
% QRS_amp:QRS�����.
% QRS_ind:QRS������.
% ����ͼ��.
%% ���ߣ����ĺ���WHliu@whu.edu.cn��
%% �汾��1.1
%% 04-24-2018
%% ����:
if nargin < 2
    gr = 1; 
    if nargin<1
           error('The algorithm need a input:ecg_i.');
    end
end
if ~isvector(ecg_i)
  error('ecg_i must be a row or column vector.');
end
fs=360;
if size(ecg_i,2)<round(1.5*fs)+1
    error('The algorithm need a longer input.');
end
tic,
s=ecg_i;
N=size(s,2);
ECG=s;
FIR_c1=[0.0041,0.0053,0.0068,0.0080,0.0081,0.0058,-0.0000,-0.0097,-0.0226,...   
   -0.0370,-0.0498,-0.0577,-0.0576,-0.0477,-0.0278,0,0.0318,0.0625,0.0867,...    
    0.1000,0.1000,0.0867,0.0625,0.0318,0,-0.0278,-0.0477,-0.0576,-0.0577,...   
    -0.0498,-0.0370,-0.0226,-0.0097,-0.0000,0.0058,0.0081,0.0080,0.0068,...
    0.0053,0.0041]; % ʹ��fdatool��Ʋ��������˲���ϵ��,��ͨFIR,15~25Hz,����ʹ��fdatool��DS1.fda�鿴
FIR_c2=[0.0070,0.0094,0.0162,0.0269,0.0405,0.0555,0.0703,0.0833,0.0928,...    
    0.0979,0.0979,0.0928,0.0833,0.0703,0.0555,0.0405,0.0269,0.0162,0.0094,...    
    0.0070]; % ʹ��fdatool��Ʋ��������˲���ϵ��,��ͨFIR,��ֹƵ��5Hz,����ʹ��fdatool��DS2.fda�鿴

l1=size(FIR_c1,2);
ECG_l=[ones(1,l1)*ECG(1) ECG ones(1,l1)*ECG(N)]; % ���ݵ����أ���ֹ�˲���ԵЧӦ��
ECG=filter(FIR_c1,1,ECG_l); % ʹ��filter�˲���
ECG=ECG((l1+1):(N+l1)); % ǰ�����������ݵ㣬�����ȡ���õĲ��֣�

%% ˫б�ʴ���
a=round(0.015*fs);  % ����Ŀ������0.015~0.060s;
b=round(0.060*fs);
Ns=N-2*b;           % ȷ���ڲ������źų��ȣ�
S_l=zeros(1,b-a+1);
S_r=zeros(1,b-a+1);
S_dmax=zeros(1,Ns);
for i=1:Ns          % ��ÿ����˫б�ʴ���
    for k=a:b
        S_l(k-a+1)=(ECG(i+b)-ECG(i+b-k))./k;
        S_r(k-a+1)=(ECG(i+b)-ECG(i+b+k))./k;
    end
  S_lmax=max(S_l);
  S_lmin=min(S_l);
  S_rmax=max(S_r);
  S_rmin=min(S_r);
  C1=S_rmax-S_lmin;
  C2=S_lmax-S_rmin;
  S_dmax(i)=max([C1 C2]);
end

%% �ٴν��е�ͨ�˲���˼·��������ͨ�˲�һ��
l2=size(FIR_c2,2);
S_dmaxl=[ones(1,l2)*S_dmax(1) S_dmax ones(1,l2)*S_dmax(Ns)];
S_dmaxt=filter(FIR_c2,1,S_dmaxl);
S_dmaxt=S_dmaxt((l2+1):(Ns+l2));

%% �������ڻ���
w=8;wd=7;
d_l=[zeros(1,w) S_dmaxt zeros(1,w)];  % �����أ�ȷ�����еĵ㶼���Խ��д��ڻ���
m=zeros(1,Ns);
   for n=(w+1):(Ns+w)                 % �������ڣ�
      m(n-w)=sum(d_l(n-w:n+w));       % ���֣�
   end
m_l=[ones(1,wd)*m(1) m ones(1,wd)*m(Ns)]; 

%% ˫��ֵ����붯̬�仯
QRS_buf1=[];   % �洢��⵽��QRS������
AMP_buf1=[];   % �洢�����⵽��8��QRS����Ӧ�����źŵĲ���ֵ
thr_init0=0.4;thr_lim0=0.23;
thr_init1=0.6;thr_lim1=0.3;  %% ��ֵ�仯�ĳ�ʼֵ����������
en=-1;        % ��ǲ�������������ڸ���ֵ--1���ߵ���ֵ֮��--0��δ���-- -1
thr0=thr_init0;
thr1=thr_init1;
thr1_buf=[]; % ��ֵ���棬��¼��ֵ�仯�����
thr0_buf=[];
for j=8:Ns
       t=1;
       cri=1;
       while t<=wd&&cri>0   % ����ѡ���壻
           cri=((m_l(j)-m_l(j-t))>0)&&(m_l(j)-m_l(j+t)>0);
           t=t+1;
       end
       if t==wd+1
           N1=size(QRS_buf1,2);               %N1:�Ѿ���⵽��QRS������
           if m_l(j)>thr1                     % ���ڸ���ֵʱ�Ĵ���
               if N1<2                        % N1С��2ʱֱ�Ӵ洢��
                 QRS_buf1=[QRS_buf1 (j-wd)];  % j-wd ��ȥ�˻������ڻ��ִ������ӳ٣�
                 AMP_buf1=[AMP_buf1 m_l(j)];
                 en=1;
               else
                 dist=j-wd-QRS_buf1(N1);
                 if dist>0.24*fs               % ��Ⲩ����룻
                     QRS_buf1=[QRS_buf1 (j-wd)]; 
                     AMP_buf1=[AMP_buf1 m_l(j)];
                     en=1;
                 else
                     if m_l(j)>AMP_buf1(end)   % ��Ӧ�ڴ���
                         QRS_buf1(end)=j-wd;
                         AMP_buf1(end)=m_l(j);
                         en=1;
                     end     
                 end
               end
     
          else                                 % ������ֵ���ڸ���ֵ
               
              if N1<2&&m_l(j)>thr0             % ������ֵ������ֵ֮��
                  QRS_buf1=[QRS_buf1 (j-wd)];
                  AMP_buf1=[AMP_buf1 m_l(j)];
                  en=0;
              else
                if m_l(j)>thr0                 % ������ֵ������ֵ֮��
                  dist_m=mean(diff(QRS_buf1));
                  dist=j-wd-QRS_buf1(N1);
                  if dist>0.24*fs && dist>0.5*dist_m  % ��Ӧ�ڼ�⣬���ң�����Ҫ�����㹻Զ��> ƽ�������һ�룩
                     QRS_buf1=[QRS_buf1 (j-wd)];
                     AMP_buf1=[AMP_buf1 m_l(j)];
                     en=0;
                  else
                      if m_l(j)>AMP_buf1(end)
                         QRS_buf1(end)=j-wd;
                         AMP_buf1(end)=m_l(j);
                         en=0;
                      end 
                  end
                else
                    en=-1;
                end
              end
           end
           N2=size(AMP_buf1,2);
           if N2>8
               AMP_buf1=AMP_buf1(2:9); % ȷ��ֻ�洢�����8���������壻
           end
		   % �����if�벩���еĹ�ʽ��Ӧ
           if en==1
              thr1=0.7*mean(AMP_buf1);
              thr0=0.25*mean(AMP_buf1);
           else
               if en==0
                   thr1=thr1-(abs(m_l(j)-mean(AMP_buf1)))/2;
                   thr0=0.4*m_l(j);
               end
           end
       end
       if thr1<=thr_lim1   % ȷ����ֵ��������
           thr1=thr_lim1;
       end
       
       if thr0<=thr_lim0
           thr0=thr_lim0;
       end
       
      thr1_buf=[thr1_buf thr1]; 
      thr0_buf=[thr0_buf thr0];
end
delay=round(l1/2)-2*w+2;
QRS_ind=QRS_buf1-delay;   % ��ȥ�ӳ٣��õ����ս����
QRS_amp=s(QRS_ind);
toc
if gr==1    %��ͼ
   figure();
   set(gcf,'unit','normalized','position',[0.2,0.2,0.64,0.32]);
   subplot(2,1,1);plot(m);axis([1 size(m,2) -0.3 1.6*max(m)]);
   hold on;title('Feature signal and thresholds');grid on;
   plot(QRS_buf1,m(QRS_buf1),'ro');
   plot(thr1_buf,'r');
   plot(thr0_buf,'k');
   legend('Feature Signal','QRS Locations','Threshold1','Threshold0');
   subplot(2,1,2);plot(s);%axis([1 size(s,2) min(s) 1.5*max(s)]);
   xlabel('n');ylabel('Voltage / mV');
   hold on;title('The result on the raw ECG');grid on;
   plot(QRS_ind,QRS_amp,'ro');
   legend('Raw ECG','QRS Locations');
end
end
