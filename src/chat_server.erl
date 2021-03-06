%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 监听Socket连接，并群发消息到所有的client
%%% @end
%%% Created : 20. 八月 2018 20:23
%%%-------------------------------------------------------------------
-module(chat_server).
-author("Administrator").
-define(TCP_OPTIONS,[list,{packet,0},{active,false},{reuseaddr,true}]).
%% API
-export([start/1]).

start(ClientPort)->
    register(client_manager,spawn(fun()->manage_clients([])end)),
    {ok,LSocket}=gen_tcp:listen(ClientPort,?TCP_OPTIONS),
    do_accept(LSocket).


do_accept(LSocket)->
    {ok,Socket}=gen_tcp:accept(LSocket),
    spawn(fun()->handle_client(Socket)end),
%%    给客户端管理进程发送{connect,Socket}信息请求建立socket连接
    client_manager ! {connect,Socket},
    do_accept(LSocket).


handle_client(Socket)->
    case gen_tcp:recv(Socket, 0) of
%%        发送数据到客户端管理进程
        {ok,Data}->
            client_manager ! {data,Data},
            handle_client(Socket);
        {error,closed}->
            client_manager !{disconnect,Socket}
end.



manage_clients(Sockets)->

    receive
        {connect,Socket}->
            io:format("connect the socket~w~n",[Socket]),
            SocketList=[Socket|Sockets],
            manage_clients(SocketList);

        {disconnect,Socket}->
            SocketList=lists:delete(Socket,Sockets),
            manage_clients(SocketList);

        {data,Data}->
%%            将数据转发给所有连接客户端client
            send_data(Sockets,Data),
            SocketList=Sockets,
            manage_clients(SocketList)

    end.


send_data(Sockets,Data)->
    SendData=fun(Socket)->
        gen_tcp:send(Socket,Data)
             end,
    lists:foreach(SendData,Sockets).




