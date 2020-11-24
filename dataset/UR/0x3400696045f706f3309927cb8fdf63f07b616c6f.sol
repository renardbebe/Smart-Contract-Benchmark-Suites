 

pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract AccountRegistry is Ownable {
  mapping(address => bool) public accounts;

   
  struct Invite {
    address creator;
    address recipient;
  }

   
   
   
   
  mapping(address => Invite) public invites;

  InviteCollateralizer public inviteCollateralizer;
  ERC20 public blt;
  address private inviteAdmin;

  event InviteCreated(address indexed inviter);
  event InviteAccepted(address indexed inviter, address indexed recipient);
  event AccountCreated(address indexed newUser);

  function AccountRegistry(ERC20 _blt, InviteCollateralizer _inviteCollateralizer) public {
    blt = _blt;
    accounts[owner] = true;
    inviteAdmin = owner;
    inviteCollateralizer = _inviteCollateralizer;
  }

  function setInviteCollateralizer(InviteCollateralizer _newInviteCollateralizer) public nonZero(_newInviteCollateralizer) onlyOwner {
    inviteCollateralizer = _newInviteCollateralizer;
  }

  function setInviteAdmin(address _newInviteAdmin) public onlyOwner nonZero(_newInviteAdmin) {
    inviteAdmin = _newInviteAdmin;
  }

   
  function createAccount(address _newUser) public onlyInviteAdmin {
    require(!accounts[_newUser]);
    createAccountFor(_newUser);
  }

   
  function createInvite(bytes _sig) public onlyUser {
    require(inviteCollateralizer.takeCollateral(msg.sender));

    address signer = recoverSigner(_sig);
    require(inviteDoesNotExist(signer));

    invites[signer] = Invite(msg.sender, address(0));
    InviteCreated(msg.sender);
  }

   
  function acceptInvite(bytes _sig) public onlyNonUser {
    address signer = recoverSigner(_sig);
    require(inviteExists(signer) && inviteHasNotBeenAccepted(signer));

    invites[signer].recipient = msg.sender;
    createAccountFor(msg.sender);
    InviteAccepted(invites[signer].creator, msg.sender);
  }

   
  function inviteHasNotBeenAccepted(address _signer) internal view returns (bool) {
    return invites[_signer].recipient == address(0);
  }

   
  function inviteDoesNotExist(address _signer) internal view returns (bool) {
    return !inviteExists(_signer);
  }

   
  function inviteExists(address _signer) internal view returns (bool) {
    return invites[_signer].creator != address(0);
  }

   
  function recoverSigner(bytes _sig) private view returns (address) {
    address signer = ECRecovery.recover(keccak256(msg.sender), _sig);
    require(signer != address(0));

    return signer;
  }

   
  function createAccountFor(address _newUser) private {
    accounts[_newUser] = true;
    AccountCreated(_newUser);
  }

   
  modifier onlyNonUser {
    require(!accounts[msg.sender]);
    _;
  }

   
  modifier onlyUser {
    require(accounts[msg.sender]);
    _;
  }

  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  modifier onlyInviteAdmin {
    require(msg.sender == inviteAdmin);
    _;
  }
}

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

contract InviteCollateralizer is Ownable {
   
   
   

  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  ERC20 public blt;
  address public seizedTokensWallet;
  mapping (address => Collateralization[]) public collateralizations;
  uint256 public collateralAmount = 1e17;
  uint64 public lockupDuration = 1 years;

  address private collateralTaker;
  address private collateralSeizer;

  struct Collateralization {
    uint256 value;  
    uint64 releaseDate;  
    bool claimed;  
  }

  event CollateralPosted(address indexed owner, uint64 releaseDate, uint256 amount);
  event CollateralSeized(address indexed owner, uint256 collateralId);

  function InviteCollateralizer(ERC20 _blt, address _seizedTokensWallet) public {
    blt = _blt;
    seizedTokensWallet = _seizedTokensWallet;
    collateralTaker = owner;
    collateralSeizer = owner;
  }

  function takeCollateral(address _owner) public onlyCollateralTaker returns (bool) {
    require(blt.transferFrom(_owner, address(this), collateralAmount));

    uint64 releaseDate = uint64(now) + lockupDuration;
    CollateralPosted(_owner, releaseDate, collateralAmount);
    collateralizations[_owner].push(Collateralization(collateralAmount, releaseDate, false));

    return true;
  }

  function reclaim() public returns (bool) {
    require(collateralizations[msg.sender].length > 0);

    uint256 reclaimableAmount = 0;

    for (uint256 i = 0; i < collateralizations[msg.sender].length; i++) {
      if (collateralizations[msg.sender][i].claimed) {
        continue;
      } else if (collateralizations[msg.sender][i].releaseDate > now) {
        break;
      }

      reclaimableAmount = reclaimableAmount.add(collateralizations[msg.sender][i].value);
      collateralizations[msg.sender][i].claimed = true;
    }

    require(reclaimableAmount > 0);

    return blt.transfer(msg.sender, reclaimableAmount);
  }

  function seize(address _subject, uint256 _collateralId) public onlyCollateralSeizer {
    require(collateralizations[_subject].length >= _collateralId + 1);
    require(!collateralizations[_subject][_collateralId].claimed);

    collateralizations[_subject][_collateralId].claimed = true;
    blt.transfer(seizedTokensWallet, collateralizations[_subject][_collateralId].value);
    CollateralSeized(_subject, _collateralId);
  }

  function changeCollateralTaker(address _newCollateralTaker) public nonZero(_newCollateralTaker) onlyOwner {
    collateralTaker = _newCollateralTaker;
  }

  function changeCollateralSeizer(address _newCollateralSeizer) public nonZero(_newCollateralSeizer) onlyOwner {
    collateralSeizer = _newCollateralSeizer;
  }

  function changeCollateralAmount(uint256 _newAmount) public onlyOwner {
    require(_newAmount > 0);
    collateralAmount = _newAmount;
  }

  function changeSeizedTokensWallet(address _newSeizedTokensWallet) public nonZero(_newSeizedTokensWallet) onlyOwner {
    seizedTokensWallet = _newSeizedTokensWallet; 
  }

  function changeLockupDuration(uint64 _newLockupDuration) public onlyOwner {
    lockupDuration = _newLockupDuration;
  }

  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  modifier onlyCollateralTaker {
    require(msg.sender == collateralTaker);
    _;
  }

  modifier onlyCollateralSeizer {
    require(msg.sender == collateralSeizer);
    _;
  }
}