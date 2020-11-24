 

pragma solidity ^0.4.10;

 
contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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

contract CryptiblesVendingContract is StandardToken, SafeMath {

     
    bool public isOpen;
    uint256 ethDivisor = 1000000000000000000;
    string version = "1.0";

     
    address public owner;
    uint256 public totalSupply;

     
    address public ethFundDeposit;       

     
    uint256 public tokenExchangeRate = 1000000000000000000;
    StandardToken cryptiToken;

    address public currentTokenOffered = 0x16b262b66E300C7410f0771eAC29246A75fb8c48;

     
    event TransferCryptibles(address indexed _to, uint256 _value);
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function CryptiblesVendingContract()
    {
      isOpen = true;
      totalSupply = 0;
      owner = msg.sender;
      cryptiToken =  StandardToken(currentTokenOffered);
    }
    
     
    function () payable {
      require(isOpen);
      require(msg.value != 0);
      
      require(cryptiToken.balanceOf(this) >= tokens);
      
      uint256 amountSent = msg.value;
      uint256 tokens = safeMult(amountSent, tokenExchangeRate) / ethDivisor;  
      totalSupply = safeAdd(totalSupply, tokens);
      cryptiToken.transfer(msg.sender, tokens);
      
      TransferCryptibles(msg.sender, tokens);   
    }

     
    function finalize() onlyOwner{
      isOpen = false;
      ethFundDeposit.transfer(this.balance);   
    }

     
    function changeTokenExchangeRate(uint256 _tokenExchangeRate) onlyOwner{
        tokenExchangeRate = _tokenExchangeRate;
    }

    function setETHAddress(address _ethAddr) onlyOwner{
      ethFundDeposit = _ethAddr;
    }
    
    function getRemainingTokens(address _sendTokensTo) onlyOwner{
        require(_sendTokensTo != address(this));
        var tokensLeft = cryptiToken.balanceOf(this);
        cryptiToken.transfer(_sendTokensTo, tokensLeft);
    }

    function changeIsOpenFlag(bool _value) onlyOwner{
      isOpen = _value;
    }

    function changeCrytiblesAddress(address _newAddr) onlyOwner{
      currentTokenOffered = _newAddr;
      cryptiToken =  StandardToken(currentTokenOffered);
    }
}