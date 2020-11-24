 

pragma solidity ^0.5.8;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC223ReceiverMixin {
  function tokenFallback(address _from, uint256 _value, bytes memory _data) public;
}

 
 
contract ERC223Mixin is StandardToken {
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) 
  {
    bytes memory empty;
    return transferFrom(
      _from, 
      _to,
      _value,
      empty);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) public returns (bool)
  {
    require(_value <= allowed[_from][msg.sender], "Reached allowed value");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (isContract(_to)) {
      return transferToContract(
        _from, 
        _to, 
        _value, 
        _data);
    } else {
      return transferToAddress(
        _from, 
        _to, 
        _value, 
        _data); 
    }
  }

  function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(
        msg.sender,
        _to,
        _value,
        _data); 
    } else {
      return transferToAddress(
        msg.sender,
        _to,
        _value,
        _data);
    }
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    bytes memory empty;
    return transfer(_to, _value, empty);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 length;
     
    assembly {
       
      length := extcodesize(_addr)
    }  
    return (length>0);
  }

  function moveTokens(address _from, address _to, uint256 _value) internal returns (bool success) {
    if (balanceOf(_from) < _value) {
      revert();
    }
    balances[_from] = balanceOf(_from).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    return true;
  }

  function transferToAddress(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value), "Move is not successful");
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data);  
    return true;
  }
  
   
  function transferToContract(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value), "Move is not successful");
    ERC223ReceiverMixin(_to).tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data);  
    return true;
  }
}

 
 
 
contract RBACMixin {
   
  string constant FORBIDDEN = "Doesn't have enough rights";
  string constant DUPLICATE = "Requirement already satisfied";

   
  address public owner;

   
  mapping (address => bool) public minters;

   
   
  event SetOwner(address indexed who);

   
   
  event AddMinter(address indexed who);
   
   
  event DeleteMinter(address indexed who);

  constructor () public {
    _setOwner(msg.sender);
  }

   
  modifier onlyOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

   
  modifier onlyMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

   
   
   
  function isOwner(address _who) public view returns (bool) {
    return owner == _who;
  }

   
   
   
  function isMinter(address _who) public view returns (bool) {
    return minters[_who];
  }

   
   
   
   
  function setOwner(address _who) public onlyOwner returns (bool) {
    require(_who != address(0));
    _setOwner(_who);
  }

   
   
   
   
  function addMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, true);
  }

   
   
   
   
  function deleteMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, false);
  }

   
   
   
   
  function _setOwner(address _who) private returns (bool) {
    require(owner != _who, DUPLICATE);
    owner = _who;
    emit SetOwner(_who);
    return true;
  }

   
   
   
   
  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag, DUPLICATE);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit DeleteMinter(_who);
    }
    return true;
  }
}

contract RBACMintableTokenMixin is StandardToken, RBACMixin {
   
  uint256 totalIssued_;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished, "Minting is finished");
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    onlyMinter
    canMint
    public
    returns (bool)
  {
    totalIssued_ = totalIssued_.add(_amount);
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

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

 
 
 
contract VinciToken is StandardBurnableToken, RBACMintableTokenMixin, ERC223Mixin {
   
   
  string constant public name = "Vinci"; 
   
  string constant public symbol = "VINCI";  
   
  uint256 constant public decimals = 18;  
   
  uint256 constant public cap = 1500 * (10 ** 6) * (10 ** decimals);  

   
   
   
   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool) 
  {
    require(totalIssued_.add(_amount) <= cap, "Cap is reached");
    return super.mint(_to, _amount);
  }
}

contract BasicMultisig {
  string constant ALREADY_EXECUTED = "Operation already executed";

  VinciToken public vinci_contract;   

   
  mapping (address => bool) public owners;
   
  mapping (address => bool) public admins;

   
  mapping (uint => uint) public ownersConfirmations;
   
  mapping (uint => uint) public adminsConfirmations;

  mapping (uint => mapping (address => bool)) public ownersSigns;
  mapping (uint => mapping (address => bool)) public adminsSigns;

   
  mapping (uint => bool) public executed;

  modifier manageable() {
    require(isOwner(msg.sender) || isAdmin(msg.sender), "You're not admin or owner");
    _;
  }

  modifier shouldNotBeAlreadyExecuted(uint _operation) {
    require(!executed[_operation], ALREADY_EXECUTED);
    _;
  }

  modifier increasesConfirmationsCounter(uint _operation) {
    increaseConfirmationsCounter(_operation);
    _;
  }

  function isOwner(address who) public view returns (bool) {
    return owners[who];
  }

  function isAdmin(address who) public view returns (bool) {
    return admins[who];
  }

  uint public operation = 0;

   
  function() external payable {
    revert();
  }

   
  modifier createsNewOperation() {
    operation++;
    if (isOwner(msg.sender)) {
      ownersConfirmations[operation] = 1;
      adminsConfirmations[operation] = 0;
      ownersSigns[operation][msg.sender] = true;
    } else {
      if (isAdmin(msg.sender)) {
        ownersConfirmations[operation] = 0;
        adminsConfirmations[operation] = 1;
        adminsSigns[operation][msg.sender] = true;
      }
    }
    _;
  }

  function increaseConfirmationsCounter(uint _operation) internal {
    if (isOwner(msg.sender)) {
      if (ownersSigns[_operation][msg.sender]) revert();
      ownersConfirmations[_operation] += 1;
    } else {
      if (isAdmin(msg.sender)) {
        if (adminsSigns[_operation][msg.sender]) revert();
        adminsConfirmations[_operation] += 1;
      }
    }
  }

  function enoughConfirmations(uint _operation) public view returns (bool) {
    uint totalConfirmations = ownersConfirmations[_operation] + adminsConfirmations[_operation];
    return ((ownersConfirmations[_operation] > 0) && (totalConfirmations > 2));
  }
   
}

contract SetOwnerMultisig is BasicMultisig {
  struct SetOwnerParams { address who; }

  mapping (uint => SetOwnerParams) public setOwnerOperations;


   
  event setOwnerAction(uint operation, address indexed who);
  event setOwnerConfirmation(uint operation, address indexed who, uint ownersConfirmations, uint adminsConfirmations);


  function setOwner(address who) public manageable
                                 createsNewOperation
                                 returns (uint) {

    setOwnerOperations[operation] = SetOwnerParams(who);

    emit setOwnerAction(operation, who);
    return operation;
  }

  function setOwnerConfirm(uint _operation) public manageable
                                            shouldNotBeAlreadyExecuted(_operation)
                                            increasesConfirmationsCounter(_operation)
                                            returns (bool) {
    if (enoughConfirmations(_operation)){
      vinci_contract.setOwner(setOwnerOperations[_operation].who);
      executed[_operation] = true;
    }

    emit setOwnerConfirmation(_operation,
                              setOwnerOperations[_operation].who,
                              ownersConfirmations[_operation],
                              adminsConfirmations[_operation]);
  }
}

contract DeleteMinterMultisig is BasicMultisig {
  struct DeleteMinterParams { address who; }

  mapping (uint => DeleteMinterParams) public deleteMinterOperations;


   
  event deleteMinterAction(uint operation, address indexed who);

  event deleteMinterConfirmation(uint operation,
                                 address indexed who,
                                 uint ownersConfirmations,
                                 uint adminsConfirmations);


  function deleteMinter(address who) public manageable
                                    createsNewOperation
                                    returns (uint) {

    deleteMinterOperations[operation] = DeleteMinterParams(who);

    emit deleteMinterAction(operation, who);
    return operation;
  }

  function deleteMinterConfirm(uint _operation) public manageable
                                                shouldNotBeAlreadyExecuted(_operation)
                                                increasesConfirmationsCounter(_operation)
                                                returns (bool) {
    if (enoughConfirmations(_operation)){
      vinci_contract.deleteMinter(deleteMinterOperations[_operation].who);
      executed[_operation] = true;
    }

    emit deleteMinterConfirmation(_operation,
                                 deleteMinterOperations[_operation].who,
                                 ownersConfirmations[_operation],
                                 adminsConfirmations[_operation]);
  }
}

contract AddMinterMultisig is BasicMultisig {
  struct AddMinterParams { address who; }

  mapping (uint => AddMinterParams) public addMinterOperations;


   
  event addMinterAction(uint operation, address indexed who);

  event addMinterConfirmation(uint operation,
                              address indexed who,
                              uint ownersConfirmations,
                              uint adminsConfirmations);


  function addMinter(address who) public manageable
                                  createsNewOperation
                                  returns (uint) {

    addMinterOperations[operation] = AddMinterParams(who);

    emit addMinterAction(operation, who);
    return operation;
  }

  function addMinterConfirm(uint _operation) public manageable
                                             shouldNotBeAlreadyExecuted(_operation)
                                             increasesConfirmationsCounter(_operation)
                                             returns (bool) {

    if (enoughConfirmations(_operation)){
      vinci_contract.addMinter(addMinterOperations[_operation].who);
      executed[_operation] = true;
    }

    emit addMinterConfirmation(_operation,
                               addMinterOperations[_operation].who,
                               ownersConfirmations[_operation],
                               adminsConfirmations[_operation]);
  }
}

contract MintMultisig is BasicMultisig {
  struct MintParams { address to; uint256 amount; }

  mapping (uint => MintParams) public mintOperations;


   
  event mintAction(uint operation,
                   address indexed to,
                   uint256 amount);

  event mintConfirmation(uint operation,
                         address indexed to,
                         uint256 amount,
                         uint ownersConfirmations,
                         uint adminsConfirmations);


  function mint(address to, uint256 amount) public manageable
                             createsNewOperation
                             returns (uint) {

    mintOperations[operation] = MintParams(to, amount);

    emit mintAction(operation, to, amount);
    return operation;
  }

  function mintConfirm(uint _operation) public manageable
                                        shouldNotBeAlreadyExecuted(_operation)
                                        increasesConfirmationsCounter(_operation)
                                        returns (bool) {
    if (enoughConfirmations(_operation)){
      vinci_contract.mint(mintOperations[_operation].to, mintOperations[_operation].amount);
      executed[_operation] = true;
    }

    emit mintConfirmation(_operation,
                          mintOperations[_operation].to,
                          mintOperations[_operation].amount,
                          ownersConfirmations[_operation],
                          adminsConfirmations[_operation]);
  }
}

contract FinishMintingMultisig is BasicMultisig {
   
  event finishMintingAction(uint operation);

  event finishMintingConfirmation(uint operation,
                                  uint ownersConfirmations,
                                  uint adminsConfirmations);


  function finishMinting() public manageable
                           createsNewOperation
                           returns (uint) {

    emit finishMintingAction(operation);
    return operation;
  }

  function finishMintingConfirm(uint _operation) public manageable
                                                 shouldNotBeAlreadyExecuted(_operation)
                                                 increasesConfirmationsCounter(_operation)
                                                 returns (bool) {
    if (enoughConfirmations(_operation)){
      vinci_contract.finishMinting();
      executed[_operation] = true;
    }

    emit finishMintingConfirmation(_operation,
                                   ownersConfirmations[_operation],
                                   adminsConfirmations[_operation]);
  }
}

contract Multisig is SetOwnerMultisig,

                     AddMinterMultisig,
                     DeleteMinterMultisig,

                     MintMultisig,
                     FinishMintingMultisig {

  constructor(VinciToken _vinci_contract) public {
    vinci_contract = _vinci_contract;

    owners[0x22e936f4a00ABc4120208D7E8EF9f76d3555Cb05] = true;
    owners[0x95a06E0B6F94A6Cbae49317ED0c87056Eb8494e8] = true;

    admins[0x020748bFeB4E877125ABa9A1D283d41A48f12584] = true;
    admins[0xED182c9CE936C541599A049570DD7EEFE06387e9] = true;
    admins[0x2ef7AC759F06509535750403663278cc22FDaEF1] = true;
    admins[0x27481f1D81F8B6eff5860c43111acFEc6A8C5290] = true;
  }
}