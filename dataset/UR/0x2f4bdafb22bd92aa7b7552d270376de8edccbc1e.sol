 

 

pragma solidity ^0.5.2;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity ^0.5.2;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.2;


 
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.2;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity >=0.5.6 <0.6.0;






 
contract WizardPresaleNFT is ERC165, IERC721 {

    using Address for address;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    event WizardSummoned(uint256 indexed tokenId, uint8 element, uint256 power);

     
     
    event WizardAlignmentAssigned(uint256 indexed tokenId, uint8 element);

     
     
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

     
     
    struct Wizard {
         
         
        uint8 affinity;
        uint88 power;
        address owner;
    }

     
    mapping (uint256 => Wizard) public _wizardsById;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) internal _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
     

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownedTokensCount[owner];
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _wizardsById[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _wizardsById[tokenId].owner;
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner]--;
         
        delete _wizardsById[tokenId];

         
        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from]--;
        _ownedTokensCount[to]++;

        _wizardsById[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

pragma solidity >=0.5.6 <0.6.0;


 
 
 
 
 
contract WizardPresaleInterface {

     
     
    bytes4 public constant _INTERFACE_ID_WIZARDPRESALE = 0x4df71efb;

     
     
     
     
     
     
     
     
    function absorbWizard(uint256 id) external returns (address owner, uint256 power, uint8 affinity);

     
     
     
    function absorbWizardMulti(uint256[] calldata ids) external
        returns (address[] memory owners, uint256[] memory powers, uint8[] memory affinities);

    function powerToCost(uint256 power) public pure returns (uint256 cost);
    function costToPower(uint256 cost) public pure returns (uint256 power);
}

 

pragma solidity >=0.5.6 <0.6.0;

 
contract AddressPayable {
     
    function isContract(address payable account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }  
        return size > 0;
    }
}

 

pragma solidity >=0.5.6 <0.6.0;

 
contract WizardConstants {
    uint8 internal constant ELEMENT_NOTSET = 0;
     
    uint8 internal constant ELEMENT_NEUTRAL = 1;
     
     
    uint8 internal constant ELEMENT_FIRE = 2;
    uint8 internal constant ELEMENT_WIND = 3;
    uint8 internal constant ELEMENT_WATER = 4;
    uint8 internal constant MAX_ELEMENT = ELEMENT_WATER;
}

 

pragma solidity >=0.5.6 <0.6.0;





 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract WizardPresale is AddressPayable, WizardPresaleNFT, WizardPresaleInterface, WizardConstants {

     
     
     
    uint256 private constant POWER_SCALE = 1000;

     
    uint256 private constant TENTH_BASIS_POINTS = 100000;

     
     
     
    address payable public guildmaster;

     
     
    uint256 public saleStartBlock;
    uint256 public saleDuration;

     
    uint256 public neutralWizardCost;

     
    uint256 public elementalWizardCost;

     
     
     
    uint256 public elementalWizardIncrement;

     
    uint256 public maxExclusives;

     
    uint256 public nextWizardId;

     
     
    address payable public gatekeeper;

     
    event StartBlockChanged(uint256 oldStartBlock, uint256 newStartBlock);

     
     
     
     
     
     
    constructor(uint128 startingCost,
            uint16 costIncremement,
            uint256 exclusiveCount,
            uint128 startBlock,
            uint128 duration) public
    {
        require(startBlock > block.number, "start must be greater than current block");

        guildmaster = msg.sender;
        saleStartBlock = startBlock;
        saleDuration = duration;
        neutralWizardCost = startingCost;
        elementalWizardCost = startingCost;
        elementalWizardIncrement = costIncremement;
        maxExclusives = exclusiveCount;
        nextWizardId = exclusiveCount + 1;

        _registerInterface(_INTERFACE_ID_WIZARDPRESALE);
    }

     
    modifier onlyGatekeeper() {
        require(msg.sender == gatekeeper, "Must be gatekeeper");
        _;
    }

     
    modifier onlyGuildmaster() {
        require(msg.sender == guildmaster, "Must be guildmaster");
        _;
    }

     
     
     
    modifier onlyDuringSale() {
         
         
        require(block.number >= saleStartBlock, "Sale not open yet");
        require(block.number < saleStartBlock + saleDuration, "Sale closed");
        _;
    }

     
     
     
    function setGatekeeper(address payable gc) external onlyGuildmaster {
        require(gatekeeper == address(0) && gc != address(0), "Can only set once and must not be zero");
        gatekeeper = gc;
    }

     
     
    function postponeSale(uint128 newStart) external onlyGuildmaster {
        require(block.number < saleStartBlock, "Sale start time only adjustable before previous start time");
        require(newStart > saleStartBlock, "New start time must be later than previous start time");

        emit StartBlockChanged(saleStartBlock, newStart);

        saleStartBlock = newStart;
    }

     
    function isDuringSale() external view returns (bool) {
        return (block.number >= saleStartBlock && block.number < saleStartBlock + saleDuration);
    }

     
     
    function getWizard(uint256 id) public view returns (address owner, uint88 power, uint8 affinity) {
        Wizard memory wizard = _wizardsById[id];
        (owner, power, affinity) = (wizard.owner, wizard.power, wizard.affinity);
        require(wizard.owner != address(0), "Wizard does not exist");
    }

     
     
    function costToPower(uint256 cost) public pure returns (uint256 power) {
        return cost / POWER_SCALE;
    }

     
     
    function powerToCost(uint256 power) public pure returns (uint256 cost) {
        return power * POWER_SCALE;
    }

     
     
     
     
     
     
     
     
    function absorbWizard(uint256 id) external onlyGatekeeper returns (address owner, uint256 power, uint8 affinity) {
        (owner, power, affinity) = getWizard(id);

         
        _burn(owner, id);

         
        msg.sender.transfer(powerToCost(power));
    }

     
     
     
    function absorbWizardMulti(uint256[] calldata ids) external onlyGatekeeper
            returns (address[] memory owners, uint256[] memory powers, uint8[] memory affinities)
    {
         
        owners = new address[](ids.length);
        powers = new uint256[](ids.length);
        affinities = new uint8[](ids.length);

         
        uint256 totalTransfer;

         
        for (uint256 i = 0; i < ids.length; i++) {
            (owners[i], powers[i], affinities[i]) = getWizard(ids[i]);

             
            _burn(owners[i], ids[i]);

             
            totalTransfer += powerToCost(powers[i]);
        }

         
        msg.sender.transfer(totalTransfer);
    }

     
     
     
     
     
     
     
    function _createWizard(uint256 tokenId, address owner, uint256 power, uint8 affinity) internal {
        require(!_exists(tokenId), "Can't reuse Wizard ID");
        require(owner != address(0), "Owner address must exist");
        require(power > 0, "Wizard power must be non-zero");
        require(power < (1<<88), "Wizard power must fit in 88 bits of storage.");
        require(affinity <= MAX_ELEMENT, "Invalid elemental affinity");

         
        _wizardsById[tokenId] = Wizard(affinity, uint88(power), owner);
        _ownedTokensCount[owner]++;

         
        emit Transfer(address(0), owner, tokenId);
        emit WizardSummoned(tokenId, affinity, power);
    }

     
     
     
     
     
     
    function _transferRefund(uint256 actualPrice) private {
        uint256 refund = msg.value - actualPrice;

         
         
         
         
        if (refund > (tx.gasprice * (9000+700))) {
            msg.sender.transfer(refund);
        }
    }

     
     
     
     
     
     
    function conjureExclusiveWizard(uint256 id, address owner, uint8 affinity) public payable onlyGuildmaster {
        require(id > 0 && id <= maxExclusives, "Invalid exclusive ID");
        _createWizard(id, owner, costToPower(msg.value), affinity);
    }

     
     
     
     
     
    function safeConjureExclusiveWizard(uint256 id, address owner, uint8 affinity) external payable onlyGuildmaster {
        conjureExclusiveWizard(id, owner, affinity);
        require(_checkOnERC721Received(address(0), owner, id, ""), "must support erc721");
    }

     
     
     
     
     
     
     
    function conjureExclusiveWizardMulti(
        uint256[] calldata ids,
        address[] calldata owners,
        uint256[] calldata powers,
        uint8[] calldata affinities) external payable onlyGuildmaster
    {
         
        require(
            ids.length == owners.length &&
            owners.length == powers.length &&
            owners.length == affinities.length,
            "Must have equal array lengths"
        );

        uint256 totalPower = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0 && ids[i] <= maxExclusives, "Invalid exclusive ID");
            require(affinities[i] <= MAX_ELEMENT, "Must choose a valid elemental affinity");

            _createWizard(ids[i], owners[i], powers[i], affinities[i]);

            totalPower += powers[i];
        }

         
         
         
         
        require(powerToCost(totalPower) <= msg.value, "Must pay for power in all Wizards");

         
         
    }

     
     
     
     
     
    function setAffinity(uint256 wizardId, uint8 newAffinity) external {
        require(newAffinity > ELEMENT_NOTSET && newAffinity <= MAX_ELEMENT, "Must choose a valid affinity");
        (address owner, , uint8 affinity) = getWizard(wizardId);
        require(msg.sender == owner, "Affinity can only be set by the owner");
        require(affinity == ELEMENT_NOTSET, "Affinity can only be chosen once");

        _wizardsById[wizardId].affinity = newAffinity;

         
        emit WizardAlignmentAssigned(wizardId, newAffinity);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function _conjureWizard(
        uint256 wizardId,
        address owner,
        uint8 affinity,
        uint256 tempElementalWizardCost) private
        returns (uint256 wizardCost, uint256 updatedElementalWizardCost)
    {
         
        require(affinity > ELEMENT_NOTSET && affinity <= MAX_ELEMENT, "Non-exclusive Wizards need a real affinity");

        updatedElementalWizardCost = tempElementalWizardCost;

         
        if (affinity == ELEMENT_NEUTRAL) {
            wizardCost = neutralWizardCost;
        } else {
            wizardCost = updatedElementalWizardCost;

             
             
             
            updatedElementalWizardCost += (updatedElementalWizardCost * elementalWizardIncrement) / TENTH_BASIS_POINTS;
        }

         
        _createWizard(wizardId, owner, costToPower(wizardCost), affinity);
    }

     
     
     
     
     
     
     
    function conjureWizard(uint8 affinity) external payable onlyDuringSale returns (uint256 wizardId) {

        wizardId = nextWizardId;
        nextWizardId++;

        uint256 wizardCost;

        (wizardCost, elementalWizardCost) = _conjureWizard(wizardId, msg.sender, affinity, elementalWizardCost);

        require(msg.value >= wizardCost, "Not enough eth to pay");

          
        _transferRefund(wizardCost);

         
         
        require(_checkOnERC721Received(address(0), msg.sender, wizardId, ""), "must support erc721");
    }

     
     
     
     
     
     
    function conjureWizardMulti(uint8[] calldata affinities) external payable onlyDuringSale
            returns (uint256[] memory wizardIds)
    {
         
        wizardIds = new uint256[](affinities.length);

        uint256 totalCost = 0;

         
         
         
        uint256 tempWizardId = nextWizardId;
        uint256 tempElementalWizardCost = elementalWizardCost;

        for (uint256 i = 0; i < affinities.length; i++) {
            wizardIds[i] = tempWizardId;
            tempWizardId++;

            uint256 wizardCost;

            (wizardCost, tempElementalWizardCost) = _conjureWizard(
                wizardIds[i],
                msg.sender,
                affinities[i],
                tempElementalWizardCost);

            totalCost += wizardCost;
        }

        elementalWizardCost = tempElementalWizardCost;
        nextWizardId = tempWizardId;

         
        require(msg.value >= totalCost, "Not enough eth to pay");

         
         
         
         
         
        if (isContract(msg.sender)) {
            for (uint256 i = 0; i < wizardIds.length; i++) {
                bytes4 retval = IERC721Receiver(msg.sender).onERC721Received(msg.sender, address(0), wizardIds[i], "");
                require(retval == _ERC721_RECEIVED, "Contract owner didn't accept ERC-721 transfer");
            }
        }

         
        _transferRefund(totalCost);
    }

     
    function destroy() external onlyGuildmaster {
        selfdestruct(guildmaster);
    }
}