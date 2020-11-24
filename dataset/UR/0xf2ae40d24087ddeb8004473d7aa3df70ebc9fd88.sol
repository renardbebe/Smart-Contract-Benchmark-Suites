 

pragma solidity ^0.4.23;

contract SafeMath {
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract ERC20TokenInterface {
  function totalSupply() public constant returns (uint256 _totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token is ERC20TokenInterface, SafeMath, Owned {

     
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;

    address public beerContract;

     
    uint256 supply = 0;
    uint256 burnt = 0;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    event Mint(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint _value);

     
    function totalSupply() constant public returns (uint256) {
        return supply;
    }

     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);   
        balances[_to] = safeAdd(balanceOf(_to), _value);                 
        emit Transfer(msg.sender, _to, _value);                               
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;         
        emit Approval(msg.sender, _spender, _value);            
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipientInterface spender = TokenRecipientInterface(_spender);     
        approve(_spender, _value);                                               
        spender.receiveApproval(msg.sender, _value, this, _extraData);           
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[_from] = safeSub(balanceOf(_from), _value);                             
        balances[_to] = safeAdd(balanceOf(_to), _value);                                 
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);  
        emit Transfer(_from, _to, _value);                                                    
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == beerContract);
        supply = safeAdd(supply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
    }

    function burn(address _burnee, uint _amount) public {
        require(msg.sender == beerContract);
        balances[_burnee] = safeSub(balanceOf(_burnee), _amount);
        supply = safeSub(supply, _amount);
        burnt = safeAdd(burnt, _amount);
        emit Burn(_burnee, _amount);
        emit Transfer(_burnee, 0x0, _amount);
    }
    
    function setbeerContract(address _beerContract) onlyOwner public {
        beerContract = _beerContract;
    }
    
    function getBurnAmount() public view returns(uint256 burnAmount){
      return burnt;
    }

    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }
}

contract MihCoinToken is ERC20Token {

   
  constructor() public{ 
    standard = "MihCoin token v1.0";
    name = "MHCToken";
    symbol = "MHC";
    decimals = 18;
     
    beerContract = 0x0;  
  }
}