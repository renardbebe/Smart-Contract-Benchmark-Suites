 

pragma solidity ^0.4.24;

 
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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract IConnector
{
    function getSellPrice() public view returns (uint);
    function transfer(address to, uint256 numberOfTokens, uint256 price) public;
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  IConnector internal connector;
  mapping(address => uint256) balances;

  uint256 totalSupply_;

  constructor (address _connector) public
  {
      connector = IConnector(_connector);
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
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

    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MapsStorage is Ownable
{
    mapping(address => uint) public winners;
    mapping(address => address) public parents;

    function setWinnerValue(address key, uint value) public onlyOwner
    {
        winners[key] = value;
    }

    function setParentValue(address key, address value) public onlyOwner
    {
        parents[key] = value;
    }
}

contract INFToken is StandardToken
{
    string public name = "";
    string public symbol = "";
    uint public decimals = 2;

    constructor (address connector, string _name, string _symbol, uint _totalSupply) BasicToken(connector) public
    {
        name = _name;
        symbol = _symbol;
        totalSupply_ = _totalSupply * 10 ** decimals;

        address owner = msg.sender;
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);
    }

    function transfer(address _to, uint256 _value) public returns (bool)
    {
        uint price = 0;
        if(_to == address(connector))
        {
            price = connector.getSellPrice();
        }

        bool result = super.transfer(_to, _value);

        if(result && _to == address(connector))
        {
            connector.transfer(msg.sender, _value, price);
        }

        return result;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        uint price = 0;
        if(_to == address(connector))
        {
            price = connector.getSellPrice();
        }

        bool result = super.transferFrom(_from, _to, _value);

        if(result && _to == address(connector))
        {
            connector.transfer(msg.sender, _value, price);
        }

        return result;
    }
}

contract PlayInfinity is Ownable, IConnector
{
    using SafeMath for uint256;

    uint constant feePercent = 100;  
    uint constant smallJackpotPercent = 30;  
    uint constant bigJackpotPercent = 50;  
    uint constant referrerPercent = 20;  
    uint constant referrerJackpotPercent = 100;  
    uint constant fundPercent = 800;  

    INFToken public token;
    uint public startPrice;
    uint public currentPrice;
    uint public priceStep;
    uint public pricePercentGrowth;
    uint public minNumberOfTokensToBuy;
    uint public maxNumberOfTokensToBuy;

    MapsStorage public mapsStorage;
    uint public counterOfSoldTokens;
    uint public sumOfSmallJackpot;
    uint public sumOfBigJackpot;
    uint public sumOfFund;
    uint public timerTime;
    bool public gameActive;
    address public lastBuyer;
    uint public gameEndTime;

    event NewSmallJackpotWinner(address indexed winner, uint256 value);
    event NewBigJackpotWinner(address indexed winner, uint256 value);
    event SellTokens(address indexed holder, uint256 price, uint256 numberOfTokens, uint256 weiAmount);
    event BuyTokens(address indexed holder, uint256 price, uint256 numberOfTokens, uint256 weiAmount);

    constructor () public
    {
        gameActive = false;
        gameEndTime = 0;
    }

    modifier onlyForActiveGame()
    {
        require(gameActive);
        _;
    }

    modifier ifTokenCreated()
    {
        require(token != address(0));
        _;
    }

    function startNewGame(  string _name,
                            string _symbol,
                            uint _totalSupply,
                            uint _price,
                            uint _priceStep,
                            uint _pricePercentGrowth,
                            uint _minNumberOfTokensToBuy,
                            uint _maxNumberOfTokensToBuy,
                            uint _timerTime) onlyOwner public
    {
        require(!gameActive);
        require(bytes(_name).length != 0);
        require(bytes(_symbol).length != 0);
        require(_totalSupply != 0);
        require(_price != 0);
        require(_priceStep != 0);
        require(_pricePercentGrowth != 0);
        require(_minNumberOfTokensToBuy != 0);
        require(_maxNumberOfTokensToBuy != 0);
        require(_timerTime > now);
        require(now - gameEndTime > 1 weeks);


        token = new INFToken(this, _name, _symbol, _totalSupply);
        mapsStorage = new MapsStorage();
        startPrice = _price / 10 ** token.decimals();
        currentPrice = startPrice;
        priceStep = _priceStep * 10 ** token.decimals();
        pricePercentGrowth = _pricePercentGrowth;
        minNumberOfTokensToBuy = _minNumberOfTokensToBuy * 10 ** token.decimals();
        maxNumberOfTokensToBuy = _maxNumberOfTokensToBuy * 10 ** token.decimals();
        counterOfSoldTokens = 0;
        sumOfSmallJackpot = 0;
        sumOfBigJackpot = 0;
        sumOfFund = 0;
        timerTime = _timerTime;
        gameActive = true;
        lastBuyer = address(0);

        if(address(this).balance > 0)
        {
            payFee(address(this).balance);
        }
    }

    function stopGame() onlyForActiveGame onlyOwner public
    {
        require(now > timerTime);
        internalStopGame();
    }

    function internalStopGame() private
    {
        gameActive = false;
        gameEndTime = now;

        payJackpot();
    }

    function payJackpot() private
    {
        if(lastBuyer == address(0)) return;

        address parent = mapsStorage.parents(lastBuyer);
        if(parent == address(0))
        {
            lastBuyer.send(sumOfBigJackpot);
            emit NewBigJackpotWinner(lastBuyer, sumOfBigJackpot);
        }
        else
        {
            uint sum = sumOfBigJackpot.mul(referrerJackpotPercent).div(1000);
            parent.send(sum);  
            sum = sumOfBigJackpot.sub(sum);
            lastBuyer.send(sum);
            emit NewBigJackpotWinner(lastBuyer, sum);

        }

        lastBuyer = address(0);
        sumOfBigJackpot = 0;
    }

    function isGameEnd() public view returns(bool)
    {
        return  now > timerTime;
    }

    function () onlyForActiveGame public payable
    {
        if(now > timerTime)
        {
            internalStopGame();
            return;
        }

        if(msg.value == 0)  
        {
            getPrize(msg.sender);
        }
        else  
        {
            buyTokens(msg.sender, msg.value);
        }
    }

    function getTotalAvailableTokens() onlyForActiveGame public view returns (uint)
    {
        return token.balanceOf(this);
    }

    function getTotalSoldTokens() ifTokenCreated public view returns (uint)
    {
        return token.totalSupply().sub(token.balanceOf(this));
    }

    function getAvailableTokensAtCurrentPrice() onlyForActiveGame public view returns (uint)
    {
        uint tokens = priceStep - counterOfSoldTokens % priceStep;
        uint modulo = tokens % 10 ** token.decimals();
        if(modulo != 0) return tokens.sub(modulo);
        return tokens;
    }

    function getPrize(address sender) private
    {
        uint value = mapsStorage.winners(sender);
        require(value > 0);

        mapsStorage.setWinnerValue(sender, 0);
        sender.transfer(value);
    }

    function buyTokens(address sender, uint weiAmount) private
    {
        uint tokens = calcNumberOfTokens(weiAmount);
        require(tokens >= minNumberOfTokensToBuy);


        uint availableTokens = getAvailableTokensAtCurrentPrice();
        uint maxNumberOfTokens = availableTokens > maxNumberOfTokensToBuy ? maxNumberOfTokensToBuy : availableTokens;
        tokens = tokens > maxNumberOfTokens ? maxNumberOfTokens : tokens;
        uint actualWeiAmount = tokens.mul(currentPrice);
        counterOfSoldTokens = counterOfSoldTokens.add(tokens);


        sumOfSmallJackpot = sumOfSmallJackpot.add(actualWeiAmount.mul(smallJackpotPercent).div(1000));
        sumOfBigJackpot = sumOfBigJackpot.add(actualWeiAmount.mul(bigJackpotPercent).div(1000));
        sumOfFund = sumOfFund.add(actualWeiAmount.mul(fundPercent).div(1000));  

        uint fee = 0;
        if(payReferralRewards(actualWeiAmount))
        {
            fee = actualWeiAmount.mul(feePercent).div(1000);
        }
        else
        {
            fee = actualWeiAmount.mul(feePercent.add(referrerPercent)).div(1000);
        }
        payFee(fee);

        lastBuyer = msg.sender;

        emit BuyTokens(sender, currentPrice, tokens, actualWeiAmount);

        if(tokens == availableTokens)
        {
            mapsStorage.setWinnerValue(sender, mapsStorage.winners(sender).add(sumOfSmallJackpot));

            emit NewSmallJackpotWinner(sender, sumOfSmallJackpot);
            sumOfSmallJackpot = 0;
            currentPrice = getNewBuyPrice();
        }

        timerTime = getNewTimerTime(timerTime, tokens);

        token.transfer(sender, tokens);



        uint cashback = weiAmount.sub(actualWeiAmount);
        if(cashback > 0)
        {
            sender.transfer(cashback);
        }
    }

    function getNewTimerTime(uint currentTimerTime, uint numberOfTokens) public view returns (uint)
    {
        require(currentTimerTime >= now);

        uint maxTimerTime = now.add(24 hours);
        uint newTime = currentTimerTime.add(numberOfTokens.mul(1 minutes));
        return newTime > maxTimerTime ? maxTimerTime : newTime;
    }

    function payReferralRewards(uint actualWeiAmount) private returns (bool)
    {
        address referrerAddress = bytesToAddress(bytes(msg.data));
        address parent = mapsStorage.parents(msg.sender);

        if(parent == address(0))
        {
            if(referrerAddress != address(0) && token.balanceOf(referrerAddress) > 0 && msg.sender != referrerAddress)
            {
                mapsStorage.setParentValue(msg.sender, referrerAddress);
                uint value = actualWeiAmount.mul(referrerPercent).div(1000).div(2);
                referrerAddress.send(value);
                msg.sender.transfer(value);
                return true;
            }

        }
        else
        {
            parent.send(actualWeiAmount.mul(referrerPercent).div(1000));
            return true;
        }

        return false;
    }

    function payFee(uint weiAmount) private
    {
        address(0xB6c0889c8C0f47C87F003E9a161dC1C323624033).transfer(weiAmount.mul(40).div(100));
        address(0x8d1e5C1A7d3F8e18BFB5068825F10C3f5c380d71).transfer(weiAmount.mul(50).div(100));
        address(0x1E8eD35588a0B48C9920eC837eEbD698bC740f3D).transfer(weiAmount.mul(10).div(100));
    }

    function getNewBuyPrice() onlyForActiveGame public view returns (uint)
    {
        return currentPrice.add(currentPrice.mul(pricePercentGrowth).div(1000));
    }

    function getSellPrice() ifTokenCreated public view returns (uint)
    {
        return sumOfFund.div(getTotalSoldTokens());
    }

    function calcNumberOfTokens(uint weiAmount) onlyForActiveGame public view returns (uint)
    {
        uint modulo = weiAmount % currentPrice.mul(10 ** token.decimals());
        if(modulo != 0) return weiAmount.sub(modulo).div(currentPrice);
        return weiAmount.div(currentPrice);
    }

    function bytesToAddress(bytes source) internal pure returns(address parsedAddress)
    {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

    function transfer(address to, uint256 numberOfTokens, uint256 price) ifTokenCreated public
    {
        require(msg.sender == address(token));
        uint weiAmount = numberOfTokens.mul(price);
        emit SellTokens(to, price, numberOfTokens, weiAmount);
        sumOfFund = sumOfFund.sub(weiAmount);
        to.transfer(weiAmount);
    }
}