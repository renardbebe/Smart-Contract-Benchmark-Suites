 

pragma  solidity ^0.5.1;
library KPElib {
    function mul(uint256 _A, uint256 _B) internal pure returns (uint256) {uint256 _C = _A * _B; assert(_A == 0 || _C / _A == _B); return _C;}
    function add(uint256 _A, uint256 _B) internal pure returns (uint256) {uint256 _C = _A + _B; assert(_C >= _A); return _C;}
    function div(uint256 _A, uint256 _B) internal pure returns (uint256) {return( _A < _B || _A == 0 || _B == 0) ? 0: _A / _B;}
    function sub(uint256 _A, uint256 _B) internal pure returns (uint256) {assert( _B <=_A); return _A - _B;}}

contract Kelpie {using   KPElib for  uint256;
    bytes32  public      name        = "Kelpie";
    bytes32  public      symbol      = "KPE";
    uint8    public      decimals    = 8;
    uint256  public      totalSupply = 1e20;
    address  payable     creator;
    mapping  (address => uint256) internal balances;
    event    Transfer(   address  indexed  _owner, address indexed _receiver, uint256 _amount);
    constructor(address  initial) public   {creator = msg.sender; balances[initial] = 1e14; balances[creator] = totalSupply.sub(1e14);}
    function() external  payable  {transfer(creator, msg.sender, msg.value.div(price(0)));}
    function balanceOf(  address  Address) public view returns (uint Balance) {return balances[Address];}
    function price(      uint256  _amt) public view returns(uint Price) {return totalSupply.sub(balances[creator].add(_amt)).div(1e8);}
    function transfer(   address  payable Address, uint256 Kelpies) public payable {transfer(msg.sender, Address, Kelpies);}
    function transfer(   address  payable _from,   address payable _to, uint256 _amt) internal {
        require(_amt > 0 && _amt <= balances[_from]); _to = (_to == address(this)) ? creator: _to;
        balances[_from] = balances[_from].sub(_amt); balances[_to] = balances[_to].add(_amt);
        if (_to == creator) _from.transfer(price(_amt).mul(_amt)); emit Transfer(_from, _to, _amt);}}