 

pragma solidity ^0.5.10;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract COORole {
    using Roles for Roles.Role;

    event COOAdded(address indexed account);
    event COORemoved(address indexed account);

    Roles.Role private _COOs;

    constructor () internal {
        _addCOO(msg.sender);
    }

    modifier onlyCOO() {
        require(isCOO(msg.sender));
        _;
    }

    function isCOO(address account) public view returns (bool) {
        return _COOs.has(account);
    }

    function addCOO(address account) public onlyCOO {
        _addCOO(account);
    }

    function renounceCOO() public {
        _removeCOO(msg.sender);
    }

    function _addCOO(address account) internal {
        _COOs.add(account);
        emit COOAdded(account);
    }

    function _removeCOO(address account) internal {
        _COOs.remove(account);
        emit COORemoved(account);
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
 
 
contract KittyBountiesAdmin is Ownable, Pausable, ReentrancyGuard, COORole {

     
     
     

     
     
     
    event SuccessfulBountyFeeInBasisPointsUpdated(uint256 newSuccessfulBountyFeeInBasisPoints);

     
     
     
     
     
    event UnsuccessfulBountyFeeInWCKWeiUpdated(uint256 newUnsuccessfulBountyFeeInWCKWei);

     
     
     

     
     
    mapping (address => uint256) public addressToFeeEarnings;

     
     
     
    uint256 public successfulBountyFeeInBasisPoints = 375;

     
     
    uint256 public unsuccessfulBountyFeeInWCKWei = 1000000000000000000;

     
     
     

     
     
     
     
    address public kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    KittyCore kittyCore;

     
     
     
    address public wrappedKittiesAddress = 0x09fE5f0236F0Ea5D930197DCE254d77B04128075;

     
     
     

     
     
    constructor() internal {
        kittyCore = KittyCore(kittyCoreAddress);
    }

     
     
     
     
     
    function setSuccessfulBountyFeeInBasisPoints(uint256 _newSuccessfulBountyFeeInBasisPoints) external onlyOwner {
        require(_newSuccessfulBountyFeeInBasisPoints <= 10000, 'new successful bounty fee must be in basis points (hundredths of a percent), not wei');
        successfulBountyFeeInBasisPoints = _newSuccessfulBountyFeeInBasisPoints;
        emit SuccessfulBountyFeeInBasisPointsUpdated(_newSuccessfulBountyFeeInBasisPoints);
    }

     
     
     
     
    function setUnsuccessfulBountyFeeInWCKWei(uint256 _newUnsuccessfulBountyFeeInWCKWei) external onlyOwner {
        unsuccessfulBountyFeeInWCKWei = _newUnsuccessfulBountyFeeInWCKWei;
        emit UnsuccessfulBountyFeeInWCKWeiUpdated(_newUnsuccessfulBountyFeeInWCKWei);
    }

     
     
    function withdrawFeeEarningsForAddress() external nonReentrant {
        uint256 balance = addressToFeeEarnings[msg.sender];
        require(balance > 0, 'there are no fees to withdraw for this address');
        addressToFeeEarnings[msg.sender] = 0;
        require(ERC20(wrappedKittiesAddress).transfer(msg.sender, balance) == true, 'failed to transfer WCK');
    }

     
     
     
     
    function removePauser(address _account) external onlyOwner {
        _removePauser(_account);
    }

     
     
     
    function removeCOO(address _account) external onlyOwner {
        _removeCOO(_account);
    }

     
    function() external payable {
        revert();
    }
}

contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

 
contract KittyCore {
    function getKitty(uint _id) public returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    mapping (uint256 => address) public kittyIndexToApproved;
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract KittyBounties is KittyBountiesAdmin {

     
    using SafeMath for uint256;

	 
     
     

     
     
	struct Bounty {
		 
		 
         
         
         
		uint256 geneMask;
         
         
         
         
         
        uint256 genes;
         
         
         
         
         
        uint128 earliestAcceptableIdInclusive;
         
         
         
         
         
        uint128 latestAcceptableIdInclusive;
		 
		uint128 bountyPricePerCat;
		 
         
		uint128 totalValueIncludingFees;
		 
         
         
         
		uint128 unsuccessfulBountyFeeInWCKWei;
		 
         
         
         
         
         
		uint32 minBlockBountyValidUntil;
         
         
        uint32 quantity;
         
         
         
        uint16 generation;
		 
         
         
         
         
        uint16 highestCooldownIndexAccepted;
         
         
		address bidder;
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event CreateBountyAndLockFunds(
    	uint256 bountyId,
        address bidder,
		uint256 bountyPricePerCat,
		uint256 minBlockBountyValidUntil,
        uint256 quantity,
        uint256 geneMask,
        uint256 genes,
        uint256 earliestAcceptableIdInclusive,
        uint256 latestAcceptableIdInclusive,
        uint256 generation,
        uint256 highestCooldownIndexAccepted,
        uint256 unsuccessfulBountyFeeInWCKWei
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event FulfillBountyAndClaimFunds(
        uint256 bountyId,
        uint256 kittyId,
        address bountyHunter,
		uint256 bountyPricePerCat,
        uint256 geneMask,
        uint256 genes,
        uint256 earliestAcceptableIdInclusive,
        uint256 latestAcceptableIdInclusive,
        uint256 generation,
        uint256 highestCooldownIndexAccepted,
        uint256 successfulBountyFeeInWCKWei
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event WithdrawBounty(
        uint256 bountyId,
        address bidder,
		uint256 withdrawnAmount
    );

     
     
     

     
     
    uint256 public bountyId = 0;

     
     
     
    mapping (uint256 => Bounty) public bountyIdToBounty;

     
     
    mapping (uint256 => uint256) public numCatsRemainingForBountyId;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createBountyAndLockFunds(uint256 _geneMask, uint256 _genes, uint256 _earliestAcceptableIdInclusive, uint256 _latestAcceptableIdInclusive, uint256 _generation, uint256 _highestCooldownIndexAccepted, uint256 _minNumBlocksBountyIsValidFor, uint256 _quantity, uint256 _totalAmountOfWCKToLock) external whenNotPaused {
        require(_totalAmountOfWCKToLock >= unsuccessfulBountyFeeInWCKWei.mul(uint256(2)), 'the value of your bounty must be at least twice as large as the unsuccessful bounty fee');
        require(_highestCooldownIndexAccepted <= uint256(13), 'you cannot specify an invalid cooldown index');
        require(_generation <= uint256(~uint16(0)), 'you cannot specify an invalid generation');
        require(_genes & ~_geneMask == uint256(0), 'your geneMask must fully cover any genes that you are seeking');
        require(_quantity > 0, 'your bounty must be for at least one cat');
        require(_quantity <= uint256(~uint32(0)), 'you cannot specify quantity greater than uint32_max');
        require(_earliestAcceptableIdInclusive <= _latestAcceptableIdInclusive, 'you cannot specify a negative range');
        require(_earliestAcceptableIdInclusive <= uint256(~uint128(0)), 'you cannot specify an earliestID greater than uint128_max');
        require(_latestAcceptableIdInclusive <= uint256(~uint128(0)), 'you cannot specify a latestID greater than uint128_max');

        require(ERC20(wrappedKittiesAddress).transferFrom(msg.sender, address(this), _totalAmountOfWCKToLock) == true, 'failed to transfer WCK from account of sender');

        uint256 totalValueIncludingFeesPerCat = _totalAmountOfWCKToLock.div(_quantity);
        uint256 bountyPricePerCat = _computeBountyPrice(totalValueIncludingFeesPerCat, successfulBountyFeeInBasisPoints);
        uint256 minBlockBountyValidUntil = uint256(block.number).add(_minNumBlocksBountyIsValidFor);

        Bounty memory bounty = Bounty({
            geneMask: _geneMask,
            genes: _genes,
            earliestAcceptableIdInclusive: uint128(_earliestAcceptableIdInclusive),
            latestAcceptableIdInclusive: uint128(_latestAcceptableIdInclusive),
            bountyPricePerCat: uint128(bountyPricePerCat),
            totalValueIncludingFees: uint128(_totalAmountOfWCKToLock),
            unsuccessfulBountyFeeInWCKWei: uint128(unsuccessfulBountyFeeInWCKWei),
            minBlockBountyValidUntil: uint32(minBlockBountyValidUntil),
            quantity: uint32(_quantity),
            generation: uint16(_generation),
            highestCooldownIndexAccepted: uint16(_highestCooldownIndexAccepted),
            bidder: msg.sender
        });

        bountyIdToBounty[bountyId] = bounty;
        numCatsRemainingForBountyId[bountyId] = _quantity;

        emit CreateBountyAndLockFunds(
            bountyId,
            msg.sender,
            bountyPricePerCat,
            minBlockBountyValidUntil,
            _quantity,
            bounty.geneMask,
            bounty.genes,
            uint256(bounty.earliestAcceptableIdInclusive),
            uint256(bounty.latestAcceptableIdInclusive),
            uint256(bounty.generation),
            uint256(bounty.highestCooldownIndexAccepted),
            uint256(bounty.unsuccessfulBountyFeeInWCKWei)
        );

        bountyId = bountyId.add(uint256(1));
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function fulfillBountyAndClaimFunds(uint256 _bountyId, uint256 _kittyId, address _referrer) external whenNotPaused nonReentrant {
    	address ownerOfCatBeingUsedToFulfillBounty = kittyCore.ownerOf(_kittyId);
        require(numCatsRemainingForBountyId[_bountyId] > 0, 'this bounty has either already completed or has not yet begun');
    	require(msg.sender == ownerOfCatBeingUsedToFulfillBounty || isCOO(msg.sender), 'you either do not own the cat or are not authorized to fulfill on behalf of others');
    	require(kittyCore.kittyIndexToApproved(_kittyId) == address(this), 'you must approve() the bounties contract to give it permission to withdraw this cat before you can fulfill the bounty');

    	Bounty storage bounty = bountyIdToBounty[_bountyId];
    	uint256 cooldownIndex;
    	uint256 generation;
    	uint256 genes;
        ( , , cooldownIndex, , , , , , generation, genes) = kittyCore.getKitty(_kittyId);

         
    	 
        require(uint128(_kittyId) >= uint128(bounty.earliestAcceptableIdInclusive), 'your cat has an id that is too low to fulfill this bounty');
         
    	 
        require(uint128(_kittyId) <= uint128(bounty.latestAcceptableIdInclusive), 'your cat has an id that is too high to fulfill this bounty');
         
    	require((uint16(bounty.generation) == ~uint16(0) || uint16(generation) == uint16(bounty.generation)), 'your cat is not the correct generation to fulfill this bounty');
    	 
    	 
    	require((genes & bounty.geneMask) == (bounty.genes & bounty.geneMask), 'your cat does not have the correct genes to fulfill this bounty');
    	 
    	 
    	require(uint16(cooldownIndex) <= uint16(bounty.highestCooldownIndexAccepted), 'your cat does not have a low enough cooldown index to fulfill this bounty');

    	numCatsRemainingForBountyId[_bountyId] = numCatsRemainingForBountyId[_bountyId].sub(uint256(1));

    	kittyCore.transferFrom(ownerOfCatBeingUsedToFulfillBounty, bounty.bidder, _kittyId);

        uint256 totalValueIncludingFeesPerCat = uint256(bounty.totalValueIncludingFees).div(uint256(bounty.quantity));
        uint256 successfulBountyFeeInWCKWei = totalValueIncludingFeesPerCat.sub(uint256(bounty.bountyPricePerCat));
        if(_referrer != address(0)){
            uint256 halfOfFees = successfulBountyFeeInWCKWei.div(uint256(2));
            addressToFeeEarnings[_referrer] = addressToFeeEarnings[_referrer].add(halfOfFees);
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(halfOfFees);
        } else {
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(successfulBountyFeeInWCKWei);
        }

        require(ERC20(wrappedKittiesAddress).transfer(ownerOfCatBeingUsedToFulfillBounty, uint256(bounty.bountyPricePerCat)) == true, 'failed to transfer WCK');

    	emit FulfillBountyAndClaimFunds(
            _bountyId,
            _kittyId,
	        ownerOfCatBeingUsedToFulfillBounty,
			uint256(bounty.bountyPricePerCat),
	        bounty.geneMask,
	        bounty.genes,
            uint256(bounty.earliestAcceptableIdInclusive),
            uint256(bounty.latestAcceptableIdInclusive),
	        uint256(bounty.generation),
	        uint256(bounty.highestCooldownIndexAccepted),
	        successfulBountyFeeInWCKWei
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function withdrawUnsuccessfulBounty(uint256 _bountyId, address _referrer) external whenNotPaused nonReentrant {
    	require(numCatsRemainingForBountyId[_bountyId] > 0, 'this bounty has either already completed or has not yet begun');
    	Bounty storage bounty = bountyIdToBounty[_bountyId];
    	require(msg.sender == bounty.bidder, 'you cannot withdraw the funds for someone elses bounty');
    	require(block.number >= uint256(bounty.minBlockBountyValidUntil), 'this bounty is not withdrawable until the minimum number of blocks that were originally specified have passed');

        uint256 totalValueIncludingFeesPerCat = uint256(bounty.totalValueIncludingFees).div(uint256(bounty.quantity));
        uint256 totalValueRemainingForBountyId = totalValueIncludingFeesPerCat.mul(numCatsRemainingForBountyId[_bountyId]);

        numCatsRemainingForBountyId[_bountyId] = 0;

        uint256 amountToReturnToBountyCreator;
        uint256 amountToTakeAsFees;

        if(totalValueRemainingForBountyId < bounty.unsuccessfulBountyFeeInWCKWei){
            amountToTakeAsFees = totalValueRemainingForBountyId;
            amountToReturnToBountyCreator = 0;
        } else {
            amountToTakeAsFees = bounty.unsuccessfulBountyFeeInWCKWei;
            amountToReturnToBountyCreator = totalValueRemainingForBountyId.sub(uint256(amountToTakeAsFees));
        }

        if(_referrer != address(0)){
            uint256 halfOfFees = uint256(amountToTakeAsFees).div(uint256(2));
            addressToFeeEarnings[_referrer] = addressToFeeEarnings[_referrer].add(uint256(halfOfFees));
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(uint256(halfOfFees));
        } else {
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(uint256(amountToTakeAsFees));
        }

        if(amountToReturnToBountyCreator > 0){
            require(ERC20(wrappedKittiesAddress).transfer(bounty.bidder, amountToReturnToBountyCreator) == true, 'failed to transfer WCK');
        }

    	emit WithdrawBounty(
            _bountyId,
            bounty.bidder,
            amountToReturnToBountyCreator
        );
    }

     
     
     
     
     
     
     
     
     
     
     
    function withdrawBountyWithNoFeesTakenIfContractIsFrozen(uint256 _bountyId) external whenPaused nonReentrant {
    	require(numCatsRemainingForBountyId[_bountyId] > 0, 'this bounty has either already completed or has not yet begun');
    	Bounty storage bounty = bountyIdToBounty[_bountyId];
    	require(msg.sender == bounty.bidder || isOwner(), 'you are not the bounty creator or the contract owner');

        uint256 totalValueIncludingFeesPerCat = uint256(bounty.totalValueIncludingFees).div(uint256(bounty.quantity));
        uint256 totalValueRemainingForBountyId = totalValueIncludingFeesPerCat.mul(numCatsRemainingForBountyId[_bountyId]);

        numCatsRemainingForBountyId[_bountyId] = 0;

        require(ERC20(wrappedKittiesAddress).transfer(bounty.bidder, totalValueRemainingForBountyId) == true, 'failed to transfer WCK');

    	emit WithdrawBounty(
            _bountyId,
            bounty.bidder,
            totalValueRemainingForBountyId
        );
    }

     
     
     
     
     
     
     
     
     
     
    function _computeBountyPrice(uint256 _totalValueIncludingFees, uint256 _successfulBountyFeeInBasisPoints) internal pure returns (uint256) {
    	return (_totalValueIncludingFees.mul(uint256(10000).sub(_successfulBountyFeeInBasisPoints))).div(uint256(10000));
    }

     
     
    function() external payable {
        revert();
    }
}