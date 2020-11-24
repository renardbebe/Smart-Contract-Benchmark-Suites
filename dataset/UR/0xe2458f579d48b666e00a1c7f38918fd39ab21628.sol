 

pragma solidity 0.4.14;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



 
 
contract LuckyToken is StandardToken, Ownable{
  string public name = "Lucky888Coin";
  string public symbol = "LKY";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function LuckyToken() {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

   
  function burn(uint _value) onlyOwner {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

 
contract initialTeuTokenSale is Ownable {
  using SafeMath for uint256;
  event LogPeriodStart(uint period);
  event LogCollectionStart(uint period);
  event LogContribution(address indexed contributorAddress, uint256 weiAmount, uint period);
  event LogCollect(address indexed contributorAddress, uint256 tokenAmount, uint period); 

  LuckyToken                                       private  token; 
  mapping(uint => address)                       private  walletOfPeriod;
  uint256                                        private  minContribution = 0.1 ether;
  uint                                           private  saleStart;
  bool                                           private  isTokenCollectable = false;
  mapping(uint => uint)                          private  periodStart;
  mapping(uint => uint)                          private  periodDeadline;
  mapping(uint => uint256)                       private  periodTokenPool;

  mapping(uint => mapping (address => uint256))  private  contribution;  
  mapping(uint => uint256)                       private  periodContribution;  
  mapping(uint => mapping (address => bool))     private  collected;  
  mapping(uint => mapping (address => uint256))  private  tokenCollected;  
  
  uint public totalPeriod = 0;
  uint public currentPeriod = 0;


   
  function initTokenSale (address _tokenAddress
  , address _walletPeriod1, address _walletPeriod2
  , uint256 _tokenPoolPeriod1, uint256 _tokenPoolPeriod2
  , uint _saleStartDate) onlyOwner {
    assert(totalPeriod == 0);
    assert(_tokenAddress != address(0));
    assert(_walletPeriod1 != address(0));
    assert(_walletPeriod2 != address(0));
    walletOfPeriod[1] = _walletPeriod1;
    walletOfPeriod[2] = _walletPeriod2;
    periodTokenPool[1] = _tokenPoolPeriod1;
    periodTokenPool[2] = _tokenPoolPeriod2;
    token = LuckyToken(_tokenAddress);
    assert(token.owner() == owner);
    setPeriodStart(_saleStartDate);
 
  }
  
  
     
  function setPeriodStart(uint _saleStartDate) onlyOwner beforeSaleStart private {
    totalPeriod = 0;
    saleStart = _saleStartDate;
    
    uint period1_contributionInterval = 14 days;
    uint period1_collectionInterval = 14 days;
    uint period2_contributionInterval = 7 days;
    
    addPeriod(saleStart, saleStart + period1_contributionInterval);
    addPeriod(saleStart + period1_contributionInterval + period1_collectionInterval, saleStart + period1_contributionInterval + period1_collectionInterval + period2_contributionInterval);

    currentPeriod = 1;    
  } 
  
  function addPeriod(uint _periodStart, uint _periodDeadline) onlyOwner beforeSaleEnd private {
    require(_periodStart >= now && _periodDeadline > _periodStart && (totalPeriod == 0 || _periodStart > periodDeadline[totalPeriod]));
    totalPeriod = totalPeriod + 1;
    periodStart[totalPeriod] = _periodStart;
    periodDeadline[totalPeriod] = _periodDeadline;
    periodContribution[totalPeriod] = 0;
  }


   
  function goNextPeriod() onlyOwner public {
    for (uint i = 1; i <= totalPeriod; i++) {
        if (currentPeriod < totalPeriod && now >= periodStart[currentPeriod + 1]) {
            currentPeriod = currentPeriod + 1;
            isTokenCollectable = false;
            LogPeriodStart(currentPeriod);
        }
    }
    
  }

     
  function goTokenCollection() onlyOwner public {
    require(currentPeriod > 0 && now > periodDeadline[currentPeriod] && !isTokenCollectable);
    isTokenCollectable = true;
    LogCollectionStart(currentPeriod);
  }

   
  modifier saleIsOn() {
    require(currentPeriod > 0 && now >= periodStart[currentPeriod] && now < periodDeadline[currentPeriod]);
    _;
  }
  
   
  modifier collectIsOn() {
    require(isTokenCollectable && currentPeriod > 0 && now > periodDeadline[currentPeriod] && (currentPeriod == totalPeriod || now < periodStart[currentPeriod + 1]));
    _;
  }
  
     
  modifier beforeSaleStart() {
    require(totalPeriod == 0 || now < periodStart[1]);
    _;  
  }
     
   
  modifier beforeSaleEnd() {
    require(currentPeriod == 0 || now < periodDeadline[totalPeriod]);
    _;
  }
    
  modifier afterSaleEnd() {
    require(currentPeriod > 0 && now > periodDeadline[totalPeriod]);
    _;
  }
  
  modifier overMinContribution() {
    require(msg.value >= minContribution);
    _;
  }
  
  
   
  function contribute() private saleIsOn overMinContribution {
    contribution[currentPeriod][msg.sender] = contribution[currentPeriod][msg.sender].add256(msg.value);
    periodContribution[currentPeriod] = periodContribution[currentPeriod].add256(msg.value);
    assert(walletOfPeriod[currentPeriod].send(msg.value));
    LogContribution(msg.sender, msg.value, currentPeriod);
  }

   
  function collectToken() public collectIsOn {
    uint256 _tokenCollected = 0;
    for (uint i = 1; i <= totalPeriod; i++) {
        if (!collected[i][msg.sender] && contribution[i][msg.sender] > 0)
        {
            _tokenCollected = contribution[i][msg.sender].mul256(periodTokenPool[i]).div256(periodContribution[i]);

            collected[i][msg.sender] = true;
            token.transfer(msg.sender, _tokenCollected);

            tokenCollected[i][msg.sender] = _tokenCollected;
            LogCollect(msg.sender, _tokenCollected, i);
        }
    }
  }


     
  function transferTokenOut(address _to, uint256 _amount) public onlyOwner {
    token.transfer(_to, _amount);
  }

     
  function transferEtherOut(address _to, uint256 _amount) public onlyOwner {
    assert(_to.send(_amount));
  }  

     
  function contributionOf(uint _period, address _contributor) public constant returns (uint256) {
    return contribution[_period][_contributor] ;
  }

     
  function periodContributionOf(uint _period) public constant returns (uint256) {
    return periodContribution[_period];
  }

     
  function isTokenCollected(uint _period, address _contributor) public constant returns (bool) {
    return collected[_period][_contributor] ;
  }
  
     
  function tokenCollectedOf(uint _period, address _contributor) public constant returns (uint256) {
    return tokenCollected[_period][_contributor] ;
  }

   
  function() external payable {
    contribute();
  }

}