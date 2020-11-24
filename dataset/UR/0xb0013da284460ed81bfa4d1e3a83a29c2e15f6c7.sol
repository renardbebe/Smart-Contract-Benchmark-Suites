 

 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 

pragma solidity 0.4.24;

 
interface IETokenProxy {

     

     
    function nameProxy(address sender) external view returns(string);

    function symbolProxy(address sender)
        external
        view
        returns(string);

    function decimalsProxy(address sender)
        external
        view
        returns(uint8);

     
    function totalSupplyProxy(address sender)
        external
        view
        returns (uint256);

    function balanceOfProxy(address sender, address who)
        external
        view
        returns (uint256);

    function allowanceProxy(address sender,
                            address owner,
                            address spender)
        external
        view
        returns (uint256);

    function transferProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function approveProxy(address sender,
                          address spender,
                          uint256 value)
        external
        returns (bool);

    function transferFromProxy(address sender,
                               address from,
                               address to,
                               uint256 value)
        external
        returns (bool);

    function mintProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function changeMintingRecipientProxy(address sender,
                                         address mintingRecip)
        external;

    function burnProxy(address sender, uint256 value) external;

    function burnFromProxy(address sender,
                           address from,
                           uint256 value)
        external;

    function increaseAllowanceProxy(address sender,
                                    address spender,
                                    uint addedValue)
        external
        returns (bool success);

    function decreaseAllowanceProxy(address sender,
                                    address spender,
                                    uint subtractedValue)
        external
        returns (bool success);

    function pauseProxy(address sender) external;

    function unpauseProxy(address sender) external;

    function pausedProxy(address sender) external view returns (bool);

    function finalizeUpgrade() external;
}

 

 

pragma solidity 0.4.24;


 
interface IEToken {

     

    function upgrade(IETokenProxy upgradedToken) external;

     
    function name() external view returns(string);

    function symbol() external view returns(string);

    function decimals() external view returns(uint8);

     
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external
        returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

     
    function mint(address to, uint256 value) external returns (bool);

     
    function burn(uint256 value) external;

    function burnFrom(address from, uint256 value) external;

     
    function increaseAllowance(
        address spender,
        uint addedValue
    )
        external
        returns (bool success);

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
        external
        returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

}

 

 

pragma solidity 0.4.24;



 
contract TokenManager is Ownable {

     
    struct TokenEntry {
        bool exists;
        uint index;
        IEToken token;
    }

    mapping (bytes32 => TokenEntry) private tokens;
    bytes32[] private names;

    event TokenAdded(bytes32 indexed name, IEToken indexed addr);
    event TokenDeleted(bytes32 indexed name, IEToken indexed addr);
    event TokenUpgraded(bytes32 indexed name,
                        IEToken indexed from,
                        IEToken indexed to);

     
    modifier tokenExists(bytes32 _name) {
        require(_tokenExists(_name), "Token does not exist");
        _;
    }

     
    modifier tokenNotExists(bytes32 _name) {
        require(!(_tokenExists(_name)), "Token already exist");
        _;
    }

     
    modifier notNullToken(IEToken _iEToken) {
        require(_iEToken != IEToken(0), "Supplied token is null");
        _;
    }

     
    function addToken(bytes32 _name, IEToken _iEToken)
        public
        onlyOwner
        tokenNotExists(_name)
        notNullToken(_iEToken)
    {
        tokens[_name] = TokenEntry({
            index: names.length,
            token: _iEToken,
            exists: true
        });
        names.push(_name);
        emit TokenAdded(_name, _iEToken);
    }

     
    function deleteToken(bytes32 _name)
        public
        onlyOwner
        tokenExists(_name)
    {
        IEToken prev = tokens[_name].token;
        delete names[tokens[_name].index];
        delete tokens[_name].token;
        delete tokens[_name];
        emit TokenDeleted(_name, prev);
    }

     
    function upgradeToken(bytes32 _name, IEToken _iEToken)
        public
        onlyOwner
        tokenExists(_name)
        notNullToken(_iEToken)
    {
        IEToken prev = tokens[_name].token;
        tokens[_name].token = _iEToken;
        emit TokenUpgraded(_name, prev, _iEToken);
    }

     
    function getToken (bytes32 _name)
        public
        tokenExists(_name)
        view
        returns (IEToken)
    {
        return tokens[_name].token;
    }

     
    function getTokens ()
        public
        view
        returns (bytes32[])
    {
        return names;
    }

     
    function _tokenExists (bytes32 _name)
        private
        view
        returns (bool)
    {
        return tokens[_name].exists;
    }

}