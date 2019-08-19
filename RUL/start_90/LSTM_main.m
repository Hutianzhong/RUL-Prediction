function pre_data = LSTM_main(d,h,train_data,test_data)
%% Ԥ����
lag = 8;
%d = 31;
[train_input,train_output] = LSTM_data_process(d,train_data,lag); %���ݴ���

[train_input,min_input,max_input,train_output,min_output,max_output] = premnmx(train_input',train_output');

input_length = size(train_input,1); %�������볤��
output_length = size(train_output,1); %�����������
train_num = size(train_input,2); %ѵ����������
test_num = size(test_data,2); %������������
%% ���������ʼ��
% ���������
input_num = input_length;
cell_num = 10;
output_num = output_length;
% �������ŵ�ƫ��
bias_input_gate = rand(1,cell_num);
bias_forget_gate = rand(1,cell_num);
bias_output_gate = rand(1,cell_num);
%����Ȩ�س�ʼ��
ab = 20;
weight_input_x = rand(input_num,cell_num)/ab;  
weight_input_h = rand(output_num,cell_num)/ab;  
weight_inputgate_x = rand(input_num,cell_num)/ab;  
weight_inputgate_h = rand(cell_num,cell_num)/ab;  
weight_forgetgate_x = rand(input_num,cell_num)/ab;  
weight_forgetgate_h = rand(cell_num,cell_num)/ab;  
weight_outputgate_x = rand(input_num,cell_num)/ab;  
weight_outputgate_h = rand(cell_num,cell_num)/ab;  
%hidden_outputȨ��
weight_preh_h = rand(cell_num,output_num);
%����״̬��ʼ��
cost_gate = 1e-6;
h_state = rand(output_num,train_num+test_num);
cell_state = rand(cell_num,train_num+test_num);
%% ����ѵ��ѧϰ
for iter = 1:3000 %��������
    yita = 0.01;  %ÿ�ε���Ȩ�ص�������
    for m = 1:train_num
    
        %ǰ������
        if(m==1)
            gate = tanh(train_input(:,m)' * weight_input_x);
            input_gate_input = train_input(:,m)' * weight_inputgate_x + bias_input_gate;
            output_gate_input = train_input(:,m)' * weight_outputgate_x + bias_output_gate;
            for n = 1:cell_num
                input_gate(1,n) = 1 / (1 + exp(-input_gate_input(1,n)));%������
                output_gate(1,n) = 1 / (1 + exp(-output_gate_input(1,n)));%�����
                %sigmoid����
            end
            forget_gate = zeros(1,cell_num);
            forget_gate_input = zeros(1,cell_num);
            cell_state(:,m) = (input_gate .* gate)';
            
        else
            gate = tanh(train_input(:,m)' * weight_input_x + h_state(:,m-1)' * weight_input_h);
            input_gate_input = train_input(:,m)' * weight_inputgate_x + cell_state(:,m-1)' * weight_inputgate_h + bias_input_gate;
            forget_gate_input = train_input(:,m)' * weight_forgetgate_x + cell_state(:,m-1)' * weight_forgetgate_h + bias_forget_gate;
            output_gate_input = train_input(:,m)' * weight_outputgate_x + cell_state(:,m-1)' * weight_outputgate_h + bias_output_gate;
            for n = 1:cell_num
                input_gate(1,n) = 1/(1+exp(-input_gate_input(1,n)));
                forget_gate(1,n) = 1/(1+exp(-forget_gate_input(1,n)));
                output_gate(1,n) = 1/(1+exp(-output_gate_input(1,n)));
            end
            cell_state(:,m) = (input_gate .* gate + cell_state(:,m-1)' .* forget_gate)';   
        end
  
        pre_h_state = tanh(cell_state(:,m)') .* output_gate;
        h_state(:,m) = (pre_h_state * weight_preh_h)';
        %������
        Error = h_state(:,m) - train_output(:,m);
        Error_Cost(1,iter)=sum(Error.^2);  %����ƽ���ͣ�4�����ƽ���ͣ�
        if(Error_Cost(1,iter)<cost_gate)   %�ж��Ƿ����������С����
            flag = 1;
            break;
        else     
            [  weight_input_x,...
               weight_input_h,...
               weight_inputgate_x,...
               weight_inputgate_h,...
               weight_forgetgate_x,...
               weight_forgetgate_h,...
               weight_outputgate_x,...
               weight_outputgate_h,...
               weight_preh_h ] = LSTM_updata_weight(m,yita,Error,...
                                                   weight_input_x,...
                                                   weight_input_h,...
                                                   weight_inputgate_x,...
                                                   weight_inputgate_h,...
                                                   weight_forgetgate_x,...
                                                   weight_forgetgate_h,...
                                                   weight_outputgate_x,...
                                                   weight_outputgate_h,...
                                                   weight_preh_h,...
                                                   cell_state,h_state,...
                                                   input_gate,forget_gate,...
                                                   output_gate,gate,...
                                                   train_input,pre_h_state,...
                                                   input_gate_input,...
                                                   output_gate_input,...
                                                   forget_gate_input,input_num,cell_num);
       
        end
    end
    if(Error_Cost(1,iter)<cost_gate)
        break;
    end
end
% ����Error-Cost����ͼ
% figure
% for n=1:1:iter
%     semilogy(n,Error_Cost(1,n),'*');
%     hold on;
%     title('Error-Cost����ͼ');   
% end
%% ���Խ׶�
%���ݼ���
test_input = train_data(end-lag+1:end);
test_input = tramnmx(test_input',min_input,max_input);
% test_input = mapminmax('apply',test_input',ps_input);

%ǰ��
for m = train_num + 1:train_num + test_num
    gate = tanh(test_input' * weight_input_x + h_state(:,m-1)' * weight_input_h);
    input_gate_input = test_input' * weight_inputgate_x + h_state(:,m-1)' * weight_inputgate_h + bias_input_gate;
    forget_gate_input = test_input' * weight_forgetgate_x + h_state(:,m-1)' * weight_forgetgate_h + bias_forget_gate;
    output_gate_input = test_input' * weight_outputgate_x + h_state(:,m-1)' * weight_outputgate_h + bias_output_gate;
    for n = 1:cell_num
        input_gate(1,n) = 1/(1+exp(-input_gate_input(1,n)));
        forget_gate(1,n) = 1/(1+exp(-forget_gate_input(1,n)));
        output_gate(1,n) = 1/(1+exp(-output_gate_input(1,n)));  
    end
    cell_state(:,m) = (input_gate .* gate + cell_state(:,m-1)' .* forget_gate)';  
    pre_h_state = tanh(cell_state(:,m)') .* output_gate;
    h_state(:,m) = (pre_h_state * weight_preh_h)';
    
    % ����ǰԤ�����Ϊ��һ����������
    test_input = postmnmx(test_input,min_input,max_input);
    now_prepoint = postmnmx(h_state(:,m),min_output,max_output);
    %test_input = mapminmax('reverse',test_input,ps_input);
    test_input = [test_input(2:end); now_prepoint];
    test_input = tramnmx(test_input,min_input,max_input);
end

pre_data = postmnmx(h_state(:,train_num + h:h:train_num + test_num),min_output,max_output);

all_pre = postmnmx(h_state(:,1:h:train_num + test_num),min_output,max_output);

% ��ͼ
figure
title('LSTMԤ��')
hold on
plot(1:size([train_data test_data],2),[train_data test_data], 'o-', 'color','r', 'linewidth', 1);
plot(size(train_data,2) + h:h:size([train_data test_data],2),pre_data, '*-','color','b','linewidth', 1);
plot([size(train_data,2) size(train_data,2)],[-0.01 0.01],'g-','LineWidth',4);
legend({ '��ʵֵ', 'Ԥ��ֵ'});
end
