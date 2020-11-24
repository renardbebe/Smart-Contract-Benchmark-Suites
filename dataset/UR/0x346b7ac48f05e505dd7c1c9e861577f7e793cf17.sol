 

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












 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}



 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}







contract Contract is Ownable, SupportsInterfaceWithLookup {
     
    bytes4 public constant InterfaceId_Contract = 0x6125ede5;

    Template public template;

    constructor(address _owner) public {
        require(_owner != address(0));

        template = Template(msg.sender);
        owner = _owner;

        _registerInterface(InterfaceId_Contract);
    }
}


 
contract Template is Ownable, SupportsInterfaceWithLookup {
     
    bytes4 public constant InterfaceId_Template = 0xd48445ff;

    mapping(string => string) nameOfLocale;
    mapping(string => string) descriptionOfLocale;
     
    bytes32 public bytecodeHash;
     
    uint public price;
     
    address public beneficiary;

     
    event Instantiated(address indexed creator, address indexed contractAddress);

     
    constructor(
        bytes32 _bytecodeHash,
        uint _price,
        address _beneficiary
    ) public {
        bytecodeHash = _bytecodeHash;
        price = _price;
        beneficiary = _beneficiary;
        if (price > 0) {
            require(beneficiary != address(0));
        }

        _registerInterface(InterfaceId_Template);
    }

     
    function name(string _locale) public view returns (string) {
        return nameOfLocale[_locale];
    }

     
    function description(string _locale) public view returns (string) {
        return descriptionOfLocale[_locale];
    }

     
    function setNameAndDescription(string _locale, string _name, string _description) public onlyOwner {
        nameOfLocale[_locale] = _name;
        descriptionOfLocale[_locale] = _description;
    }

     
    function instantiate(bytes _bytecode, bytes _args) public payable returns (address contractAddress) {
        require(bytecodeHash == keccak256(_bytecode));
        bytes memory calldata = abi.encodePacked(_bytecode, _args);
        assembly {
            contractAddress := create(0, add(calldata, 0x20), mload(calldata))
        }
        if (contractAddress == address(0)) {
            revert("Cannot instantiate contract");
        } else {
            Contract c = Contract(contractAddress);
             
            require(c.supportsInterface(0x01ffc9a7));
             
            require(c.supportsInterface(0x6125ede5));

            if (price > 0) {
                require(msg.value == price);
                beneficiary.transfer(msg.value);
            }
            emit Instantiated(msg.sender, contractAddress);
        }
    }
}


 
contract Registry is Ownable {
    bool opened;
    string[] identifiers;
    mapping(string => address) registrantOfIdentifier;
    mapping(string => uint[]) versionsOfIdentifier;
    mapping(string => mapping(uint => Template)) templateOfVersionOfIdentifier;

    constructor(bool _opened) Ownable() public {
        opened = _opened;
    }

     
    function open() onlyOwner public {
        opened = true;
    }

     
    function register(string _identifier, uint _version, Template _template) public {
        require(opened || msg.sender == owner);

         
        require(_template.supportsInterface(0x01ffc9a7));
         
        require(_template.supportsInterface(0xd48445ff));

        address registrant = registrantOfIdentifier[_identifier];
        require(registrant == address(0) || registrant == msg.sender, "identifier already registered by another registrant");
        if (registrant == address(0)) {
            identifiers.push(_identifier);
            registrantOfIdentifier[_identifier] = msg.sender;
        }

        uint[] storage versions = versionsOfIdentifier[_identifier];
        if (versions.length > 0) {
            require(_version > versions[versions.length - 1], "new version must be greater than old versions");
        }
        versions.push(_version);
        templateOfVersionOfIdentifier[_identifier][_version] = _template;
    }

    function numberOfIdentifiers() public view returns (uint size) {
        return identifiers.length;
    }

    function identifierAt(uint _index) public view returns (string identifier) {
        return identifiers[_index];
    }

    function versionsOf(string _identifier) public view returns (uint[] version) {
        return versionsOfIdentifier[_identifier];
    }

    function templateOf(string _identifier, uint _version) public view returns (Template template) {
        return templateOfVersionOfIdentifier[_identifier][_version];
    }

    function latestTemplateOf(string _identifier) public view returns (Template template) {
        uint[] storage versions = versionsOfIdentifier[_identifier];
        return templateOfVersionOfIdentifier[_identifier][versions[versions.length - 1]];
    }
}


 
contract ERC20SaleStrategyRegistry is Registry(false) {
}