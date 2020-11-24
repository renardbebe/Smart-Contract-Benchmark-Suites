 

pragma solidity ^0.5.8;
 



 



 
 
 
 

 
 
 
 

 
 



contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

 
 

contract Resolver is DSAuth {
  mapping (bytes4 => address) public pointers;

  function register(string memory signature, address destination) public
  auth
  {
    pointers[stringToSig(signature)] = destination;
  }

  function lookup(bytes4 sig) public view returns(address) {
    return pointers[sig];
  }

  function stringToSig(string memory signature) public pure returns(bytes4) {
    return bytes4(keccak256(abi.encodePacked(signature)));
  }
}



contract EtherRouter is DSAuth {
  Resolver public resolver;

  function() external payable {
    if (msg.sig == 0) {
      return;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address destination = resolver.lookup(msg.sig);

     
    assembly {
      let size := extcodesize(destination)
      if eq(size, 0) { revert(0,0) }

      calldatacopy(mload(0x40), 0, calldatasize)
      let result := delegatecall(gas, destination, mload(0x40), calldatasize, mload(0x40), 0)  
       
      returndatacopy(mload(0x40), 0, returndatasize)
      switch result
      case 1 { return(mload(0x40), returndatasize) }
      default { revert(mload(0x40), returndatasize) }
    }
  }

  function setResolver(address _resolver) public
  auth
  {
    resolver = Resolver(_resolver);
  }
}