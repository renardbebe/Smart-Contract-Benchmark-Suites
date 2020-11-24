 

pragma solidity ^0.4.8;

contract IERC20Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract IToken {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transferViaProxy(address _from, address _to, uint _value) returns (uint error) {}
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (uint error) {}
    function approveFromProxy(address _source, address _spender, uint256 _value) returns (uint error) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {} 
    function issueNewCoins(address _destination, uint _amount, string _details) returns (uint error){}
    function destroyOldCoins(address _destination, uint _amount, string _details) returns (uint error) {}
}

contract ProxyContract is IERC20Token {


    address public dev;
    address public curator;
    address public proxyManagementAddress;
    
    bool public proxyWorking;

    string public standard = 'Neter proxy';
    string public name = 'Neter';
    string public symbol = 'NTR';
    uint8 public decimals = 8;

    IToken tokenContract;


    function ProxyContract(){ 
        dev = msg.sender;
    }

    function totalSupply() constant returns (uint256 supply) {
        return tokenContract.totalSupply();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return tokenContract.balanceOf(_owner);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (!proxyWorking) { return false;}
        
        uint error =  tokenContract.transferViaProxy(msg.sender, _to, _value);
        
        if(error == 0){
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (!proxyWorking) { return false;}
        
        uint error =  tokenContract.transferFromViaProxy(msg.sender, _from, _to, _value);
        
        if(error == 0){
            Transfer(_from, _to, _value);
            return true;
        }else{
            return false;
        }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (!proxyWorking) { return false;}
        
        uint error =  tokenContract.approveFromProxy(msg.sender, _spender, _value);
        
        if(error == 0){
            Approval(msg.sender, _spender, _value);
            return true;
        }else{
            return false;
        }
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return tokenContract.allowance(_owner, _spender);
    } 
    
    function setTokenContract(address _tokenAddress) returns (uint error){
        if (msg.sender != curator) { return 1;}
        
        tokenContract = IToken(_tokenAddress);
        return 0;
    }
    
    function setProxyManagementAddress(address _proxyManagementAddress) returns (uint error){ 
        if (msg.sender != curator) { return 1;}
        
        proxyManagementAddress = _proxyManagementAddress;
        return 0;
    }

    function EnableDisableTokenProxy() returns (uint error){
        if (msg.sender != curator) { return 1; }       
        
        proxyWorking = !proxyWorking;
        return 0;

    }
    
    function setProxyCurator(address _curatorAddress) returns (uint error){
        if( msg.sender != dev) {return 1;}
     
        curator = _curatorAddress;
        return 0;
    }

    function killContract() returns (uint error){
        if (msg.sender != dev) { return 1; }
        
        selfdestruct(dev);
        return 0;
    }

    function tokenAddress() constant returns (address contractAddress){
        return address(tokenContract);
    }

    function raiseTransferEvent(address _from, address _to, uint256 _value) returns (uint error){
        if(msg.sender != proxyManagementAddress) { return 1; }

        Transfer(_from, _to, _value);
        return 0;
    }

    function raiseApprovalEvent(address _owner, address _spender, uint256 _value) returns (uint error){
        if(msg.sender != proxyManagementAddress) { return 1; }

        Approval(_owner, _spender, _value);
        return 0;
    }

    function () {
        throw;     
    }
}