 

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


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

    function withdraw() external;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
 
 
interface ConfigInterface
{
    function isConfig() external pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 _cutieId) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 _cutieId) external view returns (uint40);
    function getCooldownIndexFromGeneration(uint16 _generation) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) external view returns (uint40);

    function getCooldownIndexCount() external view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) external pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) external view returns (uint256);
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
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
}

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;

contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}



 
contract PausableOperators is Operators {
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


 
contract CutiePluginBase is PluginInterface, PausableOperators
{
    function isPluginInterface() public pure returns (bool)
    {
        return true;
    }

     
    CutieCoreInterface public coreContract;
    address public pluginsContract;

     
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }

    modifier onlyPlugins() {
        require(msg.sender == pluginsContract);
        _;
    }

     
     
     
     
    function setup(address _coreAddress, address _pluginsContract) public onlyOwner {
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;

        pluginsContract = _pluginsContract;
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

    function withdraw() external
    {
        require(
            isOwner(msg.sender) ||
            msg.sender == address(coreContract)
        );
        _withdraw();
    }

    function _withdraw() internal
    {
        if (address(this).balance > 0)
        {
            address(coreContract).transfer(address(this).balance);
        }
    }

    function onRemove() public onlyPlugins
    {
        _withdraw();
    }

    function run(uint40, uint256, address) public payable onlyCore
    {
        revert();
    }

    function runSigned(uint40, uint256, address) external payable onlyCore
    {
        revert();
    }
}


 
 
contract CutieGenerator is CutiePluginBase
{
    uint40 public momId;
    uint40 public dadId;

    function setupGenerator(uint40 _momId, uint40 _dadId) external onlyOwner
    {
        momId = _momId;
        dadId = _dadId;
    }

    function generateSingle(uint _genome, uint16 _generation, address _target) external onlyOperator returns (uint40 babyId)
    {
        return _generate(_genome, _generation, _target);
    }

    function generate(uint _genome, uint16 _generation, address[] _target) external onlyOperator
    {
        for (uint i = 0; i < _target.length; i++)
        {
            _generate(_genome, _generation, _target[i]);
        }
    }

    function _generate(uint _genome, uint16 _generation, address _target) internal returns (uint40 babyId)
    {
        coreContract.changeCooldownEndTime(momId, 0);
        coreContract.changeCooldownEndTime(dadId, 0);
        coreContract.changeCooldownIndex(momId, 0);
        coreContract.changeCooldownIndex(dadId, 0);

        babyId = coreContract.breedWith(momId, dadId);

        coreContract.changeCooldownIndex(babyId, _generation);
        coreContract.changeGeneration(babyId, _generation);

        coreContract.changeGenes(babyId, _genome);

        coreContract.transfer(_target, babyId);

        return babyId;
    }

    function recoverCutie(uint40 _cutieId) external onlyOwner
    {
        coreContract.transfer(msg.sender, _cutieId);
    }
}