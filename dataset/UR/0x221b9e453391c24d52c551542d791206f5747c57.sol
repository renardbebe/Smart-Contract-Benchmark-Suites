 

pragma solidity ^0.4.15;


   
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
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

  }


   
  contract Haltable is Ownable {
    bool public halted = false;

    modifier inNormalState {
      require(!halted);
      _;
    }

    modifier inEmergencyState {
      require(halted);
      _;
    }

     
    function halt() external onlyOwner inNormalState {
      halted = true;
    }

     
    function unhalt() external onlyOwner inEmergencyState {
      halted = false;
    }
  }

   
  contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }


   
  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

   
  contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }

  }

   
  contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
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

   
  contract Burnable is StandardToken {
    using SafeMath for uint;

     
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) returns (bool success) {
      require(balances[msg.sender] >= _value);                 
      balances[msg.sender] = balances[msg.sender].sub(_value); 
      totalSupply = totalSupply.sub(_value);                                   
      Burn(msg.sender, _value);
      return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
      require(balances[_from] >= _value);                
      require(_value <= allowed[_from][msg.sender]);     
      balances[_from] = balances[_from].sub(_value);     
      totalSupply = totalSupply.sub(_value);             
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Burn(_from, _value);
      return true;
    }

    function transfer(address _to, uint _value) returns (bool success) {
      require(_to != 0x0);  

      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      require(_to != 0x0);  

      return super.transferFrom(_from, _to, _value);
    }
  }


   
  contract JincorToken is Burnable, Ownable {

    string public name = "Jincor Token";
    string public symbol = "JCR";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 35000000 * 1 ether;

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {
      require(transferAgents[_sender] || released);
      _;
    }

     
    modifier inReleaseState(bool releaseState) {
      require(releaseState == released);
      _;
    }

     
    modifier onlyReleaseAgent() {
      require(msg.sender == releaseAgent);
      _;
    }


     
    function JincorToken() {
      totalSupply = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
    }


     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

       
      releaseAgent = addr;
    }

    function release() onlyReleaseAgent inReleaseState(false) public {
      released = true;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
      transferAgents[addr] = state;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
       
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
       
      return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) onlyOwner returns (bool success) {
      return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
      return super.burnFrom(_from, _value);
    }
  }



  contract JincorTokenPreSale is Ownable, Haltable {
    using SafeMath for uint;

    string public name = "Jincor Token PreSale";

    JincorToken public token;

    address public beneficiary;

    uint public hardCap;

    uint public softCap;

    uint public price;

    uint public purchaseLimit;

    uint public collected = 0;

    uint public tokensSold = 0;

    uint public investorCount = 0;

    uint public weiRefunded = 0;

    uint public startBlock;

    uint public endBlock;

    bool public softCapReached = false;

    bool public crowdsaleFinished = false;

    mapping (address => bool) refunded;

    event GoalReached(uint amountRaised);

    event SoftCapReached(uint softCap);

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    event Refunded(address indexed holder, uint256 amount);

    modifier preSaleActive() {
      require(block.number >= startBlock && block.number < endBlock);
      _;
    }

    modifier preSaleEnded() {
      require(block.number >= endBlock);
      _;
    }

    function JincorTokenPreSale(
    uint _hardCapUSD,
    uint _softCapUSD,
    address _token,
    address _beneficiary,
    uint _totalTokens,
    uint _priceETH,
    uint _purchaseLimitUSD,

    uint _startBlock,
    uint _endBlock
    ) {
      hardCap = _hardCapUSD.mul(1 ether).div(_priceETH);
      softCap = _softCapUSD.mul(1 ether).div(_priceETH);
      price = _totalTokens.mul(1 ether).div(hardCap);

      purchaseLimit = _purchaseLimitUSD.mul(1 ether).div(_priceETH).mul(price);
      token = JincorToken(_token);
      beneficiary = _beneficiary;

      startBlock = _startBlock;
      endBlock = _endBlock;
    }

    function() payable {
      require(msg.value >= 0.1 * 1 ether);
      doPurchase(msg.sender);
    }

    function refund() external preSaleEnded inNormalState {
      require(softCapReached == false);
      require(refunded[msg.sender] == false);

      uint balance = token.balanceOf(msg.sender);
      require(balance > 0);

      uint refund = balance.div(price);
      if (refund > this.balance) {
        refund = this.balance;
      }

      assert(msg.sender.send(refund));
      refunded[msg.sender] = true;
      weiRefunded = weiRefunded.add(refund);
      Refunded(msg.sender, refund);
    }

    function withdraw() onlyOwner {
      require(softCapReached);
      assert(beneficiary.send(collected));
      token.transfer(beneficiary, token.balanceOf(this));
      crowdsaleFinished = true;
    }

    function doPurchase(address _owner) private preSaleActive inNormalState {

      require(!crowdsaleFinished);
      require(collected.add(msg.value) <= hardCap);

      if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
        softCapReached = true;
        SoftCapReached(softCap);
      }
      uint tokens = msg.value * price;
      require(token.balanceOf(msg.sender).add(tokens) <= purchaseLimit);

      if (token.balanceOf(msg.sender) == 0) investorCount++;

      collected = collected.add(msg.value);

      token.transfer(msg.sender, tokens);

      tokensSold = tokensSold.add(tokens);

      NewContribution(_owner, tokens, msg.value);

      if (collected == hardCap) {
        GoalReached(hardCap);
      }
    }
  }