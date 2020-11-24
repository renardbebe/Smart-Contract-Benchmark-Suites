 

pragma solidity 0.4.11;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal constant returns(uint256) {
      assert(x >= y);
      return x - y;
    }

    function safeMult(uint256 x, uint256 y) internal constant returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function safeDiv(uint256 x, uint256 y) internal constant returns (uint256) {
      uint256 z = x / y;
      return z;
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


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
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

contract DIVXToken is StandardToken, SafeMath {

     
    string public constant name = "Divi Exchange Token";
    string public constant symbol = "DIVX";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public fundDeposit;       

     
    bool public isPaused;
    bool public isRedeeming;
    uint256 public fundingStartBlock;
    uint256 public firstXRChangeBlock;
    uint256 public secondXRChangeBlock;
    uint256 public thirdXRChangeBlock;
    uint256 public fundingEndBlock;

     
     
     
    mapping (address => uint256) private weiBalances;

     
    uint256 public totalReceivedWei;

    uint256 public constant privateExchangeRate  = 1000;  
    uint256 public constant firstExchangeRate    =  650;  
    uint256 public constant secondExchangeRate   =  575;  
    uint256 public constant thirdExchangeRate    =  500;  

    uint256 public constant receivedWeiCap =  100 * (10**3) * 10**decimals;
    uint256 public constant receivedWeiMin =    5 * (10**3) * 10**decimals;

     
    event LogCreate(address indexed _to, uint256 _value, uint256 _tokenValue);
    event LogRefund(address indexed _to, uint256 _value, uint256 _tokenValue);
    event LogRedeem(address indexed _to, uint256 _value, bytes32 _diviAddress);

     
    modifier onlyOwner() {
      require(msg.sender == fundDeposit);
      _;
    }

    modifier isNotPaused() {
      require(isPaused == false);
      _;
    }

     
    function DIVXToken(
        address _fundDeposit,
        uint256 _fundingStartBlock,
        uint256 _firstXRChangeBlock,
        uint256 _secondXRChangeBlock,
        uint256 _thirdXRChangeBlock,
        uint256 _fundingEndBlock) {

      isPaused    = false;
      isRedeeming = false;

      totalSupply      = 0;
      totalReceivedWei = 0;

      fundDeposit = _fundDeposit;

      fundingStartBlock   = _fundingStartBlock;
      firstXRChangeBlock  = _firstXRChangeBlock;
      secondXRChangeBlock = _secondXRChangeBlock;
      thirdXRChangeBlock  = _thirdXRChangeBlock;
      fundingEndBlock     = _fundingEndBlock;
    }

     

     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
      require(totalReceivedWei >= receivedWeiMin);
      return super.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(totalReceivedWei >= receivedWeiMin);
      return super.transferFrom(_from, _to, _value);
    }

     
    function createTokens() payable external isNotPaused {
      require(block.number >= fundingStartBlock);
      require(block.number <= fundingEndBlock);
      require(msg.value > 0);

       
      uint256 checkedReceivedWei = safeAdd(totalReceivedWei, msg.value);
      require(checkedReceivedWei <= receivedWeiCap);

       
       
      uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());

       
      uint256 projectTokens = safeDiv(tokens, 5);

       
      totalReceivedWei = checkedReceivedWei;

       
       
       
      if (block.number >= firstXRChangeBlock) weiBalances[msg.sender] += msg.value;

       
       
      totalSupply = safeAdd(totalSupply, tokens);
      balances[msg.sender] += tokens;

       
       
      totalSupply = safeAdd(totalSupply, projectTokens);
      balances[fundDeposit] += projectTokens;

      LogCreate(msg.sender, msg.value, tokens);   
    }

     
    function withdrawWei(uint256 _value) external onlyOwner isNotPaused {
      require(_value <= this.balance);

       
       
      require((block.number < firstXRChangeBlock) || (totalReceivedWei >= receivedWeiMin));

       
      fundDeposit.transfer(_value);
    }

     
    function pause() external onlyOwner isNotPaused {
       
      isPaused = true;
    }

     
    function resume() external onlyOwner {
       
      isPaused = false;
    }

     
    function startRedeeming() external onlyOwner isNotPaused {
       
      isRedeeming = true;
    }

     
    function stopRedeeming() external onlyOwner isNotPaused {
       
      isRedeeming = false;
    }

     
    function refund() external {
       
      require(block.number > fundingEndBlock);
       
      require(totalReceivedWei < receivedWeiMin);

       
       uint256 divxVal = balances[msg.sender];
       require(divxVal > 0);

       
      uint256 weiVal = weiBalances[msg.sender];
      require(weiVal > 0);

       
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, divxVal);

       
      LogRefund(msg.sender, weiVal, divxVal);

       
      msg.sender.transfer(weiVal);
    }

     
    function redeem(bytes32 diviAddress) external {
       
      require(isRedeeming);

       
      uint256 divxVal = balances[msg.sender];
       require(divxVal > 0);

       
      assert(super.transfer(fundDeposit, divxVal));

       
      LogRedeem(msg.sender, divxVal, diviAddress);
    }

     
    function getCurrentTokenPrice() private constant returns (uint256 currentPrice) {
      if (block.number < firstXRChangeBlock) {
        return privateExchangeRate;
      } else if (block.number < secondXRChangeBlock) {
        return firstExchangeRate;
      } else if (block.number < thirdXRChangeBlock) {
        return secondExchangeRate;
      } else {
        return thirdExchangeRate;
      }
    }
}