function output = softmax(input)
expsum=sum(exp(input));
output=exp(input)/expsum;

end

