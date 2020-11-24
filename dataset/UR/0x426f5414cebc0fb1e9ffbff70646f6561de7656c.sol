 

 

pragma solidity 0.4.24;

 
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

 
contract OracleRegistry is Ownable {

    event LogAddOracle(
        address indexed oracle,
        string name
    );

    event LogRemoveOracle(
        address indexed oracle,
        string name
    );

    event LogOracleNameChange(address indexed oracle, string oldName, string newName);

    mapping (address => OracleMetadata) public oracles;
    mapping (string => address) internal oracleByName;

    address[] public oracleAddresses;

    struct OracleMetadata {
        address oracle;
        string name;
    }

    modifier oracleExists(address _oracle) {
        require(oracles[_oracle].oracle != address(0), "OracleRegistry::oracle doesn't exist");
        _;
    }

    modifier oracleDoesNotExist(address _oracle) {
        require(oracles[_oracle].oracle == address(0), "OracleRegistry::oracle exists");
        _;
    }

    modifier nameDoesNotExist(string _name) {
        require(oracleByName[_name] == address(0), "OracleRegistry::name exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "OracleRegistry::address is null");
        _;
    }

     
     
     
    function addOracle(
        address _oracle,
        string _name)
        public
        onlyOwner
        oracleDoesNotExist(_oracle)
        addressNotNull(_oracle)
        nameDoesNotExist(_name)
    {
        oracles[_oracle] = OracleMetadata({
            oracle: _oracle,
            name: _name
        });
        oracleAddresses.push(_oracle);
        oracleByName[_name] = _oracle;
        emit LogAddOracle(
            _oracle,
            _name
        );
    }

     
     
    function removeOracle(address _oracle, uint _index)
        public
        onlyOwner
        oracleExists(_oracle)
    {
        require(oracleAddresses[_index] == _oracle, "OracleRegistry::invalid index");

        oracleAddresses[_index] = oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.length -= 1;

        OracleMetadata storage oracle = oracles[_oracle];
        emit LogRemoveOracle(
            oracle.oracle,
            oracle.name
        );
        delete oracleByName[oracle.name];
        delete oracles[_oracle];
    }

     
     
     
    function setOracleName(address _oracle, string _name)
        public
        onlyOwner
        oracleExists(_oracle)
        nameDoesNotExist(_name)
    {
        OracleMetadata storage oracle = oracles[_oracle];
        emit LogOracleNameChange(_oracle, oracle.name, _name);
        delete oracleByName[oracle.name];
        oracleByName[_name] = _oracle;
        oracle.name = _name;
    }

     
     
     
    function hasOracle(address _oracle)
        public
        view
        returns (bool) {
        return (oracles[_oracle].oracle == _oracle);
    }

     
     
     
    function getOracleAddressByName(string _name)
        public
        view
        returns (address) {
        return oracleByName[_name];
    }

     
     
     
    function getOracleMetaData(address _oracle)
        public
        view
        returns (
            address,   
            string    
        )
    {
        OracleMetadata memory oracle = oracles[_oracle];
        return (
            oracle.oracle,
            oracle.name
        );
    }

     
     
     
    function getOracleByName(string _name)
        public
        view
        returns (
            address,   
            string     
        )
    {
        address _oracle = oracleByName[_name];
        return getOracleMetaData(_oracle);
    }

     
     
    function getOracleAddresses()
        public
        view
        returns (address[])
    {
        return oracleAddresses;
    }

     
     
    function getOracleList()
        public
        view
        returns (address[], uint[], string)
    {
        if (oracleAddresses.length == 0)
            return;

        address[] memory addresses = oracleAddresses;
        uint[] memory nameLengths = new uint[](oracleAddresses.length);
        string memory allStrings;
        
        for (uint i = 0; i < oracleAddresses.length; i++) {
            string memory tmp = oracles[oracleAddresses[i]].name;
            nameLengths[i] = bytes(tmp).length;
            allStrings = strConcat(allStrings, tmp);
        }

        return (addresses, nameLengths, allStrings);
    }

     
     
    function strConcat(
        string _a,
        string _b)
        internal
        pure
        returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)
            bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++)
            bab[k++] = _bb[i];
        
        return string(bab);
    }
}