 

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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 

contract Reputation is Ownable {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    uint256 public totalSupply;
    uint public decimals = 18;

     
    event Mint(address indexed _to, uint256 _amount);
     
    event Burn(address indexed _from, uint256 _amount);

     
    function reputationOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function mint(address _to, uint _amount)
    public
    onlyOwner
    returns (bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

     
    function burn(address _from, uint _amount)
    public
    onlyOwner
    returns (bool)
    {
        uint amountMinted = _amount;
        if (balances[_from] < _amount) {
            amountMinted = balances[_from];
        }
        totalSupply = totalSupply.sub(amountMinted);
        balances[_from] = balances[_from].sub(amountMinted);
        emit Burn(_from, amountMinted);
        return true;
    }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract ERC827 is ERC20 {

    function approveAndCall(address _spender,uint256 _value,bytes _data) public payable returns(bool);

    function transferAndCall(address _to,uint256 _value,bytes _data) public payable returns(bool);

    function transferFromAndCall(address _from,address _to,uint256 _value,bytes _data) public payable returns(bool);

}

 

 

pragma solidity ^0.4.24;




 
contract ERC827Token is ERC827, StandardToken {

   
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.approve(_spender, _value);

         
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

   
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_to != address(this));

        super.transfer(_to, _value);

         
        require(_to.call.value(msg.value)(_data));
        return true;
    }

   
    function transferFromAndCall(
        address _from,
        address _to,
        uint256 _value,
        bytes _data
    )
    public payable returns (bool)
    {
        require(_to != address(this));

        super.transferFrom(_from, _to, _value);

         
        require(_to.call.value(msg.value)(_data));
        return true;
    }

   
    function increaseApprovalAndCall(
        address _spender,
        uint _addedValue,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.increaseApproval(_spender, _addedValue);

         
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

   
    function decreaseApprovalAndCall(
        address _spender,
        uint _subtractedValue,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.decreaseApproval(_spender, _subtractedValue);

         
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

}

 

 

contract DAOToken is ERC827Token,MintableToken,BurnableToken {

    string public name;
    string public symbol;
     
    uint8 public constant decimals = 18;
    uint public cap;

     
    constructor(string _name, string _symbol,uint _cap) public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        if (cap > 0)
            require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }
}

 

 
contract Avatar is Ownable {
    bytes32 public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericAction(address indexed _action, bytes32[] _params);
    event SendEther(uint _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint _value);
    event ExternalTokenIncreaseApproval(StandardToken indexed _externalToken, address _spender, uint _addedValue);
    event ExternalTokenDecreaseApproval(StandardToken indexed _externalToken, address _spender, uint _subtractedValue);
    event ReceiveEther(address indexed _sender, uint _value);

     
    constructor(bytes32 _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

     
    function() public payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

     
    function genericCall(address _contract,bytes _data) public onlyOwner {
         
        bool result = _contract.call(_data);
         
        assembly {
         
        returndatacopy(0, 0, returndatasize)

        switch result
         
        case 0 { revert(0, returndatasize) }
        default { return(0, returndatasize) }
        }
    }

     
    function sendEther(uint _amountInWei, address _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

     
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value)
    public onlyOwner returns(bool)
    {
        _externalToken.transfer(_to, _value);
        emit ExternalTokenTransfer(_externalToken, _to, _value);
        return true;
    }

     
    function externalTokenTransferFrom(
        StandardToken _externalToken,
        address _from,
        address _to,
        uint _value
    )
    public onlyOwner returns(bool)
    {
        _externalToken.transferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(_externalToken, _from, _to, _value);
        return true;
    }

     
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue)
    public onlyOwner returns(bool)
    {
        _externalToken.increaseApproval(_spender, _addedValue);
        emit ExternalTokenIncreaseApproval(_externalToken, _spender, _addedValue);
        return true;
    }

     
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue )
    public onlyOwner returns(bool)
    {
        _externalToken.decreaseApproval(_spender, _subtractedValue);
        emit ExternalTokenDecreaseApproval(_externalToken,_spender, _subtractedValue);
        return true;
    }

}

 

contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post,PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
     
    function when() public returns(CallPhase);
}

 

 
interface ControllerInterface {

     
    function mintReputation(uint256 _amount, address _to,address _avatar)
    external
    returns(bool);

     
    function burnReputation(uint256 _amount, address _from,address _avatar)
    external
    returns(bool);

     
    function mintTokens(uint256 _amount, address _beneficiary,address _avatar)
    external
    returns(bool);

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions,address _avatar)
    external
    returns(bool);

     
    function unregisterScheme(address _scheme,address _avatar)
    external
    returns(bool);
     
    function unregisterSelf(address _avatar) external returns(bool);

    function isSchemeRegistered( address _scheme,address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme,address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint,address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme,address _avatar) external view returns(bytes4);

     
    function globalConstraintsCount(address _avatar) external view returns(uint,uint);

    function isGlobalConstraintRegistered(address _globalConstraint,address _avatar) external view returns(bool);

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params,address _avatar)
    external returns(bool);

     
    function removeGlobalConstraint (address _globalConstraint,address _avatar)
    external  returns(bool);

   
    function upgradeController(address _newController,address _avatar)
    external returns(bool);

     
    function genericCall(address _contract,bytes _data,address _avatar)
    external
    returns(bytes32);

   
    function sendEther(uint _amountInWei, address _to,address _avatar)
    external returns(bool);

     
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value,address _avatar)
    external
    returns(bool);

     
    function externalTokenTransferFrom(StandardToken _externalToken, address _from, address _to, uint _value,address _avatar)
    external
    returns(bool);

     
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue,address _avatar)
    external
    returns(bool);

     
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue,address _avatar)
    external
    returns(bool);

     
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);
}

 

 
contract Controller is ControllerInterface {

    struct Scheme {
        bytes32 paramsHash;   
        bytes4  permissions;  
                              
                              
                              
                              
                              
                              
                              
    }

    struct GlobalConstraint {
        address gcAddress;
        bytes32 params;
    }

    struct GlobalConstraintRegister {
        bool isRegistered;  
        uint index;     
    }

    mapping(address=>Scheme) public schemes;

    Avatar public avatar;
    DAOToken public nativeToken;
    Reputation public nativeReputation;
   
    address public newController;
   

    GlobalConstraint[] public globalConstraintsPre;
   
    GlobalConstraint[] public globalConstraintsPost;
   
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPre;
   
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPost;

    event MintReputation (address indexed _sender, address indexed _to, uint256 _amount);
    event BurnReputation (address indexed _sender, address indexed _from, uint256 _amount);
    event MintTokens (address indexed _sender, address indexed _beneficiary, uint256 _amount);
    event RegisterScheme (address indexed _sender, address indexed _scheme);
    event UnregisterScheme (address indexed _sender, address indexed _scheme);
    event GenericAction (address indexed _sender, bytes32[] _params);
    event SendEther (address indexed _sender, uint _amountInWei, address indexed _to);
    event ExternalTokenTransfer (address indexed _sender, address indexed _externalToken, address indexed _to, uint _value);
    event ExternalTokenTransferFrom (address indexed _sender, address indexed _externalToken, address _from, address _to, uint _value);
    event ExternalTokenIncreaseApproval (address indexed _sender, StandardToken indexed _externalToken, address _spender, uint _value);
    event ExternalTokenDecreaseApproval (address indexed _sender, StandardToken indexed _externalToken, address _spender, uint _value);
    event UpgradeController(address indexed _oldController,address _newController);
    event AddGlobalConstraint(address indexed _globalConstraint, bytes32 _params,GlobalConstraintInterface.CallPhase _when);
    event RemoveGlobalConstraint(address indexed _globalConstraint ,uint256 _index,bool _isPre);
    event GenericCall(address indexed _contract,bytes _data);

    constructor( Avatar _avatar) public
    {
        avatar = _avatar;
        nativeToken = avatar.nativeToken();
        nativeReputation = avatar.nativeReputation();
        schemes[msg.sender] = Scheme({paramsHash: bytes32(0),permissions: bytes4(0x1F)});
    }

   
    function() external {
        revert();
    }

   
    modifier onlyRegisteredScheme() {
        require(schemes[msg.sender].permissions&bytes4(1) == bytes4(1));
        _;
    }

    modifier onlyRegisteringSchemes() {
        require(schemes[msg.sender].permissions&bytes4(2) == bytes4(2));
        _;
    }

    modifier onlyGlobalConstraintsScheme() {
        require(schemes[msg.sender].permissions&bytes4(4) == bytes4(4));
        _;
    }

    modifier onlyUpgradingScheme() {
        require(schemes[msg.sender].permissions&bytes4(8) == bytes4(8));
        _;
    }

    modifier onlyGenericCallScheme() {
        require(schemes[msg.sender].permissions&bytes4(16) == bytes4(16));
        _;
    }

    modifier onlySubjectToConstraint(bytes32 func) {
        uint idx;
        for (idx = 0;idx<globalConstraintsPre.length;idx++) {
            require((GlobalConstraintInterface(globalConstraintsPre[idx].gcAddress)).pre(msg.sender,globalConstraintsPre[idx].params,func));
        }
        _;
        for (idx = 0;idx<globalConstraintsPost.length;idx++) {
            require((GlobalConstraintInterface(globalConstraintsPost[idx].gcAddress)).post(msg.sender,globalConstraintsPost[idx].params,func));
        }
    }

    modifier isAvatarValid(address _avatar) {
        require(_avatar == address(avatar));
        _;
    }

     
    function mintReputation(uint256 _amount, address _to,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintReputation(msg.sender, _to, _amount);
        return nativeReputation.mint(_to, _amount);
    }

     
    function burnReputation(uint256 _amount, address _from,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("burnReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit BurnReputation(msg.sender, _from, _amount);
        return nativeReputation.burn(_from, _amount);
    }

     
    function mintTokens(uint256 _amount, address _beneficiary,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintTokens")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintTokens(msg.sender, _beneficiary, _amount);
        return nativeToken.mint(_beneficiary, _amount);
    }

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions,address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("registerScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {

        Scheme memory scheme = schemes[_scheme];

     
     

     
        require(bytes4(0x1F)&(_permissions^scheme.permissions)&(~schemes[msg.sender].permissions) == bytes4(0));

     
        require(bytes4(0x1F)&(scheme.permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

     
        schemes[_scheme].paramsHash = _paramsHash;
        schemes[_scheme].permissions = _permissions|bytes4(1);
        emit RegisterScheme(msg.sender, _scheme);
        return true;
    }

     
    function unregisterScheme( address _scheme,address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("unregisterScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {
     
        if (schemes[_scheme].permissions&bytes4(1) == bytes4(0)) {
            return false;
          }
     
        require(bytes4(0x1F)&(schemes[_scheme].permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

     
        emit UnregisterScheme(msg.sender, _scheme);
        delete schemes[_scheme];
        return true;
    }

     
    function unregisterSelf(address _avatar) external isAvatarValid(_avatar) returns(bool) {
        if (_isSchemeRegistered(msg.sender,_avatar) == false) {
            return false;
        }
        delete schemes[msg.sender];
        emit UnregisterScheme(msg.sender, msg.sender);
        return true;
    }

    function isSchemeRegistered(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bool) {
        return _isSchemeRegistered(_scheme,_avatar);
    }

    function getSchemeParameters(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bytes32) {
        return schemes[_scheme].paramsHash;
    }

    function getSchemePermissions(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bytes4) {
        return schemes[_scheme].permissions;
    }

    function getGlobalConstraintParameters(address _globalConstraint,address) external view returns(bytes32) {

        GlobalConstraintRegister memory register = globalConstraintsRegisterPre[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPre[register.index].params;
        }

        register = globalConstraintsRegisterPost[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPost[register.index].params;
        }
    }

    
    function globalConstraintsCount(address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(uint,uint)
        {
        return (globalConstraintsPre.length,globalConstraintsPost.length);
    }

    function isGlobalConstraintRegistered(address _globalConstraint,address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(bool)
        {
        return (globalConstraintsRegisterPre[_globalConstraint].isRegistered || globalConstraintsRegisterPost[_globalConstraint].isRegistered);
    }

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params,address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPre[_globalConstraint].isRegistered) {
                globalConstraintsPre.push(GlobalConstraint(_globalConstraint,_params));
                globalConstraintsRegisterPre[_globalConstraint] = GlobalConstraintRegister(true,globalConstraintsPre.length-1);
            }else {
                globalConstraintsPre[globalConstraintsRegisterPre[_globalConstraint].index].params = _params;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPost[_globalConstraint].isRegistered) {
                globalConstraintsPost.push(GlobalConstraint(_globalConstraint,_params));
                globalConstraintsRegisterPost[_globalConstraint] = GlobalConstraintRegister(true,globalConstraintsPost.length-1);
            }else {
                globalConstraintsPost[globalConstraintsRegisterPost[_globalConstraint].index].params = _params;
            }
        }
        emit AddGlobalConstraint(_globalConstraint, _params,when);
        return true;
    }

     
    function removeGlobalConstraint (address _globalConstraint,address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister;
        GlobalConstraint memory globalConstraint;
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        bool retVal = false;

        if ((when == GlobalConstraintInterface.CallPhase.Pre)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPre[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPre.length-1) {
                    globalConstraint = globalConstraintsPre[globalConstraintsPre.length-1];
                    globalConstraintsPre[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPre[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPre.length--;
                delete globalConstraintsRegisterPre[_globalConstraint];
                retVal = true;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPost[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPost.length-1) {
                    globalConstraint = globalConstraintsPost[globalConstraintsPost.length-1];
                    globalConstraintsPost[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPost[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPost.length--;
                delete globalConstraintsRegisterPost[_globalConstraint];
                retVal = true;
            }
        }
        if (retVal) {
            emit RemoveGlobalConstraint(_globalConstraint,globalConstraintRegister.index,when == GlobalConstraintInterface.CallPhase.Pre);
        }
        return retVal;
    }

   
    function upgradeController(address _newController,address _avatar)
    external
    onlyUpgradingScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        require(newController == address(0));    
        require(_newController != address(0));
        newController = _newController;
        avatar.transferOwnership(_newController);
        require(avatar.owner()==_newController);
        if (nativeToken.owner() == address(this)) {
            nativeToken.transferOwnership(_newController);
            require(nativeToken.owner()==_newController);
        }
        if (nativeReputation.owner() == address(this)) {
            nativeReputation.transferOwnership(_newController);
            require(nativeReputation.owner()==_newController);
        }
        emit UpgradeController(this,newController);
        return true;
    }

     
    function genericCall(address _contract,bytes _data,address _avatar)
    external
    onlyGenericCallScheme
    onlySubjectToConstraint("genericCall")
    isAvatarValid(_avatar)
    returns (bytes32)
    {
        emit GenericCall(_contract, _data);
        avatar.genericCall(_contract, _data);
         
        assembly {
         
        returndatacopy(0, 0, returndatasize)
        return(0, returndatasize)
        }
    }

   
    function sendEther(uint _amountInWei, address _to,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("sendEther")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit SendEther(msg.sender, _amountInWei, _to);
        return avatar.sendEther(_amountInWei, _to);
    }

     
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransfer")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenTransfer(msg.sender, _externalToken, _to, _value);
        return avatar.externalTokenTransfer(_externalToken, _to, _value);
    }

     
    function externalTokenTransferFrom(StandardToken _externalToken, address _from, address _to, uint _value,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransferFrom")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenTransferFrom(msg.sender, _externalToken, _from, _to, _value);
        return avatar.externalTokenTransferFrom(_externalToken, _from, _to, _value);
    }

     
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenIncreaseApproval")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenIncreaseApproval(msg.sender,_externalToken,_spender,_addedValue);
        return avatar.externalTokenIncreaseApproval(_externalToken, _spender, _addedValue);
    }

     
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenDecreaseApproval")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenDecreaseApproval(msg.sender,_externalToken,_spender,_subtractedValue);
        return avatar.externalTokenDecreaseApproval(_externalToken, _spender, _subtractedValue);
    }

     
    function getNativeReputation(address _avatar) external isAvatarValid(_avatar) view returns(address) {
        return address(nativeReputation);
    }

    function _isSchemeRegistered(address _scheme,address _avatar) private isAvatarValid(_avatar) view returns(bool) {
        return (schemes[_scheme].permissions&bytes4(1) != bytes4(0));
    }
}

 

contract ExecutableInterface {
    function execute(bytes32 _proposalId, address _avatar, int _param) public returns(bool);
}

 

interface IntVoteInterface {
     
     
    modifier onlyProposalOwner(bytes32 _proposalId) {revert(); _;}
    modifier votable(bytes32 _proposalId) {revert(); _;}

    event NewProposal(bytes32 indexed _proposalId, address indexed _avatar, uint _numOfChoices, address _proposer, bytes32 _paramsHash);
    event ExecuteProposal(bytes32 indexed _proposalId, address indexed _avatar, uint _decision, uint _totalReputation);
    event VoteProposal(bytes32 indexed _proposalId, address indexed _avatar, address indexed _voter, uint _vote, uint _reputation);
    event CancelProposal(bytes32 indexed _proposalId, address indexed _avatar );
    event CancelVoting(bytes32 indexed _proposalId, address indexed _avatar, address indexed _voter);

     
    function propose(
        uint _numOfChoices,
        bytes32 _proposalParameters,
        address _avatar,
        ExecutableInterface _executable,
        address _proposer
        ) external returns(bytes32);

     
    function cancelProposal(bytes32 _proposalId) external returns(bool);

     
    function ownerVote(bytes32 _proposalId, uint _vote, address _voter) external returns(bool);

    function vote(bytes32 _proposalId, uint _vote) external returns(bool);

    function voteWithSpecifiedAmounts(
        bytes32 _proposalId,
        uint _vote,
        uint _rep,
        uint _token) external returns(bool);

    function cancelVote(bytes32 _proposalId) external;

     
     
     
     
    function execute(bytes32 _proposalId) external returns(bool);

    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint);

    function isVotable(bytes32 _proposalId) external view returns(bool);

     
    function voteStatus(bytes32 _proposalId,uint _choice) external view returns(uint);

     
    function isAbstainAllow() external pure returns(bool);

     
    function getAllowedRangeOfChoices() external pure returns(uint min,uint max);
}

 

contract UniversalSchemeInterface {

    function updateParameters(bytes32 _hashedParameters) public;

    function getParametersFromController(Avatar _avatar) internal view returns(bytes32);
}

 

contract UniversalScheme is Ownable, UniversalSchemeInterface {
    bytes32 public hashedParameters;  

    function updateParameters(
        bytes32 _hashedParameters
    )
        public
        onlyOwner
    {
        hashedParameters = _hashedParameters;
    }

     
    function getParametersFromController(Avatar _avatar) internal view returns(bytes32) {
        return ControllerInterface(_avatar.owner()).getSchemeParameters(this,address(_avatar));
    }
}

 

 


library RealMath {

     
    int256 constant REAL_BITS = 256;

     
    int256 constant REAL_FBITS = 40;

     
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;

     
    int256 constant REAL_ONE = int256(1) << REAL_FBITS;

     
    int256 constant REAL_HALF = REAL_ONE >> 1;

     
    int256 constant REAL_TWO = REAL_ONE << 1;

     
    int256 constant REAL_LN_TWO = 762123384786;

     
    int256 constant REAL_PI = 3454217652358;

     
    int256 constant REAL_HALF_PI = 1727108826179;

     
    int256 constant REAL_TWO_PI = 6908435304715;

     
    int256 constant SIGN_MASK = int256(1) << 255;


     
    function toReal(int216 ipart) internal pure returns (int256) {
        return int256(ipart) * REAL_ONE;
    }

     
    function fromReal(int256 realValue) internal pure returns (int216) {
        return int216(realValue / REAL_ONE);
    }

     
    function round(int256 realValue) internal pure returns (int256) {
         
        int216 ipart = fromReal(realValue);
        if ((fractionalBits(realValue) & (uint40(1) << (REAL_FBITS - 1))) > 0) {
             
            if (realValue < int256(0)) {
                 
                ipart -= 1;
            } else {
                ipart += 1;
            }
        }
        return toReal(ipart);
    }

     
    function abs(int256 realValue) internal pure returns (int256) {
        if (realValue > 0) {
            return realValue;
        } else {
            return -realValue;
        }
    }

     
    function fractionalBits(int256 realValue) internal pure returns (uint40) {
        return uint40(abs(realValue) % REAL_ONE);
    }

     
    function fpart(int256 realValue) internal pure returns (int256) {
         
        return abs(realValue) % REAL_ONE;
    }

     
    function fpartSigned(int256 realValue) internal pure returns (int256) {
         
        int256 fractional = fpart(realValue);
        if (realValue < 0) {
             
            return -fractional;
        } else {
            return fractional;
        }
    }

     
    function ipart(int256 realValue) internal pure returns (int256) {
         
        return realValue - fpartSigned(realValue);
    }

     
    function mul(int256 realA, int256 realB) internal pure returns (int256) {
         
         
        return int256((int256(realA) * int256(realB)) >> REAL_FBITS);
    }

     
    function div(int256 realNumerator, int256 realDenominator) internal pure returns (int256) {
         
         
        return int256((int256(realNumerator) * REAL_ONE) / int256(realDenominator));
    }

     
    function fraction(int216 numerator, int216 denominator) internal pure returns (int256) {
        return div(toReal(numerator), toReal(denominator));
    }

     
     
     

     
    function ipow(int256 realBase, int216 exponent) internal pure returns (int256) {
        if (exponent < 0) {
             
            revert();
        }

        int256 tempRealBase = realBase;
        int256 tempExponent = exponent;

         
        int256 realResult = REAL_ONE;
        while (tempExponent != 0) {
             
            if ((tempExponent & 0x1) == 0x1) {
                 
                realResult = mul(realResult, tempRealBase);
            }
             
            tempExponent = tempExponent >> 1;
             
            tempRealBase = mul(tempRealBase, tempRealBase);
        }

         
        return realResult;
    }

     
    function hibit(uint256 _val) internal pure returns (uint256) {
         
        uint256 val = _val;
        val |= (val >> 1);
        val |= (val >> 2);
        val |= (val >> 4);
        val |= (val >> 8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }

     
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
         
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
             
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
             
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
             
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
             
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
             
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
             
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
             
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
             
            index |= 128;
        }
    }

     
    function rescale(int256 realArg) internal pure returns (int256 realScaled, int216 shift) {
        if (realArg <= 0) {
             
            revert();
        }

         
        int216 highBit = findbit(hibit(uint256(realArg)));

         
        shift = highBit - int216(REAL_FBITS);

        if (shift < 0) {
             
            realScaled = realArg << -shift;
        } else if (shift >= 0) {
             
            realScaled = realArg >> shift;
        }
    }

     
    function lnLimited(int256 realArg, int maxIterations) internal pure returns (int256) {
        if (realArg <= 0) {
             
            revert();
        }

        if (realArg == REAL_ONE) {
             
             
            return 0;
        }

         
        int256 realRescaled;
        int216 shift;
        (realRescaled, shift) = rescale(realArg);

         
        int256 realSeriesArg = div(realRescaled - REAL_ONE, realRescaled + REAL_ONE);

         
        int256 realSeriesResult = 0;

        for (int216 n = 0; n < maxIterations; n++) {
             
            int256 realTerm = div(ipow(realSeriesArg, 2 * n + 1), toReal(2 * n + 1));
             
            realSeriesResult += realTerm;
            if (realTerm == 0) {
                 
                break;
            }
             
        }

         
        realSeriesResult = mul(realSeriesResult, REAL_TWO);

         
        return mul(toReal(shift), REAL_LN_TWO) + realSeriesResult;

    }

     
    function ln(int256 realArg) internal pure returns (int256) {
        return lnLimited(realArg, 100);
    }

     
    function expLimited(int256 realArg, int maxIterations) internal pure returns (int256) {
         
        int256 realResult = 0;

         
        int256 realTerm = REAL_ONE;

        for (int216 n = 0; n < maxIterations; n++) {
             
            realResult += realTerm;

             
            realTerm = mul(realTerm, div(realArg, toReal(n + 1)));

            if (realTerm == 0) {
                 
                break;
            }
             
        }

         
        return realResult;

    }

     
    function exp(int256 realArg) internal pure returns (int256) {
        return expLimited(realArg, 100);
    }

     
    function pow(int256 realBase, int256 realExponent) internal pure returns (int256) {
        if (realExponent == 0) {
             
            return REAL_ONE;
        }

        if (realBase == 0) {
            if (realExponent < 0) {
                 
                revert();
            }
             
            return 0;
        }

        if (fpart(realExponent) == 0) {
             

            if (realExponent > 0) {
                 
                return ipow(realBase, fromReal(realExponent));
            } else {
                 
                return div(REAL_ONE, ipow(realBase, fromReal(-realExponent)));
            }
        }

        if (realBase < 0) {
             
             
             
            revert();
        }

         
        return exp(mul(realExponent, ln(realBase)));
    }

     
    function sqrt(int256 realArg) internal pure returns (int256) {
        return pow(realArg, REAL_HALF);
    }

     
    function sinLimited(int256 _realArg, int216 maxIterations) internal pure returns (int256) {
         
         
         
        int256 realArg = _realArg;
        realArg = realArg % REAL_TWO_PI;

        int256 accumulator = REAL_ONE;

         
        for (int216 iteration = maxIterations - 1; iteration >= 0; iteration--) {
            accumulator = REAL_ONE - mul(div(mul(realArg, realArg), toReal((2 * iteration + 2) * (2 * iteration + 3))), accumulator);
             
        }

        return mul(realArg, accumulator);
    }

     
    function sin(int256 realArg) internal pure returns (int256) {
        return sinLimited(realArg, 15);
    }

     
    function cos(int256 realArg) internal pure returns (int256) {
        return sin(realArg + REAL_HALF_PI);
    }

     
    function tan(int256 realArg) internal pure returns (int256) {
        return div(sin(realArg), cos(realArg));
    }
}

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
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

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 

library OrderStatisticTree {

    struct Node {
        mapping (bool => uint) children;  
        uint parent;  
        bool side;    
        uint height;  
        uint count;  
        uint dupes;  
    }

    struct Tree {
         
         
         
         
        mapping(uint => Node) nodes;
    }
     
    function rank(Tree storage _tree,uint _value) internal view returns (uint smaller) {
        if (_value != 0) {
            smaller = _tree.nodes[0].dupes;

            uint cur = _tree.nodes[0].children[true];
            Node storage currentNode = _tree.nodes[cur];

            while (true) {
                if (cur <= _value) {
                    if (cur<_value) {
                        smaller = smaller + 1+currentNode.dupes;
                    }
                    uint leftChild = currentNode.children[false];
                    if (leftChild!=0) {
                        smaller = smaller + _tree.nodes[leftChild].count;
                    }
                }
                if (cur == _value) {
                    break;
                }
                cur = currentNode.children[cur<_value];
                if (cur == 0) {
                    break;
                }
                currentNode = _tree.nodes[cur];
            }
        }
    }

    function count(Tree storage _tree) internal view returns (uint) {
        Node storage root = _tree.nodes[0];
        Node memory child = _tree.nodes[root.children[true]];
        return root.dupes+child.count;
    }

    function updateCount(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        n.count = 1+_tree.nodes[n.children[false]].count+_tree.nodes[n.children[true]].count+n.dupes;
    }

    function updateCounts(Tree storage _tree,uint _value) private {
        uint parent = _tree.nodes[_value].parent;
        while (parent!=0) {
            updateCount(_tree,parent);
            parent = _tree.nodes[parent].parent;
        }
    }

    function updateHeight(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        uint heightLeft = _tree.nodes[n.children[false]].height;
        uint heightRight = _tree.nodes[n.children[true]].height;
        if (heightLeft > heightRight)
            n.height = heightLeft+1;
        else
            n.height = heightRight+1;
    }

    function balanceFactor(Tree storage _tree,uint _value) private view returns (int bf) {
        Node storage n = _tree.nodes[_value];
        return int(_tree.nodes[n.children[false]].height)-int(_tree.nodes[n.children[true]].height);
    }

    function rotate(Tree storage _tree,uint _value,bool dir) private {
        bool otherDir = !dir;
        Node storage n = _tree.nodes[_value];
        bool side = n.side;
        uint parent = n.parent;
        uint valueNew = n.children[otherDir];
        Node storage nNew = _tree.nodes[valueNew];
        uint orphan = nNew.children[dir];
        Node storage p = _tree.nodes[parent];
        Node storage o = _tree.nodes[orphan];
        p.children[side] = valueNew;
        nNew.side = side;
        nNew.parent = parent;
        nNew.children[dir] = _value;
        n.parent = valueNew;
        n.side = dir;
        n.children[otherDir] = orphan;
        o.parent = _value;
        o.side = otherDir;
        updateHeight(_tree,_value);
        updateHeight(_tree,valueNew);
        updateCount(_tree,_value);
        updateCount(_tree,valueNew);
    }

    function rebalanceInsert(Tree storage _tree,uint _nValue) private {
        updateHeight(_tree,_nValue);
        Node storage n = _tree.nodes[_nValue];
        uint pValue = n.parent;
        if (pValue!=0) {
            int pBf = balanceFactor(_tree,pValue);
            bool side = n.side;
            int sign;
            if (side)
                sign = -1;
            else
                sign = 1;
            if (pBf == sign*2) {
                if (balanceFactor(_tree,_nValue) == (-1 * sign)) {
                    rotate(_tree,_nValue,side);
                }
                rotate(_tree,pValue,!side);
            } else if (pBf != 0) {
                rebalanceInsert(_tree,pValue);
            }
        }
    }

    function rebalanceDelete(Tree storage _tree,uint _pValue,bool side) private {
        if (_pValue!=0) {
            updateHeight(_tree,_pValue);
            int pBf = balanceFactor(_tree,_pValue);
            int sign;
            if (side)
                sign = 1;
            else
                sign = -1;
            int bf = balanceFactor(_tree,_pValue);
            if (bf==(2*sign)) {
                Node storage p = _tree.nodes[_pValue];
                uint sValue = p.children[!side];
                int sBf = balanceFactor(_tree,sValue);
                if (sBf == (-1 * sign)) {
                    rotate(_tree,sValue,!side);
                }
                rotate(_tree,_pValue,side);
                if (sBf!=0) {
                    p = _tree.nodes[_pValue];
                    rebalanceDelete(_tree,p.parent,p.side);
                }
            } else if (pBf != sign) {
                p = _tree.nodes[_pValue];
                rebalanceDelete(_tree,p.parent,p.side);
            }
        }
    }

    function fixParents(Tree storage _tree,uint parent,bool side) private {
        if (parent!=0) {
            updateCount(_tree,parent);
            updateCounts(_tree,parent);
            rebalanceDelete(_tree,parent,side);
        }
    }

    function insertHelper(Tree storage _tree,uint _pValue,bool _side,uint _value) private {
        Node storage root = _tree.nodes[_pValue];
        uint cValue = root.children[_side];
        if (cValue==0) {
            root.children[_side] = _value;
            Node storage child = _tree.nodes[_value];
            child.parent = _pValue;
            child.side = _side;
            child.height = 1;
            child.count = 1;
            updateCounts(_tree,_value);
            rebalanceInsert(_tree,_value);
        } else if (cValue==_value) {
            _tree.nodes[cValue].dupes++;
            updateCount(_tree,_value);
            updateCounts(_tree,_value);
        } else {
            insertHelper(_tree,cValue,(_value >= cValue),_value);
        }
    }

    function insert(Tree storage _tree,uint _value) internal {
        if (_value==0) {
            _tree.nodes[_value].dupes++;
        } else {
            insertHelper(_tree,0,true,_value);
        }
    }

    function rightmostLeaf(Tree storage _tree,uint _value) private view returns (uint leaf) {
        uint child = _tree.nodes[_value].children[true];
        if (child!=0) {
            return rightmostLeaf(_tree,child);
        } else {
            return _value;
        }
    }

    function zeroOut(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        n.parent = 0;
        n.side = false;
        n.children[false] = 0;
        n.children[true] = 0;
        n.count = 0;
        n.height = 0;
        n.dupes = 0;
    }

    function removeBranch(Tree storage _tree,uint _value,uint _left) private {
        uint ipn = rightmostLeaf(_tree,_left);
        Node storage i = _tree.nodes[ipn];
        uint dupes = i.dupes;
        removeHelper(_tree,ipn);
        Node storage n = _tree.nodes[_value];
        uint parent = n.parent;
        Node storage p = _tree.nodes[parent];
        uint height = n.height;
        bool side = n.side;
        uint ncount = n.count;
        uint right = n.children[true];
        uint left = n.children[false];
        p.children[side] = ipn;
        i.parent = parent;
        i.side = side;
        i.count = ncount+dupes-n.dupes;
        i.height = height;
        i.dupes = dupes;
        if (left!=0) {
            i.children[false] = left;
            _tree.nodes[left].parent = ipn;
        }
        if (right!=0) {
            i.children[true] = right;
            _tree.nodes[right].parent = ipn;
        }
        zeroOut(_tree,_value);
        updateCounts(_tree,ipn);
    }

    function removeHelper(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        uint parent = n.parent;
        bool side = n.side;
        Node storage p = _tree.nodes[parent];
        uint left = n.children[false];
        uint right = n.children[true];
        if ((left == 0) && (right == 0)) {
            p.children[side] = 0;
            zeroOut(_tree,_value);
            fixParents(_tree,parent,side);
        } else if ((left != 0) && (right != 0)) {
            removeBranch(_tree,_value,left);
        } else {
            uint child = left+right;
            Node storage c = _tree.nodes[child];
            p.children[side] = child;
            c.parent = parent;
            c.side = side;
            zeroOut(_tree,_value);
            fixParents(_tree,parent,side);
        }
    }

    function remove(Tree storage _tree,uint _value) internal {
        Node storage n = _tree.nodes[_value];
        if (_value==0) {
            if (n.dupes==0) {
                return;
            }
        } else {
            if (n.count==0) {
                return;
            }
        }
        if (n.dupes>0) {
            n.dupes--;
            if (_value!=0) {
                n.count--;
            }
            fixParents(_tree,n.parent,n.side);
        } else {
            removeHelper(_tree,_value);
        }
    }

}

 

 


contract GenesisProtocol is IntVoteInterface,UniversalScheme {
    using SafeMath for uint;
    using RealMath for int216;
    using RealMath for int256;
    using ECRecovery for bytes32;
    using OrderStatisticTree for OrderStatisticTree.Tree;

    enum ProposalState { None ,Closed, Executed, PreBoosted,Boosted,QuietEndingPeriod }
    enum ExecutionState { None, PreBoostedTimeOut, PreBoostedBarCrossed, BoostedTimeOut,BoostedBarCrossed }

     
    struct Parameters {
        uint preBoostedVoteRequiredPercentage;  
        uint preBoostedVotePeriodLimit;  
        uint boostedVotePeriodLimit;  
        uint thresholdConstA; 
        uint thresholdConstB; 
        uint minimumStakingFee;  
        uint quietEndingPeriod;  
        uint proposingRepRewardConstA; 
        uint proposingRepRewardConstB; 
        uint stakerFeeRatioForVoters;  
                                       
                                       
        uint votersReputationLossRatio; 
        uint votersGainRepRatioFromLostRep;  
                                             
                                             
                                             
        uint daoBountyConst; 
                             
                             
                             
        uint daoBountyLimit; 



    }
    struct Voter {
        uint vote;  
        uint reputation;  
        bool preBoosted;
    }

    struct Staker {
        uint vote;  
        uint amount;  
        uint amountForBounty;  
    }

    struct Proposal {
        address avatar;  
        uint numOfChoices;
        ExecutableInterface executable;  
        uint votersStakes;
        uint submittedTime;
        uint boostedPhaseTime;  
        ProposalState state;
        uint winningVote;  
        address proposer;
        uint currentBoostedVotePeriodLimit;
        bytes32 paramsHash;
        uint daoBountyRemain;
        uint[2] totalStakes; 
                             
         
        mapping(uint    =>  uint     ) votes;
         
        mapping(uint    =>  uint     ) preBoostedVotes;
         
        mapping(address =>  Voter    ) voters;
         
        mapping(uint    =>  uint     ) stakes;
         
        mapping(address  => Staker   ) stakers;
    }

    event GPExecuteProposal(bytes32 indexed _proposalId, ExecutionState _executionState);
    event Stake(bytes32 indexed _proposalId, address indexed _avatar, address indexed _staker,uint _vote,uint _amount);
    event Redeem(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);
    event RedeemDaoBounty(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);
    event RedeemReputation(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);

    mapping(bytes32=>Parameters) public parameters;   
    mapping(bytes32=>Proposal) public proposals;  

    mapping(bytes=>bool) stakeSignatures;  

    uint constant public NUM_OF_CHOICES = 2;
    uint constant public NO = 2;
    uint constant public YES = 1;
    uint public proposalsCnt;  
    mapping(address=>uint) orgBoostedProposalsCnt;
    StandardToken public stakingToken;
    mapping(address=>OrderStatisticTree.Tree) proposalsExpiredTimes;  

     
    constructor(StandardToken _stakingToken) public
    {
        stakingToken = _stakingToken;
    }

   
    modifier votable(bytes32 _proposalId) {
        require(_isVotable(_proposalId));
        _;
    }

     
    function propose(uint _numOfChoices, bytes32 , address _avatar, ExecutableInterface _executable,address _proposer)
        external
        returns(bytes32)
    {
           
        require(_numOfChoices == NUM_OF_CHOICES);
        require(ExecutableInterface(_executable) != address(0));
         
        bytes32 paramsHash = getParametersFromController(Avatar(_avatar));

        require(parameters[paramsHash].preBoostedVoteRequiredPercentage > 0);
         
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt++;
         
        Proposal memory proposal;
        proposal.numOfChoices = _numOfChoices;
        proposal.avatar = _avatar;
        proposal.executable = _executable;
        proposal.state = ProposalState.PreBoosted;
         
        proposal.submittedTime = now;
        proposal.currentBoostedVotePeriodLimit = parameters[paramsHash].boostedVotePeriodLimit;
        proposal.proposer = _proposer;
        proposal.winningVote = NO;
        proposal.paramsHash = paramsHash;
        proposals[proposalId] = proposal;
        emit NewProposal(proposalId, _avatar, _numOfChoices, _proposer, paramsHash);
        return proposalId;
    }

   
    function cancelProposal(bytes32 ) external returns(bool) {
         
        return false;
    }

     
    function stake(bytes32 _proposalId, uint _vote, uint _amount) external returns(bool) {
        return _stake(_proposalId,_vote,_amount,msg.sender);
    }

     
     
    bytes32 public constant DELEGATION_HASH_EIP712 =
    keccak256(abi.encodePacked("address GenesisProtocolAddress","bytes32 ProposalId", "uint Vote","uint AmountToStake","uint Nonce"));
     
    string public constant ETH_SIGN_PREFIX= "\x19Ethereum Signed Message:\n32";

     
    function stakeWithSignature(
        bytes32 _proposalId,
        uint _vote,
        uint _amount,
        uint _nonce,
        uint _signatureType,
        bytes _signature
        )
        external
        returns(bool)
        {
        require(stakeSignatures[_signature] == false);
         
        bytes32 delegationDigest;
        if (_signatureType == 2) {
            delegationDigest = keccak256(
                abi.encodePacked(
                    DELEGATION_HASH_EIP712, keccak256(
                        abi.encodePacked(
                           address(this),
                          _proposalId,
                          _vote,
                          _amount,
                          _nonce)))
            );
        } else {
            delegationDigest = keccak256(
                abi.encodePacked(
                    ETH_SIGN_PREFIX, keccak256(
                        abi.encodePacked(
                            address(this),
                           _proposalId,
                           _vote,
                           _amount,
                           _nonce)))
            );
        }
        address staker = delegationDigest.recover(_signature);
         
        require(staker!=address(0));
        stakeSignatures[_signature] = true;
        return _stake(_proposalId,_vote,_amount,staker);
    }

   
    function vote(bytes32 _proposalId, uint _vote) external votable(_proposalId) returns(bool) {
        return internalVote(_proposalId, msg.sender, _vote, 0);
    }

   
    function ownerVote(bytes32 , uint , address ) external returns(bool) {
       
        return false;
    }

    function voteWithSpecifiedAmounts(bytes32 _proposalId,uint _vote,uint _rep,uint) external votable(_proposalId) returns(bool) {
        return internalVote(_proposalId,msg.sender,_vote,_rep);
    }

   
    function cancelVote(bytes32 _proposalId) external votable(_proposalId) {
        
        return;
    }

   
    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint) {
        return proposals[_proposalId].numOfChoices;
    }

     
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

     
    function voteStatus(bytes32 _proposalId,uint _choice) external view returns(uint) {
        return proposals[_proposalId].votes[_choice];
    }

     
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return _isVotable(_proposalId);
    }

     
    function proposalStatus(bytes32 _proposalId) external view returns(uint, uint, uint ,uint, uint ,uint) {
        return (
                proposals[_proposalId].preBoostedVotes[YES],
                proposals[_proposalId].preBoostedVotes[NO],
                proposals[_proposalId].totalStakes[0],
                proposals[_proposalId].totalStakes[1],
                proposals[_proposalId].stakes[YES],
                proposals[_proposalId].stakes[NO]
        );
    }

   
    function proposalAvatar(bytes32 _proposalId) external view returns(address) {
        return (proposals[_proposalId].avatar);
    }

   
    function scoreThresholdParams(address _avatar) external view returns(uint,uint) {
        bytes32 paramsHash = getParametersFromController(Avatar(_avatar));
        Parameters memory params = parameters[paramsHash];
        return (params.thresholdConstA,params.thresholdConstB);
    }

     
    function getStaker(bytes32 _proposalId,address _staker) external view returns(uint,uint) {
        return (proposals[_proposalId].stakers[_staker].vote,proposals[_proposalId].stakers[_staker].amount);
    }

     
    function state(bytes32 _proposalId) external view returns(ProposalState) {
        return proposals[_proposalId].state;
    }

     
    function winningVote(bytes32 _proposalId) external view returns(uint) {
        return proposals[_proposalId].winningVote;
    }

    
    function isAbstainAllow() external pure returns(bool) {
        return false;
    }

     
    function getAllowedRangeOfChoices() external pure returns(uint min,uint max) {
        return (NUM_OF_CHOICES,NUM_OF_CHOICES);
    }

     
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

     
    function redeem(bytes32 _proposalId,address _beneficiary) public returns (uint[5] rewards) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed) || (proposal.state == ProposalState.Closed),"wrong proposal state");
        Parameters memory params = parameters[proposal.paramsHash];
        uint amount;
        uint reputation;
        uint lostReputation;
        if (proposal.winningVote == YES) {
            lostReputation = proposal.preBoostedVotes[NO];
        } else {
            lostReputation = proposal.preBoostedVotes[YES];
        }
        lostReputation = (lostReputation * params.votersReputationLossRatio)/100;
         
        Staker storage staker = proposal.stakers[_beneficiary];
        if ((staker.amount>0) &&
             (staker.vote == proposal.winningVote)) {
            uint totalWinningStakes = proposal.stakes[proposal.winningVote];
            if (totalWinningStakes != 0) {
                rewards[0] = (staker.amount * proposal.totalStakes[0]) / totalWinningStakes;
            }
            if (proposal.state != ProposalState.Closed) {
                rewards[1] = (staker.amount * ( lostReputation - ((lostReputation * params.votersGainRepRatioFromLostRep)/100)))/proposal.stakes[proposal.winningVote];
            }
            staker.amount = 0;
        }
         
        Voter storage voter = proposal.voters[_beneficiary];
        if ((voter.reputation != 0 ) && (voter.preBoosted)) {
            uint preBoostedVotes = proposal.preBoostedVotes[YES] + proposal.preBoostedVotes[NO];
            if (preBoostedVotes>0) {
                rewards[2] = ((proposal.votersStakes * voter.reputation) / preBoostedVotes);
            }
            if (proposal.state == ProposalState.Closed) {
               
                rewards[3] = ((voter.reputation * params.votersReputationLossRatio)/100);
            } else if (proposal.winningVote == voter.vote ) {
                rewards[3] = (((voter.reputation * params.votersReputationLossRatio)/100) +
                (((voter.reputation * lostReputation * params.votersGainRepRatioFromLostRep)/100)/preBoostedVotes));
            }
            voter.reputation = 0;
        }
         
        if ((proposal.proposer == _beneficiary)&&(proposal.winningVote == YES)&&(proposal.proposer != address(0))) {
            rewards[4] = (params.proposingRepRewardConstA.mul(proposal.votes[YES]+proposal.votes[NO]) + params.proposingRepRewardConstB.mul(proposal.votes[YES]-proposal.votes[NO]))/1000;
            proposal.proposer = 0;
        }
        amount = rewards[0] + rewards[2];
        reputation = rewards[1] + rewards[3] + rewards[4];
        if (amount != 0) {
            proposal.totalStakes[1] = proposal.totalStakes[1].sub(amount);
            require(stakingToken.transfer(_beneficiary, amount));
            emit Redeem(_proposalId,proposal.avatar,_beneficiary,amount);
        }
        if (reputation != 0 ) {
            ControllerInterface(Avatar(proposal.avatar).owner()).mintReputation(reputation,_beneficiary,proposal.avatar);
            emit RedeemReputation(_proposalId,proposal.avatar,_beneficiary,reputation);
        }
    }

     
    function redeemDaoBounty(bytes32 _proposalId,address _beneficiary) public returns(uint redeemedAmount,uint potentialAmount) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed) || (proposal.state == ProposalState.Closed));
        uint totalWinningStakes = proposal.stakes[proposal.winningVote];
        if (
           
            (proposal.stakers[_beneficiary].amountForBounty>0)&&
            (proposal.stakers[_beneficiary].vote == proposal.winningVote)&&
            (proposal.winningVote == YES)&&
            (totalWinningStakes != 0))
        {
             
            Parameters memory params = parameters[proposal.paramsHash];
            uint beneficiaryLimit = (proposal.stakers[_beneficiary].amountForBounty.mul(params.daoBountyLimit)) / totalWinningStakes;
            potentialAmount = (params.daoBountyConst.mul(proposal.stakers[_beneficiary].amountForBounty))/100;
            if (potentialAmount > beneficiaryLimit) {
                potentialAmount = beneficiaryLimit;
            }
        }
        if ((potentialAmount != 0)&&(stakingToken.balanceOf(proposal.avatar) >= potentialAmount)) {
            proposal.daoBountyRemain = proposal.daoBountyRemain.sub(potentialAmount);
            require(ControllerInterface(Avatar(proposal.avatar).owner()).externalTokenTransfer(stakingToken,_beneficiary,potentialAmount,proposal.avatar));
            proposal.stakers[_beneficiary].amountForBounty = 0;
            redeemedAmount = potentialAmount;
            emit RedeemDaoBounty(_proposalId,proposal.avatar,_beneficiary,redeemedAmount);
        }
    }

     
    function shouldBoost(bytes32 _proposalId) public view returns(bool) {
        Proposal memory proposal = proposals[_proposalId];
        return (_score(_proposalId) >= threshold(proposal.paramsHash,proposal.avatar));
    }

     
    function score(bytes32 _proposalId) public view returns(int) {
        return _score(_proposalId);
    }

     
    function getBoostedProposalsCount(address _avatar) public view returns(uint) {
        uint expiredProposals;
        if (proposalsExpiredTimes[_avatar].count() != 0) {
           
            expiredProposals = proposalsExpiredTimes[_avatar].rank(now);
        }
        return orgBoostedProposalsCnt[_avatar].sub(expiredProposals);
    }

     
    function threshold(bytes32 _paramsHash,address _avatar) public view returns(int) {
        uint boostedProposals = getBoostedProposalsCount(_avatar);
        int216 e = 2;

        Parameters memory params = parameters[_paramsHash];
        require(params.thresholdConstB > 0,"should be a valid parameter hash");
        int256 power = int216(boostedProposals).toReal().div(int216(params.thresholdConstB).toReal());

        if (power.fromReal() > 100 ) {
            power = int216(100).toReal();
        }
        int256 res = int216(params.thresholdConstA).toReal().mul(e.toReal().pow(power));
        return res.fromReal();
    }

     
    function setParameters(
        uint[14] _params  
    )
    public
    returns(bytes32)
    {
        require(_params[0] <= 100 && _params[0] > 0,"0 < preBoostedVoteRequiredPercentage <= 100");
        require(_params[4] > 0 && _params[4] <= 100000000,"0 < thresholdConstB < 100000000 ");
        require(_params[3] <= 100000000 ether,"thresholdConstA <= 100000000 wei");
        require(_params[9] <= 100,"stakerFeeRatioForVoters <= 100");
        require(_params[10] <= 100,"votersReputationLossRatio <= 100");
        require(_params[11] <= 100,"votersGainRepRatioFromLostRep <= 100");
        require(_params[2] >= _params[6],"boostedVotePeriodLimit >= quietEndingPeriod");
        require(_params[7] <= 100000000,"proposingRepRewardConstA <= 100000000");
        require(_params[8] <= 100000000,"proposingRepRewardConstB <= 100000000");
        require(_params[12] <= (2 * _params[9]),"daoBountyConst <= 2 * stakerFeeRatioForVoters");
        require(_params[12] >= _params[9],"daoBountyConst >= stakerFeeRatioForVoters");


        bytes32 paramsHash = getParametersHash(_params);
        parameters[paramsHash] = Parameters({
            preBoostedVoteRequiredPercentage: _params[0],
            preBoostedVotePeriodLimit: _params[1],
            boostedVotePeriodLimit: _params[2],
            thresholdConstA:_params[3],
            thresholdConstB:_params[4],
            minimumStakingFee: _params[5],
            quietEndingPeriod: _params[6],
            proposingRepRewardConstA: _params[7],
            proposingRepRewardConstB:_params[8],
            stakerFeeRatioForVoters:_params[9],
            votersReputationLossRatio:_params[10],
            votersGainRepRatioFromLostRep:_params[11],
            daoBountyConst:_params[12],
            daoBountyLimit:_params[13]
        });
        return paramsHash;
    }

   
    function getParametersHash(
        uint[14] _params)  
        public
        pure
        returns(bytes32)
        {
        return keccak256(
            abi.encodePacked(
            _params[0],
            _params[1],
            _params[2],
            _params[3],
            _params[4],
            _params[5],
            _params[6],
            _params[7],
            _params[8],
            _params[9],
            _params[10],
            _params[11],
            _params[12],
            _params[13]));
    }

     
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        Proposal memory tmpProposal = proposal;
        uint totalReputation = Avatar(proposal.avatar).nativeReputation().totalSupply();
        uint executionBar = totalReputation * params.preBoostedVoteRequiredPercentage/100;
        ExecutionState executionState = ExecutionState.None;

        if (proposal.state == ProposalState.PreBoosted) {
             
            if ((now - proposal.submittedTime) >= params.preBoostedVotePeriodLimit) {
                proposal.state = ProposalState.Closed;
                proposal.winningVote = NO;
                executionState = ExecutionState.PreBoostedTimeOut;
             } else if (proposal.votes[proposal.winningVote] > executionBar) {
               
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.PreBoostedBarCrossed;
               } else if ( shouldBoost(_proposalId)) {
                 
                proposal.state = ProposalState.Boosted;
                 
                proposal.boostedPhaseTime = now;
                proposalsExpiredTimes[proposal.avatar].insert(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                orgBoostedProposalsCnt[proposal.avatar]++;
              }
           }

        if ((proposal.state == ProposalState.Boosted) ||
            (proposal.state == ProposalState.QuietEndingPeriod)) {
             
            if ((now - proposal.boostedPhaseTime) >= proposal.currentBoostedVotePeriodLimit) {
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                orgBoostedProposalsCnt[tmpProposal.avatar] = orgBoostedProposalsCnt[tmpProposal.avatar].sub(1);
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedTimeOut;
             } else if (proposal.votes[proposal.winningVote] > executionBar) {
                
                orgBoostedProposalsCnt[tmpProposal.avatar] = orgBoostedProposalsCnt[tmpProposal.avatar].sub(1);
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedBarCrossed;
            }
       }
        if (executionState != ExecutionState.None) {
            if (proposal.winningVote == YES) {
                uint daoBountyRemain = (params.daoBountyConst.mul(proposal.stakes[proposal.winningVote]))/100;
                if (daoBountyRemain > params.daoBountyLimit) {
                    daoBountyRemain = params.daoBountyLimit;
                }
                proposal.daoBountyRemain = daoBountyRemain;
            }
            emit ExecuteProposal(_proposalId, proposal.avatar, proposal.winningVote, totalReputation);
            emit GPExecuteProposal(_proposalId, executionState);
            (tmpProposal.executable).execute(_proposalId, tmpProposal.avatar, int(proposal.winningVote));
        }
        return (executionState != ExecutionState.None);
    }

     
    function _stake(bytes32 _proposalId, uint _vote, uint _amount,address _staker) internal returns(bool) {
         

        require(_vote <= NUM_OF_CHOICES && _vote > 0);
        require(_amount > 0);
        if (_execute(_proposalId)) {
            return true;
        }

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.PreBoosted) {
            return false;
        }

         
        Staker storage staker = proposal.stakers[_staker];
        if ((staker.amount > 0) && (staker.vote != _vote)) {
            return false;
        }

        uint amount = _amount;
        Parameters memory params = parameters[proposal.paramsHash];
        require(amount >= params.minimumStakingFee);
        require(stakingToken.transferFrom(_staker, address(this), amount));
        proposal.totalStakes[1] = proposal.totalStakes[1].add(amount);  
        staker.amount += amount;
        staker.amountForBounty = staker.amount;
        staker.vote = _vote;

        proposal.votersStakes += (params.stakerFeeRatioForVoters * amount)/100;
        proposal.stakes[_vote] = amount.add(proposal.stakes[_vote]);
        amount = amount - ((params.stakerFeeRatioForVoters*amount)/100);

        proposal.totalStakes[0] = amount.add(proposal.totalStakes[0]);
       
        emit Stake(_proposalId, proposal.avatar, _staker, _vote, _amount);
       
        return _execute(_proposalId);
    }

     
    function internalVote(bytes32 _proposalId, address _voter, uint _vote, uint _rep) internal returns(bool) {
         
        require(_vote <= NUM_OF_CHOICES && _vote > 0,"0 < _vote <= 2");
        if (_execute(_proposalId)) {
            return true;
        }

        Parameters memory params = parameters[proposals[_proposalId].paramsHash];
        Proposal storage proposal = proposals[_proposalId];

         
        uint reputation = Avatar(proposal.avatar).nativeReputation().reputationOf(_voter);
        require(reputation >= _rep);
        uint rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
         
        if (proposal.voters[_voter].reputation != 0) {
            return false;
        }
         
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
         
         
        if ((proposal.votes[_vote] > proposal.votes[proposal.winningVote]) ||
           ((proposal.votes[NO] == proposal.votes[proposal.winningVote]) &&
             proposal.winningVote == YES))
        {
            
            uint _now = now;
            if ((proposal.state == ProposalState.QuietEndingPeriod) ||
               ((proposal.state == ProposalState.Boosted) && ((_now - proposal.boostedPhaseTime) >= (params.boostedVotePeriodLimit - params.quietEndingPeriod)))) {
                 
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                if (proposal.state != ProposalState.QuietEndingPeriod) {
                    proposal.currentBoostedVotePeriodLimit = params.quietEndingPeriod;
                    proposal.state = ProposalState.QuietEndingPeriod;
                }
                proposal.boostedPhaseTime = _now;
                proposalsExpiredTimes[proposal.avatar].insert(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
            }
            proposal.winningVote = _vote;
        }
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote,
            preBoosted:(proposal.state == ProposalState.PreBoosted)
        });
        if (proposal.state == ProposalState.PreBoosted) {
            proposal.preBoostedVotes[_vote] = rep.add(proposal.preBoostedVotes[_vote]);
            uint reputationDeposit = (params.votersReputationLossRatio * rep)/100;
            ControllerInterface(Avatar(proposal.avatar).owner()).burnReputation(reputationDeposit,_voter,proposal.avatar);
        }
         
        emit VoteProposal(_proposalId, proposal.avatar, _voter, _vote, rep);
         
        return _execute(_proposalId);
    }

     
    function _score(bytes32 _proposalId) private view returns(int) {
        Proposal storage proposal = proposals[_proposalId];
        return int(proposal.stakes[YES]) - int(proposal.stakes[NO]);
    }

     
    function _isVotable(bytes32 _proposalId) private view returns(bool) {
        ProposalState pState = proposals[_proposalId].state;
        return ((pState == ProposalState.PreBoosted)||(pState == ProposalState.Boosted)||(pState == ProposalState.QuietEndingPeriod));
    }
}