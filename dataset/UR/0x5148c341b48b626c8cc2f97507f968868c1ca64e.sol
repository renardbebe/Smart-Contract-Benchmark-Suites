 

pragma solidity ^0.5.8;

 
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

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor() public {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
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


contract WCKAds is ReentrancyGuard, Ownable, Pausable {

     
    using SafeMath for uint256;

     
     
     

    struct AdvertisingSlot {
        uint256 kittyIdBeingAdvertised;
        uint256 blockThatPriceWillResetAt;
        uint256 valuationPrice;
        address slotOwner;
    }

     
     
     

    event AdvertisingSlotRented(
        uint256 slotId,
        uint256 kittyIdBeingAdvertised,
        uint256 blockThatPriceWillResetAt,
        uint256 valuationPrice,
        address slotOwner
    );

    event AdvertisingSlotContentsChanged(
        uint256 slotId,
        uint256 newKittyIdBeingAdvertised
    );

     
     
     

    mapping (uint256 => AdvertisingSlot) public advertisingSlots;

     
     
     

    address public kittyCoreContractAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address public kittySalesContractAddress = 0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C;
    address public kittySiresContractAddress = 0xC7af99Fe5513eB6710e6D5f44F9989dA40F27F26;
    address public wckContractAddress = 0x09fE5f0236F0Ea5D930197DCE254d77B04128075;
    uint256 public minimumPriceIncrementInBasisPoints = 500;
    uint256 public maxRentalPeriodInBlocks = 40320;
    uint256 public minimumRentalPrice = (10**18);

     
     
     

    function getCurrentPriceToRentAdvertisingSlot(uint256 _slotId) external view returns (uint256) {
        AdvertisingSlot memory currentSlot = advertisingSlots[_slotId];
        if(block.number < currentSlot.blockThatPriceWillResetAt){
            return _computeNextPrice(currentSlot.valuationPrice);
        } else {
            return minimumRentalPrice;
        }
    }

    function ownsKitty(address _address, uint256 _kittyId) view public returns (bool) {
        if(KittyCore(kittyCoreContractAddress).ownerOf(_kittyId) == _address){
            return true;
        } else {
            address seller;
            (seller, , , , ) = KittyAuction(kittySalesContractAddress).getAuction(_kittyId);
            if(seller == _address){
                return true;
            } else {
                (seller, , , , ) = KittyAuction(kittySiresContractAddress).getAuction(_kittyId);
                if(seller == _address){
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

    function rentAdvertisingSlot(uint256 _slotId, uint256 _newKittyIdToAdvertise, uint256 _newValuationPrice) external nonReentrant whenNotPaused {
        require(ownsKitty(msg.sender, _newKittyIdToAdvertise), 'the CryptoKitties Nifty License requires you to own any kitties whose image you want to use');
        AdvertisingSlot storage currentSlot = advertisingSlots[_slotId];
        if(block.number < currentSlot.blockThatPriceWillResetAt){
            require(_newValuationPrice >= _computeNextPrice(currentSlot.valuationPrice), 'you must submit a higher valuation price if the rental term has not elapsed');
            ERC20(wckContractAddress).transferFrom(msg.sender, address(this), _newValuationPrice);
        } else {
            ERC20(wckContractAddress).transferFrom(msg.sender, address(this), minimumRentalPrice);
        }
        uint256 newBlockThatPriceWillResetAt = (block.number).add(maxRentalPeriodInBlocks);
        AdvertisingSlot memory newAdvertisingSlot = AdvertisingSlot({
            kittyIdBeingAdvertised: _newKittyIdToAdvertise,
            blockThatPriceWillResetAt: newBlockThatPriceWillResetAt,
            valuationPrice: _newValuationPrice,
            slotOwner: msg.sender
        });
        advertisingSlots[_slotId] = newAdvertisingSlot;
        emit AdvertisingSlotRented(
            _slotId,
            _newKittyIdToAdvertise,
            newBlockThatPriceWillResetAt,
            _newValuationPrice,
            msg.sender
        );
    }

    function changeKittyIdBeingAdvertised(uint256 _slotId, uint256 _kittyId) external nonReentrant whenNotPaused {
        require(ownsKitty(msg.sender, _kittyId), 'the CryptoKitties Nifty License requires you to own any kitties whose image you want to use');
        AdvertisingSlot storage currentSlot = advertisingSlots[_slotId];
        require(msg.sender == currentSlot.slotOwner, 'only the current owner of this slot can change the advertisements subject matter');
        currentSlot.kittyIdBeingAdvertised = _kittyId;
        emit AdvertisingSlotContentsChanged(
            _slotId,
            _kittyId
        );
    }

    function ownerUpdateMinimumRentalPrice(uint256 _newMinimumRentalPrice) external onlyOwner {
        minimumRentalPrice = _newMinimumRentalPrice;
    }

    function ownerUpdateMinimumPriceIncrement(uint256 _newMinimumPriceIncrementInBasisPoints) external onlyOwner {
        minimumPriceIncrementInBasisPoints = _newMinimumPriceIncrementInBasisPoints;
    }

    function ownerUpdateMaxRentalPeriod(uint256 _newMaxRentalPeriodInBlocks) external onlyOwner {
        maxRentalPeriodInBlocks = _newMaxRentalPeriodInBlocks;
    }

    function ownerWithdrawERC20(address _erc20Address, uint256 _value) external onlyOwner {
        ERC20(_erc20Address).transfer(msg.sender, _value);
    }

    function ownerWithdrawEther() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    constructor() public {}

    function() external payable {}

    function _computeNextPrice(uint256 _currentPrice) view internal returns (uint256) {
        return _currentPrice.add((_currentPrice.mul(minimumPriceIncrementInBasisPoints)).div(uint256(10000)));
    }
}

 
contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract KittyCore {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

contract KittyAuction {
    function getAuction(uint256 _tokenId) external view returns (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    );
}