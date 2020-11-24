 

pragma solidity ^0.4.19;

  

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
    address public owner;
    address public candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function requestOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        candidate = newOwner;
    }


     
    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        OwnershipTransferred(owner, candidate);        
    }
}


 
contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;


    function MultiOwners() public {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }


    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }


    function isOwner() constant public returns (bool) {
        return owners[msg.sender] ? true : false;
    }


    function checkOwner(address maybe_owner) constant public returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) onlyOwner public {
        owners[_owner] = true;
        AccessGrant(_owner);
    }


    function revoke(address _owner) onlyOwner public {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}




 
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


 




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }


     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }


     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


 
contract McFlyToken is MintableToken {
    string public constant name = "McFlyToken";
    string public constant symbol = "McFLY";
    uint8 public constant decimals = 18;

     
    mapping(address=>bool) whitelist;

     
     
    event AllowTransfer(address from);

     
    modifier canTransfer() {
        require(mintingFinished || whitelist[msg.sender]);
        _;        
    }

     
     
    function allowTransfer(address from) onlyOwner public {
        whitelist[from] = true;
        AllowTransfer(from);
    }

     
     
     
     
    function transferFrom(address from, address to, uint256 value) canTransfer public returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
     
     
    function transfer(address to, uint256 value) canTransfer public returns (bool) {
        return super.transfer(to, value);
    }
}







 
contract Haltable is MultiOwners {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }


    modifier onlyInEmergency {
        require(halted);
        _;
    }


     
    function halt() external onlyOwner {
        halted = true;
    }


     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}



 
contract McFlyCrowd is MultiOwners, Haltable {
    using SafeMath for uint256;

     
    uint256 public counter_in;  
    
     
    uint256 public minETHin = 1e18;  

     
    McFlyToken public token;

     
    address public wallet;

     
    uint256 public sT2;  
    uint256 constant dTLP2 = 118 days;  
    uint256 constant dBt = 60 days;  
    uint256 constant dW = 12 days;  

     
    uint256 public constant hardCapInTokens = 1800e24;  

     
    uint256 public constant mintCapInTokens = 1260e24;  

     
    uint256 public crowdTokensTLP2;

    uint256 public _preMcFly;

     
    uint256 constant fundTokens = 270e24;  
    uint256 public fundTotalSupply;
    address public fundMintingAgent;

     
    uint256 constant wavesTokens = 100e24;  
    address public wavesAgent;
    address public wavesGW;

     
    uint256 constant VestingPeriodInSeconds = 30 days;  
    uint256 constant VestingPeriodsCount = 24;

     
    uint256 constant _teamTokens = 180e24;
    uint256 public teamTotalSupply;
    address public teamWallet;

     
     
    uint256 constant _bountyOnlineTokens = 36e24;
    address public bountyOnlineWallet;
    address public bountyOnlineGW;

     
    uint256 constant _bountyOfflineTokens = 54e24;
    address public bountyOfflineWallet;

     
    uint256 constant _advisoryTokens = 90e24;
    uint256 public advisoryTotalSupply;
    address public advisoryWallet;

     
    uint256 constant _reservedTokens = 162e24;
    uint256 public reservedTotalSupply;
    address public reservedWallet;

     
    uint256 constant _airdropTokens = 18e24;
    address public airdropWallet;
    address public airdropGW;

     
    address public preMcFlyWallet;

     
    struct Ppl {
        address addr;
        uint256 amount;
    }
    mapping (uint32 => Ppl) public ppls;

     
    struct Window {
        bool active;
        uint256 totalEthInWindow;
        uint32 totalTransCnt;
        uint32 refundIndex;
        uint256 tokenPerWindow;
    } 
    mapping (uint8 => Window) public ww;


     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPurchaseInWindow(address indexed beneficiary, uint256 value, uint8 winnum, uint32 totalcnt, uint256 totaleth1);
    event TransferOddEther(address indexed beneficiary, uint256 value);
    event FundMinting(address indexed beneficiary, uint256 value);
    event WithdrawVesting(address indexed beneficiary, uint256 period, uint256 value, uint256 valueTotal);
    event TokenWithdrawAtWindow(address indexed beneficiary, uint256 value);
    event SetFundMintingAgent(address newAgent);
    event SetTeamWallet(address newTeamWallet);
    event SetAdvisoryWallet(address newAdvisoryWallet);
    event SetReservedWallet(address newReservedWallet);
    event SetStartTimeTLP2(uint256 newStartTimeTLP2);
    event SetMinETHincome(uint256 newMinETHin);
    event NewWindow(uint8 winNum, uint256 amountTokensPerWin);
    event TokenETH(uint256 totalEth, uint32 totalCnt);


     
    modifier validPurchase() {
        require(msg.value != 0);
        _;        
    }


     
    function McFlyCrowd(
        uint256 _startTimeTLP2,
        uint256 _preMcFlyTotalSupply,
        address _wallet,
        address _wavesAgent,
        address _wavesGW,
        address _fundMintingAgent,
        address _teamWallet,
        address _bountyOnlineWallet,
        address _bountyOnlineGW,
        address _bountyOfflineWallet,
        address _advisoryWallet,
        address _reservedWallet,
        address _airdropWallet,
        address _airdropGW,
        address _preMcFlyWallet
    ) public 
    {   
        require(_startTimeTLP2 >= block.timestamp);
        require(_preMcFlyTotalSupply > 0);
        require(_wallet != 0x0);
        require(_wavesAgent != 0x0);
        require(_wavesGW != 0x0);
        require(_fundMintingAgent != 0x0);
        require(_teamWallet != 0x0);
        require(_bountyOnlineWallet != 0x0);
        require(_bountyOnlineGW != 0x0);
        require(_bountyOfflineWallet != 0x0);
        require(_advisoryWallet != 0x0);
        require(_reservedWallet != 0x0);
        require(_airdropWallet != 0x0);
        require(_airdropGW != 0x0);
        require(_preMcFlyWallet != 0x0);

        token = new McFlyToken();

        wallet = _wallet;

        sT2 = _startTimeTLP2;

        wavesAgent = _wavesAgent;
        wavesGW = _wavesGW;

        fundMintingAgent = _fundMintingAgent;

        teamWallet = _teamWallet;
        bountyOnlineWallet = _bountyOnlineWallet;
        bountyOnlineGW = _bountyOnlineGW;
        bountyOfflineWallet = _bountyOfflineWallet;
        advisoryWallet = _advisoryWallet;
        reservedWallet = _reservedWallet;
        airdropWallet = _airdropWallet;
        airdropGW = _airdropGW;
        preMcFlyWallet = _preMcFlyWallet;

         
        _preMcFly = _preMcFlyTotalSupply;
        token.mint(preMcFlyWallet, _preMcFly);  
        token.allowTransfer(preMcFlyWallet);
        crowdTokensTLP2 = crowdTokensTLP2.add(_preMcFly);

        token.mint(wavesAgent, wavesTokens);  
        token.allowTransfer(wavesAgent);
        token.allowTransfer(wavesGW);
        crowdTokensTLP2 = crowdTokensTLP2.add(wavesTokens);

        token.mint(this, _teamTokens);  

        token.mint(bountyOnlineWallet, _bountyOnlineTokens);
        token.allowTransfer(bountyOnlineWallet);
        token.allowTransfer(bountyOnlineGW);

        token.mint(bountyOfflineWallet, _bountyOfflineTokens);
        token.allowTransfer(bountyOfflineWallet);

        token.mint(this, _advisoryTokens);

        token.mint(this, _reservedTokens);

        token.mint(airdropWallet, _airdropTokens);
        token.allowTransfer(airdropWallet);
        token.allowTransfer(airdropGW);
    }


     
    function withinPeriod() constant public returns (bool) {
        return (now >= sT2 && now <= (sT2+dTLP2));
    }


     
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }


     
    function stageName() constant public returns (uint8) {
        uint256 eT2 = sT2+dTLP2;

        if (now < sT2) {return 101;}  
        if (now >= sT2 && now <= eT2) {return (102);}  

        if (now > eT2 && now < eT2+dBt) {return (103);}  
        if (now >= (eT2+dBt) && now <= (eT2+dBt+dW)) {return (0);}  
        if (now > (eT2+dBt+dW) && now < (eT2+dBt+dW+dBt)) {return (104);}  
        if (now >= (eT2+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW)) {return (1);}  
        if (now > (eT2+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt)) {return (105);}  
        if (now >= (eT2+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW)) {return (2);}  
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt+dW+dBt)) {return (106);}  
        if (now >= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (3);}  
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt)) {return (107);}  
        if (now >= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (4);}  
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (200);}  
        return (201);  
    }


     
    function setFundMintingAgent(address agent) onlyOwner public {
        fundMintingAgent = agent;
        SetFundMintingAgent(agent);
    }


     
    function setTeamWallet(address _newTeamWallet) onlyOwner public {
        teamWallet = _newTeamWallet;
        SetTeamWallet(_newTeamWallet);
    }


     
    function setAdvisoryWallet(address _newAdvisoryWallet) onlyOwner public {
        advisoryWallet = _newAdvisoryWallet;
        SetAdvisoryWallet(_newAdvisoryWallet);
    }


     
    function setReservedWallet(address _newReservedWallet) onlyOwner public {
        reservedWallet = _newReservedWallet;
        SetReservedWallet(_newReservedWallet);
    }


     
    function setMinETHin(uint256 _minETHin) onlyOwner public {
        minETHin = _minETHin;
        SetMinETHincome(_minETHin);
    }


     
    function setStartEndTimeTLP(uint256 _at) onlyOwner public {
        require(block.timestamp < sT2);  
        require(block.timestamp < _at);  

        sT2 = _at;
        SetStartTimeTLP2(_at);
    }


     
    function fundMinting(address to, uint256 amount) stopInEmergency public {
        require(msg.sender == fundMintingAgent || isOwner());
        require(block.timestamp < sT2);
        require(fundTotalSupply.add(amount) <= fundTokens);
        require(token.totalSupply().add(amount) <= hardCapInTokens);

        fundTotalSupply = fundTotalSupply.add(amount);
        token.mint(to, amount);
        FundMinting(to, amount);
    }


     
    function calcAmountAt(
        uint256 amount,
        uint256 at,
        uint256 _totalSupply
    ) public constant returns (uint256, uint256) 
    {
        uint256 estimate;
        uint256 price;
        
        if (at >= sT2 && at <= (sT2+dTLP2)) {
            if (at <= sT2 + 15 days) {price = 12e13;} else if (at <= sT2 + 30 days) {
                price = 14e13;} else if (at <= sT2 + 45 days) {
                    price = 16e13;} else if (at <= sT2 + 60 days) {
                        price = 18e13;} else if (at <= sT2 + 75 days) {
                            price = 20e13;} else if (at <= sT2 + 90 days) {
                                price = 22e13;} else if (at <= sT2 + 105 days) {
                                    price = 24e13;} else if (at <= sT2 + 118 days) {
                                        price = 26e13;} else {revert();}
        } else {revert();}

        estimate = _totalSupply.add(amount.mul(1e18).div(price));

        if (estimate > hardCapInTokens) {
            return (
                hardCapInTokens.sub(_totalSupply),
                estimate.sub(hardCapInTokens).mul(price).div(1e18)
            );
        }
        return (estimate.sub(_totalSupply), 0);
    }


     
    function() external payable {
        return getTokens(msg.sender);
    }


     
    function getTokens(address contributor) payable stopInEmergency validPurchase public {
        uint256 amount;
        uint256 oddEthers;
        uint256 ethers;
        uint256 _at;
        uint8 _winNum;

        _at = block.timestamp;

        require(contributor != 0x0);
       
        if (withinPeriod()) {
        
            (amount, oddEthers) = calcAmountAt(msg.value, _at, token.totalSupply());
  
            require(amount.add(token.totalSupply()) <= hardCapInTokens);

            ethers = msg.value.sub(oddEthers);

            token.mint(contributor, amount);  
            TokenPurchase(contributor, ethers, amount);
            counter_in = counter_in.add(ethers);
            crowdTokensTLP2 = crowdTokensTLP2.add(amount);

            if (oddEthers > 0) {
                require(oddEthers < msg.value);
                contributor.transfer(oddEthers);
                TransferOddEther(contributor, oddEthers);
            }

            wallet.transfer(ethers);
        } else {
            require(msg.value >= minETHin);  
            _winNum = stageName();
            require(_winNum >= 0 && _winNum < 5);
            Window storage w = ww[_winNum];

            require(w.tokenPerWindow > 0);  

            w.totalEthInWindow = w.totalEthInWindow.add(msg.value);
            ppls[w.totalTransCnt].addr = contributor;
            ppls[w.totalTransCnt].amount = msg.value;
            w.totalTransCnt++;
            TokenPurchaseInWindow(contributor, msg.value, _winNum, w.totalTransCnt, w.totalEthInWindow);
        }
    }


     
    function closeWindow(uint8 _winNum) onlyOwner stopInEmergency public {
        require(ww[_winNum].active);
        ww[_winNum].active = false;

        wallet.transfer(this.balance);
    }


     
    function sendTokensWindow(uint8 _winNum) onlyOwner stopInEmergency public {
        uint256 _tokenPerETH;
        uint256 _tokenToSend = 0;
        address _tempAddr;
        uint32 index = ww[_winNum].refundIndex;

        TokenETH(ww[_winNum].totalEthInWindow, ww[_winNum].totalTransCnt);

        require(ww[_winNum].active);
        require(ww[_winNum].totalEthInWindow > 0);
        require(ww[_winNum].totalTransCnt > 0);

        _tokenPerETH = ww[_winNum].tokenPerWindow.div(ww[_winNum].totalEthInWindow);  

        while (index < ww[_winNum].totalTransCnt && msg.gas > 100000) {
            _tokenToSend = _tokenPerETH.mul(ppls[index].amount);
            ppls[index].amount = 0;
            _tempAddr = ppls[index].addr;
            ppls[index].addr = 0;
            index++;
            token.transfer(_tempAddr, _tokenToSend);
            TokenWithdrawAtWindow(_tempAddr, _tokenToSend);
        }
        ww[_winNum].refundIndex = index;
    }


     
    function newWindow(uint8 _winNum, uint256 _tokenPerWindow) private {
        ww[_winNum] = Window(true, 0, 0, 0, _tokenPerWindow);
        NewWindow(_winNum, _tokenPerWindow);
    }


     
    function finishCrowd() onlyOwner public {
        uint256 _tokenPerWindow;
        require(now > (sT2.add(dTLP2)) || hardCapInTokens == token.totalSupply());
        require(!token.mintingFinished());

        _tokenPerWindow = (mintCapInTokens.sub(crowdTokensTLP2).sub(fundTotalSupply)).div(5);
        token.mint(this, _tokenPerWindow.mul(5));  
         
        for (uint8 y = 0; y < 5; y++) {
            newWindow(y, _tokenPerWindow);
        }

        token.finishMinting();
    }


     
    function vestingWithdraw(address withdrawWallet, uint256 withdrawTokens, uint256 withdrawTotalSupply) private returns (uint256) {
        require(token.mintingFinished());
        require(msg.sender == withdrawWallet || isOwner());

        uint256 currentPeriod = (block.timestamp.sub(sT2.add(dTLP2))).div(VestingPeriodInSeconds);
        if (currentPeriod > VestingPeriodsCount) {
            currentPeriod = VestingPeriodsCount;
        }
        uint256 tokenAvailable = withdrawTokens.mul(currentPeriod).div(VestingPeriodsCount).sub(withdrawTotalSupply);   

        require((withdrawTotalSupply.add(tokenAvailable)) <= withdrawTokens);

        uint256 _withdrawTotalSupply = withdrawTotalSupply.add(tokenAvailable);

        token.transfer(withdrawWallet, tokenAvailable);
        WithdrawVesting(withdrawWallet, currentPeriod, tokenAvailable, _withdrawTotalSupply);

        return _withdrawTotalSupply;
    }


     
    function teamWithdraw() public {
        teamTotalSupply = vestingWithdraw(teamWallet, _teamTokens, teamTotalSupply);
    }


     
    function advisoryWithdraw() public {
        advisoryTotalSupply = vestingWithdraw(advisoryWallet, _advisoryTokens, advisoryTotalSupply);
    }


     
    function reservedWithdraw() public {
        reservedTotalSupply = vestingWithdraw(reservedWallet, _reservedTokens, reservedTotalSupply);
    }
}