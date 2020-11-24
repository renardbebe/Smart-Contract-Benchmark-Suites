 

pragma solidity >=0.5.6 <0.6.0;

 
contract WizardConstants {
     
     
     
    uint8 internal constant ELEMENT_NOTSET = 0;  
     
     
    uint8 internal constant ELEMENT_NEUTRAL = 1;  
     
     
     
     
     
    uint8 internal constant ELEMENT_FIRE = 2;  
    uint8 internal constant ELEMENT_WATER = 3;  
    uint8 internal constant ELEMENT_WIND = 4;  
    uint8 internal constant MAX_ELEMENT = ELEMENT_WIND;
}



 
 
contract ERC165Query {
    bytes4 constant _INTERFACE_ID_INVALID = 0xffffffff;
    bytes4 constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    function doesContractImplementInterface(
        address _contract,
        bytes4 _interfaceId
    )
        internal
        view
        returns (bool)
    {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, _INTERFACE_ID_ERC165);
        if ((success == 0) || (result == 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _INTERFACE_ID_INVALID);
        if ((success == 0) || (result != 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success == 1) && (result == 1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(
        address _contract,
        bytes4 _interfaceId
    )
        internal
        view
        returns (
            uint256 success,
            uint256 result
        )
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, _interfaceId);

         
        assembly {  
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)

            let output := mload(0x40)     
            mstore(output, 0x0)

            success := staticcall(
                30000,                    
                _contract,                
                encodedParams_data,
                encodedParams_size,
                output,
                0x20                      
            )

            result := mload(output)       
        }
    }
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



 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}




 
 
interface ERC165Interface {
     
     
     
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



 
 
contract Address {
     
     
     
     
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }  
        return size > 0;
    }
}




 
 
 
contract WizardNFT is ERC165Interface, IERC721, WizardConstants, Address {

     
    event WizardConjured(uint256 wizardId, uint8 affinity, uint256 innatePower);

     
     
     
    event WizardAffinityAssigned(uint256 wizardId, uint8 affinity);

     
     
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

     
     
    struct Wizard {
         
         
        uint8 affinity;
        uint88 innatePower;
        address owner;
        bytes32 metadata;
    }

     
    mapping (uint256 => Wizard) public wizardsById;

     
    mapping (uint256 => address) private wizardApprovals;

     
    mapping (address => uint256) internal ownedWizardsCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
     
     
     
     
     
     
     
     
     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

     
     
     
     
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == this.supportsInterface.selector ||  
            interfaceId == _INTERFACE_ID_ERC721;  
    }

     
     
     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ownedWizardsCount[owner];
    }

     
     
     
    function ownerOf(uint256 wizardId) public view returns (address) {
        address owner = wizardsById[wizardId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

     
     
     
     
     
     
    function approve(address to, uint256 wizardId) public {
        address owner = ownerOf(wizardId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        wizardApprovals[wizardId] = to;
        emit Approval(owner, to, wizardId);
    }

     
     
     
     
    function getApproved(uint256 wizardId) public view returns (address) {
        require(_exists(wizardId), "ERC721: approved query for nonexistent token");
        return wizardApprovals[wizardId];
    }

     
     
     
     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
     
     
     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 wizardId) public {
        require(_isApprovedOrOwner(msg.sender, wizardId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, wizardId);
    }

     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address from, address to, uint256 wizardId) public {
        safeTransferFrom(from, to, wizardId, "");
    }

     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address from, address to, uint256 wizardId, bytes memory _data) public {
        transferFrom(from, to, wizardId);
        require(_checkOnERC721Received(from, to, wizardId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
     
     
    function _exists(uint256 wizardId) internal view returns (bool) {
        address owner = wizardsById[wizardId].owner;
        return owner != address(0);
    }

     
     
     
     
     
    function _isApprovedOrOwner(address spender, uint256 wizardId) internal view returns (bool) {
        require(_exists(wizardId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(wizardId);
        return (spender == owner || getApproved(wizardId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _createWizard(uint256 wizardId, address owner, uint88 innatePower, uint8 affinity) internal {
        require(owner != address(0), "ERC721: mint to the zero address");
        require(!_exists(wizardId), "ERC721: token already minted");
        require(wizardId > 0, "No 0 token allowed");
        require(innatePower > 0, "Wizard power must be non-zero");

         
        wizardsById[wizardId] = Wizard({
            affinity: affinity,
            innatePower: innatePower,
            owner: owner,
            metadata: 0
        });

        ownedWizardsCount[owner]++;

         
        emit Transfer(address(0), owner, wizardId);
        emit WizardConjured(wizardId, affinity, innatePower);
    }

     
     
     
     
     
    function _burn(address owner, uint256 wizardId) internal {
        require(ownerOf(wizardId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(wizardId);

        ownedWizardsCount[owner]--;
         
        delete wizardsById[wizardId];

         
        emit Transfer(owner, address(0), wizardId);
    }

     
     
     
    function _burn(uint256 wizardId) internal {
        _burn(ownerOf(wizardId), wizardId);
    }

     
     
     
     
     
    function _transferFrom(address from, address to, uint256 wizardId) internal {
        require(ownerOf(wizardId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(wizardId);

        ownedWizardsCount[from]--;
        ownedWizardsCount[to]++;

        wizardsById[wizardId].owner = to;

        emit Transfer(from, to, wizardId);
    }

     
     
     
     
     
     
     
    function _checkOnERC721Received(address from, address to, uint256 wizardId, bytes memory _data)
        internal returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, wizardId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
     
    function _clearApproval(uint256 wizardId) private {
        if (wizardApprovals[wizardId] != address(0)) {
            wizardApprovals[wizardId] = address(0);
        }
    }
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




 
library SigTools {

     
     
     
    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
         
        require(signature.length == 65, "Invalid signature length");

         
         
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;  
        }

         
         
         

        return (r, s, v);
    }
}



contract ERC1654 {

     
    bytes4 public constant ERC1654_VALIDSIGNATURE = 0x1626ba7e;

     
     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        bytes calldata _signature)
        external
        view
        returns (bytes4);
}



 
contract WizardGuild is AccessControl, WizardNFT, WizardGuildInterface, ERC165Query {

     
    event SeriesOpen(uint64 seriesIndex, uint256 reservedIds);
    event SeriesClose(uint64 seriesIndex);

     
    event MetadataSet(uint256 indexed wizardId, bytes32 metadata);

     
     
     
    uint64 internal seriesIndex;

     
     
    address internal seriesMinter;

     
     
     
     
     
     
     
     
     
     
     
     
     
    uint256 internal nextWizardIndex;

    function getNextWizardIndex() external view returns (uint256) {
        return nextWizardIndex;
    }

     
     
     
    uint256 internal constant SERIES_OFFSET = 192;
    uint256 internal constant SERIES_MASK = uint256(-1) << SERIES_OFFSET;
    uint256 internal constant INDEX_MASK = uint256(-1) >> 64;

     
    bytes4 internal constant ERC1654_VALIDSIGNATURE = 0x1626ba7e;

     
     
     
     
     
     
    constructor(address _cooAddress) public AccessControl(_cooAddress, address(0)) {
    }

     
     
     
     
     
    modifier duringSeries() {
        require(seriesMinter != address(0), "No series is currently open");
        _;
    }

     
     
     
     
     
     
    modifier onlyMinter() {
        require(msg.sender == seriesMinter, "Only callable by minter");
        _;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function openSeries(address minter, uint256 reservedIds) external onlyCOO returns (uint64 seriesId) {
        require(seriesMinter == address(0), "A series is already open");
        require(minter != address(0), "Minter address cannot be 0");

        if (seriesIndex == 0) {
             
             
             
             
             

             
             
             
             
             
             
             
            require(reservedIds == 6133, "Invalid reservedIds for 1st series");
        } else {
            require(reservedIds < 1 << 192, "Invalid reservedIds");
        }

         
         

        seriesMinter = minter;
        nextWizardIndex = reservedIds + 1;

        emit SeriesOpen(seriesIndex, reservedIds);

        return seriesIndex;
    }

     
     
     
     
     
     
    function closeSeries() external duringSeries {
        require(
            msg.sender == seriesMinter || msg.sender == cooAddress,
            "Only Minter or COO can close a Series");

        seriesMinter = address(0);
        emit SeriesClose(seriesIndex);

         
        seriesIndex += 1;
        nextWizardIndex = 0;
    }

     
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == _INTERFACE_ID_WIZARDGUILD || super.supportsInterface(interfaceId);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getWizard(uint256 id) public view returns (address owner, uint88 innatePower, uint8 affinity, bytes32 metadata) {
        Wizard memory wizard = wizardsById[id];
        require(wizard.owner != address(0), "Wizard does not exist");
        (owner, innatePower, affinity, metadata) = (wizard.owner, wizard.innatePower, wizard.affinity, wizard.metadata);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function mintWizards(
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
    ) external onlyMinter returns (uint256[] memory wizardIds)
    {
        require(affinities.length == powers.length, "Inconsistent parameter lengths");

         
        wizardIds = new uint256[](affinities.length);

         
         
        uint256 tempWizardId = (uint256(seriesIndex) << SERIES_OFFSET) + nextWizardIndex;

        for (uint256 i = 0; i < affinities.length; i++) {
            wizardIds[i] = tempWizardId;
            tempWizardId++;

            _createWizard(wizardIds[i], owner, powers[i], affinities[i]);
        }

        nextWizardIndex = tempWizardId & INDEX_MASK;
    }

     
     
     
     
     
     
     
     
     
    function mintReservedWizards(
        uint256[] calldata wizardIds,
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
    )
    external onlyMinter
    {
        require(
            wizardIds.length == affinities.length &&
            wizardIds.length == powers.length, "Inconsistent parameter lengths");

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 currentId = wizardIds[i];

            require((currentId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizards not in current series");
            require((currentId & INDEX_MASK) > 0, "Wizards id cannot be zero");

             
             
             
             
             
             
             
             
             
             
            require((currentId & INDEX_MASK) < nextWizardIndex, "Wizards not in reserved range");

            _createWizard(currentId, owner, powers[i], affinities[i]);
        }
    }

     
     
     
     
     
     
     
    function setMetadata(uint256[] calldata wizardIds, bytes32[] calldata metadata) external duringSeries {
        require(msg.sender == seriesMinter || msg.sender == cooAddress, "Only Minter or COO can set metadata");
        require(wizardIds.length == metadata.length, "Inconsistent parameter lengths");

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 currentId = wizardIds[i];
            bytes32 currentMetadata = metadata[i];

            require((currentId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizards not in current series");

            require(wizardsById[currentId].metadata == bytes32(0), "Metadata already set");

            require(currentMetadata != bytes32(0), "Invalid metadata");

            wizardsById[currentId].metadata = currentMetadata;

            emit MetadataSet(currentId, currentMetadata);
        }
    }

     
     
     
     
     
     
     
     
    function setAffinity(uint256 wizardId, uint8 newAffinity) external onlyMinter {
        require((wizardId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizard not in current series");

        Wizard storage wizard = wizardsById[wizardId];

        require(wizard.affinity == ELEMENT_NOTSET, "Affinity can only be chosen once");

         
        wizard.affinity = newAffinity;

         
        emit WizardAffinityAssigned(wizardId, newAffinity);
    }

     
     
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function verifySignature(uint256 wizardId, bytes32 hash, bytes memory sig) public view {
         
        address owner = ownerOf(wizardId);

        if (_validSignatureForAddress(owner, hash, sig)) {
            return;
        }

         
        address approved = getApproved(wizardId);

        if (_validSignatureForAddress(approved, hash, sig)) {
            return;
        }

        revert("Invalid signature");
    }

     
     
     
     
     
     
     
     
     
    function verifySignatures(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 hash1,
        bytes32 hash2,
        bytes calldata sig1,
        bytes calldata sig2) external view
    {
        verifySignature(wizardId1, hash1, sig1);
        verifySignature(wizardId2, hash2, sig2);
    }

     
     
     
     
    function _validSignatureForAddress(address possibleSigner, bytes32 hash, bytes memory signature)
        internal view returns(bool)
    {
        if (possibleSigner == address(0)) {
             
            return false;
        } else if (Address.isContract(possibleSigner)) {
             
             
             
            if (doesContractImplementInterface(possibleSigner, ERC1654_VALIDSIGNATURE)) {
                 
                ERC1654 tso = ERC1654(possibleSigner);
                bytes4 result = tso.isValidSignature(keccak256(abi.encodePacked(hash)), signature);
                if (result == ERC1654_VALIDSIGNATURE) {
                    return true;
                }
            }

            return false;
        } else {
             
             
            (bytes32 r, bytes32 s, uint8 v) = SigTools._splitSignature(signature);
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);

             
            return (signer == possibleSigner);
        }
    }

}