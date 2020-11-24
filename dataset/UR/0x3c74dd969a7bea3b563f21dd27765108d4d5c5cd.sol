 

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}





contract BaseCHIPToken {
    using SafeMath for uint256;

     
    address public owner;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Mint(address indexed to, uint256 amount);

     
    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner is allowed to call this."); 
        _; 
    }

    constructor() public{
        owner = msg.sender;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "You do not have sufficient balance.");
        require(_to != address(0), "You cannot send tokens to 0 address");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= balances[_from], "You do not have sufficient balance.");
        require(_value <= allowed[_from][msg.sender], "You do not have allowance.");
        require(_to != address(0), "You cannot send tokens to 0 address");

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

     
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who], "Insufficient balance of tokens");
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance to burn tokens.");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool){
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

}

contract CHIPToken is BaseCHIPToken {
    
     
    string  public constant name = "Chips";
    string  public constant symbol = "CHP";
    uint8   public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY      =  2000000000 * (10 ** uint256(decimals));
    uint256 public constant CROWDSALE_ALLOWANCE =  1000000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE     =  1000000000 * (10 ** uint256(decimals));
    
     
     
    uint256 public crowdSaleAllowance;       
    uint256 public adminAllowance;           
    address public crowdSaleAddr;            
    address public adminAddr;                
     
    bool    public transferEnabled = true;   

     
    modifier validDestination(address _to) {
        require(_to != address(0x0), "Cannot send to 0 address");
        require(_to != address(this), "Cannot send to contract address");
         
         
        require(_to != address(crowdSaleAddr), "Cannot send to crowdsale address");
        _;
    }

    modifier onlyCrowdsale {
        require(msg.sender == crowdSaleAddr, "Only crowdsale contract can call this");
        _;
    }

    constructor(address _admin) public {
        require(msg.sender != _admin, "Owner and admin cannot be the same");

        totalSupply_ = INITIAL_SUPPLY;
        crowdSaleAllowance = CROWDSALE_ALLOWANCE;
        adminAllowance = ADMIN_ALLOWANCE;

         
        balances[msg.sender] = totalSupply_.sub(adminAllowance);
        emit Transfer(address(0x0), msg.sender, totalSupply_.sub(adminAllowance));

        balances[_admin] = adminAllowance;
        emit Transfer(address(0x0), _admin, adminAllowance);

        adminAddr = _admin;
        approve(adminAddr, adminAllowance);
    }

     
    function transfer(address _to, uint256 _value) public validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public validDestination(_to) returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            if (msg.sender == crowdSaleAddr)
                crowdSaleAllowance = crowdSaleAllowance.sub(_value);
            if (msg.sender == adminAddr)
                adminAllowance = adminAllowance.sub(_value);
        }
        return result;
    }

     
    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(_amountForSale <= crowdSaleAllowance, "Sale amount should be less than the crowdsale allowance limits.");

         
        uint amount = (_amountForSale == 0) ? crowdSaleAllowance : _amountForSale;

         
        approve(crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);

        crowdSaleAddr = _crowdSaleAddr;
    }

    function setAllowanceBeforeWithdrawal(address _from, address _to, uint _value) public onlyCrowdsale returns (bool) {
        allowed[_from][_to] = _value;
        emit Approval(_from, _to, _value);
        return true;
    }
}