 

pragma solidity 0.4.21;


 
library SafeMath {
     
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint a, uint b) internal pure returns(uint) {
         
         
         
        return a / b;
    }
     
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }
     
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 

contract ERC721 {
     
    function approve(address _to, uint _tokenId) public;
    function balanceOf(address _owner) public view returns(uint balance);
    function implementsERC721() public pure returns(bool);
    function ownerOf(uint _tokenId) public view returns(address addr);
    function takeOwnership(uint _tokenId) public;
    function totalSupply() public view returns(uint total);
    function transferFrom(address _from, address _to, uint _tokenId) public;
    function transfer(address _to, uint _tokenId) public;

     
    event Approval(uint tokenId, address indexed owner, address indexed approved);
    
     
     
     
     
     
}
contract CryptoCovfefes is ERC721 {
     
     
    string public constant NAME = "CryptoCovfefes";
    string public constant SYMBOL = "Covfefe Token";
    
    uint private constant startingPrice = 0.001 ether;
    
    uint private constant PROMO_CREATION_LIMIT = 5000;
    uint private constant CONTRACT_CREATION_LIMIT = 45000;
    uint private constant SaleCooldownTime = 12 hours;
    
    uint private randNonce = 0;
    uint private constant duelVictoryProbability = 51;
    uint private constant duelFee = .001 ether;
    
    uint private addMeaningFee = .001 ether;

     
         
    event NewCovfefeCreated(uint tokenId, string term, string meaning, uint generation, address owner);
    
     
    event CovfefeMeaningAdded(uint tokenId, string term, string meaning);
    
     
    event CovfefeSold(uint tokenId, string term, string meaning, uint generation, uint sellingpPice, uint currentPrice, address buyer, address seller);
    
      
    event AddedValueToCovfefe(uint tokenId, string term, string meaning, uint generation, uint currentPrice);
    
      
     event CovfefeTransferred(uint tokenId, address from, address to);
     
     
    event ChallengerWinsCovfefeDuel(uint tokenIdChallenger, string termChallenger, uint tokenIdDefender, string termDefender);
    
     
    event DefenderWinsCovfefeDuel(uint tokenIdDefender, string termDefender, uint tokenIdChallenger, string termChallenger);

     
     
     
    mapping(uint => address) public covfefeIndexToOwner;
    
     
     
    mapping(address => uint) private ownershipTokenCount;
    
     
     
     
    mapping(uint => address) public covfefeIndexToApproved;
    
     
    mapping(uint => uint) private covfefeIndexToPrice;
    
     
    mapping(uint => uint) private covfefeIndexToLastPrice;
    
     
    address public covmanAddress;
    address public covmanagerAddress;
    uint public promoCreatedCount;
    uint public contractCreatedCount;
    
     
    struct Covfefe {
        string term;
        string meaning;
        uint16 generation;
        uint16 winCount;
        uint16 lossCount;
        uint64 saleReadyTime;
    }
    
    Covfefe[] private covfefes;
     
     
    modifier onlyCovman() {
        require(msg.sender == covmanAddress);
        _;
    }
     
    modifier onlyCovmanager() {
        require(msg.sender == covmanagerAddress);
        _;
    }
     
    modifier onlyCovDwellers() {
        require(msg.sender == covmanAddress || msg.sender == covmanagerAddress);
        _;
    }
    
     
    function CryptoCovfefes() public {
        covmanAddress = msg.sender;
        covmanagerAddress = msg.sender;
    }
     
     
     
     
     
     
    function approve(address _to, uint _tokenId) public {
         
        require(_owns(msg.sender, _tokenId));
        covfefeIndexToApproved[_tokenId] = _to;
        emit Approval(_tokenId, msg.sender, _to);
    }
    
     
     
     
    function balanceOf(address _owner) public view returns(uint balance) {
        return ownershipTokenCount[_owner];
    }
     

     
    function createPromoCovfefe(address _owner, string _term, string _meaning, uint16 _generation, uint _price) public onlyCovmanager {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        address covfefeOwner = _owner;
        if (covfefeOwner == address(0)) {
            covfefeOwner = covmanagerAddress;
        }
        if (_price <= 0) {
            _price = startingPrice;
        }
        promoCreatedCount++;
        _createCovfefe(_term, _meaning, _generation, covfefeOwner, _price);
    }
    
     
    function createContractCovfefe(string _term, string _meaning, uint16 _generation) public onlyCovmanager {
        require(contractCreatedCount < CONTRACT_CREATION_LIMIT);
        contractCreatedCount++;
        _createCovfefe(_term, _meaning, _generation, address(this), startingPrice);
    }

    function _triggerSaleCooldown(Covfefe storage _covfefe) internal {
        _covfefe.saleReadyTime = uint64(now + SaleCooldownTime);
    }

    function _ripeForSale(Covfefe storage _covfefe) internal view returns(bool) {
        return (_covfefe.saleReadyTime <= now);
    }
     
     
    function getCovfefe(uint _tokenId) public view returns(string Term, string Meaning, uint Generation, uint ReadyTime, uint WinCount, uint LossCount, uint CurrentPrice, uint LastPrice, address Owner) {
        Covfefe storage covfefe = covfefes[_tokenId];
        Term = covfefe.term;
        Meaning = covfefe.meaning;
        Generation = covfefe.generation;
        ReadyTime = covfefe.saleReadyTime;
        WinCount = covfefe.winCount;
        LossCount = covfefe.lossCount;
        CurrentPrice = covfefeIndexToPrice[_tokenId];
        LastPrice = covfefeIndexToLastPrice[_tokenId];
        Owner = covfefeIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns(bool) {
        return true;
    }
     
    function name() public pure returns(string) {
        return NAME;
    }
    
     
     
     
    
    function ownerOf(uint _tokenId)
    public
    view
    returns(address owner) {
        owner = covfefeIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == covfefeIndexToOwner[_tokenId]);
        _;
    }
    
     
    
    function addMeaningToCovfefe(uint _tokenId, string _newMeaning) external payable onlyOwnerOf(_tokenId) {
        
         
        require(!isContract(msg.sender));
        
         
        require(msg.value == addMeaningFee);
        
         
        covfefes[_tokenId].meaning = _newMeaning;
    
         
        emit CovfefeMeaningAdded(_tokenId, covfefes[_tokenId].term, _newMeaning);
    }

    function payout(address _to) public onlyCovDwellers {
        _payout(_to);
    }
     
    
     
    function buyCovfefe(uint _tokenId) public payable {
        address oldOwner = covfefeIndexToOwner[_tokenId];
        address newOwner = msg.sender;
        
         
        Covfefe storage myCovfefe = covfefes[_tokenId];
        require(_ripeForSale(myCovfefe));
        
         
        require(!isContract(msg.sender));
        
        covfefeIndexToLastPrice[_tokenId] = covfefeIndexToPrice[_tokenId];
        uint sellingPrice = covfefeIndexToPrice[_tokenId];
        
         
        require(oldOwner != newOwner);
        
         
        require(_addressNotNull(newOwner));
        
         
        require(msg.value >= sellingPrice);
        uint payment = uint(SafeMath.div(SafeMath.mul(sellingPrice, 95), 100));
        uint purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        
         
        covfefeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 95);
        _transfer(oldOwner, newOwner, _tokenId);
        
         
        _triggerSaleCooldown(myCovfefe);
        
         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);  
        }
        
        emit CovfefeSold(_tokenId, covfefes[_tokenId].term, covfefes[_tokenId].meaning, covfefes[_tokenId].generation, covfefeIndexToLastPrice[_tokenId], covfefeIndexToPrice[_tokenId], newOwner, oldOwner);
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint _tokenId) public view returns(uint price) {
        return covfefeIndexToPrice[_tokenId];
    }

    function lastPriceOf(uint _tokenId) public view returns(uint price) {
        return covfefeIndexToLastPrice[_tokenId];
    }
    
     
     
    function setCovman(address _newCovman) public onlyCovman {
        require(_newCovman != address(0));
        covmanAddress = _newCovman;
    }
    
     
     
    function setCovmanager(address _newCovmanager) public onlyCovman {
        require(_newCovmanager != address(0));
        covmanagerAddress = _newCovmanager;
    }
    
     
    function symbol() public pure returns(string) {
        return SYMBOL;
    }
    
     
     
     
    function takeOwnership(uint _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = covfefeIndexToOwner[_tokenId];
         
        require(_addressNotNull(newOwner));
         
        require(_approved(newOwner, _tokenId));
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
     
     

    function addValueToCovfefe(uint _tokenId) external payable onlyOwnerOf(_tokenId) {
        
         
        require(!isContract(msg.sender));
        
         
        require(msg.value >= 0.001 ether);
        require(msg.value <= 9999.000 ether);
        
         
        covfefeIndexToLastPrice[_tokenId] = covfefeIndexToPrice[_tokenId];
        
        uint newValue = msg.value;

         
        newValue = SafeMath.div(SafeMath.mul(newValue, 115), 100);
        covfefeIndexToPrice[_tokenId] = SafeMath.add(newValue, covfefeIndexToPrice[_tokenId]);
        
         
        emit AddedValueToCovfefe(_tokenId, covfefes[_tokenId].term, covfefes[_tokenId].meaning, covfefes[_tokenId].generation, covfefeIndexToPrice[_tokenId]);
    }
    
     
     
     
     
     
    
    function getTokensOfOwner(address _owner) external view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
             
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalCovfefes = totalSupply();
            uint resultIndex = 0;
            uint covfefeId;
            for (covfefeId = 0; covfefeId <= totalCovfefes; covfefeId++) {
                if (covfefeIndexToOwner[covfefeId] == _owner) {
                    result[resultIndex] = covfefeId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
    
     
     
    function totalSupply() public view returns(uint total) {
        return covfefes.length;
    }
     
     
     
     
    function transfer(address _to, uint _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        _transfer(msg.sender, _to, _tokenId);
    }
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
    }
     
     
    function _addressNotNull(address _to) private pure returns(bool) {
        return _to != address(0);
    }
     
    function _approved(address _to, uint _tokenId) private view returns(bool) {
        return covfefeIndexToApproved[_tokenId] == _to;
    }
    
     
    
    function _createCovfefe(string _term, string _meaning, uint16 _generation, address _owner, uint _price) private {
        Covfefe memory _covfefe = Covfefe({
            term: _term,
            meaning: _meaning,
            generation: _generation,
            saleReadyTime: uint64(now),
            winCount: 0,
            lossCount: 0
        });
        
        uint newCovfefeId = covfefes.push(_covfefe) - 1;
         
         
        require(newCovfefeId == uint(uint32(newCovfefeId)));
        
         
        emit NewCovfefeCreated(newCovfefeId, _term, _meaning, _generation, _owner);
        
        covfefeIndexToPrice[newCovfefeId] = _price;
        
         
         
        _transfer(address(0), _owner, newCovfefeId);
    }
    
     
    function _owns(address claimant, uint _tokenId) private view returns(bool) {
        return claimant == covfefeIndexToOwner[_tokenId];
    }
    
     
    function _payout(address _to) private {
        if (_to == address(0)) {
            covmanAddress.transfer(address(this).balance);
        } else {
            _to.transfer(address(this).balance);
        }
    }
    
     
     
     
    
     
    function _transfer(address _from, address _to, uint _tokenId) private {
         
        ownershipTokenCount[_to]++;
         
        covfefeIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete covfefeIndexToApproved[_tokenId];
        }
         
        emit CovfefeTransferred(_tokenId, _from, _to);
    }
    
     
    
     
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
    }
    
    function duelAnotherCovfefe(uint _tokenId, uint _targetId) external payable onlyOwnerOf(_tokenId) {
         
        Covfefe storage myCovfefe = covfefes[_tokenId];
        
         
        require(!isContract(msg.sender));
        
         
        require(msg.value == duelFee);
        
         
        Covfefe storage enemyCovfefe = covfefes[_targetId];
        uint rand = randMod(100);
        
        if (rand <= duelVictoryProbability) {
            myCovfefe.winCount++;
            enemyCovfefe.lossCount++;
        
         
            emit ChallengerWinsCovfefeDuel(_tokenId, covfefes[_tokenId].term, _targetId, covfefes[_targetId].term);
            
        } else {
        
            myCovfefe.lossCount++;
            enemyCovfefe.winCount++;
        
             
            emit DefenderWinsCovfefeDuel(_targetId, covfefes[_targetId].term, _tokenId, covfefes[_tokenId].term);
        }
    }
    
     
    
    function isContract(address addr) internal view returns(bool) {
        uint size;
        assembly {
            size: = extcodesize(addr)
        }
        return size > 0;
    }
}