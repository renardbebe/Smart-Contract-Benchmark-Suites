 

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

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

 

interface IPassportLogicRegistry {
     
    event PassportLogicAdded(string version, address implementation);

     
    event CurrentPassportLogicSet(string version, address implementation);

     
    function getPassportLogic(string _version) external view returns (address);

     
    function getCurrentPassportLogicVersion() external view returns (string);

     
    function getCurrentPassportLogic() external view returns (address);
}

 

 
contract PassportLogicRegistry is IPassportLogicRegistry, Ownable, HasNoEther, HasNoTokens {
     
    string internal currentPassportLogicVersion;
    address internal currentPassportLogic;

     
    mapping(string => address) internal passportLogicImplementations;

     
    constructor (string _version, address _implementation) public {
        _addPassportLogic(_version, _implementation);
        _setCurrentPassportLogic(_version);
    }

     
    function addPassportLogic(string _version, address _implementation) public onlyOwner {
        _addPassportLogic(_version, _implementation);
    }

     
    function getPassportLogic(string _version) external view returns (address) {
        return passportLogicImplementations[_version];
    }

     
    function setCurrentPassportLogic(string _version) public onlyOwner {
        _setCurrentPassportLogic(_version);
    }

     
    function getCurrentPassportLogicVersion() external view returns (string) {
        return currentPassportLogicVersion;
    }

     
    function getCurrentPassportLogic() external view returns (address) {
        return currentPassportLogic;
    }

    function _addPassportLogic(string _version, address _implementation) internal {
        require(_implementation != 0x0, "Cannot set implementation to a zero address");
        require(passportLogicImplementations[_version] == 0x0, "Cannot replace existing version implementation");

        passportLogicImplementations[_version] = _implementation;
        emit PassportLogicAdded(_version, _implementation);
    }

    function _setCurrentPassportLogic(string _version) internal {
        require(passportLogicImplementations[_version] != 0x0, "Cannot set non-existing passport logic as current implementation");

        currentPassportLogicVersion = _version;
        currentPassportLogic = passportLogicImplementations[_version];
        emit CurrentPassportLogicSet(currentPassportLogicVersion, currentPassportLogic);
    }
}