 

pragma solidity ^0.4.24;

 

 
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

     
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

 

 

contract ILogger {
    function addNewLoggerPermission(address addressToPermission) public;
    function emitTaskCreated(uint uuid, uint amount) public;
    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public;
    function emitNewSmartToken(address token) public;
    function emitIssuance(uint256 amount) public;
    function emitDestruction(uint256 amount) public;
    function emitTransfer(address from, address to, uint256 value) public;
    function emitApproval(address owner, address spender, uint256 value) public;
    function emitGenericLog(string messageType, string message) public;
}

 

 
contract Logger is Owned, ILogger  {

     
    event TaskCreated(address msgSender, uint _uuid, uint _amount);
    event ProjectCreated(address msgSender, uint _uuid, uint _amount, address _address);

     
     
     
    event NewSmartToken(address msgSender, address _token);
     
    event Issuance(address msgSender, uint256 _amount);
     
    event Destruction(address msgSender, uint256 _amount);
     
    event Transfer(address msgSender, address indexed _from, address indexed _to, uint256 _value);
    event Approval(address msgSender, address indexed _owner, address indexed _spender, uint256 _value);

     
    event NewCommunityAddress(address msgSender, address _newAddress);

    event GenericLog(address msgSender, string messageType, string message);
    mapping (address => bool) public permissionedAddresses;

    modifier hasLoggerPermissions(address _address) {
        require(permissionedAddresses[_address] == true);
        _;
    }

    function addNewLoggerPermission(address addressToPermission) ownerOnly public {
        permissionedAddresses[addressToPermission] = true;
    }

    function emitTaskCreated(uint uuid, uint amount) public hasLoggerPermissions(msg.sender) {
        emit TaskCreated(msg.sender, uuid, amount);
    }

    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public hasLoggerPermissions(msg.sender) {
        emit ProjectCreated(msg.sender, uuid, amount, rewardAddress);
    }

    function emitNewSmartToken(address token) public hasLoggerPermissions(msg.sender) {
        emit NewSmartToken(msg.sender, token);
    }

    function emitIssuance(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Issuance(msg.sender, amount);
    }

    function emitDestruction(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Destruction(msg.sender, amount);
    }

    function emitTransfer(address from, address to, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Transfer(msg.sender, from, to, value);
    }

    function emitApproval(address owner, address spender, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Approval(msg.sender, owner, spender, value);
    }

    function emitGenericLog(string messageType, string message) public hasLoggerPermissions(msg.sender) {
        emit GenericLog(msg.sender, messageType, message);
    }
}

 

 
contract IERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 

 
contract ICommunityAccount is IOwned {
    function setStakedBalances(uint _amount, address msgSender) public;
    function setTotalStaked(uint _totalStaked) public;
    function setTimeStaked(uint _timeStaked, address msgSender) public;
    function setEscrowedTaskBalances(uint uuid, uint balance) public;
    function setEscrowedProjectBalances(uint uuid, uint balance) public;
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public;
    function setTotalTaskEscrow(uint balance) public;
    function setTotalProjectEscrow(uint balance) public;
}

 

 
contract CommunityAccount is Owned, ICommunityAccount {

     
    mapping (address => uint256) public stakedBalances;
    mapping (address => uint256) public timeStaked;
    uint public totalStaked;

     
    uint public totalTaskEscrow;
    uint public totalProjectEscrow;
    mapping (uint256 => uint256) public escrowedTaskBalances;
    mapping (uint256 => uint256) public escrowedProjectBalances;
    mapping (uint256 => address) public escrowedProjectPayees;
    
     
    function transferTokensOut(address tokenContractAddress, address destination, uint amount) public ownerOnly returns(bool result) {
        IERC20 token = IERC20(tokenContractAddress);
        return token.transfer(destination, amount);
    }

     
    function setStakedBalances(uint _amount, address msgSender) public ownerOnly {
        stakedBalances[msgSender] = _amount;
    }

     
    function setTotalStaked(uint _totalStaked) public ownerOnly {
        totalStaked = _totalStaked;
    }

     
    function setTimeStaked(uint _timeStaked, address msgSender) public ownerOnly {
        timeStaked[msgSender] = _timeStaked;
    }

     
    function setEscrowedTaskBalances(uint uuid, uint balance) public ownerOnly {
        escrowedTaskBalances[uuid] = balance;
    }

     
    function setEscrowedProjectBalances(uint uuid, uint balance) public ownerOnly {
        escrowedProjectBalances[uuid] = balance;
    }

     
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public ownerOnly {
        escrowedProjectPayees[uuid] = payeeAddress;
    }

     
    function setTotalTaskEscrow(uint balance) public ownerOnly {
        totalTaskEscrow = balance;
    }

     
    function setTotalProjectEscrow(uint balance) public ownerOnly {
        totalProjectEscrow = balance;
    }
}

 

 
contract ISmartToken is IOwned, IERC20 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

 
contract ICommunity {
    function transferCurator(address _curator) public;
    function transferVoteController(address _voteController) public;
    function setMinimumStakingRequirement(uint _minimumStakingRequirement) public;
    function setLockupPeriodSeconds(uint _lockupPeriodSeconds) public;
    function setLogger(address newLoggerAddress) public;
    function setTokenAddresses(address newNativeTokenAddress, address newCommunityTokenAddress) public;
    function setCommunityAccount(address newCommunityAccountAddress) public;
    function setCommunityAccountOwner(address newOwner) public;
    function getAvailableDevFund() public view returns (uint);
    function getLockedDevFundAmount() public view returns (uint);
    function createNewTask(uint uuid, uint amount) public;
    function cancelTask(uint uuid) public;
    function rewardTaskCompletion(uint uuid, address user) public;
    function createNewProject(uint uuid, uint amount, address projectPayee) public;
    function cancelProject(uint uuid) public;
    function rewardProjectCompletion(uint uuid) public;
    function stakeCommunityTokens() public;
    function unstakeCommunityTokens() public;
    function isMember(address memberAddress)public view returns (bool);
}

 

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

 

 
contract Community is ICommunity {

    address public curator;
    address public voteController;
    uint public minimumStakingRequirement;
    uint public lockupPeriodSeconds;
    ISmartToken public nativeTokenInstance;
    ISmartToken public communityTokenInstance;
    Logger public logger;
    CommunityAccount public communityAccount;

    modifier onlyCurator {
        require(msg.sender == curator);
        _;
    }

    modifier onlyVoteController {
        require(msg.sender == voteController);
        _;
    }

    modifier sufficientDevFundBalance (uint amount) {
        require(amount <= getAvailableDevFund());
        _;
    }

     
    constructor(uint _minimumStakingRequirement,
        uint _lockupPeriodSeconds,
        address _curator,
        address _communityTokenContractAddress,
        address _nativeTokenContractAddress,
        address _voteController,
        address _loggerContractAddress,
        address _communityAccountContractAddress) public {
        communityAccount = CommunityAccount(_communityAccountContractAddress);
        curator = _curator;
        minimumStakingRequirement = _minimumStakingRequirement;
        lockupPeriodSeconds = _lockupPeriodSeconds;
        logger = Logger(_loggerContractAddress);
        voteController = _voteController;
        nativeTokenInstance = ISmartToken(_nativeTokenContractAddress);
        communityTokenInstance = ISmartToken(_communityTokenContractAddress);
    }

     
     
    function transferCurator(address _curator) public onlyCurator {
        curator = _curator;
        logger.emitGenericLog("transferCurator", "");
    }

     
    function transferVoteController(address _voteController) public onlyCurator {
        voteController = _voteController;
        logger.emitGenericLog("transferVoteController", "");
    }

     
    function setMinimumStakingRequirement(uint _minimumStakingRequirement) public onlyCurator {
        minimumStakingRequirement = _minimumStakingRequirement;
        logger.emitGenericLog("setMinimumStakingRequirement", "");
    }

     
    function setLockupPeriodSeconds(uint _lockupPeriodSeconds) public onlyCurator {
        lockupPeriodSeconds = _lockupPeriodSeconds;
        logger.emitGenericLog("setLockupPeriodSeconds", "");
    }

     
    function setLogger(address newLoggerAddress) public onlyCurator {
        logger = Logger(newLoggerAddress);
        logger.emitGenericLog("setLogger", "");
    }

     
    function setTokenAddresses(address newNativeTokenAddress, address newCommunityTokenAddress) public onlyCurator {
        nativeTokenInstance = ISmartToken(newNativeTokenAddress);
        communityTokenInstance = ISmartToken(newCommunityTokenAddress);
        logger.emitGenericLog("setTokenAddresses", "");
    }

     
    function setCommunityAccount(address newCommunityAccountAddress) public onlyCurator {
        communityAccount = CommunityAccount(newCommunityAccountAddress);
        logger.emitGenericLog("setCommunityAccount", "");
    }

     
    function setCommunityAccountOwner(address newOwner) public onlyCurator {
        communityAccount.transferOwnershipNow(newOwner);
        logger.emitGenericLog("setCommunityAccountOwner", "");
    }

     
    function getAvailableDevFund() public view returns (uint) {
        uint devFundBalance = nativeTokenInstance.balanceOf(address(communityAccount));
        return SafeMath.sub(devFundBalance, getLockedDevFundAmount());
    }

     
    function getLockedDevFundAmount() public view returns (uint) {
        return SafeMath.add(communityAccount.totalTaskEscrow(), communityAccount.totalProjectEscrow());
    }

     

     
    function createNewTask(uint uuid, uint amount) public onlyCurator sufficientDevFundBalance (amount) {
        communityAccount.setEscrowedTaskBalances(uuid, amount);
        communityAccount.setTotalTaskEscrow(SafeMath.add(communityAccount.totalTaskEscrow(), amount));
        logger.emitTaskCreated(uuid, amount);
        logger.emitGenericLog("createNewTask", "");
    }

     
    function cancelTask(uint uuid) public onlyCurator {
        communityAccount.setTotalTaskEscrow(SafeMath.sub(communityAccount.totalTaskEscrow(), communityAccount.escrowedTaskBalances(uuid)));
        communityAccount.setEscrowedTaskBalances(uuid, 0);
        logger.emitGenericLog("cancelTask", "");
    }

     
    function rewardTaskCompletion(uint uuid, address user) public onlyVoteController {
        communityAccount.transferTokensOut(address(nativeTokenInstance), user, communityAccount.escrowedTaskBalances(uuid));
        communityAccount.setTotalTaskEscrow(SafeMath.sub(communityAccount.totalTaskEscrow(), communityAccount.escrowedTaskBalances(uuid)));
        communityAccount.setEscrowedTaskBalances(uuid, 0);
        logger.emitGenericLog("rewardTaskCompletion", "");
    }

     

     
    function createNewProject(uint uuid, uint amount, address projectPayee) public onlyCurator sufficientDevFundBalance (amount) {
        communityAccount.setEscrowedProjectBalances(uuid, amount);
        communityAccount.setEscrowedProjectPayees(uuid, projectPayee);
        communityAccount.setTotalProjectEscrow(SafeMath.add(communityAccount.totalProjectEscrow(), amount));
        logger.emitProjectCreated(uuid, amount, projectPayee);
        logger.emitGenericLog("createNewProject", "");
    }

     
    function cancelProject(uint uuid) public onlyCurator {
        communityAccount.setTotalProjectEscrow(SafeMath.sub(communityAccount.totalProjectEscrow(), communityAccount.escrowedProjectBalances(uuid)));
        communityAccount.setEscrowedProjectBalances(uuid, 0);
        logger.emitGenericLog("cancelProject", "");
    }

     
     
    function rewardProjectCompletion(uint uuid) public onlyVoteController {
        communityAccount.transferTokensOut(
            address(nativeTokenInstance),
            communityAccount.escrowedProjectPayees(uuid),
            communityAccount.escrowedProjectBalances(uuid));
        communityAccount.setTotalProjectEscrow(SafeMath.sub(communityAccount.totalProjectEscrow(), communityAccount.escrowedProjectBalances(uuid)));
        communityAccount.setEscrowedProjectBalances(uuid, 0);
        logger.emitGenericLog("rewardProjectCompletion", "");
    }

     
    function stakeCommunityTokens() public {

        require(minimumStakingRequirement >= communityAccount.stakedBalances(msg.sender));

        uint amount = minimumStakingRequirement - communityAccount.stakedBalances(msg.sender);
        require(amount > 0);
        require(communityTokenInstance.transferFrom(msg.sender, address(communityAccount), amount));

        communityAccount.setStakedBalances(SafeMath.add(communityAccount.stakedBalances(msg.sender), amount), msg.sender);
        communityAccount.setTotalStaked(SafeMath.add(communityAccount.totalStaked(), amount));
        communityAccount.setTimeStaked(now, msg.sender);
        logger.emitGenericLog("stakeCommunityTokens", "");
    }

     
     
    function unstakeCommunityTokens() public {
        uint amount = communityAccount.stakedBalances(msg.sender);

        require(now - communityAccount.timeStaked(msg.sender) >= lockupPeriodSeconds);

        communityAccount.setStakedBalances(0, msg.sender);
        communityAccount.setTotalStaked(SafeMath.sub(communityAccount.totalStaked(), amount));
        require(communityAccount.transferTokensOut(address(communityTokenInstance), msg.sender, amount));
        logger.emitGenericLog("unstakeCommunityTokens", "");
    }

     
    function isMember(address memberAddress) public view returns (bool) {
        return (communityAccount.stakedBalances(memberAddress) >= minimumStakingRequirement);
    }
}