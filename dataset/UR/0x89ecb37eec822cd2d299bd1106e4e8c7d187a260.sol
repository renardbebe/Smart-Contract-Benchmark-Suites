 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BoostoPool{
    using SafeMath for uint256;

     
    uint256 public totalInvestors;

    address[] investorsList;

    mapping(address => bool) public investors;
    mapping(address => bool) public winners;

    address private BSTContract = 0xDf0041891BdA1f911C4243f328F7Cf61b37F965b;
    address private fundsWallet;
    address private operatorWallet;

    uint256 public unit;
    uint256 public size;

    uint256 public BSTAmount;

    uint256 public winnerCount;
    uint256 public paidWinners = 0;

    uint256 public bonus;
    bool public bonusInETH;

    uint256 public startDate;
    uint256 public duration;  

     
    constructor(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size,
        address _fundsWallet,
        address _operatorWallet
        ) public{
        
        startDate = _startDate;
        duration = _duration;
        
        winnerCount = _winnerCount;
        bonus = _bonus;
        bonusInETH = _bonusInETH;
        unit = _unit;
        BSTAmount = _BSTAmount;
        size = _size;

        fundsWallet = _fundsWallet;
        operatorWallet = _operatorWallet;
    }

     
    modifier isPoolOpen() {
        require(totalInvestors < size && now < (startDate + duration) && now >= startDate);
        _;
    }

     
    modifier isPoolClosed() {
        require(totalInvestors >= size || now >= (startDate + duration));
        _;
    }

     
    modifier isPoolFinished() {
        require(totalInvestors >= size);
        _;
    }

     
    modifier checkInvestAmount(){
        require(msg.value == unit);
        _;
    }

     
    modifier notInvestedYet(){
        require(!investors[msg.sender]);
        _;
    }

     
    modifier isAdmin(){
        require(msg.sender == operatorWallet);
        _;
    }

     
    function() checkInvestAmount notInvestedYet isPoolOpen payable public{
        fundsWallet.transfer(msg.value);

        StandardToken bst = StandardToken(BSTContract);
        bst.transfer(msg.sender, BSTAmount);

        investorsList[investorsList.length++] = msg.sender;
        investors[msg.sender] = true;

        totalInvestors += 1;
    }

     
    function adminDropETH() isAdmin payable public{
        assert(bonusInETH);
        assert(msg.value == winnerCount.mul(bonus));
    }

     
    function adminWithdraw() isAdmin isPoolClosed public{
        assert(totalInvestors <= size);

        StandardToken bst = StandardToken(BSTContract);
        uint256 bstBalance = bst.balanceOf(this);

        if(bstBalance > 0){
            bst.transfer(msg.sender, bstBalance);
        }

        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
            msg.sender.transfer(ethBalance);
        }
    }

     
    function adminAddWinner() isPoolFinished isAdmin public{
        assert(paidWinners < winnerCount);
        uint256 winnerIndex = random();
        assert(!winners[investorsList[winnerIndex]]);

        winners[investorsList[winnerIndex]] = true;
        paidWinners += 1;

        if(bonusInETH){
            investorsList[winnerIndex].transfer(bonus);
        }else{
            StandardToken(BSTContract).transfer(investorsList[winnerIndex], bonus);
        }
    }

     
    function random() public view returns (uint256) {
        return uint256(keccak256(block.timestamp, block.difficulty))%size;
    }

     
    function getWalletInfoByIndex(uint256 index) 
            public constant returns (address _addr, bool _isWinner){
        _addr = investorsList[index];
        _isWinner = winners[_addr];
    }

     
    function getWalletInfo(address addr) 
            public constant returns (bool _isWinner){
        _isWinner = winners[addr];
    }

     
    function isHealthy() 
            public constant returns (bool status){

         
        if(bonusInETH && address(this).balance < winnerCount.mul(bonus)){
            return false;
        }
        
        uint256 bstBalance = StandardToken(BSTContract).balanceOf(this);

        uint256 enoughBalance = BSTAmount.mul(size - totalInvestors); 
        if(!bonusInETH){
            enoughBalance = bstBalance.add(winnerCount.mul(bonus));
        }
        if(bstBalance < enoughBalance){
            return false;
        }
        return true;
    }
}

contract BoostoPoolFactory {

    event NewPool(address creator, address pool);

    function createNew(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size,
        address _fundsWallet,
        address _operatorWallet
    ) public returns(address created){
        address ret = new BoostoPool(
            _startDate,
            _duration,
            _winnerCount,
            _bonus,
            _bonusInETH,
            _unit,
            _BSTAmount,
            _size,
            _fundsWallet,
            _operatorWallet
        );
        emit NewPool(msg.sender, ret);
    }
}