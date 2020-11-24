 

 

pragma solidity ^0.4.25;

 
contract ServerRegistry {

     
    event LogServerRegistered(string url, uint props, address owner, uint deposit);

     
    event LogServerUnregisterRequested(string url, address owner, address caller);

     
    event LogServerUnregisterCanceled(string url, address owner);

     
    event LogServerConvicted(string url, address owner);

     
    event LogServerRemoved(string url, address owner);

    struct In3Server {
        string url;   
        address owner;  
        uint deposit;  
        uint props;  

         
        uint128 unregisterTime;  
        uint128 unregisterDeposit;  
        address unregisterCaller;  
    }

     
    In3Server[] public servers;

     
    mapping (address => bool) ownerIndex;
    mapping (bytes32 => bool) urlIndex;
    
     
    function totalServers() public view returns (uint)  {
        return servers.length;
    }

     
    function registerServer(string _url, uint _props) public payable {
        checkLimits();

        bytes32 urlHash = keccak256(bytes(_url));

         
        require (!urlIndex[urlHash] && !ownerIndex[msg.sender], "a Server with the same url or owner is already registered");

         
        In3Server memory m;
        m.url = _url;
        m.props = _props;
        m.owner = msg.sender;
        m.deposit = msg.value;
        servers.push(m);

         
        urlIndex[urlHash] = true;
        ownerIndex[msg.sender] = true;

         
        emit LogServerRegistered(_url, _props, msg.sender,msg.value);
    }

     
    function updateServer(uint _serverIndex, uint _props) public payable {
        checkLimits();

        In3Server storage server = servers[_serverIndex];
        require(server.owner == msg.sender, "only the owner may update the server");

        if (msg.value>0) 
          server.deposit += msg.value;

        if (_props!=server.props)
          server.props = _props;
        emit LogServerRegistered(server.url, _props, msg.sender,server.deposit);
    }

     
     
     
     
     
     
     
     
     
    function requestUnregisteringServer(uint _serverIndex) payable public {

        In3Server storage server = servers[_serverIndex];

         
        require(server.unregisterCaller == address(0x0), "Server is already unregistering");

        if (server.unregisterCaller == server.owner) 
           server.unregisterTime = uint128(now + 1 hours);
        else {
            server.unregisterTime = uint128(now + 28 days);  
             
            require(msg.value == calcUnregisterDeposit(_serverIndex), "the exact calcUnregisterDeposit is required to request unregister");
            server.unregisterDeposit = uint128(msg.value);
        }
        server.unregisterCaller = msg.sender;
        emit LogServerUnregisterRequested(server.url, server.owner, msg.sender);
    }
    
     
     
     
    function confirmUnregisteringServer(uint _serverIndex) public {
        In3Server storage server = servers[_serverIndex];
         
        require(server.unregisterCaller != address(0x0) && server.unregisterTime < now, "Only the caller is allowed to confirm");

        uint payBackOwner = server.deposit;
        if (server.unregisterCaller != server.owner) {
            payBackOwner -= server.deposit / 5;   
            server.unregisterCaller.transfer(server.unregisterDeposit + server.deposit - payBackOwner);
        }

        if (payBackOwner > 0)
            server.owner.transfer(payBackOwner);

        removeServer(_serverIndex);
    }

     
     
    function cancelUnregisteringServer(uint _serverIndex) public {
        In3Server storage server = servers[_serverIndex];

         
        require(server.unregisterCaller != address(0) && server.owner == msg.sender, "only the owner is allowed to cancel unregister");

         
         
        if (server.unregisterCaller != server.owner) 
            server.owner.transfer(server.unregisterDeposit);

         
        server.unregisterCaller = address(0);
        server.unregisterTime = 0;
        server.unregisterDeposit = 0;

         
        emit LogServerUnregisterCanceled(server.url, server.owner);
    }


     
    function convict(uint _serverIndex, bytes32 _blockhash, uint _blocknumber, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 evm_blockhash = blockhash(_blocknumber);
        
         
        require(evm_blockhash != 0x0 && evm_blockhash != _blockhash, "the block is too old or you try to convict with a correct hash");

         
        require(
            ecrecover(keccak256(_blockhash, _blocknumber), _v, _r, _s) == servers[_serverIndex].owner, 
            "the block was not signed by the owner of the server");

         
        if (servers[_serverIndex].deposit > 0) {
            uint payout = servers[_serverIndex].deposit / 2;
             
            msg.sender.transfer(payout);

             
             
             
            address(0).transfer(servers[_serverIndex].deposit-payout);
        }

         
        emit LogServerConvicted(servers[_serverIndex].url, servers[_serverIndex].owner );
        
        removeServer(_serverIndex);
    }

     
    function calcUnregisterDeposit(uint _serverIndex) public view returns(uint128) {
          
        return uint128(servers[_serverIndex].deposit / 50 + tx.gasprice * 50000);
    }

     
    
    function removeServer(uint _serverIndex) internal {
         
        emit LogServerRemoved(servers[_serverIndex].url, servers[_serverIndex].owner);

         
        urlIndex[keccak256(bytes(servers[_serverIndex].url))] = false;
        ownerIndex[servers[_serverIndex].owner] = false;

        uint length = servers.length;
        if (length>0) {
             
            In3Server memory m = servers[length - 1];
            servers[_serverIndex] = m;
        }
        servers.length--;
    }

    function checkLimits() internal view {
         
        if (now < 1560808800)
           require(address(this).balance < 50 ether, "Limit of 50 ETH reached");
    }

}