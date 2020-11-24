 

pragma solidity ^0.5.1;

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './Blacklistable.sol';
import './Pausable.sol';
import './ECDSA.sol';

 


contract uCNY is IERC20, Ownable, Pausable, Blacklistable {
    using SafeMath for uint256;

    string public name = "uCNY Fiat Token";
    string public symbol = "uCNY";
    uint8 public decimals = 18;
    string public currency = "CNY";
    address public masterCreator;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    uint256 public totalSupply = 0;

    mapping(address => bool) internal creators;
    mapping(address => uint256) internal creatorAllowed;

    mapping(address=> uint256) internal metaNonces;

    event Create(address indexed creator, address indexed to, uint256 amount);
    event Destroy(address indexed destroyer, uint256 amount);
    event CreatorConfigured(address indexed creator, uint256 creatorAllowedAmount);
    event CreatorRemoved(address indexed oldCreator);
    event MasterCreatorChanged(address indexed newMasterCreator);

    constructor() public {
        masterCreator = msg.sender;
        pauser = msg.sender;
        blacklister = msg.sender;
    }

     
    modifier onlyCreators() {
        require(creators[msg.sender] == true);
        _;
    }

     
    function create(address _to, uint256 _amount) whenNotPaused onlyCreators notBlacklisted(msg.sender) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0));
        require(_amount > 0);

        uint256 creatingAllowedAmount = creatorAllowed[msg.sender];
        require(_amount <= creatingAllowedAmount);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        creatorAllowed[msg.sender] = creatingAllowedAmount.sub(_amount);
        emit Create(msg.sender, _to, _amount);
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

     
    modifier onlyMasterCreator() {
        require(msg.sender == masterCreator);
        _;
    }

     
    function creatorAllowance(address creator) public view returns (uint256) {
        return creatorAllowed[creator];
    }

     
    function isCreator(address account) public view returns (bool) {
        return creators[account];
    }

     
    function configureCreator(address creator, uint256 creatorAllowedAmount) whenNotPaused onlyMasterCreator public returns (bool) {
        creators[creator] = true;
        creatorAllowed[creator] = creatorAllowedAmount;
        emit CreatorConfigured(creator, creatorAllowedAmount);
        return true;
    }

     
    function removeCreator(address creator) onlyMasterCreator public returns (bool) {
        creators[creator] = false;
        creatorAllowed[creator] = 0;
        emit CreatorRemoved(creator);
        return true;
    }

     
    function destroy(uint256 _amount) whenNotPaused onlyCreators notBlacklisted(msg.sender) public {
        uint256 balance = balances[msg.sender];
        require(_amount > 0);
        require(balance >= _amount);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        emit Destroy(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

   

    function updateMasterCreator(address _newMasterCreator) onlyOwner public {
        require(_newMasterCreator != address(0));
        masterCreator = _newMasterCreator;
        emit MasterCreatorChanged(masterCreator);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
  function getTransferPayload(
        address _from,
        address _to,
        uint256 value,
        uint256 fee,
        uint256 nonce
    ) public
    view
    returns (bytes32 payload)
  {
    return ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        "transfer",      
        _from,           
        _to,             
        address(this),   
        value,           
        fee,             
        nonce            
      ))
    );
  }


 
    function getApprovePayload(
        address _from,
        address _to,
        uint256 value,
        uint256 fee,
        uint256 metaNonce
    ) public
    view
    returns (bytes32 payload)
  {
    return ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        "approve",       
        _from,           
        _to,             
        address(this),   
        value,           
        fee,             
        metaNonce        
      ))
    );
  }


 
    function getTransferFromPayload(
        address _from,
        address _to,
        address _by,
        uint256 value,
        uint256 fee,
        uint256 metaNonce
    ) public
    view
    returns (bytes32 payload)
  {
    return ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        "transferFrom",      
        _from,               
        _to,                 
        _by,                 
        address(this),       
        value,               
        fee,                 
        metaNonce            
      ))
    );
  }

   
  function getMetaNonce(address sender) public view returns (uint256) {
    return metaNonces[sender];
  }

    

  function meta_nonce(address _from) external view returns (uint256 nonce) {
        return metaNonces[_from];
    }


   
  function isValidSignature(
    address _signer,
    bytes32 payload,
    bytes memory signature
  )
    public
    pure
    returns (bool)
  {
    return (_signer == ECDSA.recover(
      ECDSA.toEthSignedMessageHash(payload),
      signature
    ));
  }
  
      event MetaTransfer(address indexed relayer, address indexed from, address indexed to, uint256 value);

     
    event MetaApproval(address indexed relayer, address indexed owner, address indexed spender, uint256 value);


     
  function metaTransfer(
        address _from,
        address _to,
        uint256 value,
        uint256 fee,
        uint256 metaNonce,
        bytes memory signature
  ) public returns (bool success) {


     
    require(getMetaNonce(_from) == metaNonce);
    metaNonces[_from] = metaNonces[_from].add(1);
     
    bytes32 payload = getTransferPayload(_from,_to, value, fee, metaNonce);
    require(isValidSignature(_from,payload,signature));

    require(_from != address(0));

     
    _transfer(_from,_to,value);
     
    _transfer(_from,msg.sender,fee);

    emit MetaTransfer(msg.sender, _from,_to,value);
    return true;
  }

 
    function metaApprove(
        address _from,
        address _to,
        uint256 value,
        uint256 fee,
        uint256 metaNonce,
        bytes memory signature
    ) public returns (bool success) {
     
    require(getMetaNonce(_from) == metaNonce);
    metaNonces[_from] = metaNonces[_from].add(1);

     
    bytes32 payload = getApprovePayload(_from,_to, value, fee,metaNonce);
    require(isValidSignature(_from, payload, signature));

    require(_from != address(0));

     
    _approve(_from,_to,value);

     
    _transfer(_from,msg.sender,fee);

    emit MetaApproval(msg.sender,_from,_to,value);
    return true;
    }


 
    function metaTransferFrom(
        address _from,
        address _to,
        address _by,
        uint256 value,
        uint256 fee,
        uint256 metaNonce,
        bytes memory signature
        ) public returns(bool){
     
    require(getMetaNonce(_by) == metaNonce);
    metaNonces[_by] = metaNonces[_by].add(1);

     
    bytes32 payload = getTransferFromPayload(_from,_to,_by, value,fee, metaNonce);
    require(isValidSignature(_by, payload, signature));

    require(_by != address(0));

     
    _transfer(_from,_to,value);

       
    _transfer(_by,msg.sender,fee);

     
    _approve(_from, _by, allowed[_from][_by].sub(value));

    emit MetaTransfer(msg.sender, _from,_to,value);

    return true;
    }

        
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
