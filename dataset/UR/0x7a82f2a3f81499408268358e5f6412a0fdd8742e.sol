 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address previousOwner);
  event OwnershipTransferred(
    address previousOwner,
    address newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address from,
    address to,
    uint256 value
  );

  event Approval(
    address owner,
    address spender,
    uint256 value
  );
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  bool public isPaused;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(isPaused == false, "transactions on pause");
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));
    require(isPaused == false, "transactions on pause");

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));
    require(isPaused == false, "transactions on pause");

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    require(isPaused == false, "transactions on pause");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    require(isPaused == false, "transactions on pause");
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract FabgCoin is ERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;

     
    uint256 public rate;
    uint256 public minimalPayment;

    bool public isBuyBlocked;
    address saleAgent;
    uint256 public totalEarnings;

    event TokensCreatedWithoutPayment(address Receiver, uint256 Amount);
    event BoughtTokens(address Receiver, uint256 Amount, uint256 sentWei);
    event BuyPaused();
    event BuyUnpaused();
    event UsagePaused();
    event UsageUnpaused();
    event Payment(address payer, uint256 weiAmount);

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function pauseCustomBuying() public onlyOwner {
        require(isBuyBlocked == false);
        isBuyBlocked = true;
        emit BuyPaused();
    }

    function resumeCustomBuy() public onlyOwner {
        require(isBuyBlocked == true);
        isBuyBlocked = false;
        emit BuyUnpaused();
    }

    function pauseUsage() public onlyOwner {
        require(isPaused == false);
        isPaused = true;
        emit UsagePaused();
    }

    function resumeUsage() public onlyOwner {
        require(isPaused == true);
        isPaused = false;
        emit UsageUnpaused();
    }

    function setSaleAgent(address _saleAgent) public onlyOwner {
        require(saleAgent == address(0));
        saleAgent = _saleAgent;
    }

    function createTokenWithoutPayment(address _receiver, uint256 _amount) public onlyOwner {
        _mint(_receiver, _amount);

        emit TokensCreatedWithoutPayment(_receiver, _amount);
    }

    function createTokenViaSaleAgent(address _receiver, uint256 _amount) public onlySaleAgent {
        _mint(_receiver, _amount);
    }

    function buyTokens() public payable {
        require(msg.value >= minimalPayment);
        require(isBuyBlocked == false);

        uint256 amount = msg.value.mul(rate); 
        _mint(msg.sender, amount);

        totalEarnings = totalEarnings.add(amount.div(rate));

        emit BoughtTokens(msg.sender, amount, msg.value);
    }
}

contract FabgCoinMarketPack is FabgCoin {
    using SafeMath for uint256;

    bool isPausedForSale;

     
    mapping(uint256 => uint256) packsToWei;
    uint256[] packs;
    uint256 public totalEarningsForPackSale;
    address adminsWallet;

    event MarketPaused();
    event MarketUnpaused();
    event PackCreated(uint256 TokensAmount, uint256 WeiAmount);
    event PackDeleted(uint256 TokensAmount);
    event PackBought(address Buyer, uint256 TokensAmount, uint256 WeiAmount);
    event Withdrawal(address receiver, uint256 weiAmount);

    constructor() public {  
        name = "FabgCoin";
        symbol = "FABG";
        decimals = 18;
        rate = 100;
        minimalPayment = 1 ether / 100;
        isBuyBlocked = true;
    }

     
    function setAddressForPayment(address _newMultisig) public onlyOwner {
        adminsWallet = _newMultisig;
    }

     
    function() public payable {
       emit Payment(msg.sender, msg.value);
    }

     
    function pausePackSelling() public onlyOwner {
        require(isPausedForSale == false);
        isPausedForSale = true;
        emit MarketPaused();
    }

     
    function unpausePackSelling() public onlyOwner {
        require(isPausedForSale == true);
        isPausedForSale = false;
        emit MarketUnpaused();
    }    

     
    function addPack(uint256 _amountOfTokens, uint256 _amountOfWei) public onlyOwner {
        require(packsToWei[_amountOfTokens] == 0);
        require(_amountOfTokens != 0);
        require(_amountOfWei != 0);
        
        packs.push(_amountOfTokens);
        packsToWei[_amountOfTokens] = _amountOfWei;

        emit PackCreated(_amountOfTokens, _amountOfWei);
    }

     
    function buyPack(uint256 _amountOfTokens) public payable {
        require(packsToWei[_amountOfTokens] > 0);
        require(msg.value >= packsToWei[_amountOfTokens]);
        require(isPausedForSale == false);

        _mint(msg.sender, _amountOfTokens * 1 ether);
        (msg.sender).transfer(msg.value.sub(packsToWei[_amountOfTokens]));

        totalEarnings = totalEarnings.add(packsToWei[_amountOfTokens]);
        totalEarningsForPackSale = totalEarningsForPackSale.add(packsToWei[_amountOfTokens]);

        emit PackBought(msg.sender, _amountOfTokens, packsToWei[_amountOfTokens]);
    }

     
    function withdraw() public onlyOwner {
        require(adminsWallet != address(0), "admins wallet couldn't be 0x0");

        uint256 amount = address(this).balance;  
        (adminsWallet).transfer(amount);
        emit Withdrawal(adminsWallet, amount);
    }

     
    function deletePack(uint256 _amountOfTokens) public onlyOwner {
        require(packsToWei[_amountOfTokens] != 0);
        require(_amountOfTokens != 0);

        packsToWei[_amountOfTokens] = 0;

        uint256 index;

        for(uint256 i = 0; i < packs.length; i++) {
            if(packs[i] == _amountOfTokens) {
                index = i;
                break;
            }
        }

        for(i = index; i < packs.length - 1; i++) {
            packs[i] = packs[i + 1];
        }
        packs.length--;

        emit PackDeleted(_amountOfTokens);
    }

     
    function getAllPacks() public view returns (uint256[]) {
        return packs;
    }

     
    function getPackPrice(uint256 _amountOfTokens) public view returns (uint256) {
        return packsToWei[_amountOfTokens];
    }
}