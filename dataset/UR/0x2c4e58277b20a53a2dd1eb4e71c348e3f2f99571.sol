 

pragma solidity 0.5.2;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract SYNCContract is Ownable
{

using SafeMath for uint256;
    mapping(address => uint256) internal balances;

    mapping(address => uint256) internal totalBalances;
    
    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => uint256) internal totalAllowed;

     
    uint256 internal totSupply;

     
    function totalSupply() view public returns(uint256)
    {
        return totSupply;
    }
    
     
    function getTotalAllowed(address _owner) view public returns(uint256)
    {
        return totalAllowed[_owner];
    }

     
    function setTotalAllowed(address _owner, uint256 _newValue) internal
    {
        totalAllowed[_owner]=_newValue;
    }

     

    function setTotalSupply(uint256 _newValue) internal
    {
        totSupply=_newValue;
    }


     

    function balanceOf(address _owner) view public returns(uint256)
    {
        return balances[_owner];
    }

     
    function setBalanceOf(address _investor, uint256 _newValue) internal
    {
        require(_investor!=0x0000000000000000000000000000000000000000);
        balances[_investor]=_newValue;
    }


     

    function allowance(address _owner, address _spender) view public returns(uint256)
    {
        require(msg.sender==_owner || msg.sender == _spender || msg.sender==getOwner());
        return allowed[_owner][_spender];
    }

     
    function setAllowance(address _owner, address _spender, uint256 _newValue) internal
    {
        require(_spender!=0x0000000000000000000000000000000000000000);
        uint256 newTotal = getTotalAllowed(_owner).sub(allowance(_owner, _spender)).add(_newValue);
        require(newTotal <= balanceOf(_owner));
        allowed[_owner][_spender]=_newValue;
        setTotalAllowed(_owner,newTotal);
    }


   constructor() public
    {
         
     
         
        cap = 48000000*1000000000000000000;
    }

    
    bytes32 public constant name = "SYNCoin";

    bytes4 public constant symbol = "SYNC";

    uint8 public constant decimals = 18;

    uint256 public cap;

    bool public mintingFinished;

     
    event Transfer(address indexed _from, address indexed _to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 value);

     
    event Mint(address indexed _to, uint256 amount);

     
    event MintFinished();

     
     
     
     
     

     
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function getName() pure public returns(bytes32)
    {
        return name;
    }

    function getSymbol() pure public returns(bytes4)
    {
        return symbol;
    }

    function getTokenDecimals() pure public returns(uint256)
    {
        return decimals;
    }
    
    function getMintingFinished() view public returns(bool)
    {
        return mintingFinished;
    }

     
    function getTokenCap() view public returns(uint256)
    {
        return cap;
    }

     
    function setTokenCap(uint256 _newCap) external onlyOwner
    {
        cap=_newCap;
    }

     
    function updateTokenInvestorBalance(address _investor, uint256 _newValue) onlyOwner external
    {
        setTokens(_investor,_newValue);
    }

     

    function transfer(address _to, uint256 _value) external{
        require(msg.sender!=_to);
        require(_value <= balanceOf(msg.sender));

         
        setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));

        emit Transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external {
        require(_value <= balanceOf(_from));
        require(_value <= allowance(_from,_to));
        setBalanceOf(_from, balanceOf(_from).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));
        setAllowance(_from,_to,allowance(_from,_to).sub(_value));
        emit Transfer(_from, _to, _value);
    }

     
    function approve(address _owner,address _spender, uint256 _value) external {
        require(msg.sender ==_owner);
        setAllowance(msg.sender,_spender, _value);
        emit Approval(msg.sender, _spender, _value);
    }


     
    function increaseApproval(address _owner, address _spender, uint _addedValue) external{
        require(msg.sender==_owner);
        setAllowance(_owner,_spender,allowance(_owner,_spender).add(_addedValue));
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

     
    function decreaseApproval(address _owner,address _spender, uint _subtractedValue) external{
        require(msg.sender==_owner);

        uint oldValue = allowance(_owner,_spender);
        if (_subtractedValue > oldValue) {
            setAllowance(_owner,_spender, 0);
        } else {
            setAllowance(_owner,_spender, oldValue.sub(_subtractedValue));
        }
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

     


    function mint(address _to, uint256 _amount) canMint internal{
        require(totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }
    
     
    function setTokens(address _to, uint256 _amount) canMint internal{
        if(_amount > balanceOf(_to)){
            uint256 diff = _amount.sub(balanceOf(_to));
            require( totalSupply().add(diff) <= getTokenCap());
            setTotalSupply(totalSupply().add(diff));
            setBalanceOf(_to, _amount);
        }else{
            uint256 diff = balanceOf(_to).sub(_amount);
            setTotalSupply(totalSupply().sub(diff));
            setBalanceOf(_to, _amount);
        }
        emit Transfer(address(0), _to, _amount);
    }    

     
    function finishMinting() canMint onlyOwner external{
        emit MintFinished();
    }

     
    
     
     

     
     
    
     
     

      
     

     
     
     
     

     
     
     
     
     

     
     
     
     
     

     
     
     
     
     

     
     
     
     

     
     
     

     
     
     
     
     

     
     
     
     

     
     
     
     
     
     

     
    
     
     
     
     

     
    function getOwner() view internal returns(address payable)
    {
        return owner;
    }

      
     
     
     
     
    function destroy() external onlyOwner{
        selfdestruct(getOwner());
    }
}