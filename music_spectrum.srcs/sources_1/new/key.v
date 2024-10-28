module key(
    input                        clk                      ,
    input                        rst_n                    ,
    input                        Key                      ,
    output reg                   Key_P                    ,
    output reg                   Key_R                    );
    
    parameter                    CNT                     = 2_000_000-1;
    reg                          dff0_Key                 ;
    reg                          dff1_Key                 ;
    reg                [  24: 0] timer_cnt                ;
    reg                [   1: 0] State                    ;
    wire                         Key_P_w                  ;
    wire                         Key_R_w                  ;
    
    assign  Key_P_w = State[1] == 1'd1&&State[0] == 0&&timer_cnt == 0;
    assign  Key_R_w = State[1] == 0&&State[0] == 1'd1&&timer_cnt == 0;

    always @(posedge clk)
    begin
        Key_P <= Key_P_w;
    end
    
    always @(posedge clk)
    begin
        Key_R <= Key_R_w;
    end
    
    always @(posedge clk)
    begin
        dff0_Key <= Key;
    end
    
    always @(posedge clk)
    begin
        dff1_Key <= dff0_Key;
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)begin
            timer_cnt <= 0;
        end
        else if (timer_cnt == CNT)begin
            timer_cnt <= 0;
        end
        else  begin
            timer_cnt <= timer_cnt+1'd1;
        end
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)begin
            State[0]  <= 1'b1;
        end
        else if (timer_cnt == CNT) begin
            State[0] <= dff1_Key;
        end
        else begin
        end
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)begin
            State[1]  <= 1'b1;
        end
        else if (timer_cnt == CNT) begin
            State[1] <= State[0];
        end
        else begin
        end
    end
    
endmodule
