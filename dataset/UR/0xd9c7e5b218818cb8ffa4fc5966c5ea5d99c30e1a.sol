 

pragma solidity ^0.4.17;

 
 
 
interface ERC20 {

   
  function transfer (address to, uint256 value) public returns (bool success);
  function transferFrom (address from, address to, uint256 value) public returns (bool success);
  function approve (address spender, uint256 value) public returns (bool success);
  function allowance (address owner, address spender) public constant returns (uint256 remaining);
  function balanceOf (address owner) public constant returns (uint256 balance);
   
  event Transfer (address indexed from, address indexed to, uint256 value);
  event Approval (address indexed owner, address indexed spender, uint256 value);
}

 
 
interface ERC165 {
   
  function supportsInterface(bytes4 interfaceID) external constant returns (bool);
}

contract Ownable {
  address public owner;

  event NewOwner(address indexed owner);

  function Ownable () public {
    owner = msg.sender;
  }

  modifier restricted () {
    require(owner == msg.sender);
    _;
  }

  function setOwner (address candidate) public restricted returns (bool) {
    require(candidate != address(0));
    owner = candidate;
    NewOwner(owner);
    return true;
  }
}


contract InterfaceSignatureConstants {
  bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC20 =
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('allowance(address,address)'));

  bytes4 constant InterfaceSignature_ERC20_PlusOptions = 
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('decimals()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('allowance(address,address)'));
}

contract AirdropCampaign is Ownable, InterfaceSignatureConstants {
  address public tokenAddress;
  address public tokenHolderAddress;
  uint256 public disbursementAmount;
  bool    public canDisburseMultipleTimes;

  mapping (address => uint256) public disbursements;

  modifier notHolder () {
    if (tokenHolderAddress == msg.sender) revert();
    _;
  }

  function AirdropCampaign (address tokenContract, address tokenHolder, uint256 amount) Ownable() public {
     
     
     
    if (tokenContract != address(0)) {
      setTokenAddress(tokenContract);
    }

    if (tokenHolder != address(0)) {
      setTokenHolderAddress(tokenHolder);
    }

    setDisbursementAmount(amount);
  }

  function register () public notHolder {
    if (!canDisburseMultipleTimes &&
        disbursements[msg.sender] > uint256(0)) revert();

    ERC20 tokenContract = ERC20(tokenAddress);

    disbursements[msg.sender] += disbursementAmount;
    if (!tokenContract.transferFrom(tokenHolderAddress, msg.sender, disbursementAmount)) revert();
  }

  function setTokenAddress (address candidate) public restricted {
    ERC165 candidateContract = ERC165(candidate);

     
     
     
    if (!candidateContract.supportsInterface(InterfaceSignature_ERC20)) revert();
    tokenAddress = candidateContract;
  }

  function setDisbursementAmount (uint256 amount) public restricted {
    if (amount == 0) revert();
    disbursementAmount = amount;
  }

  function setCanDisburseMultipleTimes (bool value) public restricted {
    canDisburseMultipleTimes = value;
  }

  function setTokenHolderAddress(address holder) public restricted {
    tokenHolderAddress = holder;
  }
}