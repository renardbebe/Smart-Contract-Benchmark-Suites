 

pragma solidity 0.4.19;


contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
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



contract ERC20TransferInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) constant public returns (uint256);
}



contract ICO is Ownable {
    
    using SafeMath for uint256;

    event TokenAddressSet(address indexed tokenAddress);
    event FirstPreIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event SecondPreIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event MainIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event TokenPriceChanged(uint256 newTokenPrice, uint256 newExchangeRate);
    event ExchangeRateChanged(uint256 newExchangeRate, uint256 newTokenPrice);
    event BonuseChanged(uint256 newBonus);
    event OffchainPurchaseMade(address indexed recipient, uint256 tokensPurchased);
    event TokensPurchased(address indexed recipient, uint256 tokensPurchased, uint256 weiSent);
    event UnsoldTokensWithdrawn(uint256 tokensWithdrawn);
    event ICOPaused(uint256 timeOfPause);
    event ICOUnpaused(uint256 timeOfUnpause);
    event IcoDeadlineExtended(State currentState, uint256 newDeadline);
    event IcoDeadlineShortened(State currentState, uint256 newDeadline);
    event IcoTerminated(uint256 terminationTime);
    event AirdropInvoked();

    uint256 public endTime;
    uint256 private pausedTime;
    bool public IcoPaused;
    uint256 public tokenPrice;
    uint256 public rate;
    uint256 public bonus;
    uint256 public minInvestment;
    ERC20TransferInterface public MSTCOIN;
    address public multiSigWallet;
    uint256 public tokensSold;

    mapping (address => uint256) public investmentOf;

    enum State {FIRST_PRE_ICO, SECOND_PRE_ICO, MAIN_ICO, TERMINATED}
    State public icoState;

    uint256[4] public mainIcoBonusStages;

    function ICO() public {
        endTime = now.add(7 days);
        pausedTime = 0;
        IcoPaused = false;
        tokenPrice = 89e12;  
        rate = 11235;   
        bonus = 100;
        minInvestment = 1e17;
        multiSigWallet = 0xE1377e465121776d8810007576034c7E0798CD46;
        tokensSold = 0;
        icoState = State.FIRST_PRE_ICO;
        FirstPreIcoActivated(now, endTime, bonus);
    }

     
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0x0);
        MSTCOIN = ERC20TransferInterface(_tokenAddress);
        TokenAddressSet(_tokenAddress);
    }

     
    function getTokenAddress() public view returns(address) {
        return address(MSTCOIN);
    }

     
    function activateSecondPreIco() public onlyOwner {
        require(now >= endTime && icoState == State.FIRST_PRE_ICO);
        icoState = State.SECOND_PRE_ICO;
        endTime = now.add(4 days);
        bonus = 50;
        SecondPreIcoActivated(now, endTime, bonus);
    }

     
    function activateMainIco() public onlyOwner {
        require(now >= endTime && icoState == State.SECOND_PRE_ICO);
        icoState = State.MAIN_ICO;
        mainIcoBonusStages[0] = now.add(7 days);
        mainIcoBonusStages[1] = now.add(14 days);
        mainIcoBonusStages[2] = now.add(21 days);
        mainIcoBonusStages[3] = now.add(31 days);
        endTime = now.add(31 days);
        bonus = 35;
        MainIcoActivated(now, endTime, bonus);
    }

     
    function changeTokenPrice(uint256 _newTokenPrice) public onlyOwner {
        require(tokenPrice != _newTokenPrice && _newTokenPrice > 0);
        tokenPrice = _newTokenPrice;
        uint256 eth = 1e18;
        rate = eth.div(tokenPrice);
        TokenPriceChanged(tokenPrice, rate);
    }

     
    function changeRate(uint256 _newRate) public onlyOwner {
        require(rate != _newRate && _newRate > 0);
        rate = _newRate;
        uint256 x = 1e12;
        tokenPrice = x.div(rate);
        ExchangeRateChanged(rate, tokenPrice);
    }

     
    function changeBonus(uint256 _newBonus) public onlyOwner {
        require(bonus != _newBonus && _newBonus > 0);
        bonus = _newBonus;
        BonuseChanged(bonus);
    }

     
    function processOffchainTokenPurchase(address _recipient, uint256 _value) public onlyOwner {
        require(MSTCOIN.balanceOf(address(this)) >= _value);
        require(_recipient != 0x0 && _value > 0);
        MSTCOIN.transfer(_recipient, _value);
        tokensSold = tokensSold.add(_value);
        OffchainPurchaseMade(_recipient, _value);
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _recipient) public payable {
        uint256 msgVal = msg.value.div(1e12);  
        require(MSTCOIN.balanceOf(address(this)) >= msgVal.mul(rate.mul(getBonus()).div(100)).add(rate) ) ;
        require(msg.value >= minInvestment && withinPeriod());
        require(_recipient != 0x0);
        uint256 toTransfer = msgVal.mul(rate.mul(getBonus()).div(100).add(rate));
        MSTCOIN.transfer(_recipient, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        investmentOf[msg.sender] = investmentOf[msg.sender].add(msg.value);
        TokensPurchased(_recipient, toTransfer, msg.value);
        forwardFunds();
    }

     
    function forwardFunds() internal {
        multiSigWallet.transfer(msg.value);
    }

     
    function withinPeriod() internal view returns(bool) {
        return IcoPaused == false && now < endTime && icoState != State.TERMINATED;
    }

     
    function getBonus() public view returns(uint256 _bonus) {
        _bonus = bonus;
        if(icoState == State.MAIN_ICO) {
            if(now > mainIcoBonusStages[3]) {
                _bonus = 0;
            } else {
                uint256 timeStamp = now;
                for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                    if(timeStamp <= mainIcoBonusStages[i]) {
                        break;
                    } else {
                        if(_bonus >= 15) {
                            _bonus = _bonus.sub(10);
                        }
                    }
                }
            }
        }
        return _bonus;
    }

     
    function withdrawUnsoldTokens(address _recipient) public onlyOwner {
        require(icoState == State.TERMINATED);
        require(now >= endTime && MSTCOIN.balanceOf(address(this)) > 0);
        if(_recipient == 0x0) { 
            _recipient = owner; 
        }
        UnsoldTokensWithdrawn(MSTCOIN.balanceOf(address(this)));
        MSTCOIN.transfer(_recipient, MSTCOIN.balanceOf(address(this)));
    }

     
    function pauseICO() public onlyOwner {
        require(!IcoPaused);
        IcoPaused = true;
        pausedTime = now;
        ICOPaused(now);
    }

     
    function unpauseICO() public onlyOwner {
        require(IcoPaused);
        IcoPaused = false;
        endTime = endTime.add(now.sub(pausedTime));
        ICOUnpaused(now);
    }


     
    function extendDeadline(uint256 _days) public onlyOwner {
        require(icoState != State.TERMINATED);
        endTime = endTime.add(_days.mul(1 days));
        if(icoState == State.MAIN_ICO) {
            uint256 blocks = 0;
            uint256 stage = 0;
            for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                if(now < mainIcoBonusStages[i]) {
                    stage = i;
                }
            }
            blocks = (_days.mul(1 days)).div(mainIcoBonusStages.length.sub(stage));
            for(uint x = stage; x < mainIcoBonusStages.length; x++) {
                mainIcoBonusStages[x] = mainIcoBonusStages[x].add(blocks);
            }
        }
        IcoDeadlineExtended(icoState, endTime);
    }

     
    function shortenDeadline(uint256 _days) public onlyOwner {
        if(now.add(_days.mul(1 days)) >= endTime) {
            revert();
        } else {
            endTime = endTime.sub(_days.mul(1 days));
            if(icoState == State.MAIN_ICO) {
                uint256 blocks = 0;
                uint256 stage = 0;
                for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                    if(now < mainIcoBonusStages[i]) {
                        stage = i;
                    }
                }
                blocks = (_days.mul(1 days)).div(mainIcoBonusStages.length.sub(stage));
                for(uint x = stage; x < mainIcoBonusStages.length; x++) {
                    mainIcoBonusStages[x] = mainIcoBonusStages[x].sub(blocks);
                }
            }
        }
        IcoDeadlineShortened(icoState, endTime);
    }

     
    function terminateIco() public onlyOwner {
        require(icoState == State.MAIN_ICO);
        require(now < endTime);
        endTime = now;
        icoState = State.TERMINATED;
        IcoTerminated(now);
    }

     
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }

     
    function airdrop(address[] _addrs, uint256[] _values) public onlyOwner returns(bool) {
        require(_addrs.length == _values.length && _addrs.length <= 100);
        require(MSTCOIN.balanceOf(address(this)) >= getSumOfValues(_values));
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                MSTCOIN.transfer(_addrs[i], _values[i]);
            }
        }
        AirdropInvoked();
        return true;
    }

     
    function getSumOfValues(uint256[] _values) internal pure returns(uint256) {
        uint256 sum = 0;
        for(uint i=0; i < _values.length; i++) {
            sum = sum.add(_values[i]);
        }
        return sum;
    } 
}