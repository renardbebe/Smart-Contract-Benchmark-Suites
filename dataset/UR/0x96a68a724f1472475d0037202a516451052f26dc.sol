 

pragma solidity ^0.4.16;




contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);

    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
    }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
      assert(b <= a);
      return a - b;
    }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

   
  function transfer(address _to, uint256 _value) returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

  function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      var _allowance = allowed[_from][msg.sender];

       
       

      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

  function approve(address _spender, uint256 _value) returns (bool) {

       
       
       
       
      require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }



}

contract Ownable {
  address public owner;


   
  function Ownable() {
      owner = msg.sender;
    }


   
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }


   
  function transferOwnership(address newOwner) onlyOwner {
      require(newOwner != address(0));
      owner = newOwner;
    }

}


contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

   
    uint256 public startBlock;
    uint256 public endBlock;
   
    address public wallet;

   
    uint256 public tokensPerEther;

   
    uint256 public weiRaised;

    uint256 public cap;
    uint256 public issuedTokens;
    string public name = "Realestateco.in";
    string public symbol = "REAL";
    uint public decimals = 4;
    uint public INITIAL_SUPPLY = 80000000000000;
    uint factor;
    bool internal isCrowdSaleRunning;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Token() {

        wallet = address(0x879bf61F63a8C58D802EC612Aa8E868882E532c6);
        tokensPerEther = 331;
        endBlock = block.number + 400000;

        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        startBlock = block.number;
        cap = INITIAL_SUPPLY;
        issuedTokens = 0;
        factor = 10**14;
        isCrowdSaleRunning = true;
        }

     
     

  function () payable {
      buyTokens(msg.sender);
    }

  function stopCrowdSale() onlyOwner {
    isCrowdSaleRunning = false;
  }

   
  function buyTokens(address beneficiary) payable {
      require(beneficiary != 0x0);
      require(validPurchase());

      uint256 weiAmount = msg.value;
       
      uint256 tokens = weiAmount.mul(tokensPerEther).div(factor);


       
      require(issuedTokens.add(tokens) <= cap);
       
      weiRaised = weiRaised.add(weiAmount);
      issuedTokens = issuedTokens.add(tokens);

      forwardFunds();
       
      issueToken(beneficiary,tokens);
      TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

    }

   
  function issueToken(address beneficiary, uint256 tokens) internal {

      balances[owner] = balances[owner].sub(tokens);
      balances[beneficiary] = balances[beneficiary].add(tokens);
    }

   
   
  function forwardFunds() internal {
       
      wallet.transfer(msg.value);

    }

   
  function validPurchase() internal constant returns (bool) {
      uint256 current = block.number;
      bool withinPeriod = current >= startBlock && current <= endBlock;
      bool nonZeroPurchase = msg.value != 0;
      return withinPeriod && nonZeroPurchase && isCrowdSaleRunning;
    }

   
  function hasEnded() public constant returns (bool) {
      return (block.number > endBlock) && isCrowdSaleRunning;
    }

}