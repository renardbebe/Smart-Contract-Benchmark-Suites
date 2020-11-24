 

pragma solidity ^0.4.23;

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
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

 

contract TESecurityToken is StandardToken, Pausable {
    
	string public constant name = "Tokenestate Equity";
	string public constant symbol = "TEM";
	string public companyURI = "www.tokenestate.io";

	uint8 public constant decimals = 0;

	address public previousContract;
	address public nextContract = 0x0;

	mapping(address => bool) public whitelist;

	bool public transferNeedApproval = true;

	event LogAddToWhitelist(address sender, address indexed beneficiary);
	event LogRemoveFromWhitelist(address sender, address indexed beneficiary);
	event LogSetTransferNeedApproval(address sender, bool value);
    event LogTransferFromIssuer(address sender, address indexed from, address indexed to, uint256 value);
    event LogProof(bytes32 indexed proof);
    event LogProofOfExistance(bytes32 indexed p0, bytes32 indexed p1, bytes32 indexed p2, bytes data);
    event LogSetNextContract(address sender, address indexed next);

	modifier isWhitelisted(address investor) 
	{
		require(whitelist[investor] == true);
		_;
	}

	modifier isActiveContract() 
	{
		require(nextContract == 0x0);
		_;
	}

	constructor (address prev)
	public
	{
		previousContract = prev;
	}

	function setNextContract(address next)
	whenNotPaused
	onlyOwner
	isActiveContract
	public
	{
		require (nextContract == 0x0);
		nextContract = next;
		LogSetNextContract(msg.sender, nextContract);
	}

	function setTransferNeedApproval(bool value)
	onlyOwner
	isActiveContract
	public
	{
		require (transferNeedApproval != value);
		transferNeedApproval = value;
		emit LogSetTransferNeedApproval(msg.sender, value);
	}

	function proofOfExistance(bytes32 p0, bytes32 p1, bytes32 p2, bytes32 docHash, bytes data) 
	isActiveContract
	public
	{
		emit LogProofOfExistance(p0, p1, p2, data);
		emit LogProof(docHash);
	}

	function addToWhitelist(address investor, bytes32 docHash) 
	whenNotPaused
	onlyOwner
	isActiveContract	
	external 
	{
		require (investor != 0x0);
		require (whitelist[investor] == false);

		whitelist[investor] = true;

		emit LogAddToWhitelist(msg.sender, investor);
		emit LogProof(docHash);
	}

	function removeFromWhitelist(address investor, bytes32 docHash)
	onlyOwner
	whenNotPaused	
	isActiveContract	
	external 
	{
		require (investor != 0x0);
		require (whitelist[investor] == true);
		whitelist[investor] = false;
		emit LogRemoveFromWhitelist(msg.sender, investor);
		emit LogProof(docHash);
	}

	function burn(address holder, uint256 value, bytes32 docHash) 
	onlyOwner 
	whenNotPaused
	isActiveContract	
	public
	returns (bool)	
	{
		require(value <= balances[holder]);
		balances[holder] = balances[holder].sub(value);
		totalSupply_ = totalSupply_.sub(value);
		emit Transfer(holder, address(0), value);
		emit LogProof(docHash);
		return true;
	}

	function mint(address to, uint256 value, bytes32 docHash)
	onlyOwner
	whenNotPaused
	isActiveContract	
	isWhitelisted(to)
	public
	returns (bool)
	{
	    totalSupply_ = totalSupply_.add(value);
    	balances[to] = balances[to].add(value);
	    emit Transfer(address(0), to, value);
		emit LogProof(docHash);
		return true;
	}

	function transferFromIssuer(address from, address to, uint256 value, bytes32 docHash)
	onlyOwner
	whenNotPaused
	isActiveContract	
	isWhitelisted(to)
    public
    returns (bool)
	{
	    require(value <= balances[from]);
	    require(docHash != 0x0);

	    balances[from] = balances[from].sub(value);
	    balances[to] = balances[to].add(value);
	    emit Transfer(from, to, value);
	    emit LogTransferFromIssuer(msg.sender, from, to, value);
		emit LogProof(docHash);
	    return true;
	}

	function transfer(address to, uint256 amount)
	public 
	whenNotPaused
	isActiveContract
	isWhitelisted(msg.sender)		
	isWhitelisted(to)	
	returns (bool)
	{
		require (transferNeedApproval == false);
		bool ret = super.transfer(to, amount);
		return ret;
	}

	function transferFrom(address from, address to, uint256 value) 
	public 
	whenNotPaused
	isActiveContract	
	isWhitelisted(from)	
	isWhitelisted(to)
	returns (bool)
	{
		require (transferNeedApproval == false);
		bool ret = super.transferFrom(from, to, value);
		return ret;
	}

	function setCompanyURI(string _companyURI) 
	onlyOwner 
	whenNotPaused
	isActiveContract	
	public
	{
		require(bytes(_companyURI).length > 0); 
		companyURI = _companyURI;
	}
}