 

pragma solidity ^0.4.10;

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.11;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier stopInEmergency {
    if (paused) {
      throw;
    }
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

pragma solidity ^0.4.8;


contract Sales{

	enum ICOSaleState{
		PrivateSale,
	    PreSale,
	    PublicSale,
	    Success,
	    Failed
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


 
contract GACToken is Token,Ownable,Sales {
    string public constant name = "Gladage Care Token";
    string public constant symbol = "GAC";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    uint public valueToBeSent = 1;

    bool public finalizedICO = false;

    uint256 public ethraised;
    uint256 public btcraised;
    uint256 public usdraised;

    bool public istransferAllowed;

    uint256 public constant GACFund = 5 * (10**8) * 10**decimals; 
    uint256 public fundingStartBlock;  
    uint256 public fundingEndBlock;  
    uint256 public tokenCreationMax= 275 * (10**6) * 10**decimals; 
    mapping (address => bool) ownership;
    uint256 public minCapUSD = 2000000;
    uint256 public maxCapUSD = 20000000;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function burnTokens(uint256 _value) public{
        require(balances[msg.sender]>=_value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender],_value);
        totalSupply =SafeMath.sub(totalSupply,_value);
    }


     
    function GACToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        totalSupply = GACFund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }

     
    function changeEndBlock(uint256 _newFundingEndBlock) onlyOwner{
        fundingEndBlock = _newFundingEndBlock;
    }

     
    function changeStartBlock(uint256 _newFundingStartBlock) onlyOwner{
        fundingStartBlock = _newFundingStartBlock;
    }

     
     
    function changeMinCapUSD(uint256 _newMinCap) onlyOwner{
        minCapUSD = _newMinCap;
    }

     
    function changeMaxCapUSD(uint256 _newMaxCap) onlyOwner{
        maxCapUSD = _newMaxCap;
    }


    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
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


    function addToBalances(address _person,uint256 value) {
        if(!ownership[msg.sender]) throw;
        balances[_person] = SafeMath.add(balances[_person],value);
        Transfer(address(this), _person, value);
    }

    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function increaseEthRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        ethraised+=value;
    }

    function increaseBTCRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        btcraised+=value;
    }

    function increaseUSDRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        usdraised+=value;
    }

    function finalizeICO(){
        if(!ownership[msg.sender]) throw;

        if(usdraised<minCapUSD) throw;
        finalizedICO = true;
        istransferAllowed = true;
    }

    function enableTransfers() public onlyOwner{
        istransferAllowed = true;
    }

    function disableTransfers() public onlyOwner{
        istransferAllowed = false;
    }

     
    function finalizeICOOwner() onlyOwner{
        finalizedICO = true;
        istransferAllowed = true;
    }

    function isValid() returns(bool){
        if(now>=fundingStartBlock && now<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
        if(usdraised>maxCapUSD) throw;
    }

     

    function() payable{
        throw;
    }
}