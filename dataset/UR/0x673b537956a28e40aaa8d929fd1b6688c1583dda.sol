 

pragma solidity >=0.5.6 <0.6.0;

 
contract WizardConstants {
     
     
     
    uint8 internal constant ELEMENT_NOTSET = 0;  
     
     
    uint8 internal constant ELEMENT_NEUTRAL = 1;  
     
     
     
     
     
    uint8 internal constant ELEMENT_FIRE = 2;  
    uint8 internal constant ELEMENT_WATER = 3;  
    uint8 internal constant ELEMENT_WIND = 4;  
    uint8 internal constant MAX_ELEMENT = ELEMENT_WIND;
}








 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract WizardGuildInterfaceId {
    bytes4 internal constant _INTERFACE_ID_WIZARDGUILD = 0x41d4d437;
}

 
 
 
 
 
contract WizardGuildInterface is IERC721, WizardGuildInterfaceId {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getWizard(uint256 id) external view returns (address owner, uint88 innatePower, uint8 affinity, bytes32 metadata);

     
     
     
     
     
     
     
     
     
     
    function setAffinity(uint256 wizardId, uint8 newAffinity) external;

     
     
     
     
     
     
     
     
    function mintWizards(
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external returns (uint256[] memory wizardIds);

     
     
     
     
     
    function mintReservedWizards(
        uint256[] calldata wizardIds,
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external;

     
     
     
     
     
     
     
    function setMetadata(uint256[] calldata wizardIds, bytes32[] calldata metadata) external;

     
     
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function verifySignature(uint256 wizardId, bytes32 hash, bytes calldata sig) external view;

     
     
     
     
     
     
     
     
     
    function verifySignatures(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 hash1,
        bytes32 hash2,
        bytes calldata sig1,
        bytes calldata sig2) external view;
}






 
 
interface ERC165Interface {
     
     
     
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract TournamentInterfaceId {
    bytes4 internal constant _INTERFACE_ID_TOURNAMENT = 0xbd059098;
}

 
contract TournamentInterface is TournamentInterfaceId, ERC165Interface {

     
    function revive(uint256 wizardId) external payable;

    function enterWizards(uint256[] calldata wizardIds, uint88[] calldata powers) external payable;

     
    function isActive() external view returns (bool);

    function powerScale() external view returns (uint256);

    function destroy() external;
}



 
 
contract AccessControl {

     
     
     
     
    address public ceoAddress;

     
     
     
     
     
    address public cooAddress;

     
     
     
    address payable public cfoAddress;

     
    event CEOTransferred(address previousCeo, address newCeo);
    event COOTransferred(address previousCoo, address newCoo);
    event CFOTransferred(address previousCfo, address newCfo);

     
     
     
     
    constructor(address newCooAddress, address payable newCfoAddress) public {
        _setCeo(msg.sender);
        setCoo(newCooAddress);

        if (newCfoAddress != address(0)) {
            setCfo(newCfoAddress);
        }
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "Only CEO");
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress, "Only COO");
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO");
        _;
    }

    function checkControlAddress(address newController) internal view {
        require(newController != address(0) && newController != ceoAddress, "Invalid CEO address");
    }

     
     
    function setCeo(address newCeo) external onlyCEO {
        checkControlAddress(newCeo);
        _setCeo(newCeo);
    }

     
     
    function _setCeo(address newCeo) private {
        emit CEOTransferred(ceoAddress, newCeo);
        ceoAddress = newCeo;
    }

     
     
    function setCoo(address newCoo) public onlyCEO {
        checkControlAddress(newCoo);
        emit COOTransferred(cooAddress, newCoo);
        cooAddress = newCoo;
    }

     
     
    function setCfo(address payable newCfo) public onlyCEO {
        checkControlAddress(newCfo);
        emit CFOTransferred(cfoAddress, newCfo);
        cfoAddress = newCfo;
    }
}




 
 
 
 
 
contract WizardPresaleInterface {

     
     
    bytes4 public constant _INTERFACE_ID_WIZARDPRESALE = 0x4df71efb;

     
     
     
     
     
     
     
     
    function absorbWizard(uint256 id) external returns (address owner, uint256 power, uint8 affinity);

     
     
     
    function absorbWizardMulti(uint256[] calldata ids) external
        returns (address[] memory owners, uint256[] memory powers, uint8[] memory affinities);

    function powerToCost(uint256 power) public pure returns (uint256 cost);
    function costToPower(uint256 cost) public pure returns (uint256 power);
}




 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}



 
 
contract Address {
     
     
     
     
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }  
        return size > 0;
    }
}


 
 
 
 
 
 
 
contract InauguralGateKeeper is AccessControl, WizardConstants, Address, WizardGuildInterfaceId, TournamentInterfaceId {
     
    TournamentInterface public tournament;

     
     
    WizardGuildInterface public constant WIZARD_GUILD = WizardGuildInterface(address(0x35B7838dd7507aDA69610397A85310AE0abD5034));

     
    WizardPresaleInterface public constant WIZARD_PRESALE = WizardPresaleInterface(address(0x2F4Bdafb22bd92AA7b7552d270376dE8eDccbc1E));

     
     
     
    uint256 internal constant MAX_POWER_SCALE = 1000;
    uint256 internal tournamentPowerScale;

    function getTournamentPowerScale() external view returns (uint256) {
        return tournamentPowerScale;
    }

     
    uint256 private constant TENTH_BASIS_POINTS = 100000;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    struct WizardCosts {
         
        uint96 neutralWizardCost;

         
         
        uint96 elementalWizardCost;

         
         
        uint32 elementalWizardIncrement;
    }

    WizardCosts public wizardCosts;

     
     
     
     
     
    constructor(
        address setCooAddress,
        address payable setCfoAddress,
        uint256 setNeutralWizardCost,
        uint256 setElementalWizardCost,
        uint256 setElementalWizardIncrement)
        public AccessControl(setCooAddress, setCfoAddress)
    {
        wizardCosts = WizardCosts ({
            neutralWizardCost: uint96(setNeutralWizardCost),
            elementalWizardCost: uint96(setElementalWizardCost),
            elementalWizardIncrement: uint32(setElementalWizardIncrement)
        });
    }

    modifier onlyWizardController(uint256 wizardId) {
        require(WIZARD_GUILD.isApprovedOrOwner(msg.sender, wizardId), "Must be Wizard controller");
        _;
    }

     
     
    function() external payable {
        require(msg.sender == address(WIZARD_PRESALE) || msg.sender == address(tournament), "Don't send funds to GateKeeper");
    }

     
     
     
     
     
     
     
     
     
     
    function registerTournament(address setTournament) external onlyCOO {
        require(address(tournament) == address(0), "Tournament already registered");
        tournament = TournamentInterface(setTournament);
        require(
            (setTournament != address(0)) &&
            tournament.supportsInterface(_INTERFACE_ID_TOURNAMENT), "Invalid Tournament");

        tournamentPowerScale = tournament.powerScale();
        require(tournamentPowerScale <= MAX_POWER_SCALE, "Power scale too high");
    }

     
     
     
     
     
     
     
     
     
     
     
    function conjureWizard(uint8 affinity) external payable returns (uint256) {
        uint8[] memory affinities = new uint8[](1);

        affinities[0] = affinity;

        uint256[] memory wizardIds = conjureWizardMulti(affinities);

        return wizardIds[0];
    }

     
     
     
     
     
     
     
     
    function conjureWizardMulti(uint8[] memory affinities) public payable
            returns (uint256[] memory wizardIds)
    {
        (uint256 totalCost, uint256 contribution, uint88[] memory powers) = _computeWizardPowers(affinities);

        require(msg.value >= totalCost, "Insufficient funds");

         
        wizardIds = WIZARD_GUILD.mintWizards(powers, affinities, msg.sender);

         
        tournament.enterWizards.value(contribution)(wizardIds, powers);

         
         
         
         
        if (isContract(msg.sender)) {
            for (uint256 i = 0; i < wizardIds.length; i++) {
                bytes4 transferAccepted = IERC721Receiver(msg.sender).onERC721Received(msg.sender, address(0), wizardIds[i], "");
                require(transferAccepted == _ERC721_RECEIVED, "Contract owner didn't accept ERC721 transfer");
            }
        }

         
         
        _transferRefund(totalCost);
    }

     
     
     
     
     
     
     
     
     
     
    function conjureExclusiveMulti(
        uint256[] calldata wizardIds,
        uint256[] calldata powers,
        uint8[] calldata affinities,
        address owner
    )
        external payable onlyCOO
    {
         
        require(wizardIds.length == powers.length && powers.length == affinities.length, "Inconsistent parameter lengths");

        uint256 totalCost = 0;
        uint256 contribution = 0;
        uint88[] memory localPowers = new uint88[](powers.length);

        for (uint256 i = 0; i < powers.length; i++) {
            require(affinities[i] <= MAX_ELEMENT, "Invalid affinity");

            require(powers[i] < (1 << 88), "Invalid power level");
            localPowers[i] = uint88(powers[i]);
            uint256 wizardCost = powerToCost(localPowers[i]);

            totalCost += wizardCost;
            contribution += _potContribution(localPowers[i]);
        }

        require(msg.value >= totalCost, "Insufficient funds");

         
        WIZARD_GUILD.mintReservedWizards(wizardIds, localPowers, affinities, owner);

         
        tournament.enterWizards.value(contribution)(wizardIds, localPowers);

         
         
         
         
        if (isContract(owner)) {
            for (uint256 i = 0; i < wizardIds.length; i++) {
                bytes4 transferAccepted = IERC721Receiver(owner).onERC721Received(msg.sender, address(0), wizardIds[i], "");
                require(transferAccepted == _ERC721_RECEIVED, "Contract owner didn't accept ERC721 transfer");
            }
        }

         
         
        _transferRefund(totalCost);
    }

     
     
     
    function _computeWizardPowers(uint8[] memory affinities) internal
            returns(uint256 totalCost, uint256 contribution, uint88[] memory powers)
    {
         
        uint256 neutralWizardCost = wizardCosts.neutralWizardCost;
        uint256 elementalWizardCost = wizardCosts.elementalWizardCost;
        uint256 elementalWizardIncrement = wizardCosts.elementalWizardIncrement;

        totalCost = 0;
        contribution = 0;
        powers = new uint88[](affinities.length);

        for (uint256 i = 0; i < affinities.length; i++) {
            uint8 affinity = affinities[i];
            uint256 wizardCost;

            require(affinity > ELEMENT_NOTSET && affinity <= MAX_ELEMENT, "Invalid affinity");

             
            if (affinity == ELEMENT_NEUTRAL) {
                wizardCost = neutralWizardCost;
            } else {
                wizardCost = elementalWizardCost;

                 
                 
                 
                 
                 
                 
                elementalWizardCost += (elementalWizardCost * elementalWizardIncrement) / TENTH_BASIS_POINTS;
            }

            powers[i] = costToPower(wizardCost);

             
             
             
            contribution += _potContribution(powers[i]);
            totalCost += wizardCost;
        }

         
         
        wizardCosts.elementalWizardCost = uint96(elementalWizardCost);
    }

     
     
     
     
    function absorbPresaleWizards(uint256[] calldata wizardIds) external {
         
         
         
        (
            address[] memory owners,
             uint256[] memory powers,
             uint8[] memory affinities
        ) = WIZARD_PRESALE.absorbWizardMulti(wizardIds);

        uint256 contribution = 0;
        address theOwner = owners[0];
        uint88[] memory localPowers = new uint88[](powers.length);

        for (uint256 i = 0; i < powers.length; i++) {
            require(owners[i] == theOwner, "All Wizards must have same owner");
            localPowers[i] = uint88(powers[i]);
            contribution += _potContribution(localPowers[i]);
        }

         
        WIZARD_GUILD.mintReservedWizards(wizardIds, localPowers, affinities, theOwner);

         
        tournament.enterWizards.value(contribution)(wizardIds, localPowers);
    }

     
     
     
    function revive(uint256 wizardId) external payable onlyWizardController(wizardId) {
         
         
         
        uint88 purchasedPower = costToPower(msg.value);
        uint256 potContributionValue = _potContribution(purchasedPower);

        tournament.revive.value(potContributionValue)(wizardId);
    }

     
     
     
    function setAffinity(uint256 wizardId, uint8 newAffinity) external onlyWizardController(wizardId) {
        require(newAffinity > ELEMENT_NOTSET && newAffinity <= MAX_ELEMENT, "Must choose a valid affinity");

         
        WIZARD_GUILD.setAffinity(wizardId, newAffinity);
    }

     
     
     
    function costToPower(uint256 cost) public pure returns (uint88 power) {
        return uint88(cost / MAX_POWER_SCALE);
    }

     
     
    function powerToCost(uint88 power) public pure returns (uint256 cost) {
        return power * MAX_POWER_SCALE;
    }

     
     
     
     
    function _potContribution(uint88 wizardPower) internal view returns (uint256) {
        return wizardPower * tournamentPowerScale;
    }

     
    function withdraw() external onlyCFO {
         
         
        msg.sender.transfer(address(this).balance);
    }


     
     
    function destroy() external onlyCOO {
        require(address(this).balance == 0, "Drain the funds first");
        require(address(tournament) == address(0), "Destroy Tournament first");

        selfdestruct(msg.sender);
    }

     
    function destroyTournament() external onlyCOO {
        if (address(tournament) != address(0)) {
            require(tournament.isActive() == false, "Tournament active");
            tournament.destroy();
            tournament = TournamentInterface(0);
        }
    }

     
     
     
     
     
     
    function _transferRefund(uint256 actualPrice) private {
        uint256 refund = msg.value - actualPrice;

         
         
         
         
        if (refund > (tx.gasprice * (9000+700))) {
            msg.sender.transfer(refund);
        }
    }
}