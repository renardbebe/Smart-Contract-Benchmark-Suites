 

pragma solidity ^0.4.11;

contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address newOwner=0x0;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Controlled is Owned{

    function Controlled() {
       setExclude(msg.sender);
    }

     
    bool public transferEnabled = false;

     
    bool lockFlag=true;
    mapping(address => bool) locked;
    mapping(address => bool) exclude;

    function enableTransfer(bool _enable) 
    public onlyOwner{
        transferEnabled=_enable;
    }
    function disableLock(bool _enable)
    onlyOwner
    returns (bool success){
        lockFlag=_enable;
        return true;
    }
    function addLock(address _addr) 
    onlyOwner 
    returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        return true;
    }

    function setExclude(address _addr) 
    onlyOwner 
    returns (bool success){
        exclude[_addr]=true;
        return true;
    }
    function removeLock(address _addr)
    onlyOwner
    returns (bool success){
        locked[_addr]=false;
        return true;
    }

    modifier transferAllowed {
        if (!exclude[msg.sender]) {
            assert(transferEnabled);
            if(lockFlag){
                assert(!locked[msg.sender]);
            }
        }
        
        _;
    }
  
}

 

contract StandardToken is Token,Controlled {

    function transfer(address _to, uint256 _value) transferAllowed returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) transferAllowed returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HumanStandardToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken() {
        totalSupply = 400000000 * (10 ** 18); 
        balances[msg.sender] = totalSupply;                
        name = "OneRoot Network Token";                                    
        decimals = 18;                             
        symbol = "RNT";                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}