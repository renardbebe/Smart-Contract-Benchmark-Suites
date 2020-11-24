 

pragma solidity ^0.4.17;


 
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

 
contract EthealWhitelist is Ownable {
    using ECRecovery for bytes32;

     
    address public signer;

     
    mapping(address => bool) public isWhitelisted;

    event WhitelistSet(address indexed _address, bool _state);

     
     
     
    function EthealWhitelist(address _signer) {
        require(_signer != address(0));

        signer = _signer;
    }

     
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));

        signer = _signer;
    }

     
     
     

     
    function setWhitelist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
        isWhitelisted[_addr] = _state;
        WhitelistSet(_addr, _state);
    }

     
    function setManyWhitelist(address[] _addr, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i], _state);
        }
    }

     
    function isOffchainWhitelisted(address _addr, bytes _sig) public view returns (bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n20",_addr);
        return hash.recover(_sig) == signer;
    }
}