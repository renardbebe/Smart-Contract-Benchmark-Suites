 

pragma solidity ^0.4.21;

 
 
 
 
contract ContractOwned {
    address public contract_owner;
    address public contract_newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        contract_owner = msg.sender;
    }

    modifier contract_onlyOwner {
        require(msg.sender == contract_owner);
        _;
    }

    function transferOwnership(address _newOwner) public contract_onlyOwner {
        contract_newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == contract_newOwner);
        emit OwnershipTransferred(contract_owner, contract_newOwner);
        contract_owner = contract_newOwner;
        contract_newOwner = address(0);
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
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

  

 
contract CustomEvents {
    event ChibiCreated(uint tokenId, address indexed _owner, bool founder, string _name, uint16[13] dna, uint father, uint mother, uint gen, uint adult, string infoUrl);
    event ChibiForFusion(uint tokenId, uint price);
    event ChibiForFusionCancelled(uint tokenId);
    event WarriorCreated(uint tokenId, string battleRoar);
}

 
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function tokenMetadata(uint256 _tokenId) constant public returns (string infoUrl);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract GeneInterface {
     
     
    function createGenes(address, uint, bool, uint, uint) external view returns (
    uint16[13] genes
);
 
 
 
 
function splitGenes(address, uint, uint) external view returns (
    uint16[13] genes
    );
    function exhaustAfterFusion(uint _gen, uint _counter, uint _exhaustionTime) public pure returns (uint);
    function exhaustAfterBattle(uint _gen, uint _exhaust) public pure returns (uint);
        
}

 
contract FcfInterface {
    function balanceOf(address) public pure returns (uint) {}
    function transferFrom(address, address, uint) public pure returns (bool) {}
}

 
contract BattleInterface {
    function addWarrior(address, uint, uint8, string) pure public returns (bool) {}
    function isDead(uint) public pure returns (bool) {}
}
 

 
contract ChibiFighters is ERC721, ContractOwned, CustomEvents {
    using SafeMath for uint256;

     
    uint256 private totalTokens;

     
    mapping (uint256 => address) private tokenOwner;

     
    mapping (uint256 => address) private tokenApprovals;

     
    mapping (address => uint256[]) private ownedTokens;

     
    mapping(uint256 => uint256) private ownedTokensIndex;

     
    GeneInterface geneContract;
    FcfInterface fcfContract;
    BattleInterface battleContract;
    address battleContractAddress;

     
    uint public priceChibi;
     
    uint priceFusionChibi;

     
    uint uniqueCounter;

     
    uint adultTime;

     
    uint exhaustionTime;
    
     
    uint comission;
    
     
    address battleRemoveContractAddress;

    struct Chibi {
         
        address owner;
         
        bool founder;
         
        string nameChibi;
         
         
        uint16[13] dna;
         
         
        uint256 father;
        uint256 mother;
         
         
        uint gen;
         
        uint256[] fusions;
         
        bool forFusion;
         
        uint256 fusionPrice;
         
        uint256 exhausted;
         
        uint256 adult;
         
        string infoUrl;
    }

     
    string _infoUrlPrefix;

    Chibi[] public chibies;

    string public constant name = "Chibi Fighters";
    string public constant symbol = "CBF";

     
    bool paused;
    bool fcfPaused;
    bool fusionPaused;  

     
    constructor() public {
         
        uniqueCounter = 0;
         
        priceChibi = 100000000000000000;
         
        priceFusionChibi = 10000000000000000;
         
        adultTime = 2 hours;
         
        exhaustionTime = 1 hours;
         
        paused = true;
        fcfPaused = true;
        fusionPaused = true;
         
        comission = 90; 

        _infoUrlPrefix = "https://chibigame.io/chibis.php?idj=";
    }
    
     
    function setComission(uint _comission) public contract_onlyOwner returns(bool success) {
        comission = _comission;
        return true;
    }
    
     
    function setMinimumPriceFusion(uint _price) public contract_onlyOwner returns(bool success) {
        priceFusionChibi = _price;
        return true;
    }
    
     
    function setAdultTime(uint _adultTimeSecs) public contract_onlyOwner returns(bool success) {
        adultTime = _adultTimeSecs;
        return true;
    }

     
    function setExhaustionTime(uint _exhaustionTime) public contract_onlyOwner returns(bool success) {
        exhaustionTime = _exhaustionTime;
        return true;
    }
    
     
    function setGameState(bool _setPaused) public contract_onlyOwner returns(bool _paused) {
        paused = _setPaused;
        fcfPaused = _setPaused;
        fusionPaused = _setPaused;
        return paused;
    }
    
     
    function setGameStateFCF(bool _setPaused) public contract_onlyOwner returns(bool _pausedFCF) {
        fcfPaused = _setPaused;
        return fcfPaused;
    }
    
     
    function setGameStateFusion(bool _setPaused) public contract_onlyOwner returns(bool _pausedFusions) {
        fusionPaused = _setPaused;
        return fusionPaused;
    }

     
    function getGameState() public constant returns(bool _paused) {
        return paused;
    }

     
    function setInfoUrlPrefix(string prefix) external contract_onlyOwner returns (string infoUrlPrefix) {
        _infoUrlPrefix = prefix;
        return _infoUrlPrefix;
    }
    
     
    function changeInfoUrl(uint _tokenId, string _infoUrl) public returns (bool success) {
        if (ownerOf(_tokenId) != msg.sender && msg.sender != contract_owner) revert();
        chibies[_tokenId].infoUrl = _infoUrl;
        return true;
    }

     
    function setFcfContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        fcfContract = FcfInterface(_address);
        return true;
    }

     
    function setBattleContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        battleContract = BattleInterface(_address);
        battleContractAddress = _address;
        return true;
    }
    
     
    function setBattleRemoveContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        battleRemoveContractAddress = _address;
        return true;
    }

     
    function renameChibi(uint _tokenId, string _name) public returns (bool success){
        require(ownerOf(_tokenId) == msg.sender);

        chibies[_tokenId].nameChibi = _name;
        return true;
    }

     
    function isNecromancer(uint _tokenId) public view returns (bool) {
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 1000) {
                return true;
            }
        }
        return false;
    }

     
    function buyChibiWithFcf(string _name, string _battleRoar, uint8 _region, uint _seed) public returns (bool success) {
         
        require(fcfContract.balanceOf(msg.sender) >= 1 * 10 ** 18);
        require(fcfPaused == false);
         
        uint fcfBefore = fcfContract.balanceOf(address(this));
         
         
         
        if (fcfContract.transferFrom(msg.sender, this, 1 * 10 ** 18)) {
            _mint(_name, _battleRoar, _region, _seed, true, 0);
        }
         
        assert(fcfBefore == fcfContract.balanceOf(address(this)) - 1 * 10 ** 18);
        return true;
    }

     
    function setChibiForFusion(uint _tokenId, uint _price) public returns (bool success) {
        require(ownerOf(_tokenId) == msg.sender);
        require(_price >= priceFusionChibi);
        require(chibies[_tokenId].adult <= now);
        require(chibies[_tokenId].exhausted <= now);
        require(chibies[_tokenId].forFusion == false);
        require(battleContract.isDead(_tokenId) == false);

        chibies[_tokenId].forFusion = true;
        chibies[_tokenId].fusionPrice = _price;

        emit ChibiForFusion(_tokenId, _price);
        return true;
    }

    function cancelChibiForFusion(uint _tokenId) public returns (bool success) {
        if (ownerOf(_tokenId) != msg.sender && msg.sender != address(battleRemoveContractAddress)) {
            revert();
        }
        require(chibies[_tokenId].forFusion == true);
        
        chibies[_tokenId].forFusion = false;
        
        emit ChibiForFusionCancelled(_tokenId);
            
    return false;
    }
    

 
     
    function setGeneContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        geneContract = GeneInterface(_address);
        return true;
    }
 
     
    function queryFusionData(uint _tokenId) public view returns (
        uint256[] fusions,
        bool forFusion,
        uint256 costFusion,
        uint256 adult,
        uint exhausted
        ) {
        return (
        chibies[_tokenId].fusions,
        chibies[_tokenId].forFusion,
        chibies[_tokenId].fusionPrice,
        chibies[_tokenId].adult,
        chibies[_tokenId].exhausted
        );
    }
    
     
    function queryFusionData_ext(uint _tokenId) public view returns (
        bool forFusion,
        uint fusionPrice
        ) {
        return (
        chibies[_tokenId].forFusion,
        chibies[_tokenId].fusionPrice
        );
    }
 
     
    function queryChibi(uint _tokenId) public view returns (
        string nameChibi,
        string infoUrl,
        uint16[13] dna,
        uint256 father,
        uint256 mother,
        uint gen,
        uint adult
        ) {
        return (
        chibies[_tokenId].nameChibi,
        chibies[_tokenId].infoUrl,
        chibies[_tokenId].dna,
        chibies[_tokenId].father,
        chibies[_tokenId].mother,
        chibies[_tokenId].gen,
        chibies[_tokenId].adult
        );
    }

     
    function queryChibiAdd(uint _tokenId) public view returns (
        address owner,
        bool founder
        ) {
        return (
        chibies[_tokenId].owner,
        chibies[_tokenId].founder
        );
    }
     
    function exhaustBattle(uint _tokenId) internal view returns (uint) {
        uint _exhaust = 0;
        
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 1) {
                _exhaust += (exhaustionTime * 3);
            }
            if (chibies[_tokenId].dna[i] == 3) {
                _exhaust += exhaustionTime.div(2);
            }
        }
        
        _exhaust = geneContract.exhaustAfterBattle(chibies[_tokenId].gen, _exhaust);

        return _exhaust;
    }
     
    function exhaustFusion(uint _tokenId) internal returns (uint) {
        uint _exhaust = 0;
        
        uint counter = chibies[_tokenId].dna[9];
         
         
        if (chibies[_tokenId].dna[9] < 9999) chibies[_tokenId].dna[9]++;
        
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 2) {
                counter = counter.sub(1);
            }
            if (chibies[_tokenId].dna[i] == 4) {
                counter++;
            }
        }

        _exhaust = geneContract.exhaustAfterFusion(chibies[_tokenId].gen, counter, exhaustionTime);
        
        return _exhaust;
    }
     
    function exhaustChibis(uint _tokenId1, uint _tokenId2) public returns (bool success) {
        require(msg.sender == battleContractAddress);
        
        chibies[_tokenId1].exhausted = now.add(exhaustBattle(_tokenId1));
        chibies[_tokenId2].exhausted = now.add(exhaustBattle(_tokenId2)); 
        
        return true;
    }
    
     
    function traits(uint16[13] memory genes, uint _seed, uint _fatherId, uint _motherId) internal view returns (uint16[13] memory) {
    
        uint _switch = uint136(keccak256(_seed, block.coinbase, block.timestamp)) % 5;
        
        if (_switch == 0) {
            genes[10] = chibies[_fatherId].dna[10];
            genes[11] = chibies[_motherId].dna[11];
        }
        if (_switch == 1) {
            genes[10] = chibies[_motherId].dna[10];
            genes[11] = chibies[_fatherId].dna[11];
        }
        if (_switch == 2) {
            genes[10] = chibies[_fatherId].dna[10];
            genes[11] = chibies[_fatherId].dna[11];
        }
        if (_switch == 3) {
            genes[10] = chibies[_motherId].dna[10];
            genes[11] = chibies[_motherId].dna[11];
        }
        
        return genes;
        
    }
    
     
    function fusionChibis(uint _fatherId, uint _motherId, uint _seed, string _name, string _battleRoar, uint8 _region) payable public returns (bool success) {
        require(fusionPaused == false);
        require(ownerOf(_fatherId) == msg.sender);
        require(ownerOf(_motherId) != msg.sender);
        require(chibies[_fatherId].adult <= now);
        require(chibies[_fatherId].exhausted <= now);
        require(chibies[_motherId].adult <= now);
        require(chibies[_motherId].exhausted <= now);
        require(chibies[_motherId].forFusion == true);
        require(chibies[_motherId].fusionPrice == msg.value);
         
        chibies[_motherId].forFusion = false;
        chibies[_motherId].exhausted = now.add(exhaustFusion(_motherId));
        chibies[_fatherId].exhausted = now.add(exhaustFusion(_fatherId));
        
        uint _gen = 0;
        if (chibies[_fatherId].gen >= chibies[_motherId].gen) {
            _gen = chibies[_fatherId].gen.add(1);
        } else {
            _gen = chibies[_motherId].gen.add(1);
        }
         
        uint16[13] memory dna = traits(geneContract.splitGenes(address(this), _seed, uniqueCounter+1), _seed, _fatherId, _motherId);
        
         
        addToken(msg.sender, uniqueCounter);

         
        chibies[_fatherId].fusions.push(uniqueCounter);
         
        if (_fatherId != _motherId) {
            chibies[_motherId].fusions.push(uniqueCounter);
        }
        
         
        uint[] memory _fusions;
        
         
        chibies.push(Chibi(
            msg.sender,
            false,
            _name, 
            dna,
            _fatherId,
            _motherId,
            _gen,
            _fusions,
            false,
            priceFusionChibi,
            0,
            now.add(adultTime.mul((_gen.mul(_gen)).add(1))),
            strConcat(_infoUrlPrefix, uint2str(uniqueCounter))
        ));
        
         
        emit ChibiCreated(
            uniqueCounter,
            chibies[uniqueCounter].owner,
            chibies[uniqueCounter].founder,
            chibies[uniqueCounter].nameChibi,
            chibies[uniqueCounter].dna, 
            chibies[uniqueCounter].father, 
            chibies[uniqueCounter].mother, 
            chibies[uniqueCounter].gen,
            chibies[uniqueCounter].adult,
            chibies[uniqueCounter].infoUrl
        );

         
        emit Transfer(0x0, msg.sender, uniqueCounter);
        
         
        if (battleContract.addWarrior(address(this), uniqueCounter, _region, _battleRoar) == false) revert();
        
        uniqueCounter ++;
         
        uint256 amount = msg.value / 100 * comission;
        chibies[_motherId].owner.transfer(amount);
        return true;
 }

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }
 
     
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }
 
     
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedTokens[_owner].length;
    }
 
     
    function tokensOf(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }
 
     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
 
     
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }
 
     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }
 
     
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (approvedFor(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }
 
     
    function takeOwnership(uint256 _tokenId) public {
        require(isApprovedFor(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
    function mintSpecial(string _name, string _battleRoar, uint8 _region, uint _seed, uint _specialId) public contract_onlyOwner returns (bool success) {
         
        _mint(_name, _battleRoar, _region, _seed, false, _specialId);
        return true;
    }
    
     
    function _mint(string _name, string _battleRoar, uint8 _region, uint _seed, bool _founder, uint _specialId) internal {
        require(msg.sender != address(0));
        addToken(msg.sender, uniqueCounter);
    
         
        uint16[13] memory dna;
        
        if (_specialId > 0) {
            dna  = geneContract.createGenes(address(this), _seed, _founder, uniqueCounter, _specialId);
        } else {
            dna = geneContract.createGenes(address(this), _seed, _founder, uniqueCounter, 0);
        }

        uint[] memory _fusions;

        chibies.push(Chibi(
            msg.sender,
            _founder,
            _name, 
            dna,
            0,
            0,
            0,
            _fusions,
            false,
            priceFusionChibi,
            0,
            now.add(adultTime),
            strConcat(_infoUrlPrefix, uint2str(uniqueCounter))
        ));
        
         
        emit Transfer(0x0, msg.sender, uniqueCounter);
        
         
        if (battleContract.addWarrior(address(this), uniqueCounter, _region, _battleRoar) == false) revert();
        
         
        emit ChibiCreated(
            uniqueCounter,
            chibies[uniqueCounter].owner,
            chibies[uniqueCounter].founder,
            chibies[uniqueCounter].nameChibi,
            chibies[uniqueCounter].dna, 
            chibies[uniqueCounter].father, 
            chibies[uniqueCounter].mother, 
            chibies[uniqueCounter].gen,
            chibies[uniqueCounter].adult,
            chibies[uniqueCounter].infoUrl
        );
        
        uniqueCounter ++;
    }
 
     
    function buyGEN0Chibi(string _name, string _battleRoar, uint8 _region, uint _seed) payable public returns (bool success) {
        require(paused == false);
         
        require(msg.value == priceChibi);
         
        _mint(_name, _battleRoar, _region, _seed, false, 0);
        return true;
    }
 
     
    function setChibiGEN0Price(uint _priceChibi) public contract_onlyOwner returns (bool success) {
        priceChibi = _priceChibi;
        return true;
    }
 
     
    function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }
 
     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        clearApproval(_from, _tokenId);
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        
         
        chibies[_tokenId].owner = _to;
        chibies[_tokenId].forFusion = false;
        
        emit Transfer(_from, _to, _tokenId);
    }
 
     
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = 0;
        emit Approval(_owner, 0, _tokenId);
    }
 
     
    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        totalTokens++;
    }
 
     
    function removeToken(address _from, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);
        
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];
        
        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         
        
        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        totalTokens = totalTokens.sub(1);
    }

     
    function weiToOwner(address _address, uint amount) public contract_onlyOwner {
        require(amount <= address(this).balance);
        _address.transfer(amount);
    }
    
     
    function tokenMetadata(uint256 _tokenId) constant public returns (string infoUrl) {
        return chibies[_tokenId].infoUrl;
    }
    
    function tokenURI(uint256 _tokenId) public view returns (string) {
        return chibies[_tokenId].infoUrl;
    }

     
     
     
     
    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
        }
    }