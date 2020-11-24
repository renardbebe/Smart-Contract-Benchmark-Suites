 

pragma solidity ^0.4.24;

 
contract ERC20
{
    function balanceOf    (address _owner) public constant returns (uint256 balance);
    function transfer     (               address _to, uint256 _value) public returns (bool success);
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
    function approve      (address _spender, uint256 _value) public returns (bool success);
    function allowance    (address _owner, address _spender) public constant returns (uint256 remaining);
    function totalSupply  () public constant returns (uint);

    event Transfer (address indexed _from,  address indexed _to,      uint _value);
    event Approval (address indexed _owner, address indexed _spender, uint _value);
}

 
interface TokenRecipient
{
     
    function receiveApproval (address _from, uint256 _value, address _token, bytes _extraData) external;
}

 
library SafeMath
{
     
    function add (uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        require (c >= a); return c;
    }

     
    function sub (uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        require (a >= b);
        c = a - b; return c;
    }

     
    function mul (uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a * b;
        require (a == 0 || c / a == b); return c;
    }

     
    function div (uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        require (b > 0);
        c = a / b; return c;
    }
}

 
contract ERC20Token is ERC20
{
    using SafeMath for uint256;

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

     
    constructor (string _name, string _symbol, uint8 _decimals, uint256 _initSupply) public
    {
        name        = _name;                                     
        symbol      = _symbol;                                   
        decimals    = _decimals;                                 
        totalSupply = _initSupply * (10 ** uint256 (decimals));  
        balances[msg.sender] = totalSupply;                      

        emit Transfer (address(0), msg.sender, totalSupply);
    }

     
    function balanceOf (address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }

     
    function name        () public view returns (string  _name    ) { return name;        } 
    function symbol      () public view returns (string  _symbol  ) { return symbol;      } 
    function decimals    () public view returns (uint8   _decimals) { return decimals;    }
    function totalSupply () public view returns (uint256 _supply  ) { return totalSupply; }

     
    function _transfer (address _from, address _to, uint256 _value) internal
    {
        require (_to != 0x0);                                
        require (balances[_from] >= _value);                 
        require (balances[_to  ] +  _value > balances[_to]); 

        uint256 previous = balances[_from] + balances[_to];  

        balances[_from] = balances[_from].sub (_value);      
        balances[_to  ] = balances[_to  ].add (_value);      
        emit Transfer (_from, _to, _value);

         
        assert (balances[_from] + balances[_to] == previous);
    }

     
    function transfer (address _to, uint256 _value) public returns (bool success)
    {
        _transfer (msg.sender, _to, _value); return true;
    }

     
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success)
    {
        require (allowed[_from][msg.sender] >= _value);  
        allowed [_from][msg.sender] = allowed [_from][msg.sender].sub (_value);

        _transfer (_from, _to, _value); return true;
    }

     
    function allowance (address _owner, address _spender) public constant returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }

     
    function approve (address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall (address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        TokenRecipient spender = TokenRecipient (_spender);

        if (approve (_spender, _value))
        {
            spender.receiveApproval (msg.sender, _value, address (this), _extraData);
            return true;
        }
    }
}

 
contract Ownable
{
    address public owner;    

     
    event OwnershipTransferred (address indexed _owner, address indexed _to);
    event OwnershipRenounced   (address indexed _owner);

     
    constructor () public 
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner 
    {
        require (msg.sender == owner);
        _;
    }

     
    function transferOwnership (address _to) public onlyOwner
    {
        require (_to != address(0));
        emit OwnershipTransferred (owner, _to);
        owner = _to;
    }

     
    function renounceOwnership (bytes32 _safePhrase) public onlyOwner
    {
        require (_safePhrase == "This contract is to be disowned.");
        emit OwnershipRenounced (owner);
        owner = address(0);
    }
}

 
contract ExpERC20Token is ERC20Token, Ownable
{
     
    constructor (
        string   _name,      
        string   _symbol,    
        uint8    _decimals,  
        uint256 _initSupply  
    ) ERC20Token (_name, _symbol, _decimals, _initSupply) public {}

     
    function changeName (string _name, string _symbol) onlyOwner public
    {
        name   = _name;
        symbol = _symbol;
    }

     

     
    event Burn (address indexed from, uint256 value);

     
    function _burn (address _from, uint256 _value) internal
    {
        require (balances[_from] >= _value);             

        balances[_from] = balances[_from].sub (_value);  
        totalSupply = totalSupply.sub (_value);          
        emit Burn (_from, _value);
    }

     
    function burn (uint256 _value) public returns (bool success)
    {
        _burn (msg.sender, _value); return true;
    }

     
    function burnFrom (address _from, uint256 _value) public returns (bool success)
    {
        require (allowed [_from][msg.sender] >= _value);
        allowed [_from][msg.sender] = allowed [_from][msg.sender].sub (_value);
        _burn (_from, _value); return true;
    }


     

     
    event Mint (address indexed _to, uint256 _amount);
    event MintFinished ();

    bool public mintingFinished = false;

     
    modifier canMint ()
    {
        require (!mintingFinished);
        _;
    }

     
    modifier hasMintPermission ()
    {
        require (msg.sender == owner);
        _;
    }

     
    function mint (address _to, uint256 _amount) hasMintPermission canMint public returns (bool)
    {
        totalSupply   = totalSupply.add  (_amount);
        balances[_to] = balances[_to].add (_amount);

        emit Mint (_to, _amount);
        emit Transfer (address (0), this, _amount);
        emit Transfer (       this,  _to, _amount);
        return true;
    }

     
    function finishMinting () onlyOwner canMint public returns (bool)
    {
        mintingFinished = true;
        emit MintFinished ();
        return true;
    }


     

    bool public tokenLocked = false;

     
    event Lock (address indexed _target, bool _locked);

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds (address target, bool frozen);

     
    function freezeAccount (address _target, bool _freeze) onlyOwner public
    {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds (_target, _freeze);
    }

     
    modifier whenTokenUnlocked ()
    {
        require (!tokenLocked);
        _;
    }

     
    function _lock (bool _value) internal
    {
        require (tokenLocked != _value);
        tokenLocked = _value;
        emit Lock (this, tokenLocked);
    }

     
    function isTokenLocked () public view returns (bool success)
    {
        return tokenLocked;
    }

     
    function lock (bool _value) onlyOwner public returns (bool)
    {
        _lock (_value); return true;
    }

     
    function transfer (address _to, uint256 _value) whenTokenUnlocked public returns (bool success)
    {
        require (!frozenAccount[msg.sender]);    
        require (!frozenAccount[_to  ]);         

        return super.transfer (_to, _value);
    }

     
    function transferFrom (address _from, address _to, uint256 _value) whenTokenUnlocked public returns (bool success)
    {
        require (!frozenAccount[msg.sender]);    
        require (!frozenAccount[_from]);         
        require (!frozenAccount[_to  ]);         

        return super.transferFrom (_from, _to, _value);
    }

     
    function approve (address _spender, uint256 _value) whenTokenUnlocked public returns (bool success)
    {
        require (!frozenAccount[msg.sender]);    
        require (!frozenAccount[_spender  ]);    

        return super.approve (_spender, _value);
    }

     
    function approveAndCall (address _spender, uint256 _value, bytes _extraData) whenTokenUnlocked public returns (bool success)
    {
        require (!frozenAccount[msg.sender]);    
        require (!frozenAccount[_spender  ]);    

        return super.approveAndCall (_spender, _value, _extraData);
    }

     

    uint256 public sellPrice;
    uint256 public buyPrice;

     
    function _transfer (address _from, address _to, uint _value) internal
    {
        require (_to != 0x0);                                    
        require (balances[_from] >= _value);                     
        require (balances[_to  ]  + _value >= balances[_to]);    

        require (!frozenAccount[_from]);                         
        require (!frozenAccount[_to  ]);                         

        balances[_from] = balances[_from].sub (_value);          
        balances[_to  ] = balances[_to  ].add (_value);          
        emit Transfer (_from, _to, _value);
    }

     
    function setPrices (uint256 _sellPrice, uint256 _buyPrice) onlyOwner public
    {
        sellPrice = _sellPrice;
        buyPrice  = _buyPrice ;
    }

     
    function buy () whenTokenUnlocked payable public
    {
        uint amount = msg.value / buyPrice;      
        _transfer (this, msg.sender, amount);    
    }

     
    function sell (uint256 _amount) whenTokenUnlocked public
    {
        require (balances[this] >= _amount * sellPrice);     
        _transfer (msg.sender, this, _amount);               
        msg.sender.transfer (_amount * sellPrice);           
    }


}