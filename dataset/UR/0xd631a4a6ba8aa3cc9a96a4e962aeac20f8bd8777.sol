 

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
      function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;


contract SpiderPay {
  event Paid(bytes32 hash, bytes32 indexed no, address token, address from, uint256 value);
  using Address for address;

  mapping(bytes32 => bool) public paid;
  address accountant = address(0xf2EBAbAeA9da140416793cbF348F14b650fe7329);
  address signer;
  address owner;

  constructor(address _owner, address _signer) public {
    owner = _owner;
    signer = _signer;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "The caller is not the Owner role");
    _;
  }

  function setOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function() external payable {
    require(false, "DISABLED_METHOD");
  }

  function isValid(
    bytes32 hash,
    address signer,
    bytes memory signature
  )
  public
  pure
  returns (bool)
  {
    require(
      signature.length == 65,
      "LENGTH_65_REQUIRED"
    );

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
     
      r := mload(add(signature, 32))
     
      s := mload(add(signature, 64))
     
      v := byte(0, mload(add(signature, 96)))
    }

    address recovered = ecrecover(
      keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        hash
      )),
      v,
      r,
      s
    );
    return signer == recovered;
  }

  function payETH(bytes32 no, uint256 expiration, bytes memory signature) public payable {
    require(expiration > block.timestamp, "EXPIRED_PAY");
    require(!paid[no], "PAID_NO");

    bytes32 hash = keccak256(abi.encodePacked(no, expiration));
    require(isValid(hash, signer, signature), "INVALID_SIGN");

    accountant.toPayable().transfer(msg.value);

    emit Paid(hash, no, address(0x0000000000000000000000000000000000000001), msg.sender, msg.value);
  }
}