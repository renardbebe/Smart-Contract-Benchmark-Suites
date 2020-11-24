 

 

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

  function PromoCode(ERC20 _token, uint256 _amount) {
    amount = _amount;
    token = _token;
  }

  function setAmount(uint256 _amount) onlyOwner {
    amount = _amount;
  }

  function redeem(string promoCode, bytes signature) {
    bytes32 hash = keccak256(abi.encodePacked(promoCode));
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) v += 27;

    require(!used[hash]);
    used[hash] = true;
    require(verifyString(promoCode, v, r, s) == owner);
    address user = msg.sender;
    require(token.transferFrom(owner, user, amount));
    emit Redeem(user, amount, promoCode);
  }

   
   
  function verifyString(string message, uint8 v, bytes32 r, bytes32 s) public pure returns (address signer) {
     
    string memory header = "\x19Ethereum Signed Message:\n000000";
    uint256 lengthOffset;
    uint256 length;
    assembly {
     
      length := mload(message)
     
      lengthOffset := add(header, 57)
    }
     
    require(length <= 999999);
     
    uint256 lengthLength = 0;
     
    uint256 divisor = 100000;
     
    while (divisor != 0) {
       
      uint256 digit = length / divisor;
      if (digit == 0) {
         
        if (lengthLength == 0) {
          divisor /= 10;
          continue;
        }
      }
       
      lengthLength++;
       
      length -= digit * divisor;
       
      divisor /= 10;

       
      digit += 0x30;
       
      lengthOffset++;
      assembly {
        mstore8(lengthOffset, digit)
      }
    }
     
    if (lengthLength == 0) {
      lengthLength = 1 + 0x19 + 1;
    } else {
      lengthLength += 1 + 0x19;
    }
     
    assembly {
      mstore(header, lengthLength)
    }
     
    bytes32 check = keccak256(header, message);
    return ecrecover(check, v, r, s);
  }
}