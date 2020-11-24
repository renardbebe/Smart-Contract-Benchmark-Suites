 

pragma solidity ^0.5.0;

 
library  SafeMath {
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a );
        uint256 c = a - b;
        return c;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require( c >= a && c >= b );
        return c;
    }
}

 
contract Authorized {
     
    address public admin;
    bool public _openTransfer = false;

    constructor( address _admin ) public {
        admin = _admin;
    }

     
    event OpenTransfer( address indexed _operation, bool _previousFlag, bool _currentFlag );

     
    event CloseTransfer( address indexed _operation, bool _previousFlag, bool _currentFlag );

     
    modifier onlyAdmin( ) {
        require( msg.sender == admin);
        _;
    }

     
    modifier onlyOpen( ) {
        require( _openTransfer );
        _;
    }

     
    function openTransfer( ) public onlyAdmin returns(bool success) {
        require( !_openTransfer, "The flag is open");

        bool currentFlag = _openTransfer;
        _openTransfer = true;

        emit OpenTransfer(msg.sender, currentFlag, _openTransfer);
        return true;
    }

     
    function closeTransfer( ) public onlyAdmin returns(bool success) {
        require(_openTransfer, "The flag is close");

        bool currentFlag = _openTransfer;
        _openTransfer = false;

        emit CloseTransfer(msg.sender, currentFlag, _openTransfer);
        return true;
    }
}


contract LBKCoin is  Authorized {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public freezeOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, bool _flag);

     
    event Unfreeze(address indexed from, bool _flag);

    constructor( string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, address _admin ) public Authorized( _admin ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

         
        balanceOf[_admin] = totalSupply;
    }

     
    function transfer(address _to, uint256 _value) public onlyOpen {
         
        require( freezeOf[msg.sender] == false && freezeOf[_to] == false );
        require( _to != address(0) );
        require( _value > 0 );

        require (balanceOf[msg.sender] > _value) ;
        require ((balanceOf[_to] + _value ) > balanceOf[_to]) ;
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub( _value );
        balanceOf[_to] = balanceOf[_to].safeAdd( _value );
        emit Transfer(msg.sender, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public onlyOpen returns (bool success) {
         
        require( freezeOf[msg.sender] == false && freezeOf[_spender] == false );
        require( _spender != address(0) );
        require( _value >= 0 );
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyOpen returns (bool success) {
         
        require( freezeOf[msg.sender] == false && freezeOf[_from] == false && freezeOf[_to] == false );
        require( _to != address(0) );
        require( _value > 0 );

        require( balanceOf[_from] >= _value );
        require( (balanceOf[_to] + _value) >= balanceOf[_to] );

        require (_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function burn(uint256 _value) public onlyAdmin returns (bool success) {
        require( balanceOf[msg.sender] >= _value );
        require( _value > 0 );

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function freeze(address _freezeAddress) public onlyAdmin returns (bool success) {
        require( _freezeAddress != address(0) && _freezeAddress != admin );
        require( freezeOf[_freezeAddress] == false );
        freezeOf[_freezeAddress] = true;
        emit Freeze(_freezeAddress, freezeOf[_freezeAddress]);
        return true;
    }

     
    function unfreeze(address _unfreezeAddress) public onlyAdmin returns (bool success) {
        require( _unfreezeAddress != address(0) && _unfreezeAddress != admin );
        require( freezeOf[_unfreezeAddress] == true );
        freezeOf[_unfreezeAddress] = false;
        emit Unfreeze(_unfreezeAddress, freezeOf[_unfreezeAddress]);
        return true;
    }
}