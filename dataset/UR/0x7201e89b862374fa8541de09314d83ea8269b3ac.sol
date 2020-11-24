 

 

 
 
 
 
 
 
 
 
 

pragma solidity >=0.5.0 <0.6.0;

contract ERC20Interface
{
    uint256 public totalSupply;
    string  public name;
    uint8   public decimals;
    string  public symbol;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function API_MoveToken(address _from, address _to, uint256 _value) external;
}

 

 
 
 
 
 
 
 
 
 
 

pragma solidity >=0.5.0 <0.6.0;

interface TicketInterface {

     
    function PaymentTicket() external;

     
    function HasTicket( address ownerAddr ) external view returns (bool);
}

 

pragma solidity >=0.5.0 <0.6.0;


contract InternalModule {

    address[] _authAddress;

    address _contractOwner;

    address _managerAddress;

    constructor() public {
        _contractOwner = msg.sender;
    }

    modifier OwnerOnly() {
        require( _contractOwner == msg.sender ); _;
    }

    modifier ManagerOnly() {
        require(msg.sender == _managerAddress); _;
    }

    modifier APIMethod() {

        bool exist = false;

        for (uint i = 0; i < _authAddress.length; i++) {
            if ( _authAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }

        require(exist); _;
    }

    function SetRoundManager(address rmaddr ) external OwnerOnly {
        _managerAddress = rmaddr;
    }

    function AddAuthAddress(address _addr) external ManagerOnly {
        _authAddress.push(_addr);
    }

    function DelAuthAddress(address _addr) external ManagerOnly {

        for (uint i = 0; i < _authAddress.length; i++) {

            if (_authAddress[i] == _addr) {

                for (uint j = 0; j < _authAddress.length - 1; j++) {

                    _authAddress[j] = _authAddress[j+1];

                }

                delete _authAddress[_authAddress.length - 1];
                _authAddress.length--;
            }

        }
    }


}

 

pragma solidity >=0.5.0 <0.6.0;




contract ERC20Token is ERC20Interface, InternalModule {
    string  public name                     = "Name";
    string  public symbol                   = "Symbol";
    uint8   public decimals                 = 18;
    uint256 public totalSupply              = 1000000000 * 10 ** 18;
    uint256 constant private MAX_UINT256    = 2 ** 256 - 1;
    uint256 private constant brunMaxLimit = (1000000000 * 10 ** 18) - (10000000 * 10 ** 18);

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory tokenName, string memory tokenSymbol, uint256 tokenTotalSupply, uint256 mint) public {

        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = tokenTotalSupply;

        balances[_contractOwner] = mint;
        balances[address(this)] = tokenTotalSupply - mint;
    }

    function transfer(address _to, uint256 _value) public
    returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view
    returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    uint256 private ticketPrice = 60000000000000000000;

    mapping( address => bool ) private _paymentTicketAddrMapping;

    function PaymentTicket() external {

        require( _paymentTicketAddrMapping[msg.sender] == false, "ERC20_ERR_001");
        require( balances[msg.sender] >= ticketPrice, "ERC20_ERR_002");

        balances[msg.sender] -= ticketPrice;

        if ( balances[address(0x0)] == brunMaxLimit ) {
            balances[_contractOwner] += ticketPrice;
        } else if ( balances[address(0x0)] + ticketPrice >= brunMaxLimit ) {
            balances[_contractOwner] += (balances[address(0x0)] + ticketPrice) - brunMaxLimit;
            balances[address(0x0)] = brunMaxLimit;
        } else {
            balances[address(0x0)] += ticketPrice;
        }
        _paymentTicketAddrMapping[msg.sender] = true;
    }

    function HasTicket( address ownerAddr ) external view returns (bool) {
        return _paymentTicketAddrMapping[ownerAddr];
    }
    function API_MoveToken(address _from, address _to, uint256 _value) external APIMethod {

        require( balances[_from] >= _value, "ERC20_ERR_003" );

        balances[_from] -= _value;

        if ( _to == address(0x0) ) {
            if ( balances[address(0x0)] == brunMaxLimit ) {
                balances[_contractOwner] += _value;
            } else if ( balances[address(0x0)] + _value >= brunMaxLimit ) {
                balances[_contractOwner] += (balances[address(0x0)] + _value) - brunMaxLimit;
                balances[address(0x0)] = brunMaxLimit;
            } else {
                balances[address(0x0)] += _value;
            }
        } else {
            balances[_to] += _value;
        }

        emit Transfer( _from, _to, _value );
    }
}