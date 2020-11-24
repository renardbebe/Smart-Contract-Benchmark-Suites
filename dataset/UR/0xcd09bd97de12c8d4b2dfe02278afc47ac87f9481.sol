 

pragma solidity ^0.5.3;

pragma solidity ^0.5.3;

 
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

 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract KittyCoreInterface is ERC721  {
    uint256 public autoBirthFee;
    address public saleAuction;
    address public siringAuction;
    function breedWithAuto(uint256 _matronId, uint256 _sireId) public payable;
    function createSaleAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external;
    function createSiringAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external;
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract AuctionInterface {
    function cancelAuction(uint256 _tokenId) external;
}

contract Ownable {
  address payable public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor(address payable _owner) public {
    if(_owner == address(0)) {
      owner = msg.sender;
    } else {
      owner = _owner;
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address payable _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    constructor(address payable _owner) Ownable(_owner) public {}

    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract should be paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract CKProxy is Pausable {
  KittyCoreInterface public kittyCore;
  AuctionInterface public saleAuction;
  AuctionInterface public siringAuction;

constructor(address payable _owner, address _kittyCoreAddress) Pausable(_owner) public {
    require(_kittyCoreAddress != address(0));
    kittyCore = KittyCoreInterface(_kittyCoreAddress);
    require(kittyCore.supportsInterface(0x9a20483d));

    saleAuction = AuctionInterface(kittyCore.saleAuction());
    siringAuction = AuctionInterface(kittyCore.siringAuction());
  }

   
  function transferKitty(address _to, uint256 _kittyId) external onlyOwner {
    kittyCore.transfer(_to, _kittyId);
  }

   
  function transferKittyBulk(address _to, uint256[] calldata _kittyIds) external onlyOwner {
    for(uint256 i = 0; i < _kittyIds.length; i++) {
      kittyCore.transfer(_to, _kittyIds[i]);
    }
  }

   
  function transferKittyFrom(address _from, address _to, uint256 _kittyId) external onlyOwner {
    kittyCore.transferFrom(_from, _to, _kittyId);
  }

   
  function approveKitty(address _to, uint256 _kittyId) external  onlyOwner {
    kittyCore.approve(_to, _kittyId);
  }

   
  function createSaleAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external onlyOwner {
    kittyCore.createSaleAuction(_kittyId, _startingPrice, _endingPrice, _duration);
  }

   
  function cancelSaleAuction(uint256 _kittyId) external onlyOwner {
    saleAuction.cancelAuction(_kittyId);
  }

   
  function createSiringAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external onlyOwner {
    kittyCore.createSiringAuction(_kittyId, _startingPrice, _endingPrice, _duration);
  }

   
  function cancelSiringAuction(uint256 _kittyId) external onlyOwner {
    siringAuction.cancelAuction(_kittyId);
  }
}

  

contract SimpleBreeding is CKProxy {
  address payable public breeder;
  uint256 public breederReward;
  uint256 public originalBreederReward;
  uint256 public maxBreedingFee;

  event Breed(address breeder, uint256 matronId, uint256 sireId, uint256 reward);
  event MaxBreedingFeeChange(uint256 oldBreedingFee, uint256 newBreedingFee);
  event BreederRewardChange(uint256 oldBreederReward, uint256 newBreederReward);

  constructor(address payable _owner, address payable _breeder, address _kittyCoreAddress, uint256 _breederReward) CKProxy(_owner, _kittyCoreAddress) public {
    require(_breeder != address(0));
    breeder = _breeder;
    maxBreedingFee = kittyCore.autoBirthFee();
    breederReward = _breederReward;
    originalBreederReward = _breederReward;
  }

   
  function () external payable {}

   
  function withdraw(uint256 amount) external onlyOwner {
    owner.transfer(amount);
  }

   
  function setMaxBreedingFee(
    uint256 _maxBreedingFee
  ) external onlyOwner {
    emit MaxBreedingFeeChange(maxBreedingFee, _maxBreedingFee);
    maxBreedingFee = _maxBreedingFee;
  }

    
  function setBreederReward(
    uint256 _breederReward
  ) external {
    require(msg.sender == breeder || msg.sender == owner);
    
    if(msg.sender == owner) {
      require(_breederReward >= originalBreederReward || _breederReward > breederReward, 'Reward value is less than required');
    } else if(msg.sender == breeder) {
      require(_breederReward <= originalBreederReward, 'Reward value is more than original');
    }

    emit BreederRewardChange(breederReward, _breederReward);
    breederReward = _breederReward;
  }

   
  function breed(uint256 _matronId, uint256 _sireId) external whenNotPaused {
    require(msg.sender == breeder || msg.sender == owner);
    uint256 fee = kittyCore.autoBirthFee();
    require(fee <= maxBreedingFee);
    kittyCore.breedWithAuto.value(fee)(_matronId, _sireId);

    uint256 reward = 0;
     
    if(msg.sender == breeder) {
      reward = breederReward;
      breeder.transfer(reward);
    }

    emit Breed(msg.sender, _matronId, _sireId, reward);
  }

  function destroy() public onlyOwner {
    require(kittyCore.balanceOf(address(this)) == 0, 'Contract has tokens');
    selfdestruct(owner);
  }

  function destroyAndSend(address payable _recipient) public onlyOwner {
    require(kittyCore.balanceOf(address(this)) == 0, 'Contract has tokens');
    selfdestruct(_recipient);
  }
}

contract SimpleBreedingFactory is Pausable {
    using SafeMath for uint256;

    KittyCoreInterface public kittyCore;
    uint256 public breederReward = 0.001 ether;
    uint256 public commission = 0 wei;
    uint256 public provisionFee;
    mapping (bytes32 => address) public breederToContract;

    event ContractCreated(address contractAddress, address breeder, address owner);
    event ContractRemoved(address contractAddress);

    constructor(address _kittyCoreAddress) Pausable(address(0)) public {
        provisionFee = commission + breederReward;
        kittyCore = KittyCoreInterface(_kittyCoreAddress);
        require(kittyCore.supportsInterface(0x9a20483d), "Invalid contract");
    }

     
    function setBreederReward(uint256 _breederReward) external onlyOwner {
        require(_breederReward > 0, "Breeder reward must be greater than 0");
        breederReward = _breederReward;
        provisionFee = uint256(commission).add(breederReward);
    }

     
    function setCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
        provisionFee = uint256(commission).add(breederReward);
    }

     
    function setKittyCore(address _kittyCore) external onlyOwner {
        kittyCore = KittyCoreInterface(_kittyCore);
        require(kittyCore.supportsInterface(0x9a20483d), "Invalid contract");
    }

    function () external payable {
        revert("Do not send funds to contract");
    }

     
    function withdraw(uint256 amount) external onlyOwner {
        owner.transfer(amount);
    }
    
     
    function createContract(address payable _breederAddress) external payable whenNotPaused {
        require(msg.value >= provisionFee, "Invalid value");

         
         
         
        bytes32 key = keccak256(abi.encodePacked(_breederAddress, msg.sender));
        require(breederToContract[key] == address(0), "Breeder already enrolled");
        
         
        uint256 excess = uint256(msg.value).sub(provisionFee);
        SimpleBreeding newContract = new SimpleBreeding(msg.sender, _breederAddress, address(kittyCore), breederReward);
        breederToContract[key] = address(newContract);
        if(excess > 0) {
            address(newContract).transfer(excess);
        }

         
        _breederAddress.transfer(breederReward);

        emit ContractCreated(address(newContract), _breederAddress, msg.sender);
    }

     
    function removeContract(address _breederAddress, address _ownerAddress) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_breederAddress, _ownerAddress));
        address contractAddress = breederToContract[key];
        require(contractAddress != address(0), "Breeder not enrolled");
        delete breederToContract[key];

        emit ContractRemoved(contractAddress);
    }
}