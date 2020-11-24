 

pragma solidity ^0.4.23;


 
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
        require(msg.sender == owner, "Only owner is allowed for this operation.");
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
        require(_newOwner != address(0), "Cannot transfer ownership to an empty user.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ANKRTokenVault is Ownable {
    using SafeMath for uint256;

     

     
    address public opentokenAddress           = 0x7B1f5F0FCa6434D7b01161552D335A774706b650;
    address public tokenmanAddress            = 0xBB46219183f1F17364914e353A44F982de77eeC8;

     
    address public marketingAddress           = 0xc2e96F45232134dD32B6DF4D51AC82248CA942cc;

     
    address public teamReserveWallet          = 0x0AA7Aa665276A96acD25329354FeEa8F955CAf2b;
    address public communityReserveWallet     = 0xeFA1f626670445271359940e1aC346Ac374019E7;

     
    uint256 public opentokenAllocation            = 0.5 * (10 ** 9) * (10 ** 18);
    uint256 public tokenmanAllocation             = 0.2 * (10 ** 9) * (10 ** 18);
    uint256 public marketingAllocation            = 0.5 * (10 ** 9) * (10 ** 18);
    uint256 public teamReserveAllocation          = 2.0 * (10 ** 9) * (10 ** 18);
    uint256 public communityReserveAllocation     = 4.0 * (10 ** 9) * (10 ** 18);

     
    uint256 public totalAllocation = 10 * (10 ** 9) * (10 ** 18);

    uint256 public investorTimeLock = 183 days;  
    uint256 public othersTimeLock = 3 * 365 days;
     
    uint256 public othersVestingStages = 3 * 12;

     
     

     
    mapping(address => uint256) public allocations;

     
    mapping(address => uint256) public timeLocks;

     
    mapping(address => uint256) public claimed;

     
    mapping(address => uint256) public lockedInvestors;
    address[] public lockedInvestorsIndices;

     
    mapping(address => uint256) public unLockedInvestors;
    address[] public unLockedInvestorsIndices;

     
    uint256 public lockedAt = 0;

    ERC20Basic public token;

     
    event Allocated(address wallet, uint256 value);

     
    event Distributed(address wallet, uint256 value);

     
    event Locked(uint256 lockTime);

     
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0, "There should be non-zero allocation.");
        _;
    }

     
     
     
     
     
     
     
     

     
    modifier notLocked {
        require(lockedAt == 0, "lockedAt should be zero.");
        _;
    }

    modifier locked {
        require(lockedAt > 0, "lockedAt should be larger than zero.");
        _;
    }

     
    modifier notAllocated {
        require(allocations[opentokenAddress] == 0, "Allocation should be zero.");
        require(allocations[tokenmanAddress] == 0, "Allocation should be zero.");
        require(allocations[marketingAddress] == 0, "Allocation should be zero.");
        require(allocations[teamReserveWallet] == 0, "Allocation should be zero.");
        require(allocations[communityReserveWallet] == 0, "Allocation should be zero.");
        _;
    }

    constructor(ERC20Basic _token) public {
        token = ERC20Basic(_token);
    }

    function addUnlockedInvestor(address investor, uint256 amt) public onlyOwner notLocked notAllocated returns (bool) {
        require(investor != address(0), "Unlocked investor must not be zero.");
        require(amt > 0, "Unlocked investor's amount should be larger than zero.");
        unLockedInvestorsIndices.push(investor);
        unLockedInvestors[investor] = amt * (10 ** 18);
        return true;
    }

    function addLockedInvestor(address investor, uint256 amt) public onlyOwner notLocked notAllocated returns (bool) {
        require(investor != address(0), "Locked investor must not be zero.");
        require(amt > 0, "Locked investor's amount should be larger than zero.");
        lockedInvestorsIndices.push(investor);
        lockedInvestors[investor] = amt * (10 ** 18);
        return true;
    }

    function allocate() public notLocked notAllocated onlyOwner {

         
        require(token.balanceOf(address(this)) == totalAllocation, "Token should not be allocated yet.");

        allocations[opentokenAddress] = opentokenAllocation;
        allocations[tokenmanAddress] = tokenmanAllocation;
        allocations[marketingAddress] = marketingAllocation;
        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[communityReserveWallet] = communityReserveAllocation;

        emit Allocated(opentokenAddress, opentokenAllocation);
        emit Allocated(tokenmanAddress, tokenmanAllocation);
        emit Allocated(marketingAddress, marketingAllocation);
        emit Allocated(teamReserveWallet, teamReserveAllocation);
        emit Allocated(communityReserveWallet, communityReserveAllocation);

        address cur;
        uint arrayLength;
        uint i;
        arrayLength = unLockedInvestorsIndices.length;
        for (i = 0; i < arrayLength; i++) {
            cur = unLockedInvestorsIndices[i];
            allocations[cur] = unLockedInvestors[cur];
            emit Allocated(cur, unLockedInvestors[cur]);
        }
        arrayLength = lockedInvestorsIndices.length;
        for (i = 0; i < arrayLength; i++) {
            cur = lockedInvestorsIndices[i];
            allocations[cur] = lockedInvestors[cur];
            emit Allocated(cur, lockedInvestors[cur]);
        }

         
        preDistribute();
    }

    function distribute() public notLocked onlyOwner {
        claimTokenReserve(marketingAddress);
        
        uint arrayLength;
        uint i;
        arrayLength = unLockedInvestorsIndices.length;
        for (i = 0; i < arrayLength; i++) {
            claimTokenReserve(unLockedInvestorsIndices[i]);
        }
        lock();
    }

     
    function lock() internal {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = lockedAt.add(othersTimeLock);
        timeLocks[communityReserveWallet] = lockedAt.add(othersTimeLock);

        emit Locked(lockedAt);
    }

     
     
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

         
        require(token.transfer(owner, token.balanceOf(address(this))), "recoverFailedLock: token transfer failed!");
    }

     
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

     
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

     
    function preDistribute() internal {
        claimTokenReserve(opentokenAddress);
        claimTokenReserve(tokenmanAddress);
    }

     
    function claimTokenReserve(address reserveWallet) internal {
         
        require(allocations[reserveWallet] > 0, "There should be non-zero allocation.");
        require(claimed[reserveWallet] == 0, "This address should be never claimed before.");

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(reserveWallet, amount), "Token transfer failed");

        emit Distributed(reserveWallet, amount);
    }

     
    function distributeInvestorsReserve() onlyOwner locked public {
        require(block.timestamp.sub(lockedAt) > investorTimeLock, "Still in locking period.");

        uint arrayLength;
        uint i;
        
        arrayLength = lockedInvestorsIndices.length;
        for (i = 0; i < arrayLength; i++) {
            claimTokenReserve(lockedInvestorsIndices[i]);
        }
    }

     
     
    function claimNonInvestorReserve() public onlyOwner locked {
        uint256 vestingStage = nonInvestorVestingStage();

         
        uint256 totalUnlockedTeam = vestingStage.mul(allocations[teamReserveWallet]).div(othersVestingStages);
        uint256 totalUnlockedComm = vestingStage.mul(allocations[communityReserveWallet]).div(othersVestingStages);

         
        require(claimed[teamReserveWallet] < totalUnlockedTeam, "Team's claimed tokens must be less than what is unlocked");
        require(claimed[communityReserveWallet] < totalUnlockedComm, "Community's claimed tokens must be less than what is unlocked");

        uint256 paymentTeam = totalUnlockedTeam.sub(claimed[teamReserveWallet]);
        uint256 paymentComm = totalUnlockedComm.sub(claimed[communityReserveWallet]);

        claimed[teamReserveWallet] = totalUnlockedTeam;
        claimed[communityReserveWallet] = totalUnlockedComm;

        require(token.transfer(teamReserveWallet, paymentTeam), "Team token transfer failed.");
        require(token.transfer(communityReserveWallet, paymentComm), "Community token transfer failed.");

        emit Distributed(teamReserveWallet, paymentTeam);
        emit Distributed(communityReserveWallet, paymentComm);
    }

     
    function nonInvestorVestingStage() public view returns(uint256){

         
        uint256 vestingMonths = othersTimeLock.div(othersVestingStages);

        uint256 stage = (block.timestamp.sub(lockedAt).sub(investorTimeLock)).div(vestingMonths);

         
        if(stage > othersVestingStages){
            stage = othersVestingStages;
        }

        return stage;

    }
}