function pre_data = DBN_main(h,train_data,test_data)

lag = 3;
d = 61;
train_input = [];
train_output = [];

for i = d:size(train_data,2)-lag-h+1 
    train_input = [train_input; i:i+lag-1]; 
    train_output = [train_output; train_data(i+lag+h-1)];
end

[train_input,min_input,max_input,train_output,min_output,max_output] = premnmx(train_input',train_output');
train_input = train_input';
train_output = train_output';

%% network setup
% �������10ά���ݣ�����Ϊ10�������DBN���������Լ�����
dbn.sizes = [35 25];
opts.numepochs =  100;
opts.batchsize =  size(train_input,1);
opts.momentum  =   0;
opts.alpha     =   0.01;
dbn = dbnsetup(dbn, train_input, opts);
dbn = dbntrain(dbn, train_input, opts);

%% unfold dbn to nn
% ��DBN����ת��ΪNN���磬�������Ϊ1����Ϊ���ά��Ϊ1
nn = dbnunfoldtonn(dbn, 1);
 
nn.activation_function = 'tanh_opt';    %  tanh_opt activation function
nn.output              = 'linear';      %  linear is usual choice for regression problems
nn.learningRate        = 0.001;         %  Linear output can be sensitive to learning rate
 
opts.numepochs = 100;   %  Number of full sweeps through data
opts.batchsize = size(train_input,1);   %  Take a mean gradient step over this many samples
[nn, L] = nntrain(nn, train_input, train_output, opts);
 
% nnoutput calculates the predicted regression values
test_input = [];
for i = size(train_data,2)+h:h:size(train_data,2)+size(test_data,2) 
    test_input = [test_input; i-h-lag+1:i-h]; 
end

test_input = tramnmx(test_input',min_input,max_input);
test_input = test_input';

pre_data = nnoutput(nn, test_input);%Ԥ����
pre_data = postmnmx(pre_data,min_output,max_output);

end

