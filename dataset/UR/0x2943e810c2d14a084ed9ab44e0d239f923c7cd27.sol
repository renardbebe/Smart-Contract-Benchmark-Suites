 

pragma solidity ^0.5.12;

 
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

 
 
contract CheezyExchangeAdmin is Ownable, Pausable, ReentrancyGuard {

     
     
     

     
     
     
     
     
    event SuccessfulTradeFeeInBasisPointsUpdated(uint256 newSuccessfulTradeFeeInBasisPoints);

     
     
     

     
     
     
     
    mapping (address => uint256) public addressToFeeEarnings;

     
     
     
     
    uint256 public successfulTradeFeeInBasisPoints = 375;

     
     
     

     
     
    address public wizardGuildAddress = 0x35B7838dd7507aDA69610397A85310AE0abD5034;

     
     
     

     
     
    constructor() internal {

    }

     
     
     
     
     
     
     
     
     
    function setSuccessfulTradeFeeInBasisPoints(uint256 _newSuccessfulTradeFeeInBasisPoints) external onlyOwner {
        require(_newSuccessfulTradeFeeInBasisPoints <= 10000, 'new successful trade fee must be in basis points (hundredths of a percent), not wei');
        successfulTradeFeeInBasisPoints = _newSuccessfulTradeFeeInBasisPoints;
        emit SuccessfulTradeFeeInBasisPointsUpdated(_newSuccessfulTradeFeeInBasisPoints);
    }

     
     
     
    function withdrawFeeEarningsForAddress() external nonReentrant {
        uint256 balance = addressToFeeEarnings[msg.sender];
        require(balance > 0, 'there are no fees to withdraw for this address');
        addressToFeeEarnings[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

     
     
     
     
     
     
    function removePauser(address _account) external onlyOwner {
        _removePauser(_account);
    }

     
     
    function() external payable {
        revert();
    }
}

 
 
contract WizardGuild {
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}

 
 
contract BasicTournament {
    function getWizard(uint256 wizardId) public view returns(
        uint256 affinity,
        uint256 power,
        uint256 maxPower,
        uint256 nonce,
        bytes32 currentDuel,
        bool ascending,
        uint256 ascensionOpponent,
        bool molded,
        bool ready
    );
    function giftPower(uint256 sendingWizardId, uint256 receivingWizardId) external;
}

 
 
 
 
 
 
 
contract CheezyExchangeTournamentTime {

     
     
     
     
    struct WindowParameters {
         
        uint48 firstWindowStartBlock;

         
         
        uint48 pauseEndedBlock;

         
         
        uint32 sessionDuration;

         
        uint32 windowDuration;
    }

     
     
     
     
     
     
    function _isInWindow(WindowParameters memory localParams) internal view returns (bool) {
         
        if (block.number < localParams.pauseEndedBlock) {
            return false;
        }

         
         
        if (block.number < localParams.firstWindowStartBlock) {
            return false;
        }

         
         
         
        uint256 windowOffset = (block.number - localParams.firstWindowStartBlock) % localParams.sessionDuration;

         
         
        return windowOffset < localParams.windowDuration;
    }

     
     
     
     
     
    function _isInFightWindowForTournament(address _basicTournamentAddress) internal view returns (bool){
        uint256 tournamentStartBlock;
        uint256 pauseEndedBlock;
        uint256 admissionDuration;
        uint256 duelTimeoutDuration;
        uint256 ascensionWindowDuration;
        uint256 fightWindowDuration;
        uint256 cullingWindowDuration;
        (
            tournamentStartBlock,
            pauseEndedBlock,
            admissionDuration,
            ,
            duelTimeoutDuration,
            ,
            ascensionWindowDuration,
            ,
            fightWindowDuration,
            ,
            ,
            ,
            cullingWindowDuration
        ) = IBasicTournamentTimeParams(_basicTournamentAddress).getTimeParameters();
        uint256 firstSessionStartBlock = uint256(tournamentStartBlock) + uint256(admissionDuration);
        uint256 sessionDuration = uint256(ascensionWindowDuration) + uint256(fightWindowDuration) + uint256(duelTimeoutDuration) + uint256(cullingWindowDuration);

        return _isInWindow(WindowParameters({
            firstWindowStartBlock: uint48(uint256(firstSessionStartBlock) + uint256(ascensionWindowDuration)),
            pauseEndedBlock: uint48(pauseEndedBlock),
            sessionDuration: uint32(sessionDuration),
            windowDuration: uint32(fightWindowDuration)
        }));
    }
}

contract IBasicTournamentTimeParams{
    function getTimeParameters() external view returns (
        uint256 tournamentStartBlock,
        uint256 pauseEndedBlock,
        uint256 admissionDuration,
        uint256 revivalDuration,
        uint256 duelTimeoutDuration,
        uint256 ascensionWindowStart,
        uint256 ascensionWindowDuration,
        uint256 fightWindowStart,
        uint256 fightWindowDuration,
        uint256 resolutionWindowStart,
        uint256 resolutionWindowDuration,
        uint256 cullingWindowStart,
        uint256 cullingWindowDuration
    );
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract CheezyExchange is CheezyExchangeAdmin, CheezyExchangeTournamentTime {

     
     
    using SafeMath for uint256;

	 
     
     

     
     
    struct Order {
         
         
        uint256 wizardId;
         
         
         
         
        uint128 pricePerPower;
         
         
		address makerAddress;
         
         
         
         
		address basicTournamentAddress;
         
         
         
        uint16 savedSuccessfulTradeFeeInBasisPoints;
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event CreateSellOrder(
    	uint256 wizardId,
        uint256 pricePerPower,
		address makerAddress,
        address basicTournamentAddress,
        uint256 savedSuccessfulTradeFeeInBasisPoints
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event UpdateSellOrder(
    	uint256 wizardId,
        uint256 oldPricePerPower,
        uint256 newPricePerPower,
		address makerAddress,
        address basicTournamentAddress,
        uint256 savedSuccessfulTradeFeeInBasisPoints
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event CancelSellOrder(
    	uint256 wizardId,
        uint256 pricePerPower,
		address makerAddress,
        address basicTournamentAddress,
        uint256 savedSuccessfulTradeFeeInBasisPoints
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event FillSellOrder(
    	uint256 makerWizardId,
        uint256 takerWizardId,
        uint256 pricePerPower,
		address makerAddress,
        address takerAddress,
        address basicTournamentAddress,
        uint256 savedSuccessfulTradeFeeInBasisPoints
    );

     
     
     

     
     
     
     
     
     
     
    mapping(address => mapping(uint256 => Order)) internal orderForWizardIdAndTournamentAddress;

     
     
     
     
    mapping(address => uint256) public lastSuccessfulPricePerPowerForTournamentAddress;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createSellOrder(uint256 _wizardId, uint256 _pricePerPower, address _basicTournamentAddress) external whenNotPaused nonReentrant {
        require(WizardGuild(wizardGuildAddress).ownerOf(_wizardId) == msg.sender, 'only the owner of the wizard can create a sell order');
        require(WizardGuild(wizardGuildAddress).isApprovedOrOwner(address(this), _wizardId), 'you must call the approve() function on WizardGuild before you can create a sell order');
        require(_pricePerPower <= uint256(~uint128(0)), 'you cannot specify a _pricePerPower greater than uint128_max');

         
        bool molded;
        bool ready;
        ( , , , , , , , molded, ready) = BasicTournament(_basicTournamentAddress).getWizard(_wizardId);
        require(molded == false, 'you cannot sell the power from a molded wizard');
        require(ready == true, 'you cannot sell the power from a wizard that is not ready');

        Order memory previousOrder = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];

         
         
        if(previousOrder.makerAddress != address(0)){
             
            emit CancelSellOrder(
                uint256(previousOrder.wizardId),
                uint256(previousOrder.pricePerPower),
                previousOrder.makerAddress,
                previousOrder.basicTournamentAddress,
                uint256(previousOrder.savedSuccessfulTradeFeeInBasisPoints)
            );
            delete orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
        }

         
        Order memory order = Order({
            wizardId: uint256(_wizardId),
            pricePerPower: uint128(_pricePerPower),
            makerAddress: msg.sender,
            basicTournamentAddress: _basicTournamentAddress,
            savedSuccessfulTradeFeeInBasisPoints: uint16(successfulTradeFeeInBasisPoints)
        });
        orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId] = order;
        emit CreateSellOrder(
            _wizardId,
            _pricePerPower,
            msg.sender,
            _basicTournamentAddress,
            successfulTradeFeeInBasisPoints
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function updateSellOrder(uint256 _wizardId, uint256 _newPricePerPower, address _basicTournamentAddress) external whenNotPaused nonReentrant {
        require(WizardGuild(wizardGuildAddress).ownerOf(_wizardId) == msg.sender, 'only the owner of the wizard can update a sell order');
        require(WizardGuild(wizardGuildAddress).isApprovedOrOwner(address(this), _wizardId), 'you must call the approve() function on WizardGuild before you can update a sell order');
        require(_newPricePerPower <= uint256(~uint128(0)), 'you cannot specify a _newPricePerPower greater than uint128_max');

         
        Order storage order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];

         
        require(msg.sender == order.makerAddress, 'you can only update a sell order that you created');

         
        emit UpdateSellOrder(
            _wizardId,
            uint256(order.pricePerPower),
            _newPricePerPower,
            msg.sender,
            _basicTournamentAddress,
            uint256(order.savedSuccessfulTradeFeeInBasisPoints)
        );

         
        order.pricePerPower = uint128(_newPricePerPower);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function cancelSellOrder(uint256 _wizardId, address _basicTournamentAddress) external nonReentrant {
        require(WizardGuild(wizardGuildAddress).ownerOf(_wizardId) == msg.sender, 'only the owner of the wizard can cancel a sell order');

         
         
        Order memory order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
        emit CancelSellOrder(
            uint256(order.wizardId),
            uint256(order.pricePerPower),
            msg.sender,
            _basicTournamentAddress,
            uint256(order.savedSuccessfulTradeFeeInBasisPoints)
        );

         
        delete orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function fillSellOrder(uint256 _makerWizardId, uint256 _takerWizardId, address _basicTournamentAddress, address _referrer) external payable whenNotPaused nonReentrant {
        require(WizardGuild(wizardGuildAddress).ownerOf(_takerWizardId) == msg.sender, 'you can only purchase power for a wizard that you own');
        Order memory order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_makerWizardId];
        require(WizardGuild(wizardGuildAddress).ownerOf(_makerWizardId) == order.makerAddress, 'an order is only valid while the order creator owns the wizard');

         
        uint256 power;
        bool molded;
        bool ready;
        ( , power, , , , , , molded, ready) = BasicTournament(_basicTournamentAddress).getWizard(_makerWizardId);
        require(molded == false, 'you cannot sell the power from a molded wizard');
        require(ready == true, 'you cannot sell the power from a wizard that is not ready');

         
         
        lastSuccessfulPricePerPowerForTournamentAddress[_basicTournamentAddress] = uint256(order.pricePerPower);

         
        uint256 priceToFillOrder = (uint256(order.pricePerPower)).mul(power);
        require(msg.value >= priceToFillOrder, 'you did not send enough wei to fulfill this order');
        uint256 sellerProceeds = _computeSellerProceeds(priceToFillOrder, uint256(order.savedSuccessfulTradeFeeInBasisPoints));
        uint256 fees = priceToFillOrder.sub(sellerProceeds);
        uint256 excess = (msg.value).sub(priceToFillOrder);

         
        address payable orderMakerAddress = address(uint160(order.makerAddress));

         
        emit FillSellOrder(
            uint256(order.wizardId),
            _takerWizardId,
            uint256(order.pricePerPower),
            address(order.makerAddress),
            msg.sender,
            order.basicTournamentAddress,
            uint256(order.savedSuccessfulTradeFeeInBasisPoints)
        );

         
        delete orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_makerWizardId];

         
        BasicTournament(_basicTournamentAddress).giftPower(_makerWizardId, _takerWizardId);

         
        orderMakerAddress.transfer(sellerProceeds);

         
         
         
         
        if(_referrer != address(0)){
            uint256 halfOfFees = fees.div(uint256(2));
            addressToFeeEarnings[_referrer] = addressToFeeEarnings[_referrer].add(halfOfFees);
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(halfOfFees);
        } else {
            addressToFeeEarnings[owner()] = addressToFeeEarnings[owner()].add(fees);
        }

         
        if(excess > 0){
            msg.sender.transfer(excess);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function getOrder(uint256 _wizardId, address _basicTournamentAddress) external view returns (uint256 wizardId, uint256 pricePerPower, address makerAddress, address basicTournamentAddress, uint256 savedSuccessfulTradeFeeInBasisPoints){
        Order memory order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
        return (uint256(order.wizardId), uint256(order.pricePerPower), address(order.makerAddress), address(order.basicTournamentAddress), uint256(order.savedSuccessfulTradeFeeInBasisPoints));
    }

     
     
     
     
     
     
     
     
    function getCurrentPriceForOrder(uint256 _wizardId, address _basicTournamentAddress) external view returns (uint256){
        Order memory order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
        uint256 power;
        ( , power, , , , , , , ) = BasicTournament(_basicTournamentAddress).getWizard(_wizardId);
        uint256 price = power.mul(uint256(order.pricePerPower));
        return price;
    }

     
     
     
     
     
     
     
     
     
     
    function getIsOrderCurrentlyValid(uint256 _wizardId, address _basicTournamentAddress) external view returns (bool){
        Order memory order = orderForWizardIdAndTournamentAddress[_basicTournamentAddress][_wizardId];
        if(order.makerAddress == address(0)){
             
            return false;
        } else {

            if(WizardGuild(wizardGuildAddress).ownerOf(_wizardId) != order.makerAddress){
                 
                return false;
            }
            bool molded;
            bool ready;
            ( , , , , , , , molded, ready) = BasicTournament(_basicTournamentAddress).getWizard(_wizardId);
            if(molded == true || ready == false){
                 
                return false;
            } else {
                return true;
            }
        }
    }

     
     
     
     
     
    function getIsInFightWindow(address _basicTournamentAddress) external view returns (bool){
        return _isInFightWindowForTournament(_basicTournamentAddress);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function _computeSellerProceeds(uint256 _totalValueIncludingFees, uint256 _successfulTradeFeeInBasisPoints) internal pure returns (uint256) {
    	return (_totalValueIncludingFees.mul(uint256(10000).sub(_successfulTradeFeeInBasisPoints))).div(uint256(10000));
    }

     
     
    function() external payable {
        revert();
    }
}