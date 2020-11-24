 

pragma solidity ^0.4.18;

 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    uint8 public decimals;
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function transfer(address _to, uint256 _value) public returns (bool _succes);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}



 
contract Crowdsale is SafeMath {

     
    address public tokenAddress = 0xa5FD4f631Ddf9C37d7B8A2c429a58bDC78abC843;
    
     
    ERC20Basic public ipc = ERC20Basic(tokenAddress);
    
     
    address public crowdsaleAgent = 0x783fE4521c2164eB6a7972122E7E33a1D1A72799;
    
    address public owner = 0xa52858fB590CFe15d03ee1F3803F2D3fCa367166;

     
    uint256 public weiRaised;

     
    uint256 public minimumEtherAmount = 0.2 ether;

     
     
    uint256 public startTime = 1520082000;      
    uint256 public deadlineOne = 1520168400;    
    uint256 public deadlineTwo = 1520427600;    
    uint256 public deadlineThree = 1520773200;  
    uint256 public endTime = 1522674000;        
    
     
    uint public firstRate = 6000; 
    uint public secondRate = 5500;
    uint public thirdRate = 5000;
    uint public finalRate = 4400;

     
    mapping(address => uint256) public distribution;
    
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyCrowdsaleAgent {
        require(msg.sender == crowdsaleAgent);
        _;
    }
    
     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(beneficiary != address(this));
        require(beneficiary != tokenAddress);
        require(validPurchase());
        uint256 weiAmount = msg.value;
         
        uint256 tokens = calcTokenAmount(weiAmount);
         
        weiRaised = safeAdd(weiRaised, weiAmount);
        distribution[beneficiary] = safeAdd(distribution[beneficiary], tokens);
        ipc.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
    
     
    function setCrowdsaleAgent(address _crowdsaleAgent) public returns (bool) {
        require(msg.sender == owner || msg.sender == crowdsaleAgent);
        crowdsaleAgent = _crowdsaleAgent;
        return true;
    }
    
     
    function setTimes(  uint256 _startTime, bool changeStartTime,
                        uint256 firstDeadline, bool changeFirstDeadline,
                        uint256 secondDeadline, bool changeSecondDeadline,
                        uint256 thirdDeadline, bool changeThirdDeadline,
                        uint256 _endTime, bool changeEndTime) onlyCrowdsaleAgent public returns (bool) {
        if(changeStartTime) startTime = _startTime;
        if(changeFirstDeadline) deadlineOne = firstDeadline;
        if(changeSecondDeadline) deadlineTwo = secondDeadline;
        if(changeThirdDeadline) deadlineThree = thirdDeadline;
        if(changeEndTime) endTime = _endTime;
        return true;
                            
    }
    
     
    function setNewIPCRates(uint _firstRate, bool changeFirstRate,
                            uint _secondRate, bool changeSecondRate,
                            uint _thirdRate, bool changeThirdRate,
                            uint _finaleRate, bool changeFinalRate) onlyCrowdsaleAgent public returns (bool) {
        if(changeFirstRate) firstRate = _firstRate;
        if(changeSecondRate) secondRate = _secondRate;
        if(changeThirdRate) thirdRate = _thirdRate;
        if(changeFinalRate) finalRate = _finaleRate;
        return true;
    }
    
     
    function setMinimumEtherAmount(uint256 _minimumEtherAmountInWei) onlyCrowdsaleAgent public returns (bool) {
        minimumEtherAmount = _minimumEtherAmountInWei;
        return true;
    }
    
     
    function withdrawRemainingIPCToken() onlyCrowdsaleAgent public returns (bool) {
        uint256 remainingToken = ipc.balanceOf(this);
        require(hasEnded() && remainingToken > 0);
        ipc.transfer(crowdsaleAgent, remainingToken);
        return true;
    }
    
     
    function withdrawERC20Token(address beneficiary, address _token) onlyCrowdsaleAgent public {
        ERC20Basic erc20Token = ERC20Basic(_token);
        uint256 amount = erc20Token.balanceOf(this);
        require(amount>0);
        erc20Token.transfer(beneficiary, amount);
    }
    
     
    function sendEther(address beneficiary, uint256 weiAmount) onlyCrowdsaleAgent public {
        beneficiary.transfer(weiAmount);
    }

     
    function calcTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 price;
        if (now >= startTime && now < deadlineOne) {
            price = firstRate; 
        } else if (now >= deadlineOne && now < deadlineTwo) {
            price = secondRate;
        } else if (now >= deadlineTwo && now < deadlineThree) {
            price = thirdRate;
        } else if (now >= deadlineThree && now <= endTime) {
        	price = finalRate;
        }
        uint256 tokens = safeMul(price, weiAmount);
        uint8 decimalCut = 18 > ipc.decimals() ? 18-ipc.decimals() : 0;
        return safeDiv(tokens, 10**uint256(decimalCut));
    }

     
    function forwardFunds() internal {
        crowdsaleAgent.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool isMinimumAmount = msg.value >= minimumEtherAmount;
        bool hasTokenBalance = ipc.balanceOf(this) > 0;
        return withinPeriod && isMinimumAmount && hasTokenBalance;
    }
     
     
    function killContract() onlyCrowdsaleAgent public {
        require(hasEnded() && ipc.balanceOf(this) == 0);
     selfdestruct(crowdsaleAgent);
    }
}