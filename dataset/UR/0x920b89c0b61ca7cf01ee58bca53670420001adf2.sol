 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

     
    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

 

contract ImpLoot is Haltable {

    struct TemplateState {
        uint weiAmount;
        mapping (address => address) owners;
    }

    address private destinationWallet;

     
    mapping (uint => TemplateState) private templatesState;

     
    event Bought(address _receiver, uint _lootTemplateId, uint _weiAmount);

    constructor(address _destinationWallet) public {
        require(_destinationWallet != address(0));
        destinationWallet = _destinationWallet;
    }

    function buy(uint _lootTemplateId) payable stopInEmergency{
        uint weiAmount = msg.value;
        address receiver = msg.sender;

        require(destinationWallet != address(0));
        require(weiAmount != 0);
        require(templatesState[_lootTemplateId].owners[receiver] != receiver);
        require(templatesState[_lootTemplateId].weiAmount == weiAmount);

        templatesState[_lootTemplateId].owners[receiver] = receiver;

        destinationWallet.transfer(weiAmount);

        emit Bought(receiver, _lootTemplateId, weiAmount);
    }

    function getPrice(uint _lootTemplateId) constant returns (uint weiAmount) {
        return templatesState[_lootTemplateId].weiAmount;
    }

    function setPrice(uint _lootTemplateId, uint _weiAmount) external onlyOwner {
        templatesState[_lootTemplateId].weiAmount = _weiAmount;
    }

    function isOwner(uint _lootTemplateId, address _owner) constant returns (bool isOwner){
        return templatesState[_lootTemplateId].owners[_owner] == _owner;
    }

    function setDestinationWallet(address _walletAddress) external onlyOwner {
        require(_walletAddress != address(0));

        destinationWallet = _walletAddress;
    }

    function getDestinationWallet() constant returns (address wallet) {
        return destinationWallet;
    }
}