 

pragma solidity ^0.4.23;


 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface ERC721 {
     
    function totalSupply() external view returns (uint256 total);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract GeneScienceInterface {
     
    function isGeneScience() public pure returns (bool);

     
     
     
     
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);

     
    function processCooldown(uint16 childGen, uint256 targetBlock) public returns (uint16);

     
    function upgradePonyResult(uint8 unicornation, uint256 targetBlock) public returns (bool);
    
    function setMatingSeason(bool _isMatingSeason) public returns (bool);
}



 
interface ERC20 {
     
    function transfer(address _to, uint _value) external returns (bool success);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) external returns (bool);

    function recoverSigner(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) external view returns (address);
}

 
contract SignatureVerifier {

    function splitSignature(bytes sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
         
            r := mload(add(sig, 32))
         
            s := mload(add(sig, 64))
         
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recover(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
         
        if (sig.length != 65) {
            return (address(0));
        }
         
        (v, r, s) = splitSignature(sig);
         
        if (v < 27) {
            v += 27;
        }
         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            return ecrecover(prefixedHash, v, r, s);
        }
    }
}

 
contract AccessControl is SignatureVerifier {
    using SafeMath for uint256;

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public systemAddress;
    uint256 public CLevelTxCount_ = 0;
    mapping(address => uint256) nonces;

     
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }


     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
     
    function signedByCLevel(
        bytes32 _message,
        bytes _sig
    )
    internal
    view
    onlyCLevel
    returns (bool)
    {
        address signer = recover(_message, _sig);
        require(signer != msg.sender);
        return (
        signer == cooAddress ||
        signer == ceoAddress ||
        signer == cfoAddress
        );
    }

     
     
     
    function signedBySystem(
        bytes32 _message,
        bytes _sig
    )
    internal
    view
    returns (bool)
    {
        address signer = recover(_message, _sig);
        require(signer != msg.sender);
        return (
        signer == systemAddress
        );
    }

     
    function getCEOHashing(address _newCEO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E94), _newCEO, _nonce));
    }

     
     
     
    function setCEO(
        address _newCEO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCEO != address(0) &&
            _newCEO != cfoAddress &&
            _newCEO != cooAddress
        );

        bytes32 hashedTx = getCEOHashing(_newCEO, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        ceoAddress = _newCEO;
        CLevelTxCount_++;
    }

     
    function getCFOHashing(address _newCFO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E95), _newCFO, _nonce));
    }

     
     
    function setCFO(
        address _newCFO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCFO != address(0) &&
            _newCFO != ceoAddress &&
            _newCFO != cooAddress
        );

        bytes32 hashedTx = getCFOHashing(_newCFO, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        cfoAddress = _newCFO;
        CLevelTxCount_++;
    }

     
    function getCOOHashing(address _newCOO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E96), _newCOO, _nonce));
    }

     
     
     
    function setCOO(
        address _newCOO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCOO != address(0) &&
            _newCOO != ceoAddress &&
            _newCOO != cfoAddress
        );

        bytes32 hashedTx = getCOOHashing(_newCOO, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        cooAddress = _newCOO;
        CLevelTxCount_++;
    }

    function getNonces(address _sender) public view returns (uint256) {
        return nonces[_sender];
    }
}


 
contract PonyAccessControl is AccessControl {
     
    event ContractUpgrade(address newContract);


     
    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}


 
contract PonyBase is PonyAccessControl {
     

     
     
     
    event Birth(address owner, uint256 ponyId, uint256 matronId, uint256 sireId, uint256 genes);

     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
     
     
     
     
    struct Pony {
         
         
        uint256 genes;

         
        uint64 birthTime;

         
         
         
        uint64 cooldownEndBlock;

         
         
         
         
         
         
        uint32 matronId;
        uint32 sireId;

         
         
         
         
        uint32 matingWithId;

         
         
         
         
         
        uint16 cooldownIndex;

         
         
         
         
         
        uint16 generation;

        uint16 txCount;

        uint8 unicornation;


    }

     

     
     
     
     
     
     
    uint32[10] public cooldowns = [
    uint32(1 minutes),
    uint32(5 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    uint8[5] public incubators = [
    uint8(5),
    uint8(10),
    uint8(15),
    uint8(20),
    uint8(25)
    ];

     
    uint256 public secondsPerBlock = 15;

     

     
     
     
     
     
    Pony[] ponies;

     
     
    mapping(uint256 => address) public ponyIndexToOwner;

     
     
    mapping(address => uint256) ownershipTokenCount;

     
     
     
    mapping(uint256 => address) public ponyIndexToApproved;

     
     
     
    mapping(uint256 => address) public matingAllowedToAddress;

    mapping(address => bool) public hasIncubator;

     
     
     
    SaleClockAuction public saleAuction;

     
     
     
    SiringClockAuction public siringAuction;


    BiddingClockAuction public biddingAuction;
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        ponyIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete matingAllowedToAddress[_tokenId];
             
            delete ponyIndexToApproved[_tokenId];
        }
         
        emit Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
     
     
    function _createPony(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner,
        uint16 _cooldownIndex
    )
    internal
    returns (uint)
    {
         
         
         
         
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));


        Pony memory _pony = Pony({
            genes : _genes,
            birthTime : uint64(now),
            cooldownEndBlock : 0,
            matronId : uint32(_matronId),
            sireId : uint32(_sireId),
            matingWithId : 0,
            cooldownIndex : _cooldownIndex,
            generation : uint16(_generation),
            unicornation : 0,
            txCount : 0
            });
        uint256 newPonyId = ponies.push(_pony) - 1;

        require(newPonyId == uint256(uint32(newPonyId)));

         
        emit Birth(
            _owner,
            newPonyId,
            uint256(_pony.matronId),
            uint256(_pony.sireId),
            _pony.genes
        );

         
         
        _transfer(0, _owner, newPonyId);

        return newPonyId;
    }

     
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}


 
 
 
 
contract PonyOwnership is PonyBase, ERC721 {

     
    string public constant name = "EtherPonies";
    string public constant symbol = "EP";

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ponyIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ponyIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        ponyIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));


         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return ponies.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = ponyIndexToOwner[_tokenId];

    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPonies = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 ponyId;

            for (ponyId = 1; ponyId <= totalPonies; ponyId++) {
                if (ponyIndexToOwner[ponyId] == _owner) {
                    result[resultIndex] = ponyId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _id,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(bytes4(0x486A0E97), _token, _to, _id, _nonce));
    }

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _id,
        uint256 _nonce
    )
    public
    {
        require(_to != address(0));
         
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _id, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_to != address(this));

         
        require(_owns(from, _id));
        nonces[from]++;
         
        _transfer(from, _to, _id);
    }

    function approvePreSignedHashing(
        address _token,
        address _spender,
        uint256 _tokenId,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_token, _spender, _tokenId, _nonce));
    }

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _tokenId,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_spender != address(0));
         
        bytes32 hashedTx = approvePreSignedHashing(address(this), _spender, _tokenId, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

         
        require(_owns(from, _tokenId));

        nonces[from]++;
         
        _approve(_tokenId, _spender);

         
        emit Approval(from, _spender, _tokenId);
        return true;
    }
}



 
 
 
contract PonyBreeding is PonyOwnership {

     
     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

     
     
     
    uint256 public autoBirthFee = 2 finney;

     
    uint256 public pregnantPonies;

     
     
    GeneScienceInterface public geneScience;

     
     
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

         
        require(candidateContract.isGeneScience());

         
        geneScience = candidateContract;
    }

     
     
     
    function _isReadyToMate(Pony _pon) internal view returns (bool) {
         
         
         
        return (_pon.matingWithId == 0) && (_pon.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function _isMatingPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = ponyIndexToOwner[_matronId];
        address sireOwner = ponyIndexToOwner[_sireId];

         
         
        return (matronOwner == sireOwner || matingAllowedToAddress[_sireId] == matronOwner);
    }

     
     
     
    function _triggerCooldown(Pony storage _pony) internal {
         
        _pony.cooldownEndBlock = uint64((cooldowns[_pony.cooldownIndex] / secondsPerBlock) + block.number);

         
         
         
        if (_pony.cooldownIndex < 13) {
            _pony.cooldownIndex += 1;
        }
    }

    function _triggerPregnant(Pony storage _pony, uint8 _incubator) internal {
         

        if (_incubator > 0) {
            uint64 initialCooldown = uint64(cooldowns[_pony.cooldownIndex] / secondsPerBlock);
            _pony.cooldownEndBlock = uint64((initialCooldown - (initialCooldown * incubators[_incubator] / 100)) + block.number);

        } else {
            _pony.cooldownEndBlock = uint64((cooldowns[_pony.cooldownIndex] / secondsPerBlock) + block.number);
        }
         
         
         
        if (_pony.cooldownIndex < 13) {
            _pony.cooldownIndex += 1;
        }
    }

     
     
     
     
    function approveSiring(address _addr, uint256 _sireId)
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        matingAllowedToAddress[_sireId] = _addr;
    }

     
     
     
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

     
     
    function _isReadyToGiveBirth(Pony _matron) private view returns (bool) {
        return (_matron.matingWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function isReadyToMate(uint256 _ponyId)
    public
    view
    returns (bool)
    {
        require(_ponyId > 0);
        Pony storage pon = ponies[_ponyId];
        return _isReadyToMate(pon);
    }

     
     
    function isPregnant(uint256 _ponyId)
    public
    view
    returns (bool)
    {
        require(_ponyId > 0);
         
        return ponies[_ponyId].matingWithId != 0;
    }

     
     
     
     
     
     
    function _isValidMatingPair(
        Pony storage _matron,
        uint256 _matronId,
        Pony storage _sire,
        uint256 _sireId
    )
    private
    view
    returns (bool)
    {
         
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

         
        return true;
    }

     
     
    function canMateWithViaAuction(uint256 _matronId, uint256 _sireId)
    public
    view
    returns (bool)
    {
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
     
     
     
    function canMateWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isMatingPermitted(_sireId, _matronId);
    }

     
     
    function _mateWith(uint256 _matronId, uint256 _sireId, uint8 _incubator) internal {
         
        Pony storage sire = ponies[_sireId];
        Pony storage matron = ponies[_matronId];

         
        matron.matingWithId = uint32(_sireId);

         
        _triggerCooldown(sire);
        _triggerPregnant(matron, _incubator);

         
         
        delete matingAllowedToAddress[_matronId];
        delete matingAllowedToAddress[_sireId];

         
        pregnantPonies++;

         

        emit Pregnant(ponyIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

    function getIncubatorHashing(
        address _sender,
        uint8 _incubator,
        uint256 txCount
    )
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(bytes4(0x486A0E98), _sender, _incubator, txCount));
    }

     
     
     
     
     
    function mateWithAuto(uint256 _matronId, uint256 _sireId, uint8 _incubator, bytes _sig)
    external
    payable
    whenNotPaused
    {
         
        require(msg.value >= autoBirthFee);

         
        require(_owns(msg.sender, _matronId));

        require(_isMatingPermitted(_sireId, _matronId));

         
        Pony storage matron = ponies[_matronId];

         
        require(_isReadyToMate(matron));

         
        Pony storage sire = ponies[_sireId];

         
        require(_isReadyToMate(sire));

         
        require(
            _isValidMatingPair(matron, _matronId, sire, _sireId)
        );

        if (_incubator == 0 && hasIncubator[msg.sender]) {
            _mateWith(_matronId, _sireId, _incubator);
        } else {
            bytes32 hashedTx = getIncubatorHashing(msg.sender, _incubator, nonces[msg.sender]);
            require(signedBySystem(hashedTx, _sig));
            nonces[msg.sender]++;

             
            if (!hasIncubator[msg.sender]) {
                hasIncubator[msg.sender] = true;
            }
            _mateWith(_matronId, _sireId, _incubator);
        }
    }

     
     
     
     
     
     
     
     
    function giveBirth(uint256 _matronId)
    external
    whenNotPaused
    returns (uint256)
    {
         
        Pony storage matron = ponies[_matronId];

         
        require(matron.birthTime != 0);

         
        require(_isReadyToGiveBirth(matron));

         
        uint256 sireId = matron.matingWithId;
        Pony storage sire = ponies[sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

         
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);
         
        uint16 cooldownIndex = geneScience.processCooldown(parentGen + 1, block.number);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }
         
        address owner = ponyIndexToOwner[_matronId];
        uint256 ponyId = _createPony(_matronId, matron.matingWithId, parentGen + 1, childGenes, owner, cooldownIndex);

         
         
        delete matron.matingWithId;

         
        pregnantPonies--;

         
        msg.sender.transfer(autoBirthFee);

         
        return ponyId;
    }
    
    function  setMatingSeason(bool _isMatingSeason) external onlyCLevel {
        geneScience.setMatingSeason(_isMatingSeason);
    }
}


 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
        uint256 price;
        bool allowPayDekla;
    }

     
    ERC721 public nonFungibleContract;

    ERC20 public tokens;

     
     
    uint256 public ownerCut = 500;

     
    mapping(uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId)
        );
    }


     
     
    function _bidEth(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(!auction.allowPayDekla);
         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = auction.price;
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            seller.transfer(sellerProceeds);
        }

         
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _bidDkl(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(auction.allowPayDekla);
         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = auction.price;
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            tokens.transfer(seller, sellerProceeds);
        }
         
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }


     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.price > 0);
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }



     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}







 
contract Pausable is AccessControl{
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() onlyCEO whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() onlyCEO whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}


 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
    constructor(address _nftAddress, address _tokenAddress) public {
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        tokens = ERC20(_tokenAddress);
        nonFungibleContract = candidateContract;
    }


     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyCEO
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 price,
        bool allowPayDekla

    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
        auction.seller,
        auction.price,
        auction.allowPayDekla
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return auction.price;
    }

}


 
 
contract SiringClockAuction is ClockAuction {

     
     
    bool public isSiringClockAuction = true;

    uint256 public prizeCut = 100;

    uint256 public tokenDiscount = 100;

    address prizeAddress;

     
    constructor(address _nftAddr, address _tokenAddress, address _prizeAddress) public
    ClockAuction(_nftAddr, _tokenAddress) {
        prizeAddress = _prizeAddress;
    }

     
     
     
     
    function createEthAuction(
        uint256 _tokenId,
        address _seller,
        uint256 _price
    )
    external
    {

        require(msg.sender == address(nonFungibleContract));
        require(_price > 0);
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _price,
            false
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
     
    function createDklAuction(
        uint256 _tokenId,
        address _seller,
        uint256 _price
    )
    external
    {

        require(msg.sender == address(nonFungibleContract));
        require(_price > 0);
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _price,
            true
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
     
    function bidEth(uint256 _tokenId)
    external
    payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bidEth(_tokenId, msg.value);
         
         

        uint256 prizeAmount = (msg.value * prizeCut) / 10000;
        prizeAddress.transfer(prizeAmount);

        _transfer(seller, _tokenId);
    }


    function bidDkl(uint256 _tokenId,
        uint256 _price,
        uint256 _fee,
        bytes _signature,
        uint256 _nonce)
    external
    whenNotPaused
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        tokens.transferPreSigned(_signature, address(this), _price, _fee, _nonce);
         
        _bidDkl(_tokenId, _price);
        tokens.transfer(msg.sender, _fee);
        address spender = tokens.recoverSigner(_signature, address(this), _price, _fee, _nonce);
        uint256 discountAmount = (_price * tokenDiscount) / 10000;
        uint256 prizeAmount = (_price * prizeCut) / 10000;
        tokens.transfer(prizeAddress, prizeAmount);
        tokens.transfer(spender, discountAmount);
        _transfer(seller, _tokenId);
    }

    function setCut(uint256 _prizeCut, uint256 _tokenDiscount)
    external
    {
        require(msg.sender == address(nonFungibleContract));
        require(_prizeCut + _tokenDiscount < ownerCut);

        prizeCut = _prizeCut;
        tokenDiscount = _tokenDiscount;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );

        nftAddress.transfer(address(this).balance);
    }

    function withdrawDklBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );

        tokens.transfer(nftAddress, tokens.balanceOf(this));
    }
}





 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

    uint256 public prizeCut = 100;

    uint256 public tokenDiscount = 100;

    address prizeAddress;

     
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

     
    constructor(address _nftAddr, address _token, address _prizeAddress) public
    ClockAuction(_nftAddr, _token) {
        prizeAddress = _prizeAddress;
    }

     
     
     
    function createEthAuction(
        uint256 _tokenId,
        address _seller,
        uint256 _price
    )
    external
    {

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _price,
            false
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function createDklAuction(
        uint256 _tokenId,
        address _seller,
        uint256 _price
    )
    external
    {

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _price,
            true
        );
        _addAuction(_tokenId, auction);
    }


    function bidEth(uint256 _tokenId)
    external
    payable
    whenNotPaused
    {
         
        _bidEth(_tokenId, msg.value);
        uint256 prizeAmount = (msg.value * prizeCut) / 10000;
        prizeAddress.transfer(prizeAmount);
        _transfer(msg.sender, _tokenId);
    }


    function bidDkl(uint256 _tokenId,
        uint256 _price,
        uint256 _fee,
        bytes _signature,
        uint256 _nonce)
    external
    whenNotPaused
    {
        address buyer = tokens.recoverSigner(_signature, address(this), _price, _fee, _nonce);
        tokens.transferPreSigned(_signature, address(this), _price, _fee, _nonce);
         
        _bidDkl(_tokenId, _price);
        uint256 prizeAmount = (_price * prizeCut) / 10000;
        uint256 discountAmount = (_price * tokenDiscount) / 10000;
        tokens.transfer(buyer, discountAmount);
        tokens.transfer(prizeAddress, prizeAmount);
        _transfer(buyer, _tokenId);
    }

    function setCut(uint256 _prizeCut, uint256 _tokenDiscount)
    external
    {
        require(msg.sender == address(nonFungibleContract));
        require(_prizeCut + _tokenDiscount < ownerCut);

        prizeCut = _prizeCut;
        tokenDiscount = _tokenDiscount;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );

        nftAddress.transfer(address(this).balance);
    }

    function withdrawDklBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );

        tokens.transfer(nftAddress, tokens.balanceOf(this));
    }
}


 
 
 
contract PonyAuction is PonyBreeding {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

         
        require(candidateContract.isSiringClockAuction());

         
        siringAuction = candidateContract;
    }

     
     
    function setBiddingAuctionAddress(address _address) external onlyCEO {
        BiddingClockAuction candidateContract = BiddingClockAuction(_address);

         
        require(candidateContract.isBiddingClockAuction());

         
        biddingAuction = candidateContract;
    }


     
     
    function createEthSaleAuction(
        uint256 _PonyId,
        uint256 _price
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _PonyId));
         
         
         
        require(!isPregnant(_PonyId));
        _approve(_PonyId, saleAuction);
         
         
        saleAuction.createEthAuction(
            _PonyId,
            msg.sender,
            _price
        );
    }


     
     
    function delegateDklSaleAuction(
        uint256 _tokenId,
        uint256 _price,
        bytes _ponySig,
        uint256 _nonce
    )
    external
    whenNotPaused
    {
        bytes32 hashedTx = approvePreSignedHashing(address(this), saleAuction, _tokenId, _nonce);
        address from = recover(hashedTx, _ponySig);
         
         
         
        require(_owns(from, _tokenId));
         
         
         
        require(!isPregnant(_tokenId));
        approvePreSigned(_ponySig, saleAuction, _tokenId, _nonce);
         
         
        saleAuction.createDklAuction(
            _tokenId,
            from,
            _price
        );
    }


     
     
    function delegateDklSiringAuction(
        uint256 _tokenId,
        uint256 _price,
        bytes _ponySig,
        uint256 _nonce
    )
    external
    whenNotPaused
    {
        bytes32 hashedTx = approvePreSignedHashing(address(this), siringAuction, _tokenId, _nonce);
        address from = recover(hashedTx, _ponySig);
         
         
         
        require(_owns(from, _tokenId));
         
         
         
        require(!isPregnant(_tokenId));
        approvePreSigned(_ponySig, siringAuction, _tokenId, _nonce);
         
         
        siringAuction.createDklAuction(
            _tokenId,
            from,
            _price
        );
    }

     
     
    function delegateDklBidAuction(
        uint256 _tokenId,
        uint256 _price,
        bytes _ponySig,
        uint256 _nonce,
        uint16 _durationIndex
    )
    external
    whenNotPaused
    {
        bytes32 hashedTx = approvePreSignedHashing(address(this), biddingAuction, _tokenId, _nonce);
        address from = recover(hashedTx, _ponySig);
         
         
         
        require(_owns(from, _tokenId));
         
         
         
        require(!isPregnant(_tokenId));
        approvePreSigned(_ponySig, biddingAuction, _tokenId, _nonce);
         
         
        biddingAuction.createDklAuction(_tokenId, from, _durationIndex, _price);
    }


     
     
     
    function createEthSiringAuction(
        uint256 _PonyId,
        uint256 _price
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _PonyId));
        require(isReadyToMate(_PonyId));
        _approve(_PonyId, siringAuction);
         
         
        siringAuction.createEthAuction(
            _PonyId,
            msg.sender,
            _price
        );
    }

     
     
    function createDklSaleAuction(
        uint256 _PonyId,
        uint256 _price
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _PonyId));
         
         
         
        require(!isPregnant(_PonyId));
        _approve(_PonyId, saleAuction);
         
         
        saleAuction.createDklAuction(
            _PonyId,
            msg.sender,
            _price
        );
    }

     
     
     
    function createDklSiringAuction(
        uint256 _PonyId,
        uint256 _price
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _PonyId));
        require(isReadyToMate(_PonyId));
        _approve(_PonyId, siringAuction);
         
         
        siringAuction.createDklAuction(
            _PonyId,
            msg.sender,
            _price
        );
    }

    function createEthBidAuction(
        uint256 _ponyId,
        uint256 _price,
        uint16 _durationIndex
    ) external whenNotPaused {
        require(_owns(msg.sender, _ponyId));
        _approve(_ponyId, biddingAuction);
        biddingAuction.createETHAuction(_ponyId, msg.sender, _durationIndex, _price);
    }

    function createDeklaBidAuction(
        uint256 _ponyId,
        uint256 _price,
        uint16 _durationIndex
    ) external whenNotPaused {
        require(_owns(msg.sender, _ponyId));
        _approve(_ponyId, biddingAuction);
        biddingAuction.createDklAuction(_ponyId, msg.sender, _durationIndex, _price);
    }

     
     
     
     
    function bidOnEthSiringAuction(
        uint256 _sireId,
        uint256 _matronId,
        uint8 _incubator,
        bytes _sig
    )
    external
    payable
    whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToMate(_matronId));
        require(canMateWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        siringAuction.bidEth.value(msg.value - autoBirthFee)(_sireId);
        if (_incubator == 0 && hasIncubator[msg.sender]) {
            _mateWith(_matronId, _sireId, _incubator);
        } else {
            bytes32 hashedTx = getIncubatorHashing(msg.sender, _incubator, nonces[msg.sender]);
            require(signedBySystem(hashedTx, _sig));
            nonces[msg.sender]++;

             
            if (!hasIncubator[msg.sender]) {
                hasIncubator[msg.sender] = true;
            }
            _mateWith(_matronId, _sireId, _incubator);
        }
    }

     
     
     
     
    function bidOnDklSiringAuction(
        uint256 _sireId,
        uint256 _matronId,
        uint8 _incubator,
        bytes _incubatorSig,
        uint256 _price,
        uint256 _fee,
        bytes _delegateSig,
        uint256 _nonce

    )
    external
    payable
    whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToMate(_matronId));
        require(canMateWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= autoBirthFee);
        require(_price >= currentPrice);

         
        siringAuction.bidDkl(_sireId, _price, _fee, _delegateSig, _nonce);
        if (_incubator == 0 && hasIncubator[msg.sender]) {
            _mateWith(_matronId, _sireId, _incubator);
        } else {
            bytes32 hashedTx = getIncubatorHashing(msg.sender, _incubator, nonces[msg.sender]);
            require(signedBySystem(hashedTx, _incubatorSig));
            nonces[msg.sender]++;

             
            if (!hasIncubator[msg.sender]) {
                hasIncubator[msg.sender] = true;
            }
            _mateWith(_matronId, _sireId, _incubator);
        }
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
        biddingAuction.withdrawBalance();
    }

    function withdrawAuctionDklBalance() external onlyCLevel {
        saleAuction.withdrawDklBalance();
        siringAuction.withdrawDklBalance();
        biddingAuction.withdrawDklBalance();
    }


    function setBiddingRate(uint256 _prizeCut, uint256 _tokenDiscount) external onlyCLevel {
        biddingAuction.setCut(_prizeCut, _tokenDiscount);
    }

    function setSaleRate(uint256 _prizeCut, uint256 _tokenDiscount) external onlyCLevel {
        saleAuction.setCut(_prizeCut, _tokenDiscount);
    }

    function setSiringRate(uint256 _prizeCut, uint256 _tokenDiscount) external onlyCLevel {
        siringAuction.setCut(_prizeCut, _tokenDiscount);
    }
}

 
 
 
contract BiddingAuctionBase {
     
    uint256 public secondsPerBlock = 15;

     
    struct Auction {
         
        address seller;
         
        uint16 durationIndex;
         
         
        uint64 startedAt;

        uint64 auctionEndBlock;
         
        uint256 startingPrice;

        bool allowPayDekla;
    }

    uint32[4] public auctionDuration = [
     
     uint32(2 days),
     uint32(3 days),
     uint32(4 days),
     uint32(5 days)
    ];

     
    ERC721 public nonFungibleContract;


    uint256 public ownerCut = 500;

     
    mapping(uint256 => Auction) public tokenIdToAuction;

    event AuctionCreated(uint256 tokenId);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }


     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }



     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}


 
 
contract BiddingAuction is Pausable, BiddingAuctionBase {
     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);



     
     
     
     
    constructor(address _nftAddress) public {

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    function cancelAuctionHashing(
        uint256 _tokenId,
        uint64 _endblock
    )
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(bytes4(0x486A0E9E), _tokenId, _endblock));
    }

     
     
     
     
     
    function cancelAuction(
        uint256 _tokenId,
        bytes _sig
    )
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        address seller = auction.seller;
        uint64 endblock = auction.auctionEndBlock;
        require(msg.sender == seller);
        require(endblock < block.number);

        bytes32 hashedTx = cancelAuctionHashing(_tokenId, endblock);
        require(signedBySystem(hashedTx, _sig));

        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyCLevel
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint64 startedAt,
        uint16 durationIndex,
        uint64 auctionEndBlock,
        uint256 startingPrice,
        bool allowPayDekla
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
        auction.seller,
        auction.startedAt,
        auction.durationIndex,
        auction.auctionEndBlock,
        auction.startingPrice,
        auction.allowPayDekla
        );
    }

    function setSecondsPerBlock(uint256 secs) external onlyCEO {
        secondsPerBlock = secs;
    }

}


contract BiddingWallet is AccessControl {

     
    mapping(address => uint) public EthBalances;

    mapping(address => uint) public DeklaBalances;

    ERC20 public tokens;

     
     
    uint public EthLimit = 50000000000000000;
    uint public DeklaLimit = 100;

    uint256 public totalEthDeposit;
    uint256 public totalDklDeposit;

    event withdrawSuccess(address receiver, uint amount);
    event cancelPendingWithdrawSuccess(address sender);

    function getNonces(address _address) public view returns (uint256) {
        return nonces[_address];
    }

    function setSystemAddress(address _systemAddress, address _tokenAddress) internal {
        systemAddress = _systemAddress;
        tokens = ERC20(_tokenAddress);
    }

     
    function depositETH() payable external {
        require(msg.value >= EthLimit);
        EthBalances[msg.sender] = EthBalances[msg.sender] + msg.value;
        totalEthDeposit = totalEthDeposit + msg.value;
    }

    function depositDekla(
        uint256 _amount,
        uint256 _fee,
        bytes _signature,
        uint256 _nonce)
    external {
        address sender = tokens.recoverSigner(_signature, address(this), _amount, _fee, _nonce);
        tokens.transferPreSigned(_signature, address(this), _amount, _fee, _nonce);
        DeklaBalances[sender] = DeklaBalances[sender] + _amount;
        totalDklDeposit = totalDklDeposit + _amount;
    }


    function withdrawAmountHashing(uint256 _amount, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E9B), _amount, _nonce));
    }

     
    function withdrawEth(
        uint256 _amount,
        bytes _sig
    ) external {
        require(EthBalances[msg.sender] >= _amount);

        bytes32 hashedTx = withdrawAmountHashing(_amount, nonces[msg.sender]);
        require(signedBySystem(hashedTx, _sig));

        EthBalances[msg.sender] = EthBalances[msg.sender] - _amount;
        totalEthDeposit = totalEthDeposit - _amount;
        msg.sender.transfer(_amount);

        nonces[msg.sender]++;
        emit withdrawSuccess(msg.sender, _amount);
    }

     
    function withdrawDekla(
        uint256 _amount,
        bytes _sig
    ) external {
        require(DeklaBalances[msg.sender] >= _amount);

        bytes32 hashedTx = withdrawAmountHashing(_amount, nonces[msg.sender]);
        require(signedBySystem(hashedTx, _sig));

        DeklaBalances[msg.sender] = DeklaBalances[msg.sender] - _amount;
        totalDklDeposit = totalDklDeposit - _amount;
        tokens.transfer(msg.sender, _amount);

        nonces[msg.sender]++;
        emit withdrawSuccess(msg.sender, _amount);
    }


    event valueLogger(uint256 value);
     
    function winBidEth(
        address winner,
        address seller,
        uint256 sellerProceeds,
        uint256 auctioneerCut
    ) internal {
        require(EthBalances[winner] >= sellerProceeds + auctioneerCut);
        seller.transfer(sellerProceeds);
        EthBalances[winner] = EthBalances[winner] - (sellerProceeds + auctioneerCut);
    }

     
    function winBidDekla(
        address winner,
        address seller,
        uint256 sellerProceeds,
        uint256 auctioneerCut
    ) internal {
        require(DeklaBalances[winner] >= sellerProceeds + auctioneerCut);
        tokens.transfer(seller, sellerProceeds);
        DeklaBalances[winner] = DeklaBalances[winner] - (sellerProceeds + auctioneerCut);
    }

    function() public {
        revert();
    }
}


 
 
contract BiddingClockAuction is BiddingAuction, BiddingWallet {

    address public prizeAddress;

    uint256 public prizeCut = 100;

    uint256 public tokenDiscount = 100;
     
     
    bool public isBiddingClockAuction = true;

    modifier onlySystem() {
        require(msg.sender == systemAddress);
        _;
    }

     
    constructor(
        address _nftAddr,
        address _tokenAddress,
        address _prizeAddress,
        address _systemAddress,
        address _ceoAddress,
        address _cfoAddress,
        address _cooAddress)
    public
    BiddingAuction(_nftAddr) {
         
        require(_systemAddress != address(0));
        require(_tokenAddress != address(0));
        require(_ceoAddress != address(0));
        require(_cooAddress != address(0));
        require(_cfoAddress != address(0));
        require(_prizeAddress != address(0));

        setSystemAddress(_systemAddress, _tokenAddress);

        ceoAddress = _ceoAddress;
        cooAddress = _cooAddress;
        cfoAddress = _cfoAddress;
        prizeAddress = _prizeAddress;
    }


     
     
    function createETHAuction(
        uint256 _tokenId,
        address _seller,
        uint16 _durationIndex,
        uint256 _startingPrice
    )
    external
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 auctionEndBlock = uint64((auctionDuration[_durationIndex] / secondsPerBlock) + block.number);
        Auction memory auction = Auction(
            _seller,
            _durationIndex,
            uint64(now),
            auctionEndBlock,
            _startingPrice,
            false
        );
        _addAuction(_tokenId, auction);
    }

    function setCut(uint256 _prizeCut, uint256 _tokenDiscount)
    external
    {
        require(msg.sender == address(nonFungibleContract));
        require(_prizeCut + _tokenDiscount < ownerCut);

        prizeCut = _prizeCut;
        tokenDiscount = _tokenDiscount;
    }

     
     
    function createDklAuction(
        uint256 _tokenId,
        address _seller,
        uint16 _durationIndex,
        uint256 _startingPrice
    )
    external

    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 auctionEndBlock = uint64((auctionDuration[_durationIndex] / secondsPerBlock) + block.number);
        Auction memory auction = Auction(
            _seller,
            _durationIndex,
            uint64(now),
            auctionEndBlock,
            _startingPrice,
            true
        );
        _addAuction(_tokenId, auction);
    }

    function getNonces(address _address) public view returns (uint256) {
        return nonces[_address];
    }

    function auctionEndHashing(uint _amount, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F0E), _tokenId, _amount));
    }

    function auctionEthEnd(address _winner, uint _amount, uint256 _tokenId, bytes _sig) public onlySystem {
        bytes32 hashedTx = auctionEndHashing(_amount, _tokenId);
        require(recover(hashedTx, _sig) == _winner);
        Auction storage auction = tokenIdToAuction[_tokenId];
        uint64 endblock = auction.auctionEndBlock;
        require(endblock < block.number);
        require(!auction.allowPayDekla);
        uint256 prize = _amount * prizeCut / 10000;
        uint256 auctioneerCut = _computeCut(_amount) - prize;
        uint256 sellerProceeds = _amount - auctioneerCut;
        winBidEth(_winner, auction.seller, sellerProceeds, auctioneerCut);
        prizeAddress.transfer(prize);
        _removeAuction(_tokenId);
        _transfer(_winner, _tokenId);
        emit AuctionSuccessful(_tokenId, _amount, _winner);
    }

    function auctionDeklaEnd(address _winner, uint _amount, uint256 _tokenId, bytes _sig) public onlySystem {
        bytes32 hashedTx = auctionEndHashing(_amount, _tokenId);
        require(recover(hashedTx, _sig) == _winner);
        Auction storage auction = tokenIdToAuction[_tokenId];
        uint64 endblock = auction.auctionEndBlock;
        require(endblock < block.number);
        require(auction.allowPayDekla);
        uint256 prize = _amount * prizeCut / 10000;
        uint256 discountAmount = _amount * tokenDiscount / 10000;
        uint256 auctioneerCut = _computeCut(_amount) - discountAmount - prizeCut;
        uint256 sellerProceeds = _amount - auctioneerCut;
        winBidDekla(_winner, auction.seller, sellerProceeds, auctioneerCut);
        tokens.transfer(prizeAddress, prize);
        tokens.transfer(_winner, discountAmount);
        _removeAuction(_tokenId);
        _transfer(_winner, _tokenId);
        emit AuctionSuccessful(_tokenId, _amount, _winner);
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );

        nftAddress.transfer(address(this).balance - totalEthDeposit);
    }

    function withdrawDklBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == nftAddress
        );
        tokens.transfer(nftAddress, tokens.balanceOf(this) - totalDklDeposit);
    }
}

 
contract PonyMinting is PonyAuction {

     
    uint256 public constant PROMO_CREATION_LIMIT = 50;
    uint256 public constant GEN0_CREATION_LIMIT = 4950;


     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
     
     
    function createPromoPony(uint256 _genes, address _owner) external onlyCOO {
        address ponyOwner = _owner;
        if (ponyOwner == address(0)) {
            ponyOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createPony(0, 0, 0, _genes, ponyOwner, 0);
    }

     
     
    function createGen0(uint256 _genes, uint256 _price, uint16 _durationIndex, bool _saleDKL ) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 ponyId = _createPony(0, 0, 0, _genes, ceoAddress, 0);

        _approve(ponyId, biddingAuction);

        if(_saleDKL) {
            biddingAuction.createDklAuction(ponyId, ceoAddress, _durationIndex, _price);
        } else {
            biddingAuction.createETHAuction(ponyId, ceoAddress, _durationIndex, _price);
        }
        gen0CreatedCount++;
    }

}


contract PonyUpgrade is PonyMinting {
    event PonyUpgraded(uint256 upgradedPony, uint256 tributePony, uint8 unicornation);

    function upgradePonyHashing(uint256 _upgradeId, uint256 _txCount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E9D), _upgradeId, _txCount));
    }

    function upgradePony(uint256 _upgradeId, uint256 _tributeId, bytes _sig)
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _upgradeId));
        require(_upgradeId != _tributeId);

        Pony storage upPony = ponies[_upgradeId];

        bytes32 hashedTx = upgradePonyHashing(_upgradeId, upPony.txCount);
        require(signedBySystem(hashedTx, _sig));

        upPony.txCount += 1;
        if (upPony.unicornation == 0) {
            if (geneScience.upgradePonyResult(upPony.unicornation, block.number)) {
                upPony.unicornation += 1;
                emit PonyUpgraded(_upgradeId, _tributeId, upPony.unicornation);
            }
        }
        else if (upPony.unicornation > 0) {
            require(_owns(msg.sender, _tributeId));

            if (geneScience.upgradePonyResult(upPony.unicornation, block.number)) {
                upPony.unicornation += 1;
                _transfer(msg.sender, address(0), _tributeId);
                emit PonyUpgraded(_upgradeId, _tributeId, upPony.unicornation);
            } else if (upPony.unicornation == 2) {
                upPony.unicornation += 1;
                _transfer(msg.sender, address(0), _tributeId);
                emit PonyUpgraded(_upgradeId, _tributeId, upPony.unicornation);
            }
        }
    }
}

 
 
 
contract PonyCore is PonyUpgrade {

    event WithdrawEthBalanceSuccessful(address sender, uint256 amount);
    event WithdrawDeklaBalanceSuccessful(address sender, uint256 amount);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    ERC20 public token;

     
    constructor(
        address _ceoAddress,
        address _cfoAddress,
        address _cooAddress,
        address _systemAddress,
        address _tokenAddress
    ) public {
         
        require(_ceoAddress != address(0));
        require(_cooAddress != address(0));
        require(_cfoAddress != address(0));
        require(_systemAddress != address(0));
        require(_tokenAddress != address(0));

         
        paused = true;

         
        ceoAddress = _ceoAddress;
        cfoAddress = _cfoAddress;
        cooAddress = _cooAddress;
        systemAddress = _systemAddress;
        token = ERC20(_tokenAddress);

         
        _createPony(0, 0, 0, uint256(- 1), address(0), 0);
    }

     
    modifier validToken() {
        require(token != address(0));
        _;
    }

    function getTokenAddressHashing(address _token, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A1216), _token, _nonce));
    }

    function setTokenAddress(address _token, bytes _sig) external onlyCLevel {
        bytes32 hashedTx = getTokenAddressHashing(_token, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        token = ERC20(_token);
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
    }

     
     
    function getPony(uint256 _id)
    external
    view
    returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint16 upgradeIndex,
        uint8 unicornation
    ) {
        Pony storage pon = ponies[_id];

         
        isGestating = (pon.matingWithId != 0);
        isReady = (pon.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(pon.cooldownIndex);
        nextActionAt = uint256(pon.cooldownEndBlock);
        siringWithId = uint256(pon.matingWithId);
        birthTime = uint256(pon.birthTime);
        matronId = uint256(pon.matronId);
        sireId = uint256(pon.sireId);
        generation = uint256(pon.generation);
        genes = pon.genes;
        upgradeIndex = pon.txCount;
        unicornation = pon.unicornation;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(geneScience != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

    function withdrawBalanceHashing(address _address, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A1217), _address, _nonce));
    }

    function withdrawEthBalance(address _withdrawWallet, bytes _sig) external onlyCLevel {
        bytes32 hashedTx = withdrawBalanceHashing(_withdrawWallet, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));

        uint256 balance = address(this).balance;

         
        uint256 subtractFees = (pregnantPonies + 1) * autoBirthFee;
        require(balance > 0);
        require(balance > subtractFees);

        nonces[msg.sender]++;
        _withdrawWallet.transfer(balance - subtractFees);
        emit WithdrawEthBalanceSuccessful(_withdrawWallet, balance - subtractFees);
    }


    function withdrawDeklaBalance(address _withdrawWallet, bytes _sig) external validToken onlyCLevel {
        bytes32 hashedTx = withdrawBalanceHashing(_withdrawWallet, nonces[msg.sender]);
        require(signedByCLevel(hashedTx, _sig));

        uint256 balance = token.balanceOf(this);
        require(balance > 0);

        nonces[msg.sender]++;
        token.transfer(_withdrawWallet, balance);
        emit WithdrawDeklaBalanceSuccessful(_withdrawWallet, balance);
    }
}