 

pragma solidity 0.5.7;

 
 
 
 
 
 
 
 
 
 
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
library Address {
  function toAddress(bytes memory source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }

  function isNotContract(address addr) internal view returns(bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length == 0;
  }
}

 
 
 
library Zero {
  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function requireNotZero(uint val) internal pure {
    require(val != 0, "require not zero value");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }

  function isZero(uint a) internal pure returns(bool) {
    return a == 0;
  }

  function notZero(uint a) internal pure returns(bool) {
    return a != 0;
  }
}

 
 
 

contract owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface token {
    function transfer(address receiver, uint amount) external;
}

contract preCrowdsaleETH is owned {
    
     
    using SafeMath for uint;
    
    uint public price;
    uint8 decimals;
    uint8 public refPercent;
    uint256 public softCap;
	uint256 public hardCap;
	uint256 public totalSalesEth;
	uint256 public totalSalesTokens;
	uint public startDate;
	uint public bonusEnds50;
	uint public bonusEnds30;
	uint public bonusEnds20;
	uint public bonusEnds10;
	uint public bonusEnds5;
    uint public endDate;
    address public beneficiary;
    token public tokenReward;
    
    mapping(address => uint256) public balanceOfEth;
    mapping(address => uint256) public balanceTokens;
    mapping(address => uint256) public buyTokens;
    mapping(address => uint256) public buyTokensBonus;
    mapping(address => uint256) public bountyTokens;
    mapping(address => uint256) public refTokens;
    
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    
    using Address for *;
    using Zero for *;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

     
    constructor(address _addressOfTokenUsedAsReward) public {
        price = 2500;
        decimals = 18;
        refPercent = 5;
        softCap = 1000000 * 10**uint(decimals);
		hardCap = 100000000 * 10**uint(decimals);
		startDate = 1555286400;		 
		bonusEnds50 = 1557014400;    
		bonusEnds30 = 1558828800;    
		bonusEnds20 = 1560211200;    
		bonusEnds10 = 1561161600;    
		bonusEnds5 = 1562112000;	 
		endDate = 1571097600; 		 
		beneficiary = owner;
        tokenReward = token(_addressOfTokenUsedAsReward);
    }

     

    function () payable external {
        require(!crowdsaleClosed);
        require(now >= startDate && now <= endDate);
        
        uint256 amount = msg.value;
        uint256 buyTokens = msg.value.mul(price);
        uint256 buyBonus = 0;
        
         
        require(hardCap >= buyTokens.add(buyBonus));

        if (now <= bonusEnds50) {
            buyBonus = msg.value.mul(price.mul(50).div(100));
        } else if (now <= bonusEnds30){
			buyBonus = msg.value.mul(price.mul(30).div(100));
		} else if (now <= bonusEnds20){
			buyBonus = msg.value.mul(price.mul(20).div(100));
		} else if (now <= bonusEnds10){
			buyBonus = msg.value.mul(price.mul(10).div(100));	
		} else if (now <= bonusEnds5){
			buyBonus = msg.value.mul(price.mul(5).div(100));
		}
		
		 
        address referrerAddr = msg.data.toAddress();
        uint256 refTokens = msg.value.mul(price).mul(refPercent).div(100);
        if (referrerAddr.notZero() && referrerAddr != msg.sender && hardCap < buyTokens.add(buyBonus).add(refTokens)) {
            balanceOfEth[msg.sender] = balanceOfEth[msg.sender].add(amount);
            totalSalesEth = totalSalesEth.add(amount);
            totalSalesTokens = totalSalesTokens.add(buyTokens).add(buyBonus).add(refTokens);
            addTokensBonusRef(msg.sender, buyTokens, buyBonus, referrerAddr, refTokens);
		    emit FundTransfer(msg.sender, amount, true);
		    
        } else {
    
            balanceOfEth[msg.sender] = balanceOfEth[msg.sender].add(amount);
            totalSalesEth = totalSalesEth.add(amount);
            totalSalesTokens = totalSalesTokens.add(buyTokens).add(buyBonus);
            addTokensBonus(msg.sender, buyTokens, buyBonus);
		    emit FundTransfer(msg.sender, amount, true);
        }
    }

    modifier afterDeadline() { if (now >= endDate) _; }

     
    function checkGoalReached() public afterDeadline {
        if (totalSalesTokens >= softCap){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, totalSalesEth);
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() public afterDeadline {
        require(crowdsaleClosed);
        if (!fundingGoalReached) {
            uint256 amount = balanceOfEth[msg.sender];
            balanceOfEth[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOfEth[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (msg.sender.send(address(this).balance)) {
               emit FundTransfer(beneficiary, address(this).balance, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
    
     
     
     
	function setRefPer(uint8 percent) public onlyOwner {
	    refPercent = percent;
	}
	
	function addTokens(address to, uint256 tokens) internal {
        require(!crowdsaleClosed);
        balanceTokens[to] = balanceTokens[to].add(tokens);
        buyTokens[to] = buyTokens[to].add(tokens);
        tokenReward.transfer(to, tokens);
    }
    
    function addTokensBonus(address to, uint256 buyToken, uint256 buyBonus) internal {
        require(!crowdsaleClosed);
        balanceTokens[to] = balanceTokens[to].add(buyToken).add(buyBonus);
        buyTokens[to] = buyTokens[to].add(buyToken);
        buyTokensBonus[to] = buyTokensBonus[to].add(buyBonus);
        tokenReward.transfer(to, buyToken.add(buyBonus));
    }
    
    function addBountyTokens(address to, uint256 bountyToken) internal {
        require(!crowdsaleClosed);
        balanceTokens[to] = balanceTokens[to].add(bountyToken);
        bountyTokens[to] = bountyTokens[to].add(bountyToken);
        tokenReward.transfer(to, bountyToken);
    }
    
    function addTokensBonusRef(address to, uint256 buyToken, uint256 buyBonus, address referrerAddr, uint256 refToken) internal {
        require(!crowdsaleClosed);
        balanceTokens[to] = balanceTokens[to].add(buyToken).add(buyBonus);
        buyTokens[to] = buyTokens[to].add(buyToken);
        buyTokensBonus[to] = buyTokensBonus[to].add(buyBonus);
        tokenReward.transfer(to, buyToken.add(buyBonus));
        
         
        balanceTokens[referrerAddr] = balanceTokens[referrerAddr].add(refToken);
        refTokens[referrerAddr] = refTokens[referrerAddr].add(refToken);
        tokenReward.transfer(referrerAddr, refToken);
    }
    
     
    function sendAllTokensToOwner(uint256 _revardTokens) onlyOwner public {
        tokenReward.transfer(owner, _revardTokens);
    }
}