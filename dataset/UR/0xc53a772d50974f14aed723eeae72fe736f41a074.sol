 

pragma solidity ^0.4.23;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.23;

 
contract PluginInterface
{
     
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

     
     
     
     
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

     
     
     
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
 
 
contract ConfigInterface
{
    function isConfig() public pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation) public view returns (uint16);
    
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) public view returns (uint40);

    function getCooldownIndexCount() public view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) public view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) public pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) public pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
}


contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    ConfigInterface public config;

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);

    function totalSupply() view returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner);
}


 
contract CutiePluginBase is PluginInterface, Pausable
{
    function isPluginInterface() public pure returns (bool)
    {
        return true;
    }

     
    CutieCoreInterface public coreContract;

     
     
    uint16 public ownerFee;

     
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }

     
     
     
     
     
     
    function setup(address _coreAddress, uint16 _fee) public {
        require(_fee <= 10000);
        require(msg.sender == owner);
        ownerFee = _fee;
        
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
    }

     
     
    function setFee(uint16 _fee) public
    {
        require(_fee <= 10000);
        require(msg.sender == owner);

        ownerFee = _fee;
    }

     
     
     
    function _isOwner(address _claimant, uint40 _cutieId) internal view returns (bool) {
        return (coreContract.ownerOf(_cutieId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint40 _cutieId) internal {
         
        coreContract.transferFrom(_owner, this, _cutieId);
    }

     
     
     
     
    function _transfer(address _receiver, uint40 _cutieId) internal {
         
        coreContract.transfer(_receiver, _cutieId);
    }

     
     
    function _computeFee(uint128 _price) internal view returns (uint128) {
         
         
         
         
         
        return _price * ownerFee / 10000;
    }

    function withdraw() public
    {
        require(
            msg.sender == owner ||
            msg.sender == address(coreContract)
        );
        if (address(this).balance > 0)
        {
            address(coreContract).transfer(address(this).balance);
        }
    }

    function onRemove() public onlyCore
    {
        withdraw();
    }

    function run(
        uint40,
        uint256,
        address
    ) 
        public
        payable
        onlyCore
    {
        revert();
    }
}


 
 
contract Custody is CutiePluginBase
{
    mapping(uint256 => uint256) public custodyFee;
    mapping(uint40 => bool) public blacklist;
    address public operatorAddress;

    event RIP(address owner, uint40 cutieId, uint256 blockchain);

    function run(
        uint40 _cutieId,
        uint256 _blockchain,
        address _owner
    )
        public
        payable
        onlyCore
    {
        require(!isBlacklisted(_cutieId));
        require(!isUnique(_cutieId));
        require(custodyFee[_blockchain] > 0);
        require(msg.value >= custodyFee[_blockchain]);
        coreContract.transferFrom(_owner, address(0x0), _cutieId);

        emit RIP(_owner, _cutieId, _blockchain);
    }

    function runSigned(uint40, uint256, address)
        external
        payable
        onlyCore
    {
        revert();
    }

    function setCustodyFee(uint256 _blockchain, uint256 _fee) public onlyOperator
    {
        custodyFee[_blockchain] = _fee;
    }

    function recoverCutie(uint40 _cutieId, address _newOwner) public onlyOperator
    {
        coreContract.transfer(_newOwner, _cutieId);
    }

    function addToBlacklist(uint40 _cutieId) public onlyOperator
    {
        blacklist[_cutieId] = true;
    }

    function isBlacklisted(uint40 _cutieId) public view returns(bool)
    {
        return blacklist[_cutieId];
    }

    function isUnique(uint40 _cutieId) public view returns(bool)
    {
        uint256 genes = coreContract.getGenes(_cutieId);
        return ((genes / 0x100000) % 0x10) == 0x1;
    }

    function setOperator(address _operator) public onlyOwner
    {
        operatorAddress = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }
}