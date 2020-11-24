 

 
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


 

contract Registry is Ownable {

    mapping(address =>
    mapping(address =>
    mapping(bytes32 =>
    mapping(bytes32 => bytes32)))) registry;

    event ClaimSet(
        address indexed subject,
        address indexed issuer,
        bytes32 indexed id,
        bytes32 key,
        bytes32 data,
        uint updatedAt
    );

    event ClaimRemoved(
        address indexed subject,
        address indexed issuer,
        bytes32 indexed id,
        bytes32 key,
        uint removedAt
    );

    function setClaim(
        address subject,
        address issuer,
        bytes32 id,
        bytes32 key,
        bytes32 data
    ) public {
        require(msg.sender == issuer || msg.sender == owner);
        registry[subject][issuer][id][key] = data;
        emit ClaimSet(subject, issuer, id, key, data, now);
    }

    function getClaim(
        address subject,
        address issuer,
        bytes32 id,
        bytes32 key
    )
    public view returns(bytes32) {
        return registry[subject][issuer][id][key];
    }

    function removeClaim(
        address subject,
        address issuer,
        bytes32 id,
        bytes32 key
    ) public {
        require(
            msg.sender == subject || msg.sender == issuer || msg.sender == owner
        );
        delete registry[subject][issuer][id][key];
        emit ClaimRemoved(subject, issuer, id, key, now);
    }
}