 

 

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

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;



contract PromoCode is Ownable {
  ERC20 public token;
  mapping(bytes32 => bool) public used;
  uint256 public amount;

  event Redeem(address user, uint256 amount, string code);

  constructor(ERC20 _token, uint256 _amount) public {
    amount = _amount;
    token = _token;
  }

  function setAmount(uint256 _amount) public onlyOwner {
    amount = _amount;
  }

  function extractSignature(bytes memory signature) private pure returns (uint8 v, bytes32 r, bytes32 s) {
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) {
      v += 27;
    }
    return (v, r, s);
  }

  function redeem(address redeemer, string promoCode, bytes redeemSignature) public {
    bytes32 promoCodeHash = keccak256(abi.encodePacked(address(this), redeemer, promoCode));
    bytes32 hash = keccak256(abi.encodePacked(promoCode));
    (uint8 v, bytes32 r, bytes32 s) = extractSignature(redeemSignature);
    require(!used[hash]);
    used[hash] = true;
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", promoCodeHash)), v, r, s) == owner);
    require(token.transferFrom(owner, redeemer, amount));
    emit Redeem(redeemer, amount, promoCode);
  }
}