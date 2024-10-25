function [R,G,B,rgb]=hsl2rgb(img_hsl)
hsl=img_hsl;
H=hsl(:,:,1);
S=hsl(:,:,2);
L=hsl(:,:,3);
[m,n]=size(H);
R=zeros(m,n);
G=zeros(m,n);
B=zeros(m,n);
%%  求 R  %%
for i=1:m
    for j=1:n
        if S(i,j)==0
            R(i,j)=L(i,j);
        else if L(i,j)<0.5
                temp2=L(i,j)*(1.0+S(i,j));
            else
                temp2=L(i,j)+S(i,j)-L(i,j)*S(i,j);
            end
        end
        temp1=2*L(i,j)-temp2;
        h=H(i,j)/360;
        temp3=h+1/3;
        if temp3<0
            temp3=temp+1;
        end
        if temp3>1
            temp3=temp3-1;
        end
        if 6*temp3<1
            R(i,j)=temp1+(temp2-temp1)*6*temp3;
        else if  2*temp3<1
                R(i,j)=temp2;
            else if 3*temp3<2
                    R(i,j)=temp1+(temp2-temp1)*(2/3-temp3)*6;
                else
                    R(i,j)=temp1;
                end
            end
        end
    end
end
%% 求 G  %%
for i=1:m
    for j=1:n
        if S(i,j)==0
            G(i,j)=L(i,j);
        else if L(i,j)<0.5
                temp2=L(i,j)*(1.0+S(i,j));
            else
                temp2=L(i,j)+S(i,j)-L(i,j)*S(i,j);
            end
        end
        temp1=2*L(i,j)-temp2;
        h=H(i,j)/360;
        temp3=h;
        if temp3<0
            temp3=temp+1;
        end
        if temp3>1
            temp3=temp3-1;
        end
        if 6*temp3<1
            G(i,j)=temp1+(temp2-temp1)*6*temp3;
        else if 2*temp3<1
                G(i,j)=temp2;
            else if 3*temp3<2
                    G(i,j)=temp1+(temp2-temp1)*(2/3-temp3)*6;
                else
                    G(i,j)=temp1;
                end
            end
        end
    end
end
%%  求 B  %%
for i=1:m
    for j=1:n
        if S(i,j)==0
            B(i,j)=L(i,j);
        else if L(i,j)<0.5
                temp2=L(i,j)*(1.0+S(i,j));
            else
                temp2=L(i,j)+S(i,j)-L(i,j)*S(i,j);
            end
        end
        temp1=2*L(i,j)-temp2;
        h=H(i,j)/360;
        temp3=h-1/3;
        if temp3<0
            temp3=temp3+1;
        end
        if temp3>1
            temp3=temp3-1;
        end
        if 6*temp3<1
            B(i,j)=temp1+(temp2-temp1)*6*temp3;
        else if 2*temp3<1
                B(i,j)=temp2;
            else if 3*temp3<2
                    B(i,j)=temp1+(temp2-temp1)*(2/3-temp3)*6;
                else
                    B(i,j)=temp1;
                end
            end
        end
    end
end
rgb=cat(3,R,G,B);