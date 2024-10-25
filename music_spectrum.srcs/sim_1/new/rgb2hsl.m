function [H,S,L,hsl]=rgb2hsl(img)

rgb=im2double(img);

r=rgb(:,:,1);

g=rgb(:,:,2);

b=rgb(:,:,3);

[m,n]=size(r);

%%  求 L  %%

maxcolor=max(max(r,g),b);

mincolor=min(min(r,g),b);

L=(maxcolor+mincolor)/2;

H=zeros(m,n);

S=zeros(m,n);

%%  求 S  %%

for i=1:m
    
    for j=1:n
        
        if maxcolor(i,j)==mincolor(i,j)
            
            S(i,j)=0;
            
        else
            
            if L(i,j)<=0.5
                
                S(i,j)=(maxcolor(i,j)-mincolor(i,j))/(2*L(i,j));
                
            else
                
                S(i,j)=(maxcolor(i,j)-mincolor(i,j))/(2-2*L(i,j));
                
            end
            
        end
        
    end
    
end

%%  求 H  %%

for i=1:m
    
    for j=1:n
        
        if maxcolor(i,j)==mincolor(i,j)
            
            H(i,j)=0;
            
        else if r(i,j)==maxcolor(i,j)
                
                if g(i,j)>=b(i,j)
                    
                    H(i,j)=60*(g(i,j)-b(i,j))/(maxcolor(i,j)-mincolor(i,j));
                    
                else
                    
                    H(i,j)=60*(g(i,j)-b(i,j))/(maxcolor(i,j)-mincolor(i,j))+360;
                    
                end
                
            else if g(i,j)==maxcolor(i,j)
                    
                    H(i,j)=120+60*(b(i,j)-r(i,j))/(maxcolor(i,j)-mincolor(i,j));
                    
                else
                    
                    H(i,j)=240+60*(r(i,j)-g(i,j))/(maxcolor(i,j)-mincolor(i,j));
                    
                end
                
            end
            
        end
        
    end
    
end

hsl=cat(3,H,S,L);