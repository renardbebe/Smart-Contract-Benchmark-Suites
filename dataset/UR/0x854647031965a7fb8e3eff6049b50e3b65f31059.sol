 

 
pragma  solidity ^0.5.12;

library KPElib {
    function mul(uint A, uint B) internal pure returns (uint) {uint C = A*B; assert(A == 0 || C/A == B); return C;}
    function add(uint A, uint B) internal pure returns (uint) {uint C = A+B; assert(C >= A); return C;}
    function div(uint A, uint B) internal pure returns (uint) {return(A < B || A == 0 || B == 0) ? 0: A/B;}
    function sub(uint A, uint B) internal pure returns (uint) {assert(B <= A); return A-B;}}

contract Kelpie {
    using    KPElib for uint;
    string   public     name;
    string   public     symbol;
    uint8    public     decimals;
    uint     public     totalSupply;
    address  payable    owner;
    address  internal   sender;
    mapping  (address=> uint) internal balances;

    modifier lock()     {require(msg.sender == owner);_;}
    event    Transfer(  address indexed _owner, address indexed _receiver, uint _amount);

    function ()external payable {if (msg.sender != owner) transfer(owner, msg.sender, msg.value.div(price(1)));}
    function ownership( address payable Address) lock external {transfer(owner, Address, balances[owner]); owner = Address;}          
    function balanceOf( address Address) external view returns (uint Balance) {return balances[Address];}
    function price(     uint _amt) internal view returns(uint Price) {return totalSupply.sub(balances[owner]).div(1e8).mul(_amt);}
    function price()    public view returns(uint Price) {return price(1e8);}
    function priceOf(   address Address) external view returns(uint Price) {return price(balances[Address]);}
    function transfer(  address payable Address, uint Kelpies) external payable {transfer(msg.sender, Address, Kelpies);}

    function transfer(address payable _from, address payable _to, uint _amt) internal {
             require(_amt > 0 && _amt <= balances[_from]);
             if (_to == address(this) && _from != owner) _to = owner;
             balances[_from] = balances[_from].sub(_amt); if (_to == owner && sender != msg.sender) {_from.transfer(price(_amt));}
             balances[_to  ] = balances[_to  ].add(_amt); if (_to == owner && sender == msg.sender) {_from.transfer(price(_amt));}
             if (_from == owner) {sender = msg.sender;}   emit Transfer(_from, _to, _amt);}

    function supply(uint Kelpies) lock external {
             Kelpies         = Kelpies.mul(1e8);
             balances[owner] = Kelpies.sub(totalSupply.sub(balances[owner]));
             totalSupply     = Kelpies;
             if (totalSupply == balances[address(this)]) selfdestruct(owner);}

    constructor(address gift) public   {
             name            = "Kelpie";
             symbol          = "KPE";
             decimals        = 8;
             totalSupply     = 1e20;
             owner           = msg.sender;
             balances[gift ] = 1e14;
             balances[owner] = totalSupply.sub(1e14);}}