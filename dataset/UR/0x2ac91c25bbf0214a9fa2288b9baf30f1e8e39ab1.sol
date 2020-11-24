 

pragma solidity ^0.4.15;

contract InputValidator {

     
    modifier safe_arguments(uint _numArgs) {
        assert(msg.data.length == _numArgs * 32 + 4);
        _;
    }
}

contract Owned {

     
    address internal owner;


     
    function Owned() {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner);

        _;
    }
}

contract IOwnership {

     
    function isOwner(address _account) constant returns (bool);


     
    function getOwner() constant returns (address);
}

contract Ownership is IOwnership, Owned {


     
    function isOwner(address _account) public constant returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public constant returns (address) {
        return owner;
    }
}

contract ITransferableOwnership {

     
    function transferOwnership(address _newOwner);
}

contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
contract IToken { 

     
    function totalSupply() constant returns (uint);


     
    function balanceOf(address _owner) constant returns (uint);


     
    function transfer(address _to, uint _value) returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) returns (bool);


     
    function approve(address _spender, uint _value) returns (bool);


     
    function allowance(address _owner, address _spender) constant returns (uint);
}


 
contract Token is IToken, InputValidator {

     
    string public standard = "Token 0.3";
    string public name;        
    string public symbol;
    uint8 public decimals = 8;

     
    uint internal totalTokenSupply;

     
    mapping (address => uint) internal balances;

     
    mapping (address => mapping (address => uint)) internal allowed;


     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     
    function Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = 0;
        totalTokenSupply = 0;
    }


     
    function totalSupply() public constant returns (uint) {
        return totalTokenSupply;
    }


     
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint _value) public safe_arguments(2) returns (bool) {

         
        require(balances[msg.sender] >= _value);   

         
        require(balances[_to] + _value >= balances[_to]);

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint _value) public safe_arguments(3) returns (bool) {

         
        require(balances[_from] >= _value);

         
        require(balances[_to] + _value >= balances[_to]);

         
        require(_value <= allowed[_from][msg.sender]);

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint _value) public safe_arguments(2) returns (bool) {

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) public constant returns (uint) {
      return allowed[_owner][_spender];
    }
}


 
contract IManagedToken is IToken { 

     
    function isLocked() constant returns (bool);


     
    function unlock() returns (bool);


     
    function issue(address _to, uint _value) returns (bool);
}


 
contract ManagedToken is IManagedToken, Token, TransferableOwnership {

     
    bool internal locked;


     
    modifier only_when_unlocked() {
        require(!locked);

        _;
    }


     
    function ManagedToken(string _name, string _symbol, bool _locked) Token(_name, _symbol) {
        locked = _locked;
    }


     
    function transfer(address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


     
    function approve(address _spender, uint _value) public returns (bool) {
        return super.approve(_spender, _value);
    }


     
    function isLocked() public constant returns (bool) {
        return locked;
    }


     
    function unlock() public only_owner returns (bool)  {
        locked = false;
        return !locked;
    }


     
    function issue(address _to, uint _value) public only_owner safe_arguments(2) returns (bool) {
        
         
        require(balances[_to] + _value >= balances[_to]);

         
        balances[_to] += _value;
        totalTokenSupply += _value;

         
        Transfer(0, this, _value);
        Transfer(this, _to, _value);

        return true;
    }
}


 
contract ITokenRetreiver {

     
    function retreiveTokens(address _tokenContract);
}

 
contract NUToken is ManagedToken, ITokenRetreiver {


     
    function NUToken() ManagedToken("Network Units Token", "NU", true) {}


     
    function retreiveTokens(address _tokenContract) public only_owner {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(owner, tokenBalance);
        }
    }


     
    function () payable {
        revert();
    }
}