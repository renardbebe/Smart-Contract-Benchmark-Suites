 

pragma solidity ^0.4.25;

contract IStdToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
}

contract PoolCommon {
    
     
    mapping(address => bool) private _administrators;

     
    mapping(address => bool) private _managers;

    
    modifier onlyAdministrator() {
        require(_administrators[msg.sender]);
        _;
    }

    modifier onlyAdministratorOrManager() {
        require(_administrators[msg.sender] || _managers[msg.sender]);
        _;
    }
    
    constructor() public {
        _administrators[msg.sender] = true;
    }
    
    
    function addAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = true;
    }

    function removeAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = false;
    }

    function isAdministrator(address addr) public view returns (bool) {
        return _administrators[addr];
    }

    function addManager(address addr) onlyAdministrator public {
        _managers[addr] = true;
    }

    function removeManager(address addr) onlyAdministrator public {
        _managers[addr] = false;
    }
    
    function isManager(address addr) public view returns (bool) {
        return _managers[addr];
    }
}

contract PoolCore is PoolCommon {
    uint256 constant public MAGNITUDE = 2**64;

     
    uint256 public mntpRewardPerShare;
     
    uint256 public goldRewardPerShare;

     
    uint256 public totalMntpHeld;

     
    mapping(address => uint256) public _mntpRewardPerShare;   

     
    mapping(address => uint256) public _goldRewardPerShare;  

    address public controllerAddress = address(0x0);

    mapping(address => uint256) public _rewardMntpPayouts;
    mapping(address => uint256) public _rewardGoldPayouts;

    mapping(address => uint256) public _userStakes;

    IStdToken public mntpToken;
    IStdToken public goldToken;


    modifier onlyController() {
        require(controllerAddress == msg.sender);
        _;
    }
	
    constructor(address mntpTokenAddr, address goldTokenAddr) PoolCommon() public {
        controllerAddress = msg.sender;
        mntpToken = IStdToken(mntpTokenAddr);
        goldToken = IStdToken(goldTokenAddr);
    }
	
    function setNewControllerAddress(address newAddress) onlyController public {
        controllerAddress = newAddress;
    }
    
    function addHeldTokens(address userAddress, uint256 tokenAmount) onlyController public {
        _userStakes[userAddress] = SafeMath.add(_userStakes[userAddress], tokenAmount);
        totalMntpHeld = SafeMath.add(totalMntpHeld, tokenAmount);
        
        addUserPayouts(userAddress, SafeMath.mul(mntpRewardPerShare, tokenAmount), SafeMath.mul(goldRewardPerShare, tokenAmount));
    }
	
    function freeHeldTokens(address userAddress) onlyController public {
        totalMntpHeld = SafeMath.sub(totalMntpHeld, _userStakes[userAddress]);
		_userStakes[userAddress] = 0;
		_rewardMntpPayouts[userAddress] = 0;
        _rewardGoldPayouts[userAddress] = 0;
    }

    function addRewardPerShare(uint256 mntpReward, uint256 goldReward) onlyController public {
        require(totalMntpHeld > 0);

        uint256 mntpShareReward = SafeMath.div(SafeMath.mul(mntpReward, MAGNITUDE), totalMntpHeld);
        uint256 goldShareReward = SafeMath.div(SafeMath.mul(goldReward, MAGNITUDE), totalMntpHeld);

        mntpRewardPerShare = SafeMath.add(mntpRewardPerShare, mntpShareReward);
        goldRewardPerShare = SafeMath.add(goldRewardPerShare, goldShareReward);
    }  
    
    function addUserPayouts(address userAddress, uint256 mntpReward, uint256 goldReward) onlyController public {
        _rewardMntpPayouts[userAddress] = SafeMath.add(_rewardMntpPayouts[userAddress], mntpReward);
        _rewardGoldPayouts[userAddress] = SafeMath.add(_rewardGoldPayouts[userAddress], goldReward);
    }

    function getMntpTokenUserReward(address userAddress) public view returns(uint256 reward, uint256 rewardAmp) {  
        rewardAmp = SafeMath.mul(mntpRewardPerShare, getUserStake(userAddress));
        rewardAmp = (rewardAmp < getUserMntpRewardPayouts(userAddress)) ? 0 : SafeMath.sub(rewardAmp, getUserMntpRewardPayouts(userAddress));
        reward = SafeMath.div(rewardAmp, MAGNITUDE);
        
        return (reward, rewardAmp);
    }
    
    function getGoldTokenUserReward(address userAddress) public view returns(uint256 reward, uint256 rewardAmp) {  
        rewardAmp = SafeMath.mul(goldRewardPerShare, getUserStake(userAddress));
        rewardAmp = (rewardAmp < getUserGoldRewardPayouts(userAddress)) ? 0 : SafeMath.sub(rewardAmp, getUserGoldRewardPayouts(userAddress));
        reward = SafeMath.div(rewardAmp, MAGNITUDE);
        
        return (reward, rewardAmp);
    }
    
    function getUserMntpRewardPayouts(address userAddress) public view returns(uint256) {
        return _rewardMntpPayouts[userAddress];
    }    
    
    function getUserGoldRewardPayouts(address userAddress) public view returns(uint256) {
        return _rewardGoldPayouts[userAddress];
    }    
    
    function getUserStake(address userAddress) public view returns(uint256) {
        return _userStakes[userAddress];
    }    

}


contract GoldmintPool {

    address public tokenBankAddress = address(0x0);

    PoolCore public core;
    IStdToken public mntpToken;
    IStdToken public goldToken;

    bool public isActualContractVer = true;
    bool public isActive = true;
    
    event onDistribShareProfit(uint256 mntpReward, uint256 goldReward); 
    event onUserRewardWithdrawn(address indexed userAddress, uint256 mntpReward, uint256 goldReward);
    event onHoldStake(address indexed userAddress, uint256 mntpAmount);
    event onUnholdStake(address indexed userAddress, uint256 mntpAmount);

    modifier onlyAdministrator() {
        require(core.isAdministrator(msg.sender));
        _;
    }

    modifier onlyAdministratorOrManager() {
        require(core.isAdministrator(msg.sender) || core.isManager(msg.sender));
        _;
    }
    
    modifier notNullAddress(address addr) {
        require(addr != address(0x0));
        _;
    }
    
    modifier onlyActive() {
        require(isActive);
        _;
    }

    constructor(address coreAddr, address tokenBankAddr) notNullAddress(coreAddr) notNullAddress(tokenBankAddr) public { 
        core = PoolCore(coreAddr);
        mntpToken = core.mntpToken();
        goldToken = core.goldToken();
        
        tokenBankAddress = tokenBankAddr;
    }
    
    function setTokenBankAddress(address addr) onlyAdministrator notNullAddress(addr) public {
        tokenBankAddress = addr;
    }
    
    function switchActive() onlyAdministrator public {
        require(isActualContractVer);
        isActive = !isActive;
    }
    
    function holdStake(uint256 mntpAmount) onlyActive public {
        require(mntpToken.balanceOf(msg.sender) > 0);
        require(mntpToken.balanceOf(msg.sender) >= mntpAmount);
        
        mntpToken.transferFrom(msg.sender, address(this), mntpAmount);
        core.addHeldTokens(msg.sender, mntpAmount);
        
        emit onHoldStake(msg.sender, mntpAmount);
    }
    
    function unholdStake() onlyActive public {
        uint256 amount = core.getUserStake(msg.sender);
        
        require(amount > 0);
        require(getMntpBalance() >= amount);
		
        core.freeHeldTokens(msg.sender);
        mntpToken.transfer(msg.sender, amount);
        
        emit onUnholdStake(msg.sender, amount);
    }
    
    function distribShareProfit(uint256 mntpReward, uint256 goldReward) onlyActive onlyAdministratorOrManager public {
        if (mntpReward > 0) mntpToken.transferFrom(tokenBankAddress, address(this), mntpReward);
        if (goldReward > 0) goldToken.transferFrom(tokenBankAddress, address(this), goldReward);
        
        core.addRewardPerShare(mntpReward, goldReward);
        
        emit onDistribShareProfit(mntpReward, goldReward);
    }

    function withdrawUserReward() onlyActive public {
        uint256 mntpReward; uint256 mntpRewardAmp;
        uint256 goldReward; uint256 goldRewardAmp;

        (mntpReward, mntpRewardAmp) = core.getMntpTokenUserReward(msg.sender);
        (goldReward, goldRewardAmp) = core.getGoldTokenUserReward(msg.sender);

        require(getMntpBalance() >= mntpReward);
        require(getGoldBalance() >= goldReward);

        core.addUserPayouts(msg.sender, mntpRewardAmp, goldRewardAmp);
        
        if (mntpReward > 0) mntpToken.transfer(msg.sender, mntpReward);
        if (goldReward > 0) goldToken.transfer(msg.sender, goldReward);
        
        emit onUserRewardWithdrawn(msg.sender, mntpReward, goldReward);
    }
    
    function withdrawRewardAndUnholdStake() onlyActive public {
        withdrawUserReward();
        unholdStake();
    }
    
    function addRewadToStake() onlyActive public {
        uint256 mntpReward; uint256 mntpRewardAmp;
        
        (mntpReward, mntpRewardAmp) = core.getMntpTokenUserReward(msg.sender);
        
        require(mntpReward > 0);

        core.addUserPayouts(msg.sender, mntpRewardAmp, 0);
        core.addHeldTokens(msg.sender, mntpReward);
    }

     
    function migrateToNewControllerContract(address newControllerAddr) onlyAdministrator public {
        require(newControllerAddr != address(0x0) && isActualContractVer);
        
        isActive = false;

        core.setNewControllerAddress(newControllerAddr);

        uint256 mntpTokenAmount = getMntpBalance();
        uint256 goldTokenAmount = getGoldBalance();

        if (mntpTokenAmount > 0) mntpToken.transfer(newControllerAddr, mntpTokenAmount); 
        if (goldTokenAmount > 0) goldToken.transfer(newControllerAddr, goldTokenAmount); 

        isActualContractVer = false;
    }

    function getMntpTokenUserReward() public view returns(uint256) {  
        uint256 mntpReward; uint256 mntpRewardAmp;
        (mntpReward, mntpRewardAmp) = core.getMntpTokenUserReward(msg.sender);
        return mntpReward;
    }
    
    function getGoldTokenUserReward() public view returns(uint256) {  
        uint256 goldReward; uint256 goldRewardAmp;
        (goldReward, goldRewardAmp) = core.getGoldTokenUserReward(msg.sender);
        return goldReward;
    }
    
    function getUserMntpRewardPayouts() public view returns(uint256) {
        return core.getUserMntpRewardPayouts(msg.sender);
    }    
    
    function getUserGoldRewardPayouts() public view returns(uint256) {
        return core.getUserGoldRewardPayouts(msg.sender);
    }    
    
    function getUserStake() public view returns(uint256) {
        return core.getUserStake(msg.sender);
    } 

     

    function getMntpBalance() view public returns(uint256) {
        return mntpToken.balanceOf(address(this));
    }

    function getGoldBalance() view public returns(uint256) {
        return goldToken.balanceOf(address(this));
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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }   

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }   
}