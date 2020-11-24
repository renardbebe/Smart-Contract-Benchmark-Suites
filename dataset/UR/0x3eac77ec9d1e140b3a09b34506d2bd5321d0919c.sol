 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor(address custom_owner) public {
    if (custom_owner != address (0))
      _owner = custom_owner;
    else
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


 

contract ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Created(uint time);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event AllowanceUsed(address indexed owner, address indexed spender, uint amount);

    constructor(string _name, string _symbol)
    public
    {
        name = _name;
        symbol = _symbol;
        emit Created(now);
    }

    function transfer(address _to, uint _value)
    public
    returns (bool success)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint _value)
    public
    returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success)
    {
        address _spender = msg.sender;
        require(allowance[_from][_spender] >= _value);
        allowance[_from][_spender] = allowance[_from][_spender].sub(_value);
        emit AllowanceUsed(_from, _spender, _value);
        return _transfer(_from, _to, _value);
    }

     
     
    function _transfer(address _from, address _to, uint _value)
    private
    returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

interface HasTokenFallback {
    function tokenFallback(address _from, uint256 _amount, bytes _data)
    external
    returns (bool success);
}

contract ERC667 is ERC20 {
    constructor(string _name, string _symbol)
    public
    ERC20(_name, _symbol)
    {}

    function transferAndCall(address _to, uint _value, bytes _data)
    public
    returns (bool success)
    {
        require(super.transfer(_to, _value));
        require(HasTokenFallback(_to).tokenFallback(msg.sender, _value, _data));
        return true;
    }
}

 
contract DividendTokenERC667 is ERC667, Ownable
{
    using SafeMath for uint256;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint constant POINTS_PER_WEI = 1e32;
    uint public dividendsTotal;
    uint public dividendsCollected;
    uint public totalPointsPerToken;
    mapping (address => uint) public creditedPoints;
    mapping (address => uint) public lastPointsPerToken;

     
    event CollectedDividends(uint time, address indexed account, uint amount);
    event DividendReceived(uint time, address indexed sender, uint amount);

    constructor(uint256 _totalSupply, address _custom_owner)
    public
    ERC667("Noteshares Token", "NST")
    Ownable(_custom_owner)
    {
        totalSupply = _totalSupply;
    }

     
    function receivePayment()
    internal
    {
        if (msg.value == 0) return;
         
         
        totalPointsPerToken = totalPointsPerToken.add((msg.value.mul(POINTS_PER_WEI)).div(totalSupply));
        dividendsTotal = dividendsTotal.add(msg.value);
        emit DividendReceived(now, msg.sender, msg.value);
    }
     
     
     

     
     
    function transfer(address _to, uint _value)
    public
    returns (bool success)
    {
         
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC20.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success)
    {
        _updateCreditedPoints(_from);
        _updateCreditedPoints(_to);
        return ERC20.transferFrom(_from, _to, _value);
    }

     
     
    function transferAndCall(address _to, uint _value, bytes _data)
    public
    returns (bool success)
    {
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC667.transferAndCall(_to, _value, _data);
    }

     
    function collectOwedDividends()
    internal
    returns (uint _amount)
    {
         
        _updateCreditedPoints(msg.sender);
        _amount = creditedPoints[msg.sender].div(POINTS_PER_WEI);
        creditedPoints[msg.sender] = 0;
        dividendsCollected = dividendsCollected.add(_amount);
        emit CollectedDividends(now, msg.sender, _amount);
        require(msg.sender.call.value(_amount)());
    }


     
     
     
     
     
     
    function _updateCreditedPoints(address _account)
    private
    {
        creditedPoints[_account] = creditedPoints[_account].add(_getUncreditedPoints(_account));
        lastPointsPerToken[_account] = totalPointsPerToken;
    }

     
    function _getUncreditedPoints(address _account)
    private
    view
    returns (uint _amount)
    {
        uint _pointsPerToken = totalPointsPerToken.sub(lastPointsPerToken[_account]);
         
         
         
         
        return _pointsPerToken.mul(balanceOf[_account]);
    }


     
     
     
     
    function getOwedDividends(address _account)
    public
    constant
    returns (uint _amount)
    {
        return (_getUncreditedPoints(_account).add(creditedPoints[_account])).div(POINTS_PER_WEI);
    }
}

contract NSERC667 is DividendTokenERC667 {
    using SafeMath for uint256;

    uint256 private TOTAL_SUPPLY =  100 * (10 ** uint256(decimals));  

    constructor (address ecosystemFeeAccount, uint256 ecosystemShare, address _custom_owner)
    public
    DividendTokenERC667(TOTAL_SUPPLY, _custom_owner)
    {
        uint256 ownerSupply = totalSupply.sub(ecosystemShare);
        balanceOf[owner()] = ownerSupply;
        balanceOf[ecosystemFeeAccount] = ecosystemShare;
    }
}

contract NotesharesToken is NSERC667 {
    using SafeMath for uint256;

    uint8 public state;  

    string private contentLink;
    string private folderLink;
    bool public hidden = false;

    constructor (string _contentLink, string _folderLink, address _ecosystemFeeAccount, uint256 ecosystemShare, address _custom_owner)
    public
    NSERC667(_ecosystemFeeAccount, ecosystemShare, _custom_owner) {
        state = 3;
        contentLink = _contentLink;
        folderLink = _folderLink;
    }

     
     
    function () public payable {
        require(state == 3);  
        receivePayment();
    }

    function getContentLink () public view returns (string) {
        require(hidden == false);
        return contentLink;
    }

    function getFolderLink() public view returns (string) {
        require(hidden == false);
        return folderLink;
    }
     
     

    function setCancelled () public onlyOwner {
        state = 0;
    }

    function setHidden (bool _hidden) public onlyOwner {
        hidden = _hidden;
    }

    function claimDividend () public {
        require(state > 1);
        collectOwedDividends();
    }

     
    function destruct () public onlyOwner {
        require(state == 2 || state == 3);
        require(balanceOf[owner()] == totalSupply);
        selfdestruct(owner());
    }

     
    function claimOwnership () public {
         
        require(balanceOf[msg.sender] == totalSupply);
        _transferOwnership(msg.sender);
    }
}