 

pragma solidity ^0.4.24;

 

contract Bank {
    using SafeMath for uint256;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public claimedSum;
    mapping(address => uint256) public donateSum;
    mapping(address => bool) public isMember;
    address[] public member;

    uint256 public TIME_OUT = 7 days;
    mapping(address => uint256) public lastClaim;

    CitizenInterface public citizenContract;
    LotteryInterface public lotteryContract;
    F2mInterface public f2mContract;
    DevTeamInterface public devTeamContract;

    constructor (address _devTeam)
        public
    {
         
        devTeamContract = DevTeamInterface(_devTeam);
        devTeamContract.setBankAddress(address(this));
    }

     
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0,"already setup");
        f2mContract = F2mInterface(_contract[0]);
         
        citizenContract = CitizenInterface(_contract[2]);
        lotteryContract = LotteryInterface(_contract[3]);
    }

     

    function pushToBank(address _player)
        public
        payable
    {
        uint256 _amount = msg.value;
        lastClaim[_player] = block.timestamp;
        balance[_player] = _amount.add(balance[_player]);
    }

    function collectDividends(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = f2mContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectRef(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = citizenContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectReward(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = lotteryContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectIncome(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
         
        uint256 collected = collectDividends(_member) + collectRef(_member) + collectReward(_member);
        return collected;
    }

    function restTime(address _member)
        public
        view
        returns(uint256)
    {
        uint256 timeDist = block.timestamp - lastClaim[_member];
        if (timeDist >= TIME_OUT) return 0;
        return TIME_OUT - timeDist;
    }

    function timeout(address _member)
        public
        view
        returns(bool)
    {
        return lastClaim[_member] > 0 && restTime(_member) == 0;
    }

    function memberLog()
        private
    {
        address _member = msg.sender;
        lastClaim[_member] = block.timestamp;
        if (isMember[_member]) return;
        member.push(_member);
        isMember[_member] = true;
    }

    function cashoutable()
        public
        view
        returns(bool)
    {
        return lotteryContract.cashoutable(msg.sender);
    }

    function cashout()
        public
    {
        address _sender = msg.sender;
        uint256 _amount = balance[_sender];
        require(_amount > 0, "nothing to cashout");
        balance[_sender] = 0;
        memberLog();
        require(cashoutable() && _amount > 0, "need 1 ticket or wait to new round");
        _sender.transfer(_amount);
    }

     
     
     
    function checkTimeout(address _member)
        public
    {
        require(timeout(_member), "member still got time to withdraw");
        require(_member != address(devTeamContract), "no right");
        uint256 _curBalance = balance[_member];
        uint256 _refIncome = collectRef(_member);
        uint256 _divIncome = collectDividends(_member);
        uint256 _rewardIncome = collectReward(_member);
        donateSum[_member] += _refIncome + _divIncome + _rewardIncome;
        balance[_member] = _curBalance;
        f2mContract.pushDividends.value(_divIncome + _rewardIncome)();
        citizenContract.pushRefIncome.value(_refIncome)(0x0);
    }

    function withdraw() 
        public
    {
        address _member = msg.sender;
        collectIncome(_member);
        cashout();
         
    } 

    function lotteryReinvest(string _sSalt, uint256 _amount)
        public
        payable
    {
        address _sender = msg.sender;
        uint256 _deposit = msg.value;
        uint256 _curBalance = balance[_sender];
        uint256 investAmount;
        uint256 collected = 0;
        if (_deposit == 0) {
            if (_amount > balance[_sender]) 
                collected = collectIncome(_sender);
            require(_amount <= _curBalance + collected, "balance not enough");
            investAmount = _amount; 
        } else {
            collected = collectIncome(_sender);
            investAmount = _deposit.add(_curBalance).add(collected);
        }
        balance[_sender] = _curBalance.add(collected + _deposit).sub(investAmount);
        lastClaim [_sender] = block.timestamp;
        lotteryContract.buyFor.value(investAmount)(_sSalt, _sender);
    }

    function tokenReinvest(uint256 _amount) 
        public
        payable
    {
        address _sender = msg.sender;
        uint256 _deposit = msg.value;
        uint256 _curBalance = balance[_sender];
        uint256 investAmount;
        uint256 collected = 0;
        if (_deposit == 0) {
            if (_amount > balance[_sender]) 
                collected = collectIncome(_sender);
            require(_amount <= _curBalance + collected, "balance not enough");
            investAmount = _amount; 
        } else {
            collected = collectIncome(_sender);
            investAmount = _deposit.add(_curBalance).add(collected);
        }
        balance[_sender] = _curBalance.add(collected + _deposit).sub(investAmount);
        lastClaim [_sender] = block.timestamp;
        f2mContract.buyFor.value(investAmount)(_sender);
    }

     
    function getDivBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = f2mContract.ethBalance(_sender);
        return _amount;
    }

    function getEarlyIncomeBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = lotteryContract.getCurEarlyIncomeByAddress(_sender);
        return _amount;
    }

    function getRewardBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = lotteryContract.getRewardBalance(_sender);
        return _amount;
    }

    function getRefBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = citizenContract.getRefWallet(_sender);
        return _amount;
    }

    function getBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _sum = getUnclaimedBalance(_sender);
        return _sum + balance[_sender];
    }

    function getUnclaimedBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _sum = getDivBalance(_sender) + getRefBalance(_sender) + getRewardBalance(_sender) + getEarlyIncomeBalance(_sender);
        return _sum;
    }

    function getClaimedBalance(address _sender)
        public
        view
        returns(uint256)
    {
        return balance[_sender];
    }

    function getTotalMember() 
        public
        view
        returns(uint256)
    {
        return member.length;
    }
}


 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface F2mInterface {
    function joinNetwork(address[6] _contract) public;
     
     
    function activeBuy() public;
     
     
    function pushDividends() public payable;
     
    function buyFor(address _buyer) public payable;
    function sell(uint256 _tokenAmount) public;
    function exit() public;
    function devTeamWithdraw() public returns(uint256);
    function withdrawFor(address sender) public returns(uint256);
    function transfer(address _to, uint256 _tokenAmount) public returns(bool);
     
    function setAutoBuy() public;
     
    function ethBalance(address _address) public view returns(uint256);
    function myBalance() public view returns(uint256);
    function myEthBalance() public view returns(uint256);

    function swapToken() public;
    function setNewToken(address _newTokenAddress) public;
}

interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
     
    function devTeamWithdraw() public;

     
    function updateUsername(string _sNewUsername) public;
     
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

     
    function getRefWallet(address _address) public view returns(uint256);
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
     
    function activeFirstRound() public;
     
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
     
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
     
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
     
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
     
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    function getCurRoundId() public view returns(uint256);
     
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
    function sBountyClaim(address _sBountyHunter) public returns(uint256);
}

interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}