 

pragma solidity ^0.4.19;

 
contract ServerRegistry {

    uint internal constant unregisterDeposit = 100000;

    event LogServerRegistered(string url, uint props, address owner, uint deposit);
    event LogServerUnregisterRequested(string url, address owner, address caller);
    event LogServerUnregisterCanceled(string url, address owner);
    event LogServerConvicted(string url, address owner);
    event LogServerRemoved(string url, address owner);

    struct Web3Server {
        string url;   
        address owner;  
        uint deposit;  
        uint props;  

         
        uint unregisterTime;  
        address unregisterCaller;  
    }
    
    Web3Server[] public servers;

    function totalServers() public constant returns (uint)  {
        return servers.length;
    }

     
    function registerServer(string _url, uint _props) public payable {
         
        bytes32 hash = keccak256(_url);
        for (uint i=0;i<servers.length;i++) 
            require(keccak256(servers[i].url)!=hash && servers[i].owner!=msg.sender);

         
        Web3Server memory m;
        m.url = _url;
        m.props = _props;
        m.owner = msg.sender;
        m.deposit = msg.value;
        servers.push(m);
        emit LogServerRegistered(_url, _props, msg.sender,msg.value);
    }

     
     
     
     
     
     
     
     
     
    function requestUnregisteringServer(uint _serverIndex) payable public {
        Web3Server storage server = servers[_serverIndex];
         
        require(server.unregisterCaller==address(0x0));

        if (server.unregisterCaller == server.owner) 
           server.unregisterTime = now + 1 hours;
        else {
            server.unregisterTime = now + 28 days;  
             
            require(msg.value==unregisterDeposit);
        }
        server.unregisterCaller = msg.sender;
        emit LogServerUnregisterRequested(server.url, server.owner, msg.sender );
    }
    
    function confirmUnregisteringServer(uint _serverIndex) public {
        Web3Server storage server = servers[_serverIndex];
         
        require(server.unregisterCaller!=address(0x0) && server.unregisterTime < now);

        uint payBackOwner = server.deposit;
        if (server.unregisterCaller != server.owner) {
            payBackOwner -= server.deposit/5;   
            server.unregisterCaller.transfer( unregisterDeposit + server.deposit - payBackOwner );
        }

        if (payBackOwner>0)
            server.owner.transfer( payBackOwner );

        removeServer(_serverIndex);
    }

    function cancelUnregisteringServer(uint _serverIndex) public {
        Web3Server storage server = servers[_serverIndex];

         
        require(server.unregisterCaller!=address(0) &&  server.owner == msg.sender);

         
         
        if (server.unregisterCaller != server.owner) 
            server.owner.transfer( unregisterDeposit );

        server.unregisterCaller = address(0);
        server.unregisterTime = 0;
        
        emit LogServerUnregisterCanceled(server.url, server.owner);
    }


    function convict(uint _serverIndex, bytes32 _blockhash, uint _blocknumber, uint8 _v, bytes32 _r, bytes32 _s) public {
         
        require(blockhash(_blocknumber) != _blockhash);

         
        require(ecrecover(keccak256(_blockhash, _blocknumber), _v, _r, _s) == servers[_serverIndex].owner);

         
        if (servers[_serverIndex].deposit>0) {
            uint payout = servers[_serverIndex].deposit/2;
             
            msg.sender.transfer(payout);

             
            address(0).transfer(servers[_serverIndex].deposit-payout);
        }

        emit LogServerConvicted(servers[_serverIndex].url, servers[_serverIndex].owner );
        removeServer(_serverIndex);

    }
    
     
    
    function removeServer(uint _serverIndex) internal {
        emit LogServerRemoved(servers[_serverIndex].url, servers[_serverIndex].owner );
        uint length = servers.length;
        Web3Server memory m = servers[length - 1];
        servers[_serverIndex] = m;
        servers.length--;
    }
}