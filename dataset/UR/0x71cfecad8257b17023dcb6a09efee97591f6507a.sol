 

pragma solidity 0.5.6;

 
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
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0);
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
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

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].sub(subtractedValue));

    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);

    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);

    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
  internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
  internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string memory) {
    return _name;
  }

   
  function symbol() public view returns(string memory) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract Ownable {
  address payable public owner;
   
  constructor() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}



contract GameWave is ERC20, ERC20Detailed, Ownable {

  uint paymentsTime = block.timestamp;
  uint totalPaymentAmount;
  uint lastTotalPaymentAmount;
  uint minted = 20000000;

  mapping (address => uint256) lastWithdrawTime;

   
  constructor() public ERC20Detailed("Game wave token", "GWT", 18) {
    _mint(msg.sender, minted * (10 ** uint256(decimals())));
  }

   
  function () payable external {
    if (msg.value == 0){
      withdrawDividends(msg.sender);
    }
  }

   
  function getDividends(address _holder) view public returns(uint) {
    if (paymentsTime >= lastWithdrawTime[_holder]){
      return totalPaymentAmount.mul(balanceOf(_holder)).div(minted * (10 ** uint256(decimals())));
    } else {
      return 0;
    }
  }

   
  function withdrawDividends(address payable _holder) public returns(uint) {
    uint dividends = getDividends(_holder);
    lastWithdrawTime[_holder] = block.timestamp;
    lastTotalPaymentAmount = lastTotalPaymentAmount.add(dividends);
    _holder.transfer(dividends);
  }

   

  function startPayments() public {
    require(block.timestamp >= paymentsTime + 30 days);
    owner.transfer(totalPaymentAmount.sub(lastTotalPaymentAmount));
    totalPaymentAmount = address(this).balance;
    paymentsTime = block.timestamp;
    lastTotalPaymentAmount = 0;
  }
}

 
contract Bank is Ownable {

    using SafeMath for uint256;

    mapping (uint256 => mapping (address => uint256)) public depositBears;
    mapping (uint256 => mapping (address => uint256)) public depositBulls;

    uint256 public currentDeadline;
    uint256 public currentRound = 1;
    uint256 public lastDeadline;
    uint256 public defaultCurrentDeadlineInHours = 24;
    uint256 public defaultLastDeadlineInHours = 48;
    uint256 public countOfBears;
    uint256 public countOfBulls;
    uint256 public totalSupplyOfBulls;
    uint256 public totalSupplyOfBears;
    uint256 public totalGWSupplyOfBulls;
    uint256 public totalGWSupplyOfBears;
    uint256 public probabilityOfBulls;
    uint256 public probabilityOfBears;
    address public lastHero;
    address public lastHeroHistory;
    uint256 public jackPot;
    uint256 public winner;
    uint256 public withdrawn;
    uint256 public withdrawnGW;
    uint256 public remainder;
    uint256 public remainderGW;
    uint256 public rate = 1;
    uint256 public rateModifier = 0;
    uint256 public tokenReturn;
    address crowdSale;

    uint256 public lastTotalSupplyOfBulls;
    uint256 public lastTotalSupplyOfBears;
    uint256 public lastTotalGWSupplyOfBulls;
    uint256 public lastTotalGWSupplyOfBears;
    uint256 public lastProbabilityOfBulls;
    uint256 public lastProbabilityOfBears;
    address public lastRoundHero;
    uint256 public lastJackPot;
    uint256 public lastWinner;
    uint256 public lastBalance;
    uint256 public lastBalanceGW;
    uint256 public lastCountOfBears;
    uint256 public lastCountOfBulls;
    uint256 public lastWithdrawn;
    uint256 public lastWithdrawnGW;


    bool public finished = false;

    Bears public BearsContract;
    Bulls public BullsContract;
    GameWave public GameWaveContract;

     
    constructor(address _crowdSale) public {
        _setRoundTime(6, 8);
        crowdSale = _crowdSale;
    }

     
    function setRateToken(uint256 _rate, uint256 _rateModifier) public onlyOwner returns(uint256){
        rate = _rate;
        rateModifier = _rateModifier;
    }

     
    function setCrowdSale(address _crowdSale) public onlyOwner{
        crowdSale = _crowdSale;
    }

     
    function _setRoundTime(uint _currentDeadlineInHours, uint _lastDeadlineInHours) internal {
        defaultCurrentDeadlineInHours = _currentDeadlineInHours;
        defaultLastDeadlineInHours = _lastDeadlineInHours;
        currentDeadline = block.timestamp + 60 * 60 * _currentDeadlineInHours;
        lastDeadline = block.timestamp + 60 * 60 * _lastDeadlineInHours;
    }

     
    function setRoundTime(uint _currentDeadlineInHours, uint _lastDeadlineInHours) public onlyOwner {
        _setRoundTime(_currentDeadlineInHours, _lastDeadlineInHours);
    }


     
    function setGameWaveAddress(address payable _GameWaveAddress) public {
        require(address(GameWaveContract) == address(0x0));
        GameWaveContract = GameWave(_GameWaveAddress);
    }

     
    function setBearsAddress(address payable _bearsAddress) external {
        require(address(BearsContract) == address(0x0));
        BearsContract = Bears(_bearsAddress);
    }

     
    function setBullsAddress(address payable _bullsAddress) external {
        require(address(BullsContract) == address(0x0));
        BullsContract = Bulls(_bullsAddress);
    }

     
    function getNow() view public returns(uint){
        return block.timestamp;
    }

     
    function getState() view public returns(bool) {
        if (block.timestamp > currentDeadline) {
            return false;
        }
        return true;
    }

     
    function setInfo(address _lastHero, uint256 _deposit) public {
        require(address(BearsContract) == msg.sender || address(BullsContract) == msg.sender);

        if (address(BearsContract) == msg.sender) {
            require(depositBulls[currentRound][_lastHero] == 0, "You are already in bulls team");
            if (depositBears[currentRound][_lastHero] == 0)
                countOfBears++;
            totalSupplyOfBears = totalSupplyOfBears.add(_deposit.mul(90).div(100));
            depositBears[currentRound][_lastHero] = depositBears[currentRound][_lastHero].add(_deposit.mul(90).div(100));
        }

        if (address(BullsContract) == msg.sender) {
            require(depositBears[currentRound][_lastHero] == 0, "You are already in bears team");
            if (depositBulls[currentRound][_lastHero] == 0)
                countOfBulls++;
            totalSupplyOfBulls = totalSupplyOfBulls.add(_deposit.mul(90).div(100));
            depositBulls[currentRound][_lastHero] = depositBulls[currentRound][_lastHero].add(_deposit.mul(90).div(100));
        }

        lastHero = _lastHero;

        if (currentDeadline.add(120) <= lastDeadline) {
            currentDeadline = currentDeadline.add(120);
        } else {
            currentDeadline = lastDeadline;
        }

        jackPot += _deposit.mul(10).div(100);

        calculateProbability();
    }

    function estimateTokenPercent(uint256 _difference) public view returns(uint256){
        if (rateModifier == 0) {
            return _difference.mul(rate);
        } else {
            return _difference.div(rate);
        }
    }

     
    function calculateProbability() public {
        require(winner == 0 && getState());

        totalGWSupplyOfBulls = GameWaveContract.balanceOf(address(BullsContract));
        totalGWSupplyOfBears = GameWaveContract.balanceOf(address(BearsContract));
        uint256 percent = (totalSupplyOfBulls.add(totalSupplyOfBears)).div(100);

        if (totalGWSupplyOfBulls < 1 ether) {
            totalGWSupplyOfBulls = 0;
        }

        if (totalGWSupplyOfBears < 1 ether) {
            totalGWSupplyOfBears = 0;
        }

        if (totalGWSupplyOfBulls <= totalGWSupplyOfBears) {
            uint256 difference = totalGWSupplyOfBears.sub(totalGWSupplyOfBulls).div(0.01 ether);

            probabilityOfBears = totalSupplyOfBears.mul(100).div(percent).add(estimateTokenPercent(difference));

            if (probabilityOfBears > 8000) {
                probabilityOfBears = 8000;
            }
            if (probabilityOfBears < 2000) {
                probabilityOfBears = 2000;
            }
            probabilityOfBulls = 10000 - probabilityOfBears;
        } else {
            uint256 difference = totalGWSupplyOfBulls.sub(totalGWSupplyOfBears).div(0.01 ether);
            probabilityOfBulls = totalSupplyOfBulls.mul(100).div(percent).add(estimateTokenPercent(difference));

            if (probabilityOfBulls > 8000) {
                probabilityOfBulls = 8000;
            }
            if (probabilityOfBulls < 2000) {
                probabilityOfBulls = 2000;
            }
            probabilityOfBears = 10000 - probabilityOfBulls;
        }

        totalGWSupplyOfBulls = GameWaveContract.balanceOf(address(BullsContract));
        totalGWSupplyOfBears = GameWaveContract.balanceOf(address(BearsContract));
    }

     
    function getWinners() public {
        require(winner == 0 && !getState());
        uint256 seed1 = address(this).balance;
        uint256 seed2 = totalSupplyOfBulls;
        uint256 seed3 = totalSupplyOfBears;
        uint256 seed4 = totalGWSupplyOfBulls;
        uint256 seed5 = totalGWSupplyOfBulls;
        uint256 seed6 = block.difficulty;
        uint256 seed7 = block.timestamp;

        bytes32 randomHash = keccak256(abi.encodePacked(seed1, seed2, seed3, seed4, seed5, seed6, seed7));
        uint randomNumber = uint(randomHash);

        if (randomNumber == 0){
            randomNumber = 1;
        }

        uint winningNumber = randomNumber % 10000;

        if (1 <= winningNumber && winningNumber <= probabilityOfBears){
            winner = 1;
        }

        if (probabilityOfBears < winningNumber && winningNumber <= 10000){
            winner = 2;
        }

        if (GameWaveContract.balanceOf(address(BullsContract)) > 0)
            GameWaveContract.transferFrom(
                address(BullsContract),
                address(this),
                GameWaveContract.balanceOf(address(BullsContract))
            );

        if (GameWaveContract.balanceOf(address(BearsContract)) > 0)
            GameWaveContract.transferFrom(
                address(BearsContract),
                address(this),
                GameWaveContract.balanceOf(address(BearsContract))
            );

        lastTotalSupplyOfBulls = totalSupplyOfBulls;
        lastTotalSupplyOfBears = totalSupplyOfBears;
        lastTotalGWSupplyOfBears = totalGWSupplyOfBears;
        lastTotalGWSupplyOfBulls = totalGWSupplyOfBulls;
        lastRoundHero = lastHero;
        lastJackPot = jackPot;
        lastWinner = winner;
        lastCountOfBears = countOfBears;
        lastCountOfBulls = countOfBulls;
        lastWithdrawn = withdrawn;
        lastWithdrawnGW = withdrawnGW;

        if (lastBalance > lastWithdrawn){
            remainder = lastBalance.sub(lastWithdrawn);
            address(GameWaveContract).transfer(remainder);
        }

        lastBalance = lastTotalSupplyOfBears.add(lastTotalSupplyOfBulls).add(lastJackPot);

        if (lastBalanceGW > lastWithdrawnGW){
            remainderGW = lastBalanceGW.sub(lastWithdrawnGW);
            tokenReturn = (totalGWSupplyOfBears.add(totalGWSupplyOfBulls)).mul(20).div(100).add(remainderGW);
            GameWaveContract.transfer(crowdSale, tokenReturn);
        }

        lastBalanceGW = GameWaveContract.balanceOf(address(this));

        totalSupplyOfBulls = 0;
        totalSupplyOfBears = 0;
        totalGWSupplyOfBulls = 0;
        totalGWSupplyOfBears = 0;
        remainder = 0;
        remainderGW = 0;
        jackPot = 0;

        withdrawn = 0;
        winner = 0;
        withdrawnGW = 0;
        countOfBears = 0;
        countOfBulls = 0;
        probabilityOfBulls = 0;
        probabilityOfBears = 0;

        _setRoundTime(defaultCurrentDeadlineInHours, defaultLastDeadlineInHours);
        currentRound++;
    }

     
    function () external payable {
        if (msg.value == 0){
            require(depositBears[currentRound - 1][msg.sender] > 0 || depositBulls[currentRound - 1][msg.sender] > 0);

            uint payout = 0;
            uint payoutGW = 0;

            if (lastWinner == 1 && depositBears[currentRound - 1][msg.sender] > 0) {
                payout = calculateLastETHPrize(msg.sender);
            }
            if (lastWinner == 2 && depositBulls[currentRound - 1][msg.sender] > 0) {
                payout = calculateLastETHPrize(msg.sender);
            }

            if (payout > 0) {
                depositBears[currentRound - 1][msg.sender] = 0;
                depositBulls[currentRound - 1][msg.sender] = 0;
                withdrawn = withdrawn.add(payout);
                msg.sender.transfer(payout);
            }

            if ((lastWinner == 1 && depositBears[currentRound - 1][msg.sender] == 0) || (lastWinner == 2 && depositBulls[currentRound - 1][msg.sender] == 0)) {
                payoutGW = calculateLastGWPrize(msg.sender);
                withdrawnGW = withdrawnGW.add(payoutGW);
                GameWaveContract.transfer(msg.sender, payoutGW);
            }

            if (msg.sender == lastRoundHero) {
                lastHeroHistory = lastRoundHero;
                lastRoundHero = address(0x0);
                withdrawn = withdrawn.add(lastJackPot);
                msg.sender.transfer(lastJackPot);
            }
        }
    }

     
    function calculateETHPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint256 totalSupply = (totalSupplyOfBears.add(totalSupplyOfBulls));

        if (depositBears[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositBears[currentRound][participant]).div(totalSupplyOfBears);
        }

        if (depositBulls[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositBulls[currentRound][participant]).div(totalSupplyOfBulls);
        }

        return payout;
    }

     
    function calculateGWPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint totalSupply = (totalGWSupplyOfBears.add(totalGWSupplyOfBulls)).mul(80).div(100);

        if (depositBears[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositBears[currentRound][participant]).div(totalSupplyOfBears);
        }

        if (depositBulls[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositBulls[currentRound][participant]).div(totalSupplyOfBulls);
        }

        return payout;
    }

     
    function calculateLastETHPrize(address _lastParticipant) public view returns(uint) {

        uint payout = 0;
        uint256 totalSupply = (lastTotalSupplyOfBears.add(lastTotalSupplyOfBulls));

        if (depositBears[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositBears[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfBears);
        }

        if (depositBulls[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositBulls[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfBulls);
        }

        return payout;
    }

     
    function calculateLastGWPrize(address _lastParticipant) public view returns(uint) {

        uint payout = 0;
        uint totalSupply = (lastTotalGWSupplyOfBears.add(lastTotalGWSupplyOfBulls)).mul(80).div(100);

        if (depositBears[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositBears[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfBears);
        }

        if (depositBulls[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositBulls[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfBulls);
        }

        return payout;
    }
}

 
contract CryptoTeam {
    using SafeMath for uint256;

    Bank public BankContract;
    GameWave public GameWaveContract;
    
     
    function () external payable {
        require(BankContract.getState() && msg.value >= 0.05 ether);

        BankContract.setInfo(msg.sender, msg.value.mul(90).div(100));

        address(GameWaveContract).transfer(msg.value.mul(10).div(100));
        
        address(BankContract).transfer(msg.value.mul(90).div(100));
    }
}

 
contract Bears is CryptoTeam {
    constructor(address payable _bankAddress, address payable _GameWaveAddress) public {
        BankContract = Bank(_bankAddress);
        BankContract.setBearsAddress(address(this));
        GameWaveContract = GameWave(_GameWaveAddress);
        GameWaveContract.approve(_bankAddress, 9999999999999999999000000000000000000);
    }
}

 
contract Bulls is CryptoTeam {
    constructor(address payable _bankAddress, address payable _GameWaveAddress) public {
        BankContract = Bank(_bankAddress);
        BankContract.setBullsAddress(address(this));
        GameWaveContract = GameWave(_GameWaveAddress);
        GameWaveContract.approve(_bankAddress, 9999999999999999999000000000000000000);
    }
}

 
contract Sale {

    GameWave public GWContract;
    uint256 public buyPrice;
    address public owner;
    uint balance;

    bool crowdSaleClosed = false;

    constructor(
        address payable _GWContract
    ) payable public {
        owner = msg.sender;
        GWContract = GameWave(_GWContract);
        GWContract.approve(owner, 9999999999999999999000000000000000000);
    }

     

    function setPrice(uint256 newBuyPrice) public {
        buyPrice = newBuyPrice;
    }

     

    function () payable external {
        uint amount = msg.value;
        balance = (amount / buyPrice) * 10 ** 18;
        GWContract.transfer(msg.sender, balance);
        address(GWContract).transfer(amount);
    }
}