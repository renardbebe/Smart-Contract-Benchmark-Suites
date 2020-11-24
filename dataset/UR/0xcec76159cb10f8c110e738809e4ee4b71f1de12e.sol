 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
 
contract Acceptable is Ownable {
    address public sender;

     
    modifier onlyAcceptable {
        require(msg.sender == sender);
        _;
    }

     
     
    function setAcceptable(address _sender) public onlyOwner {
        sender = _sender;
    }
}

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);  

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
 
contract CrystalBaseIF is ERC721 {
    function mint(address _owner, uint256 _gene, uint256 _kind, uint256 _weight) public returns(uint256);
    function burn(address _owner, uint256 _tokenId) public;
    function _transferFrom(address _from, address _to, uint256 _tokenId) public;
    function getCrystalKindWeight(uint256 _tokenId) public view returns(uint256 kind, uint256 weight);
    function getCrystalGeneKindWeight(uint256 _tokenId) public view returns(uint256 gene, uint256 kind, uint256 weight);
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
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
 
contract MiningSupplier {
    using SafeMath for uint256;

    uint256 public constant secondsPerYear = 1 years * 1 seconds;
    uint256 public constant secondsPerDay = 1 days * 1 seconds;

     
    function _getBlocksPerYear(
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
        return secondsPerYear.div(_secondsPerBlock);
    }

     
     
    function _getBlockIndexAtYear(
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
         
        require(_currentBlockNumber >= _initialBlockNumber);
        uint256 _blockIndex = _currentBlockNumber.sub(_initialBlockNumber);
        uint256 _blocksPerYear = _getBlocksPerYear(_secondsPerBlock);
        return _blockIndex.sub(_blockIndex.div(_blocksPerYear).mul(_blocksPerYear));
    }

     
     
    function _getBlockIndex(
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber
    ) public pure returns(uint256) {
         
        require(_currentBlockNumber >= _initialBlockNumber);
        return _currentBlockNumber.sub(_initialBlockNumber);
    }

     
     
    function _getYearIndex(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber
    ) public pure returns(uint256) {
        uint256 _blockIndex =  _getBlockIndex(_initialBlockNumber, _currentBlockNumber);
        uint256 _blocksPerYear = _getBlocksPerYear(_secondsPerBlock);
        return _blockIndex.div(_blocksPerYear);
    }

     
    function _getWaitingBlocks(
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
        return secondsPerDay.div(_secondsPerBlock);
    }

    function _getWeightUntil(
        uint256 _totalWeight,
        uint256 _yearIndex
    ) public pure returns(uint256) {
        uint256 _sum = 0;
        for(uint256 i = 0; i < _yearIndex; i++) {
            _sum = _sum.add(_totalWeight / (2 ** (i + 1)));
        }
        return _sum;
    }

    function _estimateSupply(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _totalWeight
    ) public pure returns(uint256){
        uint256 _yearIndex = _getYearIndex(_secondsPerBlock, _initialBlockNumber, _currentBlockNumber);  
        uint256 _blockIndex = _getBlockIndexAtYear(_initialBlockNumber, _currentBlockNumber, _secondsPerBlock) + 1;
        uint256 _numerator = _totalWeight.mul(_secondsPerBlock).mul(_blockIndex);
        uint256 _yearFactor = 2 ** (_yearIndex + 1);
        uint256 _denominator =  _yearFactor.mul(secondsPerYear);
        uint256 _supply = _numerator.div(_denominator).add(_getWeightUntil(_totalWeight, _yearIndex));
        return _supply;  
    }

    function _estimateWeight(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _totalWeight,
        uint256 _currentWeight
    ) public pure returns(uint256) {
        uint256 _supply = _estimateSupply(
            _secondsPerBlock,
            _initialBlockNumber,
            _currentBlockNumber,
            _totalWeight
        );
        uint256 _yearIndex = _getYearIndex(
            _secondsPerBlock,
            _initialBlockNumber,
            _currentBlockNumber
        );  
        uint256 _yearFactor = 2 ** _yearIndex;
        uint256 _defaultWeight = 10000;  

        if(_currentWeight > _supply) {
             
            return _supply.mul(_defaultWeight).div(_currentWeight).div(_yearFactor);
        } else {
             
            return _defaultWeight.div(_yearFactor);
        }
    }

    function _updateNeeded(
        uint256 _secondsPerBlock,
        uint256 _currentBlockNumber,
        uint256 _blockNumberUpdated
    ) public pure returns(bool) {
        if (_blockNumberUpdated == 0) {
            return true;
        }
        uint256 _waitingBlocks = _getWaitingBlocks(_secondsPerBlock);
        return _currentBlockNumber >= _blockNumberUpdated + _waitingBlocks;
    }
}

 

 
 
contract CrystalWeightManager is MiningSupplier {
     
     
     
    uint256[100] crystalWeights = [
        50000000000,226800000000,1312500000000,31500000000,235830000000,
        151200000000,655200000000,829500000000,7177734375,762300000000,
        684600000000,676200000000,5037226562,30761718750,102539062500,
        102539062500,102539062500,5126953125,31500000000,5040000000,
        20507812500,20507812500,10253906250,5024414062,6300000000,
        20507812500,102539062500,102539062500,102539062500,102539062500,
        102539062500,7690429687,15380859375,69300000000,10253906250,
        547050000000,15380859375,20507812500,15380859375,15380859375,
        20507812500,15380859375,7690429687,153808593750,92285156250,
        102539062500,71777343750,82031250000,256347656250,1384277343750,
        820312500000,743408203125,461425781250,563964843750,538330078125,
        358886718750,256347656250,358886718750,102539062500,307617187500,
        256347656250,51269531250,41015625000,307617187500,307617187500,
        2050781250,3588867187,2563476562,5126953125,399902343750,
        615234375000,563964843750,461425781250,358886718750,717773437500,
        41015625000,41015625000,2050781250,102539062500,102539062500,
        51269531250,102539062500,30761718750,41015625000,102539062500,
        102539062500,102539062500,205078125000,205078125000,556500000000,
        657300000000,41015625000,102539062500,30761718750,102539062500,
        20507812500,20507812500,20507812500,20507812500,82031250000
    ];

    uint256 public secondsPerBlock = 12;
    uint256 public initialBlockNumber = block.number;
    uint256 public constant originalTotalWeight = 21 * 10**13;  
    uint256 public currentWeight = 0;
    uint256 public estimatedWeight = 0;
    uint256 public blockNumberUpdated = 0;

    event UpdateEstimatedWeight(uint256 weight, uint256 nextUpdateBlockNumber);

    function setEstimatedWeight(uint256 _minedWeight) internal {
        currentWeight = currentWeight.add(_minedWeight);

        uint256 _currentBlockNumber = block.number;

        bool _isUpdate = _updateNeeded(
            secondsPerBlock,
            _currentBlockNumber,
            blockNumberUpdated
        );

        if(_isUpdate) {
            estimatedWeight = _estimateWeight(
                secondsPerBlock,
                initialBlockNumber,
                _currentBlockNumber,
                originalTotalWeight,
                currentWeight
            );
            blockNumberUpdated = _currentBlockNumber;

            emit UpdateEstimatedWeight(estimatedWeight, _currentBlockNumber);
        }
    }

    function getCrystalWeights() external view returns(uint256[100]) {
        return crystalWeights;
    }
}

 

 
 
contract EOACallable {
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    modifier onlyEOA {
        require(!isContract(msg.sender));
        _;
    }
}

 

 
 
contract ExchangeBaseIF {
    function create(
        address _owner,
        uint256 _ownerTokenId,
        uint256 _ownerTokenGene,
        uint256 _ownerTokenKind,
        uint256 _ownerTokenWeight,
        uint256 _kind,
        uint256 _weight,
        uint256 _createdAt
    ) public returns(uint256);
    function remove(uint256 _id) public;
    function getExchange(uint256 _id) public view returns(
        address owner,
        uint256 tokenId,
        uint256 kind,
        uint256 weight,
        uint256 createdAt
    );
    function getTokenId(uint256 _id) public view returns(uint256);
    function ownerOf(uint256 _id) public view returns(address);
    function isOnExchange(uint256 _tokenId) public view returns(bool);
    function isOnExchangeById(uint256 _id) public view returns(bool);
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
 
contract PickaxeIF is ERC20 {
    function transferFromOwner(address _to, uint256 _amount) public;
    function burn(address _from, uint256 _amount) public;
}

 

 
 
contract RandomGeneratorIF {
    function generate() public returns(uint64);
}

 

 
 
 
 
 
contract Sellable is Ownable {
    using SafeMath for uint256;

    address public wallet;
    uint256 public rate;

    address public donationWallet;
    uint256 public donationRate;

    uint256 public constant MIN_WEI_AMOUNT = 5 * 10**15;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ForwardFunds(address sender, uint256 value, uint256 deposit);
    event Donation(address sender, uint256 value);

    constructor(address _wallet, address _donationWallet, uint256 _donationRate) public {
         
        rate = 200;
        wallet = _wallet;
        donationWallet = _donationWallet;
        donationRate = _donationRate;
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function setEthereumWallet(address _donationWallet) external onlyOwner {
        donationWallet = _donationWallet;
    }

    function () external payable {
        require(msg.value >= MIN_WEI_AMOUNT);
        buyPickaxes(msg.sender);
    }

    function buyPickaxes(address _beneficiary) public payable {
        require(msg.value >= MIN_WEI_AMOUNT);

        uint256 _weiAmount = msg.value;
        uint256 _tokens = _weiAmount.mul(rate).div(1 ether);

        require(_tokens.mul(1 ether).div(rate) == _weiAmount);

        _transferFromOwner(msg.sender, _tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokens);
        _forwardFunds();
    }

    function _transferFromOwner(address _to, uint256 _value) internal {
         
    }

    function _forwardFunds() internal {
        uint256 donation = msg.value.div(donationRate);  
        uint256 value = msg.value - donation;

        wallet.transfer(value);

        emit ForwardFunds(msg.sender, value, donation);

        uint256 donationEth = 2014000000000000000;  
        if(address(this).balance >= donationEth) {
            donationWallet.transfer(donationEth);
            emit Donation(msg.sender, donationEth);
        }
    }
}

 

 
 
 
 
contract CryptoCrystal is Sellable, EOACallable, CrystalWeightManager {
    PickaxeIF public pickaxe;
    CrystalBaseIF public crystal;
    ExchangeBaseIF public exchange;
    RandomGeneratorIF public generator;

     

    event MineCrystals(
         
        address indexed owner,
         
        uint256 indexed minedAt,
         
        uint256[] tokenIds,
         
        uint256[] kinds,
         
        uint256[] weights,
         
        uint256[] genes
    );

    event MeltCrystals(
         
        address indexed owner,
         
        uint256 indexed meltedAt,
         
        uint256[] meltedTokenIds,
         
        uint256 tokenId,
         
        uint256 kind,
         
        uint256 weight,
         
        uint256 gene
    );

    event CreateExchange(
         
        uint256 indexed id,
         
        address owner,
         
        uint256 ownerTokenId,
         
        uint256 ownerTokenGene,
         
        uint256 ownerTokenKind,
         
        uint256 ownerTokenWeight,
         
        uint256 kind,
         
        uint256 weight,
         
        uint256 createdAt
    );

    event CancelExchange(
         
        uint256 indexed id,
         
        address owner,
         
        uint256 ownerTokenId,
         
        uint256 ownerTokenKind,
         
        uint256 ownerTokenWeight,
         
        uint256 cancelledAt
    );

    event BidExchange(
         
        uint256 indexed id,
         
        address owner,
         
        uint256 ownerTokenId,
         
        uint256 ownerTokenGene,
         
        uint256 ownerTokenKind,
         
        uint256 ownerTokenWeight,
         
        address exchanger,
         
        uint256 exchangerTokenId,
         
        uint256 exchangerTokenKind,
         
        uint256 exchangerTokenWeight,
         
        uint256 bidAt
    );

    struct ExchangeWrapper {
        uint256 id;
        address owner;
        uint256 tokenId;
        uint256 kind;
        uint256 weight;
        uint256 createdAt;
    }

    struct CrystalWrapper {
        address owner;
        uint256 tokenId;
        uint256 gene;
        uint256 kind;
        uint256 weight;
    }

    constructor(
        PickaxeIF _pickaxe,
        CrystalBaseIF _crystal,
        ExchangeBaseIF _exchange,
        RandomGeneratorIF _generator,
        address _wallet,
        address _donationWallet,
        uint256 _donationRate
    ) Sellable(_wallet, _donationWallet, _donationRate) public {
        pickaxe = _pickaxe;
        crystal = _crystal;
        exchange = _exchange;
        generator = _generator;
        setEstimatedWeight(0);
    }

     
     
    function mineCrystals(uint256 _pkxAmount) external onlyEOA {
        address _owner = msg.sender;
        require(pickaxe.balanceOf(msg.sender) >= _pkxAmount);
        require(0 < _pkxAmount && _pkxAmount <= 100);

        uint256 _crystalAmount = _getRandom(5);

        uint256[] memory _tokenIds = new uint256[](_crystalAmount);
        uint256[] memory _kinds = new uint256[](_crystalAmount);
        uint256[] memory _weights = new uint256[](_crystalAmount);
        uint256[] memory _genes = new uint256[](_crystalAmount);

        uint256[] memory _crystalWeightsCumsum = new uint256[](100);
        _crystalWeightsCumsum[0] = crystalWeights[0];
        for(uint256 i = 1; i < 100; i++) {
            _crystalWeightsCumsum[i] = _crystalWeightsCumsum[i - 1].add(crystalWeights[i]);
        }
        uint256 _totalWeight = _crystalWeightsCumsum[_crystalWeightsCumsum.length - 1];
        uint256 _weightRandomSum = 0;
        uint256 _weightSum = 0;

        for(i = 0; i < _crystalAmount; i++) {
            _weights[i] = _getRandom(100);
            _weightRandomSum = _weightRandomSum.add(_weights[i]);
        }

        for(i = 0; i < _crystalAmount; i++) {
             
             
            _kinds[i] = _getFirstIndex(_getRandom(_totalWeight), _crystalWeightsCumsum);

             
             
             
             
            uint256 actualWeight = estimatedWeight.mul(_pkxAmount);
            _weights[i] = _weights[i].mul(actualWeight).div(_weightRandomSum);

             
            _genes[i] = _generateGene();

            require(_weights[i] > 0);

            _tokenIds[i] = crystal.mint(_owner, _genes[i], _kinds[i], _weights[i]);

            crystalWeights[_kinds[i]] = crystalWeights[_kinds[i]].sub(_weights[i]);

            _weightSum = _weightSum.add(_weights[i]);
        }

        setEstimatedWeight(_weightSum);
        pickaxe.burn(msg.sender, _pkxAmount);

        emit MineCrystals(
        _owner,
        now,
        _tokenIds,
        _kinds,
        _weights,
        _genes
        );
    }

     
     
     
     
     
    function meltCrystals(uint256[] _tokenIds) external onlyEOA {
        uint256 _length = _tokenIds.length;
        address _owner = msg.sender;

        require(2 <= _length && _length <= 10);

        uint256[] memory _kinds = new uint256[](_length);
        uint256 _weight;
        uint256 _totalWeight = 0;

        for(uint256 i = 0; i < _length; i++) {
            require(crystal.ownerOf(_tokenIds[i]) == _owner);
            (_kinds[i], _weight) = crystal.getCrystalKindWeight(_tokenIds[i]);
            if (i != 0) {
                require(_kinds[i] == _kinds[i - 1]);
            }

            _totalWeight = _totalWeight.add(_weight);
            crystal.burn(_owner, _tokenIds[i]);
        }

        uint256 _gene = _generateGene();
        uint256 _tokenId = crystal.mint(_owner, _gene, _kinds[0], _totalWeight);

        emit MeltCrystals(_owner, now, _tokenIds, _tokenId, _kinds[0], _totalWeight, _gene);
    }

     
     
     
     
    function createExchange(uint256 _tokenId, uint256 _kind, uint256 _weight) external onlyEOA {
        ExchangeWrapper memory _ew = ExchangeWrapper({
            id: 0,  
            owner: msg.sender,
            tokenId: _tokenId,
            kind: _kind,
            weight: _weight,
            createdAt: 0
            });

        CrystalWrapper memory _cw = getCrystalWrapper(msg.sender, _tokenId);

        require(crystal.ownerOf(_tokenId) == _cw.owner);
        require(_kind < 100);

         
        crystal._transferFrom(_cw.owner, exchange, _tokenId);

        _ew.id = exchange.create(_ew.owner, _tokenId, _cw.gene, _cw.kind, _cw.weight, _ew.kind, _ew.weight, now);

        emit CreateExchange(_ew.id, _ew.owner, _ew.tokenId, _cw.gene, _cw.kind, _cw.weight, _ew.kind, _ew.weight, now);
    }

    function getCrystalWrapper(address _owner, uint256 _tokenId) internal returns(CrystalWrapper) {
        CrystalWrapper memory _cw;
        _cw.owner = _owner;
        _cw.tokenId = _tokenId;
        (_cw.gene, _cw.kind, _cw.weight) = crystal.getCrystalGeneKindWeight(_tokenId);
        return _cw;
    }

     
     
    function cancelExchange(uint256 _id) external onlyEOA {
        require(exchange.ownerOf(_id) == msg.sender);

        uint256 _tokenId = exchange.getTokenId(_id);

        CrystalWrapper memory _cw = getCrystalWrapper(msg.sender, _tokenId);

         
        crystal._transferFrom(exchange, _cw.owner, _cw.tokenId);

        exchange.remove(_id);

        emit CancelExchange(_id, _cw.owner, _cw.tokenId, _cw.kind, _cw.weight, now);
    }

     
     
     
    function bidExchange(uint256 _exchangeId, uint256 _tokenId) external onlyEOA {
         
        ExchangeWrapper memory _ew;
        _ew.id = _exchangeId;
        (_ew.owner, _ew.tokenId, _ew.kind, _ew.weight, _ew.createdAt) = exchange.getExchange(_ew.id);  

         
        CrystalWrapper memory _cwe = getCrystalWrapper(msg.sender, _tokenId);

         
        CrystalWrapper memory _cwo = getCrystalWrapper(_ew.owner, _ew.tokenId);

        require(_cwe.owner != _ew.owner);
        require(_cwe.kind == _ew.kind);
        require(_cwe.weight >= _ew.weight);

         
        crystal._transferFrom(_cwe.owner, _ew.owner, _cwe.tokenId);

         
        crystal._transferFrom(exchange, _cwe.owner, _ew.tokenId);

        exchange.remove(_ew.id);

        emit BidExchange(_ew.id, _ew.owner, _ew.tokenId, _cwo.gene, _cwo.kind, _cwo.weight, _cwe.owner, _cwe.tokenId, _cwe.kind, _cwe.weight, now);
    }

     
     
     
    function _getFirstIndex(uint256 _min, uint256[] _sorted) public pure returns(uint256) {
        for(uint256 i = 0; i < _sorted.length; i++) {
            if(_min < _sorted[i]) {
                return i;
            }
        }
        return _sorted.length - 1;
    }

    function _transferFromOwner(address _to, uint256 _value) internal {
        pickaxe.transferFromOwner(_to, _value);
    }

    function _generateGene() internal returns(uint256) {
        return _getRandom(~uint256(0));
    }

    function _getRandom(uint256 _max) public returns(uint256){
        bytes32 hash = keccak256(generator.generate());
        uint256 number = (uint256(hash) % _max) + 1;
         
        return number;
    }

     
     
    function setRandomGenerator(RandomGeneratorIF _generator) external onlyOwner {
        generator = _generator;
    }
}