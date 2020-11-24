 

pragma solidity 0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function getMaxTotalSupply() public view returns (uint256);
    function mint(address _to, uint256 _amount) public returns (bool);
    function transfer(address _to, uint256 _amount) public returns (bool);

    function allowance(
        address _who,
        address _spender
    )
        public
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool);
}


contract MiningTokenInterface {
    function multiMint(address _to, uint256 _amount) external;
    function getTokenTime(uint256 _tokenId) external returns(uint256);
    function mint(address _to, uint256 _id) external;
    function ownerOf(uint256 _tokenId) public view returns (address);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function tokenByIndex(uint256 _index) public view returns (uint256);

    function arrayOfTokensByAddress(address _holder)
        public
        view
        returns(uint256[]);

    function getTokensCount(address _owner) public returns(uint256);

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);
}


contract Management {
    using SafeMath for uint256;

    uint256 public startPriceForHLPMT = 10000;
    uint256 public maxHLPMTMarkup = 40000;
    uint256 public stepForPrice = 1000;

    uint256 public startTime;
    uint256 public lastMiningTime;

     
    uint256 public decimals = 18;

    TokenInterface public token;
    MiningTokenInterface public miningToken;

    address public dao;
    address public fund;
    address public owner;

     
    uint256 public numOfMiningTimes;

    mapping(address => uint256) public payments;
    mapping(address => uint256) public paymentsTimestamps;

     
    mapping(uint256 => uint256) internal miningReward;

     
    mapping(uint256 => uint256) internal lastGettingReward;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao);
        _;
    }

    constructor(
        address _token,
        address _miningToken,
        address _dao,
        address _fund
    )
        public
    {
        require(_token != address(0));
        require(_miningToken != address(0));
        require(_dao != address(0));
        require(_fund != address(0));

        startTime = now;
        lastMiningTime = startTime - (startTime % (1 days)) - 1 days;
        owner = msg.sender;

        token = TokenInterface(_token);
        miningToken = MiningTokenInterface(_miningToken);
        dao = _dao;
        fund = _fund;
    }

     
    function buyHLPMT() external {

        uint256 _currentTime = now;
        uint256 _allowed = token.allowance(msg.sender, address(this));
        uint256 _currentPrice = getPrice(_currentTime);
        require(_allowed >= _currentPrice);

         
        uint256 _hlpmtAmount = _allowed.div(_currentPrice);
        _allowed = _hlpmtAmount.mul(_currentPrice);

        require(token.transferFrom(msg.sender, fund, _allowed));

        for (uint256 i = 0; i < _hlpmtAmount; i++) {
            uint256 _id = miningToken.totalSupply();
            miningToken.mint(msg.sender, _id);
            lastGettingReward[_id] = numOfMiningTimes;
        }
    }

     
    function mining() external {

        uint256 _currentTime = now;
        require(_currentTime > _getEndOfLastMiningDay());


        uint256 _missedDays = (_currentTime - lastMiningTime) / (1 days);

        updateLastMiningTime(_currentTime);

        for (uint256 i = 0; i < _missedDays; i++) {
             
            uint256 _dailyTokens = token.getMaxTotalSupply().sub(token.totalSupply()).div(1000);

            uint256 _tokensToDao = _dailyTokens.mul(3).div(10);  
            token.mint(dao, _tokensToDao);

            uint256 _tokensToFund = _dailyTokens.mul(3).div(10);  
            token.mint(fund, _tokensToFund);

            uint256 _miningTokenSupply = miningToken.totalSupply();
            uint256 _tokensToMiners = _dailyTokens.mul(4).div(10);  
            uint256 _tokensPerMiningToken = _tokensToMiners.div(_miningTokenSupply);

            miningReward[++numOfMiningTimes] = _tokensPerMiningToken;

            token.mint(address(this), _tokensToMiners);
        }
    }

     
    function getReward(uint256[] tokensForReward) external {
        uint256 _rewardAmount = 0;
        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (
                msg.sender == miningToken.ownerOf(tokensForReward[i]) &&
                numOfMiningTimes > getLastRewardTime(tokensForReward[i])
            ) {
                _rewardAmount += _calculateReward(tokensForReward[i]);
                setLastRewardTime(tokensForReward[i], numOfMiningTimes);
            }
        }

        require(_rewardAmount > 0);
        token.transfer(msg.sender, _rewardAmount);
    }

    function checkReward(uint256[] tokensForReward) external view returns (uint256) {
        uint256 reward = 0;

        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (numOfMiningTimes > getLastRewardTime(tokensForReward[i])) {
                reward += _calculateReward(tokensForReward[i]);
            }
        }

        return reward;
    }

     
    function getLastRewardTime(uint256 _tokenId) public view returns(uint256) {
        return lastGettingReward[_tokenId];
    }

     
    function sendReward(uint256[] tokensForReward) public onlyOwner {
        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (numOfMiningTimes > getLastRewardTime(tokensForReward[i])) {
                uint256 reward = _calculateReward(tokensForReward[i]);
                setLastRewardTime(tokensForReward[i], numOfMiningTimes);
                token.transfer(miningToken.ownerOf(tokensForReward[i]), reward);
            }
        }
    }

     
    function miningTokensOf(address holder) public view returns (uint256[]) {
        return miningToken.arrayOfTokensByAddress(holder);
    }

     
    function setDao(address _dao) public onlyOwner {
        require(_dao != address(0));
        dao = _dao;
    }

     
    function setFund(address _fund) public onlyOwner {
        require(_fund != address(0));
        fund = _fund;
    }

     
    function setToken(address _token) public onlyOwner {
        require(_token != address(0));
        token = TokenInterface(_token);
    }

     
    function setMiningToken(address _miningToken) public onlyOwner {
        require(_miningToken != address(0));
        miningToken = MiningTokenInterface(_miningToken);
    }

     
    function getPrice(uint256 _timestamp) public view returns(uint256) {
        uint256 _raising = _timestamp.sub(startTime).div(30 days);
        _raising = _raising.mul(stepForPrice);
        if (_raising > maxHLPMTMarkup) _raising = maxHLPMTMarkup;
        return (startPriceForHLPMT + _raising) * 10 ** 18;
    }

     
    function getMiningReward(uint256 _numOfMiningTime) public view returns (uint256) {
        return miningReward[_numOfMiningTime];
    }

     
    function _calculateReward(uint256 tokenID)
        internal
        view
        returns (uint256 reward)
    {
        for (uint256 i = getLastRewardTime(tokenID) + 1; i <= numOfMiningTimes; i++) {
            reward += miningReward[i];
        }
        return reward;
    }

     
    function setLastRewardTime(uint256 _tokenId, uint256 _num) internal {
        lastGettingReward[_tokenId] = _num;
    }

     
    function updateLastMiningTime(uint256 _currentTime) internal {
        lastMiningTime = _currentTime - _currentTime % (1 days);
    }

     
    function _getEndOfLastMiningDay() internal view returns(uint256) {
        return lastMiningTime + 1 days;
    }

     
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];
        uint256 timestamp = paymentsTimestamps[payee];

        require(payment != 0);
        require(now >= timestamp);

        payments[payee] = 0;

        require(token.transfer(msg.sender, payment));
    }

     
    function asyncSend(address _dest, uint256 _amount, uint256 _timestamp) external onlyDao {
        payments[_dest] = payments[_dest].add(_amount);
        paymentsTimestamps[_dest] = _timestamp;
        require(token.transferFrom(dao, address(this), _amount));
    }
}