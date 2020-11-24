 

 
 
pragma solidity ^0.4.23;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
library SafeMath {
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Owned {

     
     
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }
    
    address newOwner=0x0;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function changeOwner(address _newOwner) public isOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Controlled is Owned{

    constructor() public {
       setExclude(msg.sender);
    }

     
    bool public transferEnabled = false;

     
    bool public lockFlag=true;
    mapping(address => bool) public locked;
    mapping(address => bool) public exclude;

    function enableTransfer(bool _enable) public isOwner{
        transferEnabled=_enable;
    }

    function disableLock(bool _enable) public isOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }

    function addLock(address _addr) public isOwner returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        return true;
    }

    function setExclude(address _addr) public isOwner returns (bool success){
        exclude[_addr]=true;
        return true;
    }

    function removeLock(address _addr) public isOwner returns (bool success){
        locked[_addr]=false;
        return true;
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnabled);
            if(lockFlag){
                assert(!locked[_addr]);
            }
        }

        _;
    }
    modifier validAddress(address _addr) {
        assert(0x0 != _addr && 0x0 != msg.sender);
        _;
    }
}

contract StandardToken is Token,Controlled {

    function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) validAddress(_to) returns (bool success) {
         
         
         
        require(_value > 0);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(_from) validAddress(_to) returns (bool success) {
         
        require(_value > 0);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MTC is StandardToken {

    function () public {
        revert();
    }

    using SafeMath for uint256;
    string public name = "MTC Mesh Network";
    uint8 public decimals = 18;
    string public symbol = "MTC";


     
    mapping(address => uint256) nonces;

    constructor (uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
    
    function setName(string _name) isOwner public {
        name = _name;
    }
    
     
    function transferProxy(address _from, address _to, uint256 _value, uint256 _fee,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

        require(_value > 0);
        if(balances[_from] < _fee.add(_value)) revert();

        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value,_fee,nonce);
        if(_from != ecrecover(h,_v,_r,_s)) revert();

        if(balances[_to].add(_value) < balances[_to]
            || balances[msg.sender].add(_fee) < balances[msg.sender]) revert();
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        balances[msg.sender] += _fee;
        emit Transfer(_from, msg.sender, _fee);

        balances[_from] -= _value.add(_fee);
        nonces[_from] = nonce + 1;
        return true;
    }

     
    function approveProxy(address _from, address _spender, uint256 _value,
        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool success) {

        require(_value > 0);
        uint256 nonce = nonces[_from];
        bytes32 hash = keccak256(_from,_spender,_value,nonce);
        if(_from != ecrecover(hash,_v,_r,_s)) revert();
        allowed[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
        nonces[_from] = nonce + 1;
        return true;
    }


     
    function getNonce(address _addr) public constant returns (uint256){
        return nonces[_addr];
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }

     
    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
        if(!_spender.call(_extraData)) { revert(); }
        return true;
    }
     
     
     
    function allocateTokens(address[] _owners, uint256[] _values) public isOwner {
        if(_owners.length != _values.length) revert();
        for(uint256 i = 0; i < _owners.length ; i++){
            address to = _owners[i];
            uint256 value = _values[i];
            balances[owner] -= value;
            balances[to] += value;
        }
    }
}