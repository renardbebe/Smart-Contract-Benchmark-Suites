 

pragma solidity ^0.4.25;

 

 
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

 
interface ERC20 {

    function name() external returns (string);
    function symbol() external returns (string);
    function decimals() external returns (uint8);
    function totalSupply() external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOwnable {
    function owner() external returns(address);
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
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

contract GoldenRatioPercent is Ownable {
    using SafeMath for uint;

    event Invested(address Investedor, uint256 amount);
    event Withdrawn(address Investedor, uint256 amount);
    event Commission(address owner, uint256 amount);
    event BountyList(address tokenAddress);

    mapping(address => uint) public balance;
    mapping(address => uint) public time;
    mapping(address => uint) public percentWithdraw;
    mapping(address => uint) public allPercentWithdraw;

    mapping(address => uint) public lastDeposit;

    uint public totalRaised = 0;
    uint public stepTime = 1 hours;
    uint public countOfInvestedors = 0;
    uint projectPercent = 9;
    uint public minDeposit = 10 finney;

    string public site_url = "";

    modifier isUser() {
        require(balance[msg.sender] > 0, "User`s address not found");
        _;
    }

    modifier isTime() {
        require(now >= time[msg.sender].add(stepTime), "Not time it is now");
        _;
    }

     
    function amendmentByRate() private view returns(uint) {
        uint contractBalance = address(this).balance;

        if (contractBalance < 1000 ether) {
            return (30);
        }
        if (contractBalance >= 1000 ether && contractBalance < 2500 ether) {
            return (40);
        }
        if (contractBalance >= 2500 ether && contractBalance < 5000 ether) {
            return (50);
        }
        if (contractBalance >= 5000 ether && contractBalance < 10000 ether) {
            return (60);
        }
        if (contractBalance >= 10000 ether) {
            return (70);
        }
    }

     
    function amendmentByLastDeposit(uint amount) private view returns(uint) {

        if (lastDeposit[msg.sender] < 10 ether) {
            return amount;
        }
        if (lastDeposit[msg.sender] >= 10 ether && lastDeposit[msg.sender] < 25 ether) {
            return amount.mul(103).div(100);
        }
        if (lastDeposit[msg.sender] >= 25 ether && lastDeposit[msg.sender] < 50 ether) {
           return amount.mul(104).div(100);
        }
        if (lastDeposit[msg.sender] >= 50 ether && lastDeposit[msg.sender] < 100 ether) {
            return amount.mul(106).div(100);
        }
        if (lastDeposit[msg.sender] >= 100 ether) {
            return amount.mul(110).div(100);
        }
    }

     
    function amendmentByDepositRate() private view returns(uint) {

        if (balance[msg.sender] < 10 ether) {
            return (0);
        }
        if (balance[msg.sender] >= 10 ether && balance[msg.sender] < 25 ether) {
            return (10);
        }
        if (balance[msg.sender] >= 25 ether && balance[msg.sender] < 50 ether) {
            return (18);
        }
        if (balance[msg.sender] >= 50 ether && balance[msg.sender] < 100 ether) {
            return (22);
        }
        if (balance[msg.sender] >= 100 ether) {
            return (28);
        }
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

     
    mapping(address => uint) public bountyAmount;
    mapping(address => mapping(address => uint)) public bountyUserWithdrawns;
    mapping(address => uint) public bountyUserCounter;
    mapping(address => uint) public bountyReward;
    uint public bountierCounter = 0;
    mapping(uint => address) public bountyList;
    mapping(address => uint) public bountyListIndex;

     
    function claimTokens(ERC20 token) public isUser returns(bool) {
        if(bountyUserWithdrawns[token][msg.sender] == 0 &&
            token.balanceOf(this) >= bountyReward[token])
        {
            bountyUserWithdrawns[token][msg.sender] = bountyReward[token];
            if(token.balanceOf(this) <= bountyReward[token]) {
                token.transfer(msg.sender, token.balanceOf(this));
                bountyList[bountyListIndex[token]] = address(0);
                return true;
            } else {
                token.transfer(msg.sender, bountyReward[token]);
                return true;
            }
        }
    }

     
    function makeBounty(ERC20 token, uint amountOfUsers) public payable {
         
        require(IOwnable(token).owner() == msg.sender);
        uint amount = token.allowance(msg.sender, this);
        token.transferFrom(msg.sender, this, amount);
        require(token.balanceOf(msg.sender) >= amount.mul(1)**token.decimals());
        require(msg.value >= amountOfUsers.mul(1 ether).div(10000));  

        bountyAmount[token] = amount;
        bountyUserCounter[token] = amountOfUsers;
        bountierCounter = bountierCounter.add(1);
        bountyList[bountierCounter] = token;
        bountyListIndex[token] = bountierCounter;
        bountyReward[token] = amount.div(amountOfUsers);
    }

     
    function getBountyList() public {
        for(uint i= 1; i <= 200 && i < bountierCounter; i++) {
            emit BountyList(bountyList[bountierCounter]);
        }
    }

    function payout() public view returns(uint256) {
        uint256 percent = amendmentByRate().sub(amendmentByDepositRate());
        uint256 different = now.sub(time[msg.sender]).div(stepTime);
        uint256 rate = balance[msg.sender].mul(percent).div(1000);
        uint256 withdrawalAmount = rate.mul(different).div(24).sub(percentWithdraw[msg.sender]);
        return amendmentByLastDeposit(withdrawalAmount);
    }

    function setSiteUrl(string _url) public onlyOwner {
        site_url = _url;
    }

    function _deposit() private {
        if (msg.value > 0) {

            require(msg.value >= minDeposit);

            lastDeposit[msg.sender] = msg.value;

            if (balance[msg.sender] == 0) {
                countOfInvestedors += 1;
            }
            if (balance[msg.sender] > 0 && now > time[msg.sender].add(stepTime)) {
                _reward();
                percentWithdraw[msg.sender] = 0;
            }

            balance[msg.sender] = balance[msg.sender].add(msg.value);
            time[msg.sender] = now;

            totalRaised = totalRaised.add(msg.value);

            uint256 commission = msg.value.mul(projectPercent).div(100);
            owner.transfer(commission);

            emit Invested(msg.sender, msg.value);
            emit Commission(owner, commission);
        } else {
            _reward();
        }
    }

     
    function _reward() private isUser isTime {

        if ((balance[msg.sender].mul(1618).div(1000)) <= allPercentWithdraw[msg.sender]) {
            balance[msg.sender] = 0;
            time[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
        } else {
            uint256 pay = payout();
            if(allPercentWithdraw[msg.sender].add(pay) >= balance[msg.sender].mul(1618).div(1000)) {
                pay = (balance[msg.sender].mul(1618).div(1000)).sub(allPercentWithdraw[msg.sender]);
            }
            percentWithdraw[msg.sender] = percentWithdraw[msg.sender].add(pay);
            allPercentWithdraw[msg.sender] = allPercentWithdraw[msg.sender].add(pay);
            msg.sender.transfer(pay);
            emit Withdrawn(msg.sender, pay);
        }
    }

    function() external payable {
        _deposit();
    }
}