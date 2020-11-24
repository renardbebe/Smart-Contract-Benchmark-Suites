 

 
pragma solidity ^0.4.20;

 
interface tokenRecipient {
  function receiveApproval( address from, uint256 value, bytes data ) external;
}

 
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

 
contract Owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }
}

 
contract Token is Owned {
  string  public name;
  string  public symbol;
  uint8   public decimals = 18;
  uint256 public totalSupply;

  mapping( address => uint256 ) balances;
  mapping( address => mapping(address => uint256) ) allowances;

   
  event Approval(
    address indexed owner,
    address indexed spender,
    uint value
  );

   
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  function Token(
    uint256 _initialSupply,
    string _tokenName,
    string _tokenSymbol
  )
    public
  {
    totalSupply = _initialSupply * 10**18;
    balances[msg.sender] = _initialSupply * 10**18;

    name = _tokenName;
    symbol = _tokenSymbol;
  }

   
  function balanceOf( address owner ) public constant returns (uint) {
    return balances[owner];
  }

   
  function approve( address spender, uint256 value ) public returns (bool success) {
     
     
     
     
    allowances[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }

   
  function safeApprove(
    address _spender,
    uint256 _currentValue,
    uint256 _value
  )
    public
    returns (bool success)
  {
     
     

    if (allowances[msg.sender][_spender] == _currentValue)
      return approve(_spender, _value);

    return false;
  }

   
  function allowance(
    address owner,
    address spender
  )
    public constant
    returns (uint256 remaining)
  {
    return allowances[owner][spender];
  }

   
  function transfer(
    address to,
    uint256 value
  )
    public
    returns (bool success)
  {
    bytes memory empty;  
    _transfer( msg.sender, to, value, empty );
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool success)
  {
    require( value <= allowances[from][msg.sender] );

    allowances[from][msg.sender] -= value;
    bytes memory empty;
    _transfer( from, to, value, empty );

    return true;
  }

   
  function approveAndCall(
    address spender,
    uint256 value,
    bytes context
  )
    public
    returns (bool success)
  {
    if (approve(spender, value))
    {
      tokenRecipient recip = tokenRecipient(spender);

      if (isContract(recip))
        recip.receiveApproval(msg.sender, value, context);

      return true;
    }

    return false;
  }


   
  function transfer(
    address to,
    uint value,
    bytes data,
    string custom_fallback
  )
    public
    returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

     
    require(
      address(to).call.value(0)(
        bytes4(keccak256(custom_fallback)),
        msg.sender,
        value,
        data
      )
    );

    return true;
  }

   
  function transfer(
    address to,
    uint value,
    bytes data
  )
    public
    returns (bool success)
  {
    if (isContract(to)) {
      return transferToContract( to, value, data );
    }

    _transfer( msg.sender, to, value, data );
    return true;
  }

   
  function transferToContract(
    address to,
    uint value,
    bytes data
  )
    private
    returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    ContractReceiver rx = ContractReceiver(to);

    if (isContract(rx)) {
      rx.tokenFallback( msg.sender, value, data );
      return true;
    }

    return false;
  }

   
  function isContract(address _addr)
    private
    constant
    returns (bool)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

   
  function _transfer(
    address from,
    address to,
    uint value,
    bytes data
  )
    internal
  {
    require( to != 0x0 );
    require( balances[from] >= value );
    require( balances[to] + value > balances[to] );  

    balances[from] -= value;
    balances[to] += value;

    bytes memory ignore;
    ignore = data;  
    Transfer( from, to, value );  
  }
}